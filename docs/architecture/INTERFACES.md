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

## Simulation native

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
