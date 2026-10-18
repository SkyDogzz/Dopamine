# Spec: `visual-assets` — Remplacement des assets visuels

## Objectif

Remplacer les sprites, environnements, effets, récompenses, icônes, identité d’accueil et assets visuels associés dans le style Neon Arcade, tout en conservant les fonctions et la lecture du combat. La priorité de production est une scène Survival complète représentative, puis la couverture de tout le roster, catalogue, environnement, récompenses et identité.

## Stack et emplacement

Godot 4.7.2; PNG de runtime sous `game/assets/`; sources graphiques Aseprite selon l’Art Bible; données d’assets existantes dans `game/data/` et références documentées sous `docs/art/`.

### Avancement (2026-10-18)

- **[PROPOSÉ]** La skyline de titre `game/assets/backgrounds/original_procedural/title_skyline.png` est une première création originale 640×360, indexée selon les 32 couleurs exactes de l’Art Bible; sa source éditable est `game/assets/source/original_procedural/title_skyline.aseprite`.
- Provenance et hashes : `game/assets/backgrounds/original_procedural/title_skyline.json`. Contrôle reproductible : `python3 game/tools/validate_original_title_art.py`.
- Revue isolée : pixel art net, 16 couleurs utilisées, silhouettes urbaines et espace sombre à gauche pour la colonne de menu. **[OUVERT]** Le contrôle headless du menu n’a pas abouti à une capture; l’adéquation visuelle au menu reste à vérifier en contexte avant intégration.
- L’asset demeure non actif. La skyline existante, sa source et les références du menu ne sont pas retirées avant une migration et un smoke de navigation valides.

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
