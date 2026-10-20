# Proposition — menus et transitions plus dynamiques

**Statut :** les six propositions ont été approuvées par l’utilisateur le 2026-10-20 et intégrées en quatre phases. Le balayage en blocs de 120 ms et sa suppression lorsque la réduction des effets visuels est active ont aussi été validés le 2026-10-20. Ce document complète l’intention générale de [`INTENTION_REFONTE_UI.md`](../../docs/planning/INTENTION_REFONTE_UI.md) sans modifier les décisions de gameplay ni les specs fonctionnelles livrées.

## Objectif

Rendre les écrans hors combat plus rythmés et leurs actions plus lisibles, en priorité dans les menus et leurs transitions. Les choix d’arme, de difficulté, d’équipement, les récompenses, les règles de run et la frontière Sandbox/progression restent inchangés.

## Références et constats

- **[VALIDÉ]** L’Art Bible demande des menus pixel art sobres, des transitions pixel rapides, des boutons bordés et des textes lisibles. La résolution logique de référence est 1280×720.
- **[VALIDÉ]** Le parcours principal, la navigation clavier/manette, le focus visible et la réduction des effets visuels sont déjà des contraintes du projet.
- **[VALIDÉ]** `UIFeedback` fournit déjà un retour de focus, de survol et d’appui; les sons UI existent. L’accueil joue déjà sa musique et anime des enseignes du skyline.
- **État observé :** les scripts actuels de menu n’animent pas les changements de scène. Les captures de référence couvrent l’accueil et le hub; des smokes couvrent notamment le choix d’arme, les options, la pause, les résultats et plusieurs layouts.
- **[OUVERT]** Les limites des clignotements et le mix audio détaillé ne sont pas définis. L’écoute sur matériel audio et le parcours sur manette physique restent à faire.

## Ordre approuvé

Les six écrans et intentions ci-dessous sont approuvés. La transition inter-écrans est un balayage en blocs de 120 ms; elle devient instantanée lorsque la réduction des effets visuels est active. Les phases sont livrées l’une après l’autre afin que chaque tranche reste vérifiable.

### Phase 1 — Accueil, hub et entrée en run

**Écrans :** accueil, hub Survival, choix de l’arme de départ.

**[VALIDÉ]** Ajouter un balayage en blocs de 120 ms entre ces destinations et au retour vers l’accueil. Le changement de scène intervient à couvert; la navigation retrouve un focus valide à l’arrivée. Lorsque la réduction des effets visuels est activée, le changement est instantané.

**[VALIDÉ]** Au hub, rendre le changement de difficulté et le lancement plus perceptibles par un état sélectionné net et un retour audio bref, sans modifier le texte de règles ni les valeurs de difficulté. Au choix d’arme, marquer clairement l’arme sélectionnée et fournir un bref retour visuel/audio à chaque changement; garder l’action de confirmation visible.

**Vérifications ciblées prévues après approbation :** `launch_navigation_smoke.gd`, `survival_hub_smoke.gd`, `survival_hub_layout_smoke.gd`, `survival_starting_weapon_smoke.gd`, `keyboard_menu_journey_smoke.gd` et capture fenêtrée aux viewports de référence, dont le format compact utilisé par les smokes.

**État au 2026-10-20 — intégré :** service global de transition utilisé pour les changements de scène de l’accueil, du Sandbox Lab, du hub et de la session. Le balayage shader en blocs dure 120 ms; il est instantané avec les effets réduits et bloque les entrées pendant son exécution. Difficulté choisie explicitement cochée; arme focalisée marquée par un curseur. Les sons de focus/confirmation existants restent la source unique de retour. Smokes transition, hub, arme de départ, navigation clavier/manette synthétique et capture fenêtrée 1280×720 passés.

### Phase 2 — Équipement, compétences, Codex et succès

**[VALIDÉ]** Lors de l’ouverture et de la fermeture des panneaux, conserver le contexte visuel du hub avec une transition discrète et rendre le focus au contrôle appelant. Garder les panneaux et leurs données actuels; ne pas ajouter d’information ni d’action. Codex et succès restent consultatifs selon leurs contrats existants.

**Vérifications ciblées prévues après approbation :** smokes visuels et fonctionnels existants des panneaux équipement, compétences, Codex et succès; navigation clavier/manette synthétique; layouts compacts.

**État au 2026-10-20 — intégré :** les cinq panneaux du hub utilisent une entrée/sortie en fondu de 90 ms, avec affichage instantané lorsque la réduction visuelle est active. Le focus revient au bouton appelant dès la fermeture. Smokes hub, succès, layouts hub (640×360, 1280×720, 1920×1080), transitions et parcours manette passent avec données utilisateur isolées. Limite de vérification : les smokes autonomes équipement et arbre de compétences échouent sur leurs assertions de rendu/cadrage; le smoke arbre change `root.size` sans redimensionner le viewport réel. Ces échecs ne traversent pas le fondu ajouté au hub.

### Phase 3 — Options, pause et écran de résultat

**[VALIDÉ]** Faire entrer les panneaux Options et Pause avec un mouvement très court ou une transition pixel; animer sobrement l’apparition du résumé de résultat. Réutiliser le balayage en blocs approuvé, avec une arrivée de panneau courte. La simulation demeure suspendue dans Pause et Options depuis Pause, et arrêtée sur le résultat. Le focus initial, l’annulation et les commandes principales restent accessibles pendant les animations.

**Vérifications ciblées prévues après approbation :** `ui_settings_smoke.gd`, `pause_panel_visual_smoke.gd`, `survival_pause_smoke.gd`, `survival_pause_inventory_smoke.gd`, `run_result_panel_smoke.gd` et `keyboard_menu_journey_smoke.gd`.

**État au 2026-10-20 — intégré :** entrée Options à 90 ms sur l’accueil et en pause; entrée Pause à 90 ms; panneau de résultat fondu à 90 ms après préparation du résumé. Les contrôles et le focus sont disponibles immédiatement. À la fermeture d’Options, le focus revient immédiatement et la simulation reste suspendue pendant la sortie visuelle; l’ouverture Options ne modifie pas l’état de pause. Smokes pause, panneau Pause, résultat, parcours clavier et navigation accueil passés. Limites de vérification : le smoke des réglages échoue à son assertion de 640×360 et celui d’inventaire en pause à son cadrage compact; leurs scénarios changent `root.size` sans redimensionner le viewport enfant. Aucun changement n’a été fait aux valeurs du résultat ni à la simulation.

### Phase 4 — Cohérence des retours audio et revue transversale

**[VALIDÉ]** Harmoniser l’usage des sons de focus, confirmation et retour déjà présents, en évitant les répétitions au survol continu. Vérifier l’effet du volume général et préserver la lecture de musique existante. Les nouveaux sons et changements de mix restent hors de cette phase.

**Vérifications ciblées prévues après approbation :** parcours complet accueil → hub → arme → pause/options → résultat, contrôles de réduction des effets visuels, captures comparatives et revue audio si une sortie réelle est disponible. Aucun passage du Sandbox vers les services de progression ne sera ajouté.

**État au 2026-10-20 — intégré :** le parcours global utilise les mêmes sons UI existants. `UIFeedback` déclenche le focus, la confirmation d’appui et le retour à l’annulation; les demandes de focus sont limitées à une par 80 ms. La sélection de difficulté s’appuie sur le son d’appui déjà attaché au bouton, sans double lecture scriptée. `ui_foundation_smoke.gd`, `settings_service_smoke.gd`, `sfx_service_assets_smoke.gd` et `sfx_specific_event_smoke.gd` passent. Le mix détaillé et l’écoute sur sortie physique restent **[OUVERTS]**; le parcours sur manette physique reste à faire.

## Règles communes proposées

- **[VALIDÉ]** Garder l’Art Bible, le thème et les contrôles Godot natifs comme références.
- **[VALIDÉ]** Limiter les animations aux entrées/sorties de panneaux et aux changements de sélection; ne pas faire clignoter ou déplacer les informations utiles.
- **[VALIDÉ]** Respecter la réduction des effets visuels; toute transition décorative devient instantanée quand elle est active.
- **[VALIDÉ]** Conserver l’ordre de focus, le focus visible, les actions souris/clavier/manette et les tailles de viewport couvertes.
- **[VALIDÉ]** Ne pas toucher aux règles de gameplay, aux récompenses, aux sauvegardes ni à l’isolation Sandbox-first.

Les détails artistiques qui ne sont pas couverts par ces validations restent **[OUVERTS]** et ne seront pas inventés au fil de l’implémentation. Chaque phase est vérifiée, documentée, committée et poussée séparément.
