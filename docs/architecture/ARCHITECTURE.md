# Architecture technique — v1.0

## Objectif

Architecture hybride **Godot 4.7.2 + GDScript + C++23 via GDExtension**, simulation de combat sur thread dédié, ECS maison minimal et rendu 2D groupé. Cible de référence : **60 FPS, 500 ennemis, 2 000 projectiles, GPU intégré milieu de gamme, 16 Go RAM**. Le budget de frame à 60 FPS est **16,67 ms** pour tous les systèmes combinés.

## Schéma logique

```text
Godot / main thread
  UI Control · InputMap · Player · Bosses · Progression · Saves · Audio
       | commandes (Godot → C++)       ^ snapshots + events (C++ → Godot)
       v                              |
  CommandQueue                   SnapshotBuffer / EventQueue
       |                              ^
       v                              |
C++23 GDExtension / simulation thread
  ECS Registry · AI · Steering · Spatial Hash · Collision
  Damage Pipeline · Status Timers · Lifecycle · Metrics
       ^
       |
Config Resolver ← JSON balance + Resources + Sandbox Overrides
```

## Responsabilités

| Domaine | Autorité |
|---|---|
| Rendu, scènes, interface, audio, inputs | Godot |
| Déplacement et état des ennemis ordinaires | ECS C++ |
| Projectiles, collisions, dégâts et statuts ECS | ECS C++ |
| Joueur et boss complexes | Godot, avec contrat explicite de synchronisation |
| Équipement, progression, achievements | GDScript, consommateurs des événements C++ |
| Configurations effectives | Resolver avec base JSON + overrides Sandbox |
| Sauvegarde permanente | SaveService isolé du Sandbox |

**Invariant :** aucun état mutable ne doit avoir deux autorités. Le contrat de synchronisation joueur/boss avec la simulation est à détailler et tester dès P2.

Le joueur est contrôlé par une scène Godot `CharacterBody2D` ; ses actions InputMap couvrent WASD et les axes gauche du gamepad. `move_speed` est exporté et sa valeur de départ de 240 px/s est **[PROPOSÉE]** faute de valeur dans le GDD. La scène `survival_session.tscn` transmet la position globale joueur à `set_steering_target` lors de ses changements. Le worker reçoit une copie de cette cible et ne possède jamais le transform joueur. Le laboratoire Sandbox existant garde ses commandes propres.

## ECS

- `EntityId {uint32_t index, generation}` ; index réutilisable, génération incrémentée lors de la destruction.
- `SparseSet<T>` pour accès par entité ; SoA pour chemins chauds mesurés.
- Composants initiaux : `Transform2D`, `Velocity2D`, `Health`, `EnemyType`, `Projectile`, `StatusEffect`, `Lifetime`.
- Command buffers appliqués entre phases pour éviter l'invalidation des itérateurs.
- Aucun nœud `CharacterBody2D` individuel pour les ennemis ordinaires.
- P2 : `SimulationCore::query_radius` utilise un hash uniforme reconstruit à la requête et filtre précisément le rayon ; la taille de cellule (64 unités par défaut dans le contrat natif) reste un paramètre technique provisoire à profiler, pas une décision de design.

## Pipeline de simulation (ordre initial proposé)

1. Consommer commandes et changements de configuration validés.
2. IA, ciblage et steering ; séparation locale.
3. Déplacements et intégration du delta.
4. Construire ou actualiser le spatial hash.
5. Détecter overlaps et collisions balayées pour projectiles rapides.
6. Résoudre dégâts et effets secondaires via événements centralisés.
7. Avancer timers de statut et DOT.
8. Appliquer spawn/despawn en fin de phase.
9. Publier snapshot visuel et batch d'événements ; relever métriques.

Pour le steering, l’index spatial est construit une fois par passe et réutilisé pour toutes les entités. La cible monde vient du mode appelant ; son point d’autorité joueur reste **OUVERT**.

P2 implémente les projectiles ECS comme entités distinctes, leur durée de vie et un test balayé relatif au mouvement des cibles. Les impacts passent par `apply_damage`, émettent des événements séquencés et appliquent le despawn en fin de passe. Les rayons d’ennemi (12 unités) et le rayon projectile par défaut (3 unités) sont des paramètres provisoires faute de hitboxes validées.

La règle de HP decay est une fonction pure du temps actif fourni par le mode et d’une durée. Elle reprend la formule exacte marquée **[PROPOSÉ]** dans le GDD ; la propriété du HP joueur et de son horloge n’est pas encore fixée par le code.

## Delta variable : risques et invariants

**ACCEPTÉ :** delta variable, non déterministe. **PROPOSÉ :** bornage par sous-étapes lorsque `dt` devient excessif. Ne jamais jeter silencieusement le temps excédentaire : conserver un accumulateur ou documenter le ralentissement. Les statuts exprimés en secondes doivent produire des résultats raisonnablement stables quel que soit le nombre de frames ; les collisions rapides utilisent des swept tests. `Step` dans le Sandbox signifie avancer une durée explicite, par exemple 1/60 s, sans imposer un tick fixe global.

## Threading

- Le thread Godot principal possède les Nodes, `SceneTree`, rendu et UI.
- Le thread C++ possède les structures ECS mutables.
- Communication par queues bornées/monitorées, snapshots immuables double/triple-buffered et lots d'événements.
- Les snapshots visuels périmés peuvent être ignorés ; les événements de gameplay critiques ne doivent pas être perdus.
- Pause/stop/snapshot doivent constituer des points de synchronisation cohérents.

## Rendu

- `MultiMeshInstance2D` pour ennemis et projectiles simples ; regroupement par matériau/atlas.
- Animation par shader et index de frame d'atlas ; shaders 2D, glow mesuré, particules GPU.
- Résolution logique pixel art fixe, upscale entier lorsque l'affichage le permet.
- Réduire le nombre de draw calls et le coût de transfert des buffers ; mesurer CPU et GPU séparément.

## Combat

Pipeline de modificateurs typés et ordonnés (ordre proposé) : base → bonus plats → bonus additifs → multiplicateurs conditionnels → critiques → résistances → application → lifesteal/statuts/kill healing. La règle exacte de stacking doit être couverte par des tests de référence. Les effets en chaîne passent par une queue avec budget par étape, jamais par récursion illimitée.

## Modes et isolation

Survival, Endless, Armorless et Sandbox partagent le combat core. Sandbox possède son `SandboxContext` et ne reçoit jamais de capacité d'écriture dans les sauvegardes normales. Les overrides sont transactionnels ; les snapshots complets comprennent ECS, RNG, clocks, queues, config effective, build et état gameplay des nœuds Godot. L'absence de déterminisme interdit de considérer une seed comme un replay exact.

## Évolutivité

Éviter d'introduire immédiatement un scheduler de jobs complexe ou une abstraction ECS générique. Ajouter la parallélisation et optimiser SoA après profiling. Maintenir un runner C++ headless indépendant de l'interface Godot.
