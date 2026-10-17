# Contrat des snapshots Sandbox Lab

Statut : inventaire technique **[PROPOSÉ]**, sans changement du format de preset ni des sauvegardes normales.

## Frontière

Un snapshot représente une session du Sandbox Lab à un instant donné. Il ne capture jamais `SaveService`, `ProgressionService`, les récompenses d’une run normale ou un slot utilisateur. Les presets restent des configurations de départ partageables; un snapshot doit reprendre une simulation en cours.

Le snapshot doit être validé complètement avant restauration. Une version inconnue, un champ manquant/inattendu, une valeur non finie ou une référence d’entité invalide doit provoquer un refus sans modifier la session active.

## État à capturer

| Groupe | Données minimales | État du code |
|---|---|---|
| Format | version explicite du snapshot | absent du contrat public Lab |
| Simulation native | entités/slots et générations, positions, vitesses, PV, projectiles, DoT, Chill, champs persistants, temps simulé et séquence d’événements | `SimulationCoreState` capture/restaure ces données en C++; l’API GDExtension ne l’expose pas |
| Worker | pause, vitesse, steering, file de commandes, prochaine séquence, événements en attente, compteurs et logs | `SimulationWorkerState` capture/restaure ces données en C++; capture refusée si le worker ne peut pas répondre; restauration exige un worker arrêté |
| Run Godot | temps actif, PV, RNG seed/état, horloges d’armes, cibles verrouillées, états de chaînes/réactions et timers des attaques ennemies | conservé dans `SurvivalSession`, sans API de capture/restauration |
| Build et configuration Lab | `SandboxBuild`, équipement de test, statistiques personnalisées, seed et overrides acceptés | build/preset disponibles séparément dans `SandboxLabContext`; pas de capture atomique avec la session |

Les éléments de rendu dérivés (batches de sprites, particules/transitions visuelles) sont reconstruits depuis l’état restauré et ne font pas partie de la source de vérité. Les opérations UI en cours ne sont pas sérialisées; la capture et la restauration s’effectuent en pause.

## Couverture existante et écart

`simulation_core_test` et `simulation_worker_test` vérifient les copies natives, leur restauration, le rejet d’une version de worker incompatible, ainsi que la conservation et la validation des commandes en attente. `CombatSimulation.capture_state()` et `restore_state()` exposent maintenant cette couche native à Godot : le smoke `sandbox_snapshot_smoke.gd` capture un ennemi, le supprime, restaure son état et vérifie qu’une version incompatible est refusée sans altérer la simulation.

Cette API native est un checkpoint opaque en mémoire, format 17; elle ne fournit pas un format exportable. La tranche P8.6 reste ouverte jusqu’à son intégration atomique avec l’état Godot (RNG, horloges, build et configuration), le Lab et son test de reprise. Les commandes en attente sont testées dans `simulation_worker_test`; le smoke Godot couvre actuellement la reprise de l’état natif simple, pas l’orchestration d’une file de commandes depuis l’interface.

La reprise déterministe est limitée à l’état capturé : elle ne couvre ni le rendu dérivé, ni l’audio, ni les délais muraux du worker; elle ne promet pas une synchronisation identique des frames entre matériels. Les opérations de gameplay consomment le RNG Godot seedé du Lab; la restauration complète doit remettre son état et l’horloge active en place avec la simulation.

## Isolation

Les opérations de snapshot restent attachées au `SandboxLabContext` et à sa session isolée. Aucun chemin de capture/restauration ne reçoit une référence vers un service de sauvegarde ou de progression. L’import de profil demeure une copie locale du build et ne change pas cette frontière.
