# Spec: `asset-pipeline` — Filière et audit des assets

## Objectif

Préparer le remplacement complet des assets graphiques et audio du jeu avec un inventaire traçable, des sources modifiables, des exports intégrables dans Godot et des contrôles de conformité. Les utilisateurs sont le créateur du jeu, les contributeurs artistiques et les systèmes d’intégration Godot. La capacité réussit si chaque asset actif a une source, un rôle et une référence d’usage connus, et si les nouveaux exports peuvent être contrôlés et intégrés sans références cassées.

## Stack et emplacement

- Godot 4.7.2, assets sous `game/assets/`, sources graphiques actuelles en Aseprite et exports PNG.
- Références : `docs/ART_BIBLE.txt`, `docs/art/INVENTAIRE_ASSETS_UI.md`, `docs/art/PROVENANCE_ASSETS.csv`, `THIRD_PARTY_NOTICES.md`.
- La procédure audio actuelle se trouve sous `game/assets/audio/`; son outil et ses formats de source sont à inventorier.

## Commandes de vérification

- `godot --headless --editor --path game --quit` — import Godot.
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/catalog_icon_assets_smoke.gd` — contrôle ciblé existant des icônes.
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/survival_combat_visual_smoke.gd` — capture visuelle représentative existante.
- Les commandes de test spécialisées seront arrêtées dans les spécifications de module avant implémentation. Pas de seuil de couverture arbitraire.

## Structure et contrats

- Garder les exports référencés par le projet sous `game/assets/` et les sources éditables organisées par famille sous `game/assets/source/`.
- Inventorier chaque référence d’asset dans scènes, scripts, données, audio bus et exports. Aucun asset actif ne doit être supprimé avant migration de toutes ses références.
- Préserver PNG + source Aseprite pour les sprites selon l’Art Bible. Pour l’audio, identifier format source, format runtime, fréquence, canaux, durée et provenance/licence avant de choisir la convention de production.
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

- Formats source et formats runtime pour musique et effets sonores; droits d’usage et attribution.
- Outil exact de production Aseprite/audio et format des métadonnées.
- Les choix ouverts de la section 10 de l’Art Bible qui deviennent bloquants au premier asset concerné.
