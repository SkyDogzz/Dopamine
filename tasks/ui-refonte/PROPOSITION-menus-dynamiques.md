# Proposition — menus et transitions plus dynamiques

**Statut :** proposition de travail en attente de revue utilisateur. Ce document n’approuve aucun changement de design. Il complète l’intention générale de [`INTENTION_REFONTE_UI.md`](../../docs/planning/INTENTION_REFONTE_UI.md) sans modifier les décisions acceptées ni les specs livrées.

## Objectif

Rendre les écrans hors combat plus rythmés et leurs actions plus lisibles, en priorité dans les menus et leurs transitions. Les choix d’arme, de difficulté, d’équipement, les récompenses, les règles de run et la frontière Sandbox/progression restent inchangés.

## Références et constats

- **[VALIDÉ]** L’Art Bible demande des menus pixel art sobres, des transitions pixel rapides, des boutons bordés et des textes lisibles. La résolution logique de référence est 1280×720.
- **[VALIDÉ]** Le parcours principal, la navigation clavier/manette, le focus visible et la réduction des effets visuels sont déjà des contraintes du projet.
- **[VALIDÉ]** `UIFeedback` fournit déjà un retour de focus, de survol et d’appui; les sons UI existent. L’accueil joue déjà sa musique et anime des enseignes du skyline.
- **État observé :** les scripts actuels de menu n’animent pas les changements de scène. Les captures de référence couvrent l’accueil et le hub; des smokes couvrent notamment le choix d’arme, les options, la pause, les résultats et plusieurs layouts.
- **[OUVERT]** La durée exacte, la forme des transitions, les limites des clignotements et le comportement audio des menus ne sont pas définis. L’écoute sur matériel audio et le parcours sur manette physique restent à faire.

## Ordre proposé

Chaque phase attend l’approbation de son périmètre avant toute modification du jeu. Les durées ci-dessous sont des propositions à confirmer, pas des critères déjà acceptés.

### Phase 1 — Accueil, hub et entrée en run

**Écrans :** accueil, hub Survival, choix de l’arme de départ.

**[PROPOSÉ]** Ajouter une transition pixel courte entre ces destinations et au retour vers l’accueil. Une durée de 100–140 ms est une première proposition. Le choix est appliqué après réception de l’action; la navigation conserve un focus valide à l’arrivée. Si la réduction des effets visuels est activée, passer directement à l’écran demandé.

**[PROPOSÉ]** Au hub, rendre le changement de difficulté et le lancement plus perceptibles par un état sélectionné net et un retour audio bref, sans modifier le texte de règles ni les valeurs de difficulté. Au choix d’arme, marquer clairement l’arme sélectionnée et fournir un bref retour visuel/audio à chaque changement; garder l’action de confirmation visible.

**Vérifications ciblées prévues après approbation :** `launch_navigation_smoke.gd`, `survival_hub_smoke.gd`, `survival_hub_layout_smoke.gd`, `survival_starting_weapon_smoke.gd`, `keyboard_menu_journey_smoke.gd` et capture fenêtrée aux viewports de référence, dont le format compact utilisé par les smokes.

### Phase 2 — Équipement, compétences, Codex et succès

**[PROPOSÉ]** Lors de l’ouverture et de la fermeture des panneaux, conserver le contexte visuel du hub avec une transition discrète et rendre le focus au contrôle appelant. Garder les panneaux et leurs données actuels; ne pas ajouter d’information ni d’action. Codex et succès restent consultatifs selon leurs contrats existants.

**Vérifications ciblées prévues après approbation :** smokes visuels et fonctionnels existants des panneaux équipement, compétences, Codex et succès; navigation clavier/manette synthétique; layouts compacts.

### Phase 3 — Options, pause et écran de résultat

**[PROPOSÉ]** Faire entrer les panneaux Options et Pause avec un mouvement très court ou une transition pixel; animer sobrement l’apparition du résumé de résultat. La durée reste à confirmer avec la Phase 1. La simulation demeure suspendue dans Pause et Options depuis Pause, et arrêtée sur le résultat. Le focus initial, l’annulation et les commandes principales restent immédiats à l’échelle de la transition.

**Vérifications ciblées prévues après approbation :** `ui_settings_smoke.gd`, `pause_panel_visual_smoke.gd`, `survival_pause_smoke.gd`, `survival_pause_inventory_smoke.gd`, `run_result_panel_smoke.gd` et `keyboard_menu_journey_smoke.gd`.

### Phase 4 — Cohérence des retours audio et revue transversale

**[PROPOSÉ]** Harmoniser l’usage des sons de focus, confirmation et retour déjà présents, en évitant les répétitions au survol continu. Vérifier l’effet du volume général et préserver la lecture de musique existante. Aucun nouveau son ni changement de mix n’est inclus sans approbation distincte.

**Vérifications ciblées prévues après approbation :** parcours complet accueil → hub → arme → pause/options → résultat, contrôles de réduction des effets visuels, captures comparatives et revue audio si une sortie réelle est disponible. Aucun passage du Sandbox vers les services de progression ne sera ajouté.

## Règles communes proposées

- **[VALIDÉ]** Garder l’Art Bible, le thème et les contrôles Godot natifs comme références.
- **[PROPOSÉ]** Limiter les animations aux entrées/sorties de panneaux et aux changements de sélection; ne pas faire clignoter ou déplacer les informations utiles.
- **[PROPOSÉ]** Respecter la réduction des effets visuels; toute transition décorative devient instantanée quand elle est active.
- **[VALIDÉ]** Conserver l’ordre de focus, le focus visible, les actions souris/clavier/manette et les tailles de viewport couvertes.
- **[VALIDÉ]** Ne pas toucher aux règles de gameplay, aux récompenses, aux sauvegardes ni à l’isolation Sandbox-first.

## Décisions attendues

1. Quelles phases sont approuvées pour une première intégration?
2. La réduction des effets visuels doit-elle rendre les transitions instantanées? **[OUVERT]**
3. La proposition de 100–140 ms convient-elle comme durée initiale de transition? **[OUVERT]**
4. Les retours audio existants peuvent-ils être harmonisés comme décrit en Phase 4? **[OUVERT]**

Après approbation, chaque phase sera détaillée dans la tâche de son écran, implémentée, vérifiée, documentée, puis committée et poussée séparément.
