# Contrat des snapshots Sandbox Lab

Statut : snapshot de session Lab en mémoire, version 1. Il ne change ni le format de preset ni les sauvegardes normales.

## Frontière

Un snapshot représente une session du Sandbox Lab à un instant donné. Il ne capture jamais `SaveService`, `ProgressionService`, les récompenses d’une run normale ou un slot utilisateur. Les presets restent des configurations de départ partageables; un snapshot doit reprendre une simulation en cours.

Le snapshot doit être validé complètement avant restauration. Une version inconnue, un champ manquant/inattendu, une valeur non finie ou une référence d’entité invalide doit provoquer un refus sans modifier la session active.

## État à capturer

| Groupe | Données minimales | État du code |
|---|---|---|
| Format | version explicite du snapshot | version 1, strictement validée |
| Simulation native | entités/slots et générations, positions, vitesses, PV, projectiles, DoT, Chill, champs persistants, temps simulé et séquence d’événements | checkpoint opaque natif format 17, validé avant restauration |
| Worker | pause, vitesse, steering, file de commandes, prochaine séquence, événements en attente, compteurs et logs | inclus dans le checkpoint natif; la capture passe par la barrière worker |
| Run Godot | variables primitives/tableaux/dictionnaires prises en charge, RNGs, position/vitesse joueur, cible, vague, loadout et timers de coffres | `SurvivalSession.capture_sandbox_snapshot_state()`; uniquement en pause et hors modal/fin de run |
| Build et configuration Lab | `SandboxBuild`, preset, seed, God Mode et overrides LIVE | capturés dans `SandboxLabContext`; validation du preset/build avant toute mutation |

Les éléments de rendu dérivés (batches de sprites, particules/transitions visuelles) sont reconstruits depuis l’état restauré et ne font pas partie de la source de vérité. Les opérations UI en cours ne sont pas sérialisées; la capture et la restauration s’effectuent en pause.

## Couverture existante et écart

`simulation_core_test` et `simulation_worker_test` vérifient les copies natives, leur restauration, le rejet d’une version de worker incompatible, ainsi que la conservation et la validation des commandes en attente. `CombatSimulation.capture_state()` et `restore_state()` exposent cette couche native à Godot. Le smoke `sandbox_snapshot_smoke.gd` couvre aussi la capture et la reprise d’une session Lab complète : build, RNG, horloges, position joueur, état natif et overrides LIVE. Il vérifie le rejet d’une version incompatible et d’un build dépassant les slots, sans altérer la session.

Le Lab expose `CAPTURE SNAPSHOT` et `RESTORE SNAPSHOT`; un seul checkpoint est conservé en mémoire jusqu’au changement de preset ou à la fermeture du Lab. Les actions sont désactivées hors pause et refusées en présence d’un choix modal ou d’un état terminal. Le checkpoint n’est ni exportable ni persistant. Les saves normales, la progression et les récompenses ne sont jamais capturées ou modifiées. Les commandes en attente sont couvertes par `simulation_worker_test`; le bouton de capture s’appuie sur la barrière native.

La reprise déterministe est limitée à l’état capturé : elle ne couvre ni le rendu dérivé, ni l’audio, ni les délais muraux du worker; elle ne promet pas une synchronisation identique des frames entre matériels. Les opérations de gameplay consomment le RNG Godot seedé du Lab; la restauration complète doit remettre son état et l’horloge active en place avec la simulation.

## Isolation

Les opérations de snapshot restent attachées au `SandboxLabContext` et à sa session isolée. Aucun chemin de capture/restauration ne reçoit une référence vers un service de sauvegarde ou de progression. L’import de profil demeure une copie locale du build et ne change pas cette frontière.
