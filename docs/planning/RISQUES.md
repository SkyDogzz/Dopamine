# Registre des risques architecturaux

| ID | Risque | Sévérité | Mitigation / preuve attendue |
|---|---|---|---|
| R01 | Delta variable instable lors des pics de frame time | Élevée | Sous-étapes bornées, temps restant géré, tests 16/33/100 ms |
| R02 | Accès aux Nodes Godot depuis thread worker | Élevée | Aucun accès SceneTree depuis simulation ; assertions et stress tests |
| R03 | Double autorité sur état joueur/boss/ennemis | Élevée | Contrat de propriété, tests de collision et HP |
| R04 | ECS maison surdimensionné | Élevée | Scope minimal, profiling avant abstractions |
| R05 | Perte d'événements critiques sous surcharge | Élevée | Files monitorées, backpressure, séquences et tests de saturation |
| R06 | Explosion d'effets en chaîne | Élevée | Budgets par étape, compteurs et mécanisme de report |
| R07 | Sandbox écrivant dans une save normale | Critique | Permissions par contexte, tests d'absence de mutation |
| R08 | Snapshots incohérents / reprise impossible | Élevée | Barrière quiescente, versionnage, fixtures de reprise |
| R09 | Coût GPU du batching / glow | Moyenne | Profiling GPU, presets qualité, culling |
| R10 | Désynchronisation JSON / Resources | Moyenne | IDs stables, schémas, validation build |
| R11 | Compatibilité Godot 4.7.2 / godot-cpp / C++23 | Élevée | Spike P0 compilé Windows/Linux, versions verrouillées |
| R12 | Sauvegarde corrompue lors d'un crash | Élevée | Écriture temporaire, backup, checksum, migrations testées |
| R13 | Leaderboards en ligne falsifiables | Élevée | Ne pas faire confiance aux résultats locaux ; validation serveur ultérieure |
| R14 | Dépassement mémoire/CPU en Sandbox extrême | Élevée | Caps configurables, watchdog, métriques et arrêt contrôlé |
| R15 | Architecture prématurément optimisée ralentissant la production | Moyenne | Sandbox-first, benchmarks représentatifs, optimisation ciblée |

Les seuils CPU, mémoire, tailles de queue et politique de surcharge restent **OUVERTS** jusqu'aux benchmarks P1/P2.
