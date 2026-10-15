# Suivi du goal

## Phase 0 — Fondations Linux

- [x] Projet Godot 4.7.2 + GDExtension C++23 créé.
- [x] `godot-cpp` verrouillé au commit `b8530af7546a3fcae80cef2477526569fd42ffc2`.
- [x] CMake compile et Godot charge l’extension via import headless puis lancement headless.

## Phase 1 — Cœur partagé

- [x] Modèle ECS minimal (Transform2D, Velocity2D, Health, EnemyType) et test ciblé.
- [x] Worker, file de commandes, pause/reprise/step et snapshots immuables.
- [x] Contrat natif documenté et pont GDExtension smoke-testé.

## Phase 2 — Sandbox développeur MVP

- [x] Contrôles de simulation et spawn/despawn.
- [x] Inspecteur, métriques et logs.
- [x] Runner headless, export JSON des métriques et absence d’accès aux saves normales.

## Phase 3 — Combat core

- [ ] Mouvement joueur et profils d’ennemis, avant la liaison au mode Survival.
- [x] Spatial hash uniforme minimal avec requête de rayon native ; paramètres de cellule à profiler.
- [x] Steering de poursuite et séparation locale avec cible fournie par le mode ; paramètres initiaux provisoires.
- [x] Projectiles ECS, collisions balayées, dégâts centraux, mort et file d’événements non perdus tant que l’acquittement est différé.
- [x] Fonction pure de HP decay, paramètres par défaut encore proposés, exemples GDD validés par test.
- [x] Menace portée par les ennemis et événements de mort ; formule de soin proposée calculée comme preview, sans changer le HP joueur.
- [x] Profils d’ennemis proposés disponibles dans le cœur et dans les scénarios Sandbox.
- [x] Scène de déplacement joueur configurable sous Godot, avec actions clavier et manette.
- [x] Scène Survival minimale : position monde du joueur transmise au steering ECS ; vitesses des profils conservées.
- [x] Relier HP decay à l’horloge active Survival et appliquer les soins des événements de mort au HP Godot.
- [x] Prototype de tir automatique Lightning Conductor ; chaînes distinctes ciblées et valeurs de combat configurables, toutes proposées.
- [x] Contrôles Sandbox pour les statuts, lifesteal Blood Chalice sur dégâts directs et ticks DoT à 25 % du taux théorique; le taux de base indépendant de la relique reste **[OUVERT]**.
- [x] Dégâts de contact joueur-ennemi et invulnérabilité provisoires en Survival; contrôles suspendus pendant les pauses et fins de run.

## Phase 4 — Premier playable Survival

- [x] HUD HP/temps actif/arme/XP/niveau/état de run dans la scène Survival.
- [x] Prototype XP : une orbe partagée apparaît à la mort d’un ennemi, se collecte une fois et fait progresser le niveau.
- [x] Prototype vagues : 24 vagues, horloge arrêtée pendant les placeholders boss, spawns selon courbes proposées et HUD vague.
- [x] HUD boss : barre HP courants/max et état de victoire distinct de la défaite.
- [x] Chests Survival : mort→drop→pickup→modal à trois choix→mise à jour du loadout et reprise; sélection du catalogue **[PROPOSÉE]**.
- [x] Projectiles prototypes Inferno/Crimson, brûlure, saignement Bloodstorm, Infinite Circuit ramifié, explosion Wildfire et modificateurs de reliques testés. Blood Chalice accorde un lifesteal direct de 5 %/niveau **[PROPOSÉ]** avec soft cap.
- [x] Écran de choix d’arme initiale parmi deux prototypes **[PROPOSÉS]**, entrée Survival depuis le Sandbox, victoire/défaite avec résumé et redémarrage.
- [x] Déclencheur Bloodstorm au niveau 5 avec Blood Chalice; saignement et lifesteal sur ticks testés, réglages encore **[PROPOSÉS]**.
- [ ] Effets d’évolution restants; confirmer le pool de départ du vertical slice. Les réglages d’explosion Wildfire et de branchement Infinite Circuit restent **[PROPOSÉS]**.
- [ ] Vagues, chests, 3 armes/reliques, mid-boss et boss final.
- [ ] HUD, fin de run, sauvegarde minimale et vérification QA complète.

## Jalons v1.6 — P5 à P9 (état actualisé)

Les prototypes de progression des anciennes tâches P5 correspondent maintenant à du travail anticipé pour P6. Le prochain jalon attendu est le contenu P5 du GDD v1.6.

- [ ] **P5 contenu** Dix armes, onze reliques incluant Magnet Heart, évolutions automatiques, règles de coffre, 8–12 familles d'ennemis et boss à phases.
- [ ] Invariant P5 : aucun bonus de pickup n'attire un coffre ; tests d'armes/statuts/synergies dans le Sandbox.
- [~] **P6 progression (prototype anticipé, non terminé)** Profil v5, Powder/enhancement, deux nodes et Exterminator, équipement/effets prototypes existent. Valeurs encore proposées ; catalogue et migrations/calibrations incomplets ; certains effets ne font rien.
- [ ] **P7** Armorless selon décisions validées ; arbitrer Endless standard avant développement.
- [ ] **P8** Sandbox Lab joueur : presets/codes, import isolé, snapshot/reprise complets.
- [ ] **P9** Équilibrage, accessibilité, performance mesurée sur GPU intégré, Windows et préparation de livraison.

Les critères de sortie détaillés figurent dans [`docs/planning/ROADMAP.md`](../docs/planning/ROADMAP.md). Les tests historiques cochés plus haut restent les résultats documentés au moment de leur exécution ; ils ne signifient pas qu'ils ont été relancés pendant le présent audit.

## Audit code/GDD du 2026-10-15

- [x] Revue statique des scripts/catalogues Survival, progression, sauvegarde, scènes, QA et contrats GDD v1.6.
- [x] Statuts distingués entre code présent, prototype, absence de fonctionnalité et QA historique.
- [x] Godot n'est pas détecté dans cet environnement ; aucune suite GDScript n'a été relancée pour cet audit documentaire.
- [x] Roadmap détaillée P0–P9 mise à jour dans `docs/planning/ROADMAP.md`.
