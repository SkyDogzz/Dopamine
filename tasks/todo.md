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
- [ ] Ajouter les contrôles Sandbox pour lifesteal et statuts; intégrer le lifesteal des dégâts sur la durée et clarifier le taux de base **[OUVERT]**.
- [x] Dégâts de contact joueur-ennemi et invulnérabilité provisoires en Survival; contrôles suspendus pendant les pauses et fins de run.

## Phase 4 — Premier playable Survival

- [x] HUD HP/temps actif/arme/XP/niveau/état de run dans la scène Survival.
- [x] Prototype XP : une orbe partagée apparaît à la mort d’un ennemi, se collecte une fois et fait progresser le niveau.
- [x] Prototype vagues : 24 vagues, horloge arrêtée pendant les placeholders boss, spawns selon courbes proposées et HUD vague.
- [x] HUD boss : barre HP courants/max et état de victoire distinct de la défaite.
- [x] Chests Survival : mort→drop→pickup→modal à trois choix→mise à jour du loadout et reprise; sélection du catalogue **[PROPOSÉE]**.
- [x] Projectiles prototypes Inferno/Crimson, brûlure, saignement Bloodstorm et modificateurs de reliques testés; explosions Inferno et effets Infinite Circuit restent à implémenter. Blood Chalice accorde un lifesteal direct de 5 %/niveau **[PROPOSÉ]** avec soft cap.
- [x] Écran de choix d’arme initiale parmi deux prototypes **[PROPOSÉS]**, entrée Survival depuis le Sandbox, victoire/défaite avec résumé et redémarrage.
- [x] Déclencheur Bloodstorm au niveau 5 avec Blood Chalice; saignement et lifesteal sur ticks testés, réglages encore **[PROPOSÉS]**.
- [ ] Infinite Circuit, Wildfire et autres effets d’évolution; confirmer le pool de départ du vertical slice.
- [ ] Vagues, chests, 3 armes/reliques, mid-boss et boss final.
- [ ] HUD, fin de run, sauvegarde minimale et vérification QA complète.
