# Tâches : `launch-navigation`

**Statut : proposé pour validation.** N’exécuter aucune tâche avant validation de cette liste et du [`plan`](plan-ui-launch-navigation.md).

## Tâche 1 — Accueil et contrat du hub

**Description :** Créer une scène d’accueil thémée avec Jouer, Options, Quitter et l’accès secondaire Sandbox, en définissant `play_requested` sans fabriquer la scène du hub.

**Critères d’acceptation :**
- [ ] L’accueil contient les quatre destinations, avec accès Sandbox visuellement secondaire.
- [ ] Les contrôles sont focusables, ordonnés et gardent le focus visible.
- [ ] Jouer émet un signal vérifiable sans démarrer directement une run ni pointer sur une fausse scène.

**Vérification :** Smoke ciblé de la scène, du focus, de l’ordre des boutons et du signal Jouer; inspection fenêtrée.

**Dépendances :** ui-foundation, ui-settings.

**Fichiers probables :** `game/scenes/launch_menu.tscn`, `game/scripts/launch_menu.gd`, `game/tests/launch_navigation_smoke.gd`.

**Portée estimée :** M.

## Tâche 2 — Options depuis l’accueil

**Description :** Instancier le panneau Options existant, gérer sa fermeture et restaurer le focus sur le bouton qui l’a ouvert.

**Critères d’acceptation :**
- [ ] Options s’ouvre depuis l’accueil et applique les réglages existants.
- [ ] Retour et Échap ferment le panneau sans quitter l’accueil.
- [ ] À la fermeture, le focus est rendu à Options.

**Vérification :** Smoke d’ouverture/fermeture clavier et signal de fermeture; régression `ui_settings_smoke.gd`.

**Dépendances :** Tâche 1.

**Fichiers probables :** `game/scripts/launch_menu.gd`, `game/tests/launch_navigation_smoke.gd`.

**Portée estimée :** S.

## Tâche 3 — Démarrage et aller-retour Sandbox

**Description :** Définir l’accueil comme scène de démarrage, relier son accès secondaire au Sandbox existant, et ajouter le retour minimal vers l’accueil. Brancher Quitter sur l’API native Godot.

**Critères d’acceptation :**
- [ ] Le projet démarre sur l’accueil; l’accès Sandbox ouvre `main.tscn`.
- [ ] Le Sandbox revient à l’accueil par une commande claire, sans modifier ses outils de simulation.
- [ ] Quitter appelle la fermeture native; le test n’interrompt pas son processus parent.
- [ ] Aucun nouvel accès du Sandbox à `SaveService` ou à la progression.

**Vérification :** Smoke d’intégration des changements de scène; smokes `sandbox_smoke.gd`, `sandbox_ui_smoke.gd` et entrée Survival pertinente; inspection statique des dépendances.

**Dépendances :** Tâches 1 et 2.

**Fichiers probables :** `game/project.godot`, `game/scenes/main.tscn`, `game/scripts/main.gd`, `game/tests/launch_navigation_smoke.gd`, configuration des tests si nécessaire.

**Portée estimée :** M.

## Checkpoint — module prêt à revue

- [ ] Toutes les tâches et critères d’acceptation sont vérifiés.
- [ ] Les résolutions UI prévues sont inspectées et les contrôles sans souris testés au mieux de l’environnement disponible.
- [ ] La séparation Sandbox/progression normale est contrôlée.
- [ ] Limites d’environnement documentées; revue utilisateur effectuée avant `survival-hub`.
