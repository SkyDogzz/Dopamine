# Contrats et interfaces — v1.0

Les exemples ci-dessous sont des **interfaces de conception proposées**, pas une API compilable définitive. Elles doivent être affinées en P0/P1.

## Contrat natif P1 implémenté

`SimulationCore` reste indépendant de Godot et appartient exclusivement à `SimulationWorker`. Le worker possède le thread de simulation ; aucun Node ni élément du `SceneTree` n'est accédé depuis ce thread.

- `submit(command)` ajoute une commande ordonnée et renvoie son numéro de séquence ; `0` signifie qu'elle a été refusée.
- La file accepte jusqu'à 2 048 commandes en attente. Le snapshot publie le dernier numéro appliqué.
- Le worker démarre en pause. `Step` exige une durée positive et finie, et seulement une simulation en pause ; la vitesse configurée (×0,25 à ×4) multiplie sa durée.
- Spawn est limité à 500 entités par commande et 2 000 entités actives. Les valeurs d'entité non valides sont rejetées et consignées.
- Les snapshots sont publiés atomiquement sous forme de `shared_ptr<const SimulationSnapshot>` ; les anciennes versions restent immuables.
- `stop()` réveille puis joint le worker ; l'état est publié après sa terminaison.

## Pont GDExtension P1 implémenté

`CombatSimulation` démarre son worker en pause. Les méthodes de commandes renvoient un numéro de séquence positif quand la commande entre dans la file, ou `0` si l'entrée est refusée. Elles ne bloquent pas le thread Godot.

```gdscript
var sequence = simulation.spawn("chaser", 5, Vector2(100, 80), 20.0, Vector2(0, 1))
simulation.despawn(entity_index, entity_generation)
simulation.kill_all()
simulation.pause()
simulation.resume()
simulation.step(1.0 / 60.0)
simulation.set_speed(2.0)
simulation.reset()
var state: Dictionary = simulation.snapshot()
```

Le snapshot contient l'état `paused`, `speed_multiplier`, `simulation_time`, `last_sequence`, `rejected_commands`, une liste `entities` (ID index/génération et composants `Transform2D`, `Velocity2D`, `Health`, `EnemyType`), les `metrics` et les `logs`. Godot reçoit des valeurs copiées ; aucune référence mutable du worker n'est exposée. `CombatSimulation` n'a pas accès au service de sauvegarde.

`spawn_projectile(type, position, velocity, damage, radius, lifetime_seconds)` ajoute un projectile au même pool d’entités. `Step`/l’intégration continue déplacent le projectile et les ennemis, testent la distance minimale entre leurs segments relatifs (swept circle), appliquent les dégâts par la fonction centrale `apply_damage`, puis détruisent projectile consommé, cible morte ou projectile expiré. Le rayon d’ennemi est provisoirement 12 unités ; rayon de projectile et durée de vie viennent de la commande (défauts Sandbox : 3 unités et 5 s). Les modificateurs d’arme, résistances, statuts et dégâts de contact ne sont pas encore implémentés.

Chaque impact produit un événement `damage` ; un impact létal produit ensuite `death`. L’événement porte un numéro croissant, source, cible, montant et HP restants. Le snapshot publie la file non acquittée. `acknowledge_events(last_sequence)` la vide jusqu’au numéro consommé. La file est bornée à 8 192 événements ; avec 2 000 entités actives, une passe peut émettre au plus 4 000 événements (dégâts + morts). Lorsque la réserve disponible est trop faible, le worker garde le temps écoulé et diffère l’intégration jusqu’à l’acquittement, sans supprimer les événements.

`set_steering_target(position, max_speed, separation_radius, separation_weight)` transmet une cible monde fournie par le mode. Une commande `Step` ou une frame active recalcule le steering des entités simulées avant l’intégration. Les valeurs de vitesse/rayon/poids sont configurables et restent provisoires ; l’appelant conserve l’autorité sur la position du joueur, conformément au point encore **OUVERT** concernant joueur/boss.

## Scénarios headless Sandbox P1

`game/scripts/scenario_runner.gd` lit un scénario JSON versionné (limite 1 Mio et 1 000 commandes), soumet les mêmes commandes au pont `CombatSimulation`, vérifie les attentes déclarées et exporte un JSON horodaté avec la version Godot, le temps simulé, les métriques, les entités, les événements de combat et les logs. Les scénarios acceptent `spawn`, `spawn_projectile`, `despawn`, `kill_all`, `pause`, `resume`, `step`, `set_speed`, `set_steering_target` et `reset`. Le runner ne charge ni n’écrit de sauvegarde normale.

```bash
godot --headless --path game --script res://scripts/scenario_runner.gd -- \\
  --scenario=res://scenarios/dev_sandbox.json --output=/tmp/result.json
```

Quand Godot est disponible à la configuration, CTest inclut les smoke tests GDScript et le scénario après un import headless initial du projet.

## Simulation native

Le cœur expose aussi `query_radius(x, y, radius, SpatialHashConfig)` pour les recherches locales nécessaires au steering et aux collisions. Il valide les valeurs finies, utilise `floor` pour les coordonnées négatives et retourne uniquement les cibles actives (hors projectiles) dans le rayon (bord inclus), dans l’ordre stable des IDs. La requête autonome reconstruit son index à l’appel ; le steering et la passe projectile partagent chacun un index spatial par passe. La taille de cellule par défaut est une valeur provisoire, modifiable à l’appel.

```cpp
struct EntityId { uint32_t index; uint32_t generation; };
struct SimulationCommand { uint64_t sequence; /* type + payload typé */ };
struct RenderInstance { float x, y, rotation, scale; uint32_t sprite_id, frame, tint_rgba; };

class CombatSimulation {
public:
    void start(const SimulationConfig&);
    void stop();
    void enqueue_command(const SimulationCommand&);
    SnapshotHandle acquire_snapshot() const;
    void release_snapshot(SnapshotHandle);
    EventBatch drain_events();
    SimulationMetrics metrics() const;
};
```

## GDExtension / GDScript

```gdscript
simulation.start_run(run_config)
simulation.submit_player_input(input_state)
simulation.request_spawn(enemy_type, count)
simulation.apply_sandbox_overrides(overrides)
var snapshot = simulation.get_render_snapshot()
var events = simulation.drain_combat_events()
```

Les méthodes GDExtension n'exposent pas de pointeurs ECS ni de références mutables à un autre thread.

## Messages

| Message | Direction | Garantie attendue |
|---|---|---|
| InputState | Godot → C++ | ordre par numéro de séquence |
| SpawnCommand | Godot → C++ | accusé d'application ou erreur |
| OverrideTransaction | Godot → C++ | validation et commit atomiques |
| RenderSnapshot | C++ → Godot | version cohérente, périmé jetable |
| Damage/Death/RewardEvent | C++ → Godot | aucun événement critique perdu |
| MetricsSnapshot | C++ → Godot | fréquence ajustable, sans blocage |
| Pause/Step/Stop | Godot → C++ | barrière de synchronisation |

## Règles de propriété

- Simulation : autorité sur HP/positions des ennemis et impacts de projectiles.
- Godot : autorité sur menus, progression permanente, rendu et entrées.
- Joueur/boss : établir explicitement le point de vérité pour HP, hitboxes et transforms ; **OUVERT**, à valider dans un test d'intégration.
- Un événement consommé par les achievements doit être identifié pour empêcher le double comptage.

## Contrat des configurations

`base JSON → validation JSON Schema → cache typé → override Sandbox validé → config effective immuable pour l'étape courante`. Les changements structurels peuvent exiger une pause/reconstruction ; certains paramètres peuvent exiger un redémarrage.

## Sauvegardes et snapshots

```text
user://saves/slot_01.json
user://sandbox/presets/<id>.json
user://sandbox/snapshots/<id>.snapshot
user://sandbox/logs/<id>.jsonl
```

- Écriture de save : fichier temporaire → validation → backup → remplacement atomique lorsque supporté.
- Migrations versionnées automatiques et checksum ; restauration du backup si corruption.
- Snapshot : capture sur état quiescent avec version de format, ECS, générations, clocks, RNG, files en attente, build, config, gameplay Godot.
- Preset partageable : JSON canonique, compression, code versionné, checksum, validation des tailles et limites ; jamais de code arbitraire.
