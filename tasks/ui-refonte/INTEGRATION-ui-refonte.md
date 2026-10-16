# Bilan d’intégration — tranche fonctionnelle initiale

## Direction artistique appliquée — 2026-10-16

Cette section résume la tranche fonctionnelle initiale au moment de sa livraison. Depuis, le viewport logique 640×360 est activé avec une fenêtre initiale 1280×720 et la refonte visuelle reste en cours. L’Art Bible v1.1 de `docs/ART_BIBLE.txt` reste la référence. Le thème commun utilise les couleurs sémantiques de la palette validée, des panneaux opaques et des boutons carrés. Press Start 2P (SIL OFL) sert aux titres; DejaVu Sans (licence Bitstream Vera/DejaVu) reste la police du corps. Un feedback commun ajoute un léger agrandissement au survol et un décalage de 2 px à l’appui.

Avant la correction viewport, 21 smokes UI et d’intégration passaient avec un `XDG_DATA_HOME` isolé par script. Après le rétablissement à 1280×800, 10 smokes ciblés passent : fondation, hub/layouts 1280×800/1600×900/1920×1080, pause, inventaire, coffre, résultat, navigation et Sandbox. Le smoke fenêtré et la suite complète restent à relancer. Le smoke de résultat vérifie aussi le libellé « RUN SANS SAUVEGARDE ».

**Statut de cette tranche : terminée et poussée.** Elle fournit les comportements fonctionnels et le premier thème, mais ne clôt pas l’objectif actuel. L’extension confirmée qui demande de refaire visuellement chaque écran et tous les assets du jeu est en cours. Voir l’[inventaire des assets et interfaces](../../docs/art/INVENTAIRE_ASSETS_UI.md) et le statut courant dans la [carte des capacités](../../UI_CAPABILITY_MAP.md). Le viewport 640×360 est activé dans le travail courant après adaptations initiales; tous les parcours et écrans restent à vérifier avant de considérer la refonte complète achevée.

## Avancée visuelle après la tranche initiale

- Le Sandbox développeur reste isolé; ses contrôles latéraux sont testés à 640×360, 1280×720 et 1920×1080.
- Le sol actif de Survival est désormais un pixel art 256×256 répétable, sa palette est limitée à six couleurs de l’Art Bible et son fichier Aseprite reste éditable. Le SVG et l’ancien motif chargé sont conservés comme références inactives.
- Le joueur utilise maintenant des feuilles idle et marche 4×4, exportées en frames 32×32 et reliées aux directions de mouvement. L’ordre des lignes et les cadences restent **[PROPOSÉS]** dans l’inventaire d’assets.
- Les morts d’ennemis produisent une courte explosion de pixels dessinée en code; elle suit le temps de simulation et ne crée aucune entité de combat. Ses paramètres restent **[PROPOSÉS]**.
- Les projectiles mobiles ont une traînée discrète bleu nuit/cyan, dessinée sous le sprite en Survival et dans le Sandbox. Son budget de 256 simultanés reste **[PROPOSÉ]**; les couleurs par élément restent **[OUVERTES]**.
- L’accueil anime trois enseignes visibles du skyline avec un VFX code-drawn; l’Art Bible demande ce clignotement, tandis que ses périodes détaillées restent **[PROPOSÉES]**.
- Les titres d’écran et d’interfaces utilisent maintenant la variante pixel `PixelHeading`; descriptions et textes d’aide gardent DejaVu Sans. Press Start 2P reste **[PROPOSÉE]** comme fonte de titre.
- L’objectif de refonte de toutes les interfaces et de tous les assets visuels actifs reste **en cours**; cet état partiel ne vaut pas clôture.

## État des modules

| Module | Résultat |
|---|---|
| `ui-foundation` | Theme partagé pixel art néon, styles de contrôles et focus, prévisualisation. Cette extension poursuit la conformité complète à l’Art Bible et aux écrans à 640×360. |
| `ui-settings` | Préférences plein écran/volume et panneau Options réutilisable; intégration depuis Pause conserve les horloges gelées. |
| `launch-navigation` | Accueil, Options, Quitter, entrée discrète et isolée au Sandbox; navigation Jouer vers le hub. |
| `survival-hub` | Préparation Survival, difficultés séquentielles, équipement/compétences, boutons Succès/Bestiaire inertes et lancement explicite. |
| `survival-hud` | HUD, choix de coffre typé et décrit, résultat de run. |
| `survival-pause` | Pause/reprise, Options, inventaire de run en lecture seule et abandon confirmé. |
| `sandbox-ui` | Theme partagé, métriques en grille, commandes clarifiées, rendu contenu au playfield et isolation conservée. |

Les multiplicateurs de difficulté et autres paramètres de balance restent **[PROPOSÉS]**. Les comportements spéciaux Chaos restent **[OUVERTS]**. Les décisions de parcours acceptées demeurent **[VALIDÉES]**. Aucun écran Succès/Bestiaire fictif, Sandbox Lab joueur P8 ou accès du Sandbox aux services de progression n’a été ajouté.

## Vérifications de clôture

Le 2026-10-16, les 21 smokes UI et d’intégration suivants ont passé avec Godot 4.7.2 Linux, chacun avec un `XDG_DATA_HOME` temporaire isolé : `ui_foundation_smoke`, `settings_service_smoke`, `ui_settings_smoke`, `launch_navigation_smoke`, `survival_hub_smoke`, `survival_hub_layout_smoke`, `survival_hud_smoke`, `survival_starting_weapon_smoke`, `survival_chest_choice_smoke`, `survival_chest_smoke`, `run_result_panel_smoke`, `survival_run_result_smoke`, `survival_pause_smoke`, `survival_pause_inventory_smoke`, `survival_abandon_smoke`, `survival_loadout_smoke`, `survival_inventory_smoke`, `survival_wave_duration_smoke`, `survival_entry_smoke`, `sandbox_smoke` et `sandbox_ui_smoke`.

L’extension de `survival_pause_inventory_smoke` pour tester le focus par objet, le défilement clavier, le contour de focus et les icônes 24×24 passe avec Godot 4.7.2. `ui_viewport_layout_smoke` passe aux résolutions logiques de 640×360, 1280×720 et 1920×1080.

Le HUD a été recomposé en deux cartes compactes dans les coins. `survival_hud_smoke`, `survival_weapon_smoke`, `survival_wave_director_smoke` et `survival_pause_smoke` passent; `pilot_scene_visual_smoke` a été rendu sous Xvfb/Mesa et inspecté dans une fenêtre 1280×720.

L’import éditeur headless passe. Le rendu Sandbox a aussi passé `render_visual_smoke` sous Xvfb/Mesa à 1280×800 et a été inspecté : le clipping du playfield empêche les entités de recouvrir l’accueil. `git diff --check` passe. Le code Sandbox et sa scène ne référencent aucun service de progression; le smoke UI conserve une sauvegarde sentinelle inchangée.

## Limites restantes, non bloquantes pour la livraison logicielle

- Aucun contrôleur physique n’est disponible : les mappings et contrats de focus sont vérifiés, l’activation sur matériel ne l’est pas.
- Plein écran sur écran réel et sortie audio sur haut-parleurs/casque non vérifiés; le service et ses valeurs sont testés sous Godot.
- `cmake` et `ctest` sont absents du PATH : aucun build natif ni CTest n’est revendiqué pour cette passe.
- L’assertion historique « dagues en orbite » de `combat_catalog_smoke.gd` contredit le catalogue actuel qui décrit un tir en éventail; aucune règle de combat n’a été modifiée dans la refonte UI.

Ces limites restent visibles dans `docs/qa/TESTS.md`. Elles ne changent pas la séparation Sandbox/progression.
