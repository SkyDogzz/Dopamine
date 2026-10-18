# Spec: `asset-pipeline` — Filière et audit des assets

## Objectif

Préparer le remplacement complet des assets graphiques et audio du jeu avec un inventaire traçable, des sources modifiables, des exports intégrables dans Godot et des contrôles de conformité. Les utilisateurs sont le créateur du jeu, les contributeurs artistiques et les systèmes d’intégration Godot. La capacité réussit si chaque asset actif a une source, un rôle et une référence d’usage connus, et si les nouveaux exports peuvent être contrôlés et intégrés sans références cassées.

## Stack et emplacement

- Godot 4.7.2, assets sous `game/assets/`, sources graphiques actuelles en Aseprite et exports PNG.
- Références : `docs/ART_BIBLE.txt`, `docs/art/INVENTAIRE_ASSETS_UI.md`, `docs/art/PROVENANCE_ASSETS.csv`, `THIRD_PARTY_NOTICES.md`.
- La production audio originale est écrite dans `game/tools/generate_original_audio.py`; sorties candidates sous `game/assets/audio/original_procedural/`. Les 38 SFX sont actifs sur les familles existantes et cinq stems musique sont intégrés au flux adaptatif; composition, gains et format restent **[PROPOSÉS]**.

### Avancement de la filière (2026-10-18)

- **[PROPOSÉ]** `docs/art/palette_master.gpl` est une copie exploitable de la palette maître; `game/tools/validate_original_title_art.py` vérifie l'ordre et les 32 valeurs contre l'Art Bible.
- **[PROPOSÉ]** La skyline de titre active a été remplacée par une création 640×360 sans référence extérieure. `game/tools/generate_original_title_skyline.py` produit le PNG indexé depuis la palette `.gpl`; LibreSprite batch produit sa source Aseprite éditable.
- Revue en copie temporaire après réimport Godot : capture de menu à 640×360 examinée et `launch_navigation_smoke.gd` réussi sous Xvfb. La migration conserve le chemin utilisé par la scène. L'identité d'un biome n'est pas déduite de ce décor de menu.
- **[PROPOSÉ]** Les neuf sprites actifs de rôles ennemis communs/soutiens ont été remplacés par des silhouettes pixel originales sans références; hashes avant/après et provenance figurent dans `docs/art/roster_migration.json` et les registres CSV. L'ancien builder n'écrit plus ces neuf chemins.
- `original_roster_assets_smoke.gd`, les smokes catalogue, hub et soutien, le rendu de combat sous Xvfb et un PCK Linux/X11 ciblé passent. La capture dense a été examinée. Les références historiques partagées restent jusqu'à migration des prototypes restants; le nouveau générateur ne les lit pas.
- Vérifications skyline : `python3 game/tools/validate_original_title_art.py`, `catalog_icon_assets_smoke.gd`, puis `launch_navigation_smoke.gd` avec capture. Le PCK décrit au jalon d'assets complet a encore à être refait après migration des autres familles.

- **[PROPOSÉ]** La famille de 24 projectiles runtime utilise des PNG originaux et leurs sources éditables `source/original_procedural/`. La route de l’ancien atlas a été retirée du builder; l’atlas, les 24 sources Aseprite parallèles et les doublons PNG/SVG racine sans consommateur ont été supprimés après recherche des références. `catalog_icon_assets_smoke.gd`, `render_batching_smoke` et la capture dense passent; le PCK Linux/X11 post-retrait contient les chemins runtime et exclut les anciens fichiers vérifiés. Les hashes des éléments retirés restent dans `ASSET_RETIREMENTS.csv`, et `ASSET_FILE_REGISTER.csv` reste le snapshot initial.

- **[PROPOSÉ]** Les 16 icônes UI actives (6 slots, 5 raretés, 2 ressources, skill, médaille, record) ont des PNG originaux et des sources Aseprite sous `source/original_procedural/`, dessinés par `generate_original_visuals.gd` depuis les rôles sémantiques et la palette maître. Les chemins runtime sont conservés. La planche, les sources et les doublons racine historiques ont été retirés après audit; voir `ASSET_MIGRATIONS.csv` et `ASSET_RETIREMENTS.csv`. `catalog_icon_assets_smoke.gd` contrôle provenance interne, source, palette et capture de planche. Cette tranche ne définit aucun nœud ou effet du skill tree.

- **[PROPOSÉ]** Les 20 icônes d’armes/évolutions et 11 icônes de reliques du catalogue utilisent des motifs générés depuis leurs rôles sémantiques et la palette maître, avec sources Aseprite sous `source/original_procedural/`. Les chemins runtime et règles de disponibilité restent inchangés. Les anciennes planches/sources et doublons racine sans consommateur ont été retirés après audit; voir `ASSET_MIGRATIONS.csv` et `ASSET_RETIREMENTS.csv`. La capture `/tmp/dopamine-catalog-icons.png` a été inspectée; le smoke vérifie la palette et les sources.

- **[VALIDÉ] Portée des remplacements (2026-10-18)** : aucun asset existant ni aucune recette de production ne doit être réutilisé pour les livrables. Les sources originales restent conservées jusqu’au remplacement des usages et vérification exhaustive; les anciennes sources/recettes/références doivent ensuite être retirées du dépôt, avec hash et usage conservés dans les registres d’audit. Les fichiers `*.import` générés par Godot ne sont pas des sources créatives.

- **[OUVERT — BLOQUANT POUR LES FAMILLES CONCERNÉES]** L’audit daté de base reste un snapshot; les familles actives non migrées incluent encore le joueur, deux boss/prototypes, élite, ennemis animés, terrain/environnement/ruines, récompenses, pickups et VFX. Aucune suppression correspondante n’est autorisée avant remplacement de tous les consommateurs et validation de l’import/PCK. Les identités définitives des boss/biome ne sont pas inventées; produire des rôles visuels provisoires si cela n’affirme aucune identité canonique.

- **[VALIDÉ]** Les 38 nouveaux SFX procéduraux sont intégrés dans les familles actives de `Sfx`; leurs anciennes sources, recettes, renders et références de runtime sont retirés après migration vérifiée.
- L’ancien OGG et son import sont retirés après migration des références, avec hashes dans les registres. L’orchestration utilise cinq stems synchronisés, évolution graduelle de l’arpège par vague et fondu du stem boss sans redémarrage; le smoke `adaptive_survival_music_smoke.gd` vérifie ces contrats.
- **[OUVERT]** Les nouveaux SFX et stems restent des candidats non approuvés jusqu’à la revue auditive; aucune sortie audio n’est disponible dans l’environnement courant. L’écoute en situation doit couvrir mix, transitions et priorité des cues.

## Commandes de vérification

- `godot --headless --editor --path game --quit` — import Godot.
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/catalog_icon_assets_smoke.gd` — contrôle ciblé existant des icônes.
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/survival_combat_visual_smoke.gd` — capture visuelle représentative existante.
- Les commandes de test spécialisées seront arrêtées dans les spécifications de module avant implémentation. Pas de seuil de couverture arbitraire.

## Structure et contrats

- Garder les exports référencés par le projet sous `game/assets/` et les sources éditables organisées par famille sous `game/assets/source/`.
- Inventorier chaque référence d’asset dans scènes, scripts, données, audio bus et exports. Aucun asset actif ne doit être supprimé avant migration de toutes ses références.
- Préserver PNG + source Aseprite pour les sprites selon l’Art Bible. Pour l’audio original, conserver le script de synthèse et les manifestes; le runtime des candidats actuels est PCM16 mono WAV 44,1 kHz, choix encore **[PROPOSÉ]** jusqu’à revue de mix.
- Les contrats validés de l’Art Bible sont obligatoires : pixel art strict, palette maître 32 couleurs, 16 couleurs maximum pour un sprite 32×32, glow uniquement en VFX, résolution logique 640×360, PNG + source Aseprite.

## Style et règles de données

Identifiants stables en `snake_case`, aucune conversion silencieuse de références, aucune exception de palette ou licence non documentée. Une référence active doit pointer vers un asset versionné et importable.

Les scripts d’outillage suivent le style GDScript existant : constantes en majuscules, fonctions en `snake_case`, vérification explicite des imports et erreurs avec un message qui identifie le chemin d’asset concerné.

## Stratégie de vérification

- Inventaire statique des références, sources, sorties, licences et usages.
- Contrôles automatiques adaptés : dimensions, transparence, couleurs, grille/frame et import pour l’image ; durée, sample rate, canaux, clipping/pics et références pour l’audio.
- Revue visuelle en scène dense et écoute en contexte pour les assets représentatifs ; les contrôles numériques ne remplacent pas ces revues.

## Limites

- Toujours préserver le fonctionnement et les références tant que leur remplacement n’est pas prêt.
- Toujours maintenir les sources et attribuer les licences/provenances.
- Demander un arbitrage lorsque l’Art Bible ou le GDD marque un point `OUVERT` qui conditionne la production.
- Ne jamais inventer une décision validée, effacer un asset tiers sans avoir vérifié sa provenance, ni confondre effets de VFX avec pixels précuits dans les sprites.

## Critères de réussite

- Couverture exhaustive des assets graphiques et audio actifs, avec statut (à conserver, remplacer, supprimer après migration) et usages référencés.
- Tous les assets remplacés ont source éditable, export importé et provenance/licence déterminée.
- Les contrôles rapportent clairement les exceptions documentées et les assets non conformes.
- Aucun chemin d’asset manquant après intégration.

## Questions ouvertes

- Format source éditable; le format runtime PCM16 mono WAV 44,1 kHz reste **[PROPOSÉ]** jusqu’à revue audio. Les droits/provenances sont consignés dans les notices et registres d’assets.
- Outil exact de production Aseprite/audio et format des métadonnées.
- Les choix ouverts de la section 10 de l’Art Bible qui deviennent bloquants au premier asset concerné.
