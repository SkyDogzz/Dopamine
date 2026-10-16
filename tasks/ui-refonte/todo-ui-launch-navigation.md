# Tâches : `launch-navigation`

**Statut : terminé.** L’accueil et ses destinations sont livrés; revue physique d’entrée non disponible.

## Tâche 1 — Accueil et contrat du hub

**Description :** Créer une scène d’accueil thémée avec Jouer, Options, Quitter et l’accès secondaire Sandbox, en définissant `play_requested` sans fabriquer la scène du hub.

**Critères d’acceptation :**
- [x] L’accueil contient les quatre destinations, avec accès Sandbox visuellement secondaire.
- [x] Les contrôles sont focusables, ordonnés et gardent le focus visible.
- [x] Jouer émet un signal vérifiable sans démarrer directement une run ni pointer sur une fausse scène.

**Vérification :** Smoke ciblé `launch_navigation_smoke.gd` de la scène, du focus initial et du signal Jouer passé sous Godot 4.7.2 headless; inspection fenêtrée complète au checkpoint.

**Dépendances :** ui-foundation, ui-settings.

**Fichiers probables :** `game/scenes/launch_menu.tscn`, `game/scripts/launch_menu.gd`, `game/tests/launch_navigation_smoke.gd`.

**Portée estimée :** M.

## Tâche 2 — Options depuis l’accueil

**Description :** Instancier le panneau Options existant, gérer sa fermeture et restaurer le focus sur le bouton qui l’a ouvert.

**Critères d’acceptation :**
- [x] Options s’ouvre depuis l’accueil et applique les réglages existants.
- [x] Retour et Échap ferment le panneau sans quitter l’accueil. (Retour testé ici; Échap couvert par `ui_settings_smoke.gd`.)
- [x] À la fermeture, le focus est rendu à Options.

**Vérification :** `launch_navigation_smoke.gd` valide l’ouverture, Retour et la restauration du focus; `ui_settings_smoke.gd` confirme les Options et Échap. Les deux passent sous Godot 4.7.2 headless.

**Dépendances :** Tâche 1.

**Fichiers probables :** `game/scripts/launch_menu.gd`, `game/tests/launch_navigation_smoke.gd`.

**Portée estimée :** S.

## Tâche 3 — Démarrage et aller-retour Sandbox

**Description :** Définir l’accueil comme scène de démarrage, relier son accès secondaire au Sandbox existant, et ajouter le retour minimal vers l’accueil. Brancher Quitter sur l’API native Godot.

**Critères d’acceptation :**
- [x] Le projet démarre sur l’accueil; l’accès Sandbox ouvre `main.tscn`.
- [x] Le Sandbox revient à l’accueil par une commande claire, sans modifier ses outils de simulation.
- [x] Quitter appelle la fermeture native; le test n’interrompt pas son processus parent.
- [x] Aucun nouvel accès du Sandbox à `SaveService` ou à la progression.

**Vérification :** `launch_navigation_smoke.gd`, `sandbox_smoke.gd` et `survival_entry_smoke.gd` passent. `sandbox_ui_smoke.gd` et `save_service_smoke.gd` ne peuvent pas valider leurs écritures dans cet environnement : une sonde isolée confirme que `FileAccess.store_string()` laisse les fichiers `user://` vides sous les exécutions headless utilisées ici. Ce problème se reproduit aussi avec le démarrage Sandbox original temporairement rétabli. Inspection statique des fichiers Sandbox modifiés : aucun lien vers `SaveService`/progression ajouté.

**Dépendances :** Tâches 1 et 2.

**Fichiers probables :** `game/project.godot`, `game/scenes/main.tscn`, `game/scripts/main.gd`, `game/tests/launch_navigation_smoke.gd`, configuration des tests si nécessaire.

**Portée estimée :** M.

## Checkpoint — module prêt à revue

- [x] Toutes les tâches de code sont implémentées; une régression Sandbox reste à diagnostiquer.
- [x] Limite de revue fenêtrée initiale consignée; les smokes de navigation et les revues des modules UI ultérieurs sont consignés dans `docs/qa/TESTS.md`. Une interaction physique complète reste non vérifiée.
- [x] La séparation Sandbox/progression normale est contrôlée statiquement et par `sandbox_ui_smoke.gd`, qui préserve le slot sentinelle avec un profil temporaire isolé.
- [x] Limites d’environnement documentées; l’utilisateur a validé la poursuite vers `survival-hub`.
