# Spec: `interface-overhaul` — Refonte complète de l’interface

## Objectif

Refaire visuellement tous les écrans et composants UI existants dans le style arcade pixel sobre de l’Art Bible, avec des parcours plus lisibles sans changer les règles validées des écrans existants. Inclut les écrans de menu, options, hub, Survival, overlays, résultats, progression, équipement et Sandbox développeur.

## Stack et emplacement

Godot 4.7.2, GDScript, scènes `Control`, Theme sous `game/themes/`, écrans et scripts sous `game/scenes/` et `game/scripts/`. Respecter ADR-011 et `docs/architecture/ARCHITECTURE.md`.

## Commandes de vérification

- `godot --headless --editor --path game --quit`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/ui_foundation_smoke.gd`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/ui_viewport_layout_smoke.gd`
- Lancer les smokes d’écran existants ou adaptés pour les parcours touchés; tester aux viewports logiques 640×360 et rendus 1280×720 / 1920×1080.

## Structure et contrats

- Réutiliser des composants Godot `Control`; prendre en charge souris, clavier et manette dès le hub.
- Navigation, actions, focus visible, options, sauvegardes et transitions existants restent fonctionnels.
- L’UI Sandbox reste dans son contexte isolé et n’accède pas au service de progression normale.
- Préserver la pause stricte, l’inventaire de run en lecture seule et les parcours de résultat.
- Les écrans détaillés arbre de compétences et équipement sont définis dans leurs spécifications dédiées.

## Style et règles de code

Pixel arcade sobre : panneaux opaques bordés, boutons rectangulaires, titres pixel et textes lisibles, transitions rapides, cibles interactives accessibles, focus clavier/manette visible. Le glow UI est rendu dynamiquement. Garder les chaînes textuelles localisables et les scènes/scripts simples.

GDScript utilise des noms `snake_case`, des types explicites pour les références de nœuds importantes et des signaux pour séparer la présentation des actions de service, selon les scènes UI existantes.

## Stratégie de vérification

Smokes de fondation et de parcours, bornes de layout aux viewports ciblés, navigation synthétique souris/clavier/manette, revue de captures pour chaque écran et états (normal, focus, désactivé, erreur, confirmations). Une revue visuelle explicite reste nécessaire.

## Limites

- Toujours respecter ADR-011 et la séparation Sandbox/progression.
- Toujours préserver les actions validées des écrans, sauf extensions explicitement décrites dans des specs dédiées.
- Arbitrage requis pour les points ouverts de navigation, typographie et accessibilité lorsqu’ils bloquent le wireframe final.
- Ne jamais activer de lien Succès/Bestiaire sans fonctionnalité correspondante ni rendre accessible la progression depuis le Sandbox.

## Critères de réussite

- Tous les écrans réellement utilisés ont été refaits et les outils de prévisualisation sont distingués des écrans livrés.
- Aucun parcours ni état interactif validé n’est perdu; souris, clavier et manette sont utilisables avec focus visible.
- Layouts sans débordement aux tailles cibles, captures revues et smokes ciblés passés.
- L’isolation Sandbox est couverte par une vérification dédiée.

## Questions ouvertes

Arbitrer les fontes exactes, tailles/espacements et navigation manette détaillée lorsqu’ils empêchent le dessin final; préserver les choix confirmés et propositions existantes comme tels.
