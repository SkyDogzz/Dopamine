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

`spawn(type, count, position, hp, velocity, threat_level=1)` garde une menace sur les entités ennemies ; cette valeur accompagne leurs événements de dégâts et de mort. `spawn_enemy(type, count, position, direction)` applique les profils **[PROPOSÉS]** du GDD : Chaser 20 HP/75 px·s⁻¹, Sprinter 12/125, Tank 80/45, Shooter 25/65. Une direction non nulle est normalisée puis multipliée par la vitesse du profil ; une direction nulle utilise l’axe +X. La menace initiale des profils reste configurable dans le catalogue natif ; elle n’est pas présentée comme équilibre validé. `spawn_projectile(type, position, velocity, damage, radius, lifetime_seconds, burn_damage_per_tick, burn_interval_seconds, burn_duration_seconds)` ajoute un projectile au même pool d’entités ; les trois derniers arguments optionnels ne sont utilisés que par `inferno_sprayer`. À l’impact, cette arme applique ses dégâts directs puis remplace l’éventuel DoT d’une cible survivante avec la configuration du projectile. `apply_damage_over_time(index, generation, damage_per_tick, interval_seconds, duration_seconds)` remplace l’éventuel DoT d’une entité vivante (projectiles et orbes exclus) ; le premier tick arrive après un intervalle complet, les durées utilisent le temps simulé et un grand pas conserve tous les ticks dus avant expiration. Les événements de dégâts portent `is_damage_over_time` pour distinguer ces impacts. Le Sandbox expose ces paramètres sur l’entité sélectionnée; Survival configure la brûlure de l’Inferno avec des valeurs **[PROPOSÉES]** et réduit à 25 % le lifesteal théorique de ces ticks, conformément au GDD. `Step`/l’intégration continue déplacent le projectile et les ennemis, testent la distance minimale entre leurs segments relatifs (swept circle), appliquent les dégâts par la fonction centrale `apply_damage`, puis détruisent projectile consommé, cible morte ou projectile expiré. Le rayon d’ennemi est provisoirement 12 unités ; rayon de projectile et durée de vie viennent de la commande (défauts Sandbox : 3 unités et 5 s). Les modificateurs d’arme et résistances restent à implémenter. En Survival, le contact géométrique joueur-ennemi applique 10 HP **[PROPOSÉS]** avec 0,35 s d’invulnérabilité **[PROPOSÉE]**; rayons joueur/ennemi de 10/12 unités sont également provisoires. Les contrôles joueur s’arrêtent pendant les pauses, choix de chest et fin de run.

Chaque impact produit un événement `damage` ; un impact létal produit ensuite `death`. L’événement porte un numéro croissant, source, cible, type de la cible, montant, HP restants, menace et position de la cible. Le snapshot publie la file non acquittée. `acknowledge_events(last_sequence)` la vide jusqu’au numéro consommé. La file est bornée à 8 192 événements ; avec 2 000 entités actives, une passe peut émettre au plus 4 000 événements (dégâts + morts). Lorsque la réserve disponible est trop faible, le worker garde le temps écoulé et diffère l’intégration jusqu’à l’acquittement, sans supprimer les événements.

`spawn_xp_orb(position, xp_value)` ajoute une orbe au même pool ECS, mais les orbes sont exclues du steering et des collisions de projectiles. Survival en crée une à la position de chaque ennemi tué. `collect_xp_orb(index, generation)` détruit une orbe valide une seule fois et ajoute un événement séquencé `xp_collected` à la file acquittable. Les valeurs proposées par `SurvivalSession` sont 5 XP par ennemi, 10 XP pour le premier niveau suivant, puis +5 par niveau ; elles restent configurables et ne constituent pas un équilibrage validé. La progression est automatique et le surplus d’XP est conservé.

`SurvivalChestDirector` reçoit l’horloge active, les familles ayant au moins trois choix éligibles et les indicateurs élite/boss. Il applique les probabilités **[PROPOSÉES]** (0,5 % ordinaire, 15 % élite), garantit les familles éligibles sur boss et maintient un filet de sécurité configurable de 60 s après le dernier drop de chaque famille. Survival le relie aux événements de mort, dessine les chests dans le monde et ouvre le modal au pickup. `ChestChoice.present(options)` exige exactement trois identifiants uniques avec titre et description. `SurvivalSession.open_chest(options)` ouvre ce modal en pause; le choix émet `chest_option_chosen(id)`, applique le niveau/objet au loadout de run et reprend la simulation. Le catalogue de prototype prend les trois premières paires du GDD **[PROPOSÉ]**; il ne constitue pas encore la sélection validée des armes de départ. Les trois armes tirent maintenant des projectiles dans le cœur partagé : Inferno utilise un projectile direct, Crimson une paire en éventail; leurs cadences, dégâts, portées et progressions par niveau sont des réglages **[PROPOSÉS]**. Storm Core augmente les dégâts Lightning, Infernal Heart les dégâts Inferno, et Blood Chalice amplifie le soin proposé par élimination; les valeurs par niveau restent **[PROPOSÉES]**. Les brûlures/explosions Inferno, les effets de lifesteal/entailles Crimson, les évolutions et le niveau 5 de Lightning (deux cibles initiales) ne sont pas encore implémentés.

Le prototype de Blood Chalice ajoute aussi 5 % de lifesteal par niveau **[PROPOSÉ]** sur les événements de dégâts directs. Les soins sont cumulés par temps actif, avec le soft cap proposé de 10 HP/s puis 25 % d'efficacité sur le surplus. Les ticks DoT comptent désormais pour 25 % de ce lifesteal théorique, tel que proposé par le GDD; le lifesteal de l'évolution Bloodstorm reste à implémenter.

Le prototype n'active actuellement ce soin que lorsque Blood Chalice est équipé. Le taux de lifesteal général indépendant de la relique reste **[OUVERT]**.

`set_steering_target(position, max_speed, separation_radius, separation_weight)` transmet une cible monde fournie par le mode. Une commande `Step` ou une frame active recalcule le steering des entités simulées avant l’intégration. Pour `spawn_enemy`, le cœur préserve la vitesse propre de chaque profil **[PROPOSÉ]** ; `max_speed` s’applique aux entités créées par le spawn générique. La scène `survival_session.tscn` garde l’autorité sur le `CharacterBody2D` joueur et transmet sa position globale à chaque changement ; le worker ne publie aucune transform joueur. Les rayons et poids restent configurables et provisoires.

`health_decay_amount(active_time_seconds, delta_seconds)` calcule une perte sans muter d’état HP. Avec la config par défaut issue de la formule **[PROPOSÉE]** du GDD, le calcul exact est `delta × (base_rate + slope × (active_time + delta/2))`, avec base 1,5 HP/s et pente 0,004 HP/s². `HealthDecayConfig` permet de tester/ajuster les coefficients. Le GDD fixe **[VALIDÉ]** le HP initial à 100 ; `SurvivalSession` garde l’instance HP côté Godot et consomme le temps actif publié par la simulation. La décroissance s’arrête lorsque son horloge est en pause.

`kill_heal_amount(threat_level)` calcule le soin **[PROPOSÉ]** `2 + 3√T`, en bornant T à `[0,5 ; 25]`. `SurvivalSession` consomme chaque événement `death` une fois, ajoute ce montant au HP Godot et le plafonne au HP initial courant ; le cœur reste sans état joueur et le Sandbox n’applique que le preview. Les coefficients et bornes sont configurables via `KillHealConfig` dans le cœur natif.

La session Survival utilise un prototype automatique **[PROPOSÉ]** Lightning Conductor. L’interprétation de travail de ses deux chaînes au niveau 1 est de tirer sur les deux ennemis distincts les plus proches. Cadence 0,5 s, dégâts 12, portée 600 unités, vitesse de projectile 800 unités/s, rayon 4 et durée 2 s sont des valeurs configurables de départ, car ces paramètres restent à rédiger dans le GDD. Le smoke test headless vérifie deux cibles, leurs morts, le soin et l’acquittement des événements.

Le HUD de `SurvivalSession` affiche le HP courant/plafond, l’horloge active en minutes/secondes, le nom et le nombre de chaînes de l’arme prototype, l’XP courante/prochain niveau, le niveau, l’état de run et la vague avec son timer. Le spawn de base utilise les courbes de population et HP **[PROPOSÉES]** du GDD, avec un cap local configurable (80 par défaut). Les compositions et comportements d’ennemis restent provisoires. Aux vagues 12 et 24, des placeholders à HP élevé sont créés; leurs patterns et récompenses restent **[OUVERTS]**. À la mort réelle du boss final, les chests boss éligibles sont générés selon le contrat de loot; l’écran de victoire attend leur collecte et le choix de chaque offre générée, puis met la session en pause. Le smoke d’intégration traverse les 24 vagues en utilisant `debug_advance_wave()` et retire les placeholders pour vérifier le flow; un smoke dédié vérifie la mort réelle du boss final et le traitement de ses chests. Cela ne valide pas encore une run de combat de 12 minutes ni les patterns des boss.

Le lancement standard démarre dans le Sandbox; son bouton `PLAY SURVIVAL` ouvre la session Survival. Celle-ci commence en pause et demande un choix parmi deux armes initiales. Le prototype utilise Lightning Conductor et Inferno Sprayer (deux premières paires de la liste du GDD) **[PROPOSÉ]**; cette sélection n’est pas une décision de design validée. La défaite par HP nul ou la victoire après le boss final ouvre un écran de résultat avec vague, temps actif et kills; `NEW RUN` recharge une session fraîche sans importer de progression persistante. Les contacts avec les ennemis font perdre les HP selon les réglages provisoires décrits ci-dessus.

## Scénarios headless Sandbox P1

`game/scripts/scenario_runner.gd` lit un scénario JSON versionné (limite 1 Mio et 1 000 commandes), soumet les mêmes commandes au pont `CombatSimulation`, vérifie les attentes déclarées et exporte un JSON horodaté avec la version Godot, le temps simulé, les métriques, les entités, les événements de combat et les logs. Les scénarios acceptent `spawn`, `spawn_enemy`, `spawn_projectile`, `despawn`, `kill_all`, `pause`, `resume`, `step`, `set_speed`, `set_steering_target` et `reset`. Le runner ne charge ni n’écrit de sauvegarde normale.

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
- Joueur/boss : `SurvivalSession` garde provisoirement le HP et le transform joueur sous autorité Godot, testés dans l’intégration ; l’autorité des hitboxes/collisions joueur-boss et leur contrat complet restent **OUVERTS**.
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
