# Bilan d’intégration — refonte UI complète

**Statut : terminée et poussée.** Les sept modules de [`UI_CAPABILITY_MAP.md`](../../UI_CAPABILITY_MAP.md) sont implémentés. L’utilisateur a explicitement demandé de continuer en prenant les décisions nécessaires et de sauter les checkpoints intermédiaires; cette consigne a été suivie sans modifier les plans du goal principal, qui reste en pause.

## État des modules

| Module | Résultat |
|---|---|
| `ui-foundation` | Theme partagé pixel art néon, styles de contrôles et focus, prévisualisation et adaptations de viewport. |
| `ui-settings` | Préférences plein écran/volume et panneau Options réutilisable; intégration depuis Pause conserve les horloges gelées. |
| `launch-navigation` | Accueil, Options, Quitter, entrée discrète et isolée au Sandbox; navigation Jouer vers le hub. |
| `survival-hub` | Préparation Survival, difficultés séquentielles, équipement/compétences, boutons Succès/Bestiaire inertes et lancement explicite. |
| `survival-hud` | HUD, choix de coffre typé et décrit, résultat de run. |
| `survival-pause` | Pause/reprise, Options, inventaire de run en lecture seule et abandon confirmé. |
| `sandbox-ui` | Theme partagé, métriques en grille, commandes clarifiées, rendu contenu au playfield et isolation conservée. |

Les multiplicateurs de difficulté et autres paramètres de balance restent **[PROPOSÉS]**. Les comportements spéciaux Chaos restent **[OUVERTS]**. Les décisions de parcours acceptées demeurent **[VALIDÉES]**. Aucun écran Succès/Bestiaire fictif, Sandbox Lab joueur P8 ou accès du Sandbox aux services de progression n’a été ajouté.

## Vérifications de clôture

Le 2026-10-16, les 21 smokes UI et d’intégration suivants ont passé avec Godot 4.7.2 Linux, chacun avec un `XDG_DATA_HOME` temporaire isolé : `ui_foundation_smoke`, `settings_service_smoke`, `ui_settings_smoke`, `launch_navigation_smoke`, `survival_hub_smoke`, `survival_hub_layout_smoke`, `survival_hud_smoke`, `survival_starting_weapon_smoke`, `survival_chest_choice_smoke`, `survival_chest_smoke`, `run_result_panel_smoke`, `survival_run_result_smoke`, `survival_pause_smoke`, `survival_pause_inventory_smoke`, `survival_abandon_smoke`, `survival_loadout_smoke`, `survival_inventory_smoke`, `survival_wave_duration_smoke`, `survival_entry_smoke`, `sandbox_smoke` et `sandbox_ui_smoke`.

L’import éditeur headless passe. Le rendu Sandbox a aussi passé `render_visual_smoke` sous Xvfb/Mesa à 1280×800 et a été inspecté : le clipping du playfield empêche les entités de recouvrir l’accueil. `git diff --check` passe. Le code Sandbox et sa scène ne référencent aucun service de progression; le smoke UI conserve une sauvegarde sentinelle inchangée.

## Limites restantes, non bloquantes pour la livraison logicielle

- Aucun contrôleur physique n’est disponible : les mappings et contrats de focus sont vérifiés, l’activation sur matériel ne l’est pas.
- Plein écran sur écran réel et sortie audio sur haut-parleurs/casque non vérifiés; le service et ses valeurs sont testés sous Godot.
- `cmake` et `ctest` sont absents du PATH : aucun build natif ni CTest n’est revendiqué pour cette passe.
- L’assertion historique « dagues en orbite » de `combat_catalog_smoke.gd` contredit le catalogue actuel qui décrit un tir en éventail; aucune règle de combat n’a été modifiée dans la refonte UI.

Ces limites restent visibles dans `docs/qa/TESTS.md`. Elles ne changent pas la séparation Sandbox/progression.
