# Spec: `visual-assets` — Remplacement des assets visuels

## Objectif

Remplacer les sprites, environnements, effets, récompenses, icônes, identité d’accueil et assets visuels associés dans le style Neon Arcade, tout en conservant les fonctions et la lecture du combat. La priorité de production est une scène Survival complète représentative, puis la couverture de tout le roster, catalogue, environnement, récompenses et identité.

## Stack et emplacement

Godot 4.7.2; PNG de runtime sous `game/assets/`; sources graphiques Aseprite selon l’Art Bible; données d’assets existantes dans `game/data/` et références documentées sous `docs/art/`.

### Avancement (2026-10-18)

- **[PROPOSÉ]** La skyline de titre active `game/assets/backgrounds/title_skyline.png` est maintenant une création originale 640×360, indexée avec 16 couleurs de la palette maître de 32 couleurs; sa source éditable Aseprite est `game/assets/source/backgrounds/title_skyline.aseprite`.
- Provenance et hashes : `docs/art/title_skyline_migration.json`; contrôle reproductible : `python3 game/tools/validate_original_title_art.py`.
- Revue visuelle dans le menu à 640×360 : une copie temporaire avec réimport Godot a passé `launch_navigation_smoke.gd` sous Xvfb; la capture `/tmp/dopamine-launch-menu.png` a été examinée. Le fond garde les silhouettes urbaines et l'espace sombre à gauche. Cette vérification **[VALIDÉE pour l'asset et le parcours d'accueil]** ne valide pas l'interface finale, dont les autres assets restent à remplacer.
- **[PROPOSÉ]** Les neuf sprites de rôles ennemis communs/soutiens (24×24) sont maintenant des formes pixel originales produites par `game/tools/generate_original_roster.py`, avec sources Aseprite générées par LibreSprite. Le générateur ne lit que les rôles et la palette validée; les anciennes sources de référence ne servent plus à ces chemins actifs. Les boss restent hors de cette migration et leurs identités restent **[OUVERTES]**.
- La validation ciblée `catalog_icon_assets_smoke.gd` et `survival_hub_smoke.gd` passe; une capture de combat dense à 640×360 a été examinée à `/tmp/dopamine-survival-combat-visual.png`. Les neuf rôles restent séparables dans la scène; le reste des visuels et l'UI visibles restent à remplacer.

- **[PROPOSÉ]** Les 24 projectiles 16×16 utilisent des créations procédurales originales et sources Aseprite sous `source/original_procedural/`; chemins runtime et comportements inchangés. Les sources/atlas historiques et doublons racine ont été retirés après recherche d’usages. Import, smoke catalogue, lots renderer et capture dense passent; le PCK Linux/X11 post-retrait contient les chemins runtime et exclut les anciens fichiers vérifiés.

- **[PROPOSÉ]** Les 16 icônes UI actives (6 slots, 5 raretés, 2 ressources, skill, médaille, record) ont des PNG originaux et des sources Aseprite sous `source/original_procedural/`, dessinés par `generate_original_visuals.gd` depuis les rôles sémantiques et la palette maître. Les chemins runtime sont conservés. La planche, les sources et les doublons racine historiques ont été retirés après audit; voir `ASSET_MIGRATIONS.csv` et `ASSET_RETIREMENTS.csv`. `catalog_icon_assets_smoke.gd` contrôle provenance interne, source, palette et capture de planche. Cette tranche ne définit aucun nœud ou effet du skill tree.

- **[PROPOSÉ]** Les 20 icônes d’armes/évolutions et 11 icônes de reliques du catalogue utilisent des motifs générés depuis leurs rôles sémantiques et la palette maître, avec sources Aseprite sous `source/original_procedural/`. Les chemins runtime et règles de disponibilité restent inchangés. Les anciennes planches/sources et doublons racine sans consommateur ont été retirés après audit; voir `ASSET_MIGRATIONS.csv` et `ASSET_RETIREMENTS.csv`. La capture `/tmp/dopamine-catalog-icons.png` a été inspectée; le smoke vérifie la palette et les sources.

## Commandes de vérification

- `godot --headless --editor --path game --quit`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/pilot_scene_visual_smoke.gd`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/survival_combat_visual_smoke.gd`
- Smokes existants ciblés selon les catégories touchées; commandes complémentaires définies dans le plan d’implémentation.

## Structure et contrats

- Remplacer les assets de joueur, ennemis, élites, boss, projectiles, armes, reliques, évolutions, terrain, ruines, pickups, coffres, VFX, catalogue, icônes, skyline et autres visuels actifs.
- Respecter top-down, proportions chibi légères, joueur 32×32, tiles 16×16, boss standard 96×96, animations du joueur (4 directions, 4 frames idle et marche), grille de spritesheets validée et palette maître 32 couleurs.
- Maintenir la distinction sprite pixel art net / VFX modernes et garder les télégraphes, dangers, projectiles, ennemis et pickups séparables pendant un combat chargé.
- Ne pas créer de visuels ou d’actions pour Succès/Bestiaire/Sandbox Lab joueur qui ne sont pas implémentés.

## Style et règles de contenu

Suivre `docs/ART_BIBLE.txt`; distinguer `[VALIDÉ]`, `[PROPOSÉ]` et `[À CONFIRMER]`. Conserver comme prototypes les identités de boss et de biome marquées ouvertes; ne pas dériver de nouvelles mécaniques depuis un brief visuel.

Les noms d’exports sont stables en `snake_case` et les références d’assets utilisent les chemins `res://` existants; les scripts de traitement suivent les conventions GDScript du dépôt.

## Stratégie de vérification

Chaque famille est contrôlée techniquement (dimensions, palette, contours, aliasing, frames, source) et revue visuellement en scène. Vérifier les sprites à la résolution logique et lors d’un combat dense. Confirmer lisibilité des silhouettes et des télégraphes.

## Limites

- Toujours suivre l’Art Bible et respecter l’isolation du Sandbox dans les scènes.
- Toujours documenter les exceptions de palette et la provenance.
- Arbitrage requis avant de fixer modèle exact du héros, identité canonique des boss, premier biome, couleurs élémentaires et règles détaillées de flashs si ces points conditionnent la production.
- Ne jamais introduire un halo flou pré-rendu ni retirer les visuels actifs avant migration.

## Critères de réussite

- Toutes les familles d’assets actives sont remplacées et toutes leurs scènes/données consommatrices chargent.
- Les sorties sont accompagnées des sources d’édition requises et passent les contrôles de conformité.
- Une scène Survival complète et dense confirme une hiérarchie visuelle lisible.
- Les captures de revue sont conservées comme preuves pour les écrans et scènes représentatifs.

## Questions ouvertes

Les détails listés dans « Points ouverts à garder visibles » de `docs/art/INVENTAIRE_ASSETS_UI.md` et les questions prioritaires de l’Art Bible restent ouverts jusqu’à ce qu’un asset les rende bloquants.
