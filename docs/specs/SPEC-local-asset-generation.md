# Spec: pipeline local de génération d’assets et migration depuis zéro

## Objectif

Fournir une production d’assets visuels et audio entièrement locale, gratuite et pilotée par Codex, avec sources, recettes, seeds, paramètres, métadonnées, QA avant import Godot et régénération ciblée. Aucun service cloud, API payante ou génération distante n’est requis.

## Skills du dépôt

- `.agents/skills/dopamine-pixel-art/` : images, palette et source éditable.
- `.agents/skills/dopamine-animation/` : feuilles cohérentes, identité stable et QA inter-frames.
- `.agents/skills/dopamine-sfx/` : SFX 8-bit/synthwave déterministes.
- `.agents/skills/dopamine-music/` : musique synthwave en boucle et stems synchronisés.
- `.agents/skills/dopamine-asset-qa/` : conformité, provenance, import et contrôle de portée.

## Architecture proposée

Les skills orchestrent les générateurs locaux existants sous `game/tools/`; ils n’embarquent pas un service de génération externe. Python standard est le socle reproductible. Godot 4.7.2 vérifie les imports runtime. LibreSprite/FFmpeg sont des utilitaires facultatifs. Pillow/NumPy/SciPy ne sont pas nécessaires au chemin par défaut.

Chaque asset possède un identifiant stable, une source modifiable ou recette, un export, une seed, des paramètres, une version de générateur, les hashes source/export, un rapport QA et des états distincts : `generation_status`, `validation_status`, `acceptance_status`, `human_review_status` et `integration_status`. Les exports passent en staging puis sont copiés vers les destinations exactes du manifeste seulement avec une acceptation explicite. Une commande de régénération nomme les IDs cibles, vérifie les hashes sources/exports et refuse les collisions ou écrasements non gérés.

## Purge initiale et reconstruction

**Étape historique — 2026-10-18 :** l’utilisateur a demandé de supprimer les assets visuels et audio présents avant leur recréation. Cette purge a été exécutée avant la production décrite ci-dessous. Elle ne décrit plus l’état du dépôt.

L’inventaire au 2026-10-18 relève 407 fichiers sous `game/assets` : 169 sprites, 34 icônes, 2 fonds, 4 fontes, 92 fichiers audio et 105 sources créatives. Plusieurs sont référencés par scènes, scripts et thèmes Godot. Une suppression seule casserait donc l’import et le démarrage du projet.

La purge initiale a ciblé tous les visuels, sources graphiques, fontes, sons, musiques et sidecars d’import sous `game/assets`. Les générateurs, palette de référence, contrats de gameplay, fichiers de configuration et registres d’audit/provenance ont été conservés.

L’application reste lançable pendant la reconstruction : une référence d’asset absente signifie « pas encore créé ». Les scènes/scripts doivent utiliser des ressources facultatives (`load` vérifié à l’exécution), des placeholders simples dessinés par code pour le visuel et le silence pour audio. Le thème garde des fontes intégrées/standards lorsque les fontes du jeu sont absentes. Les espaces visuels/audio n’ont alors aucun placeholder exporté dans `game/assets`; les marqueurs visuels temporaires sont du code runtime et non des créations importées.

Avant la purge, on retire les `preload` obligatoires, les ressources de scènes/thème et les chargements audio non tolérants à l’absence. Les anciens hashes/usages sont déjà dans les registres d’audit et doivent rester consultables. Les sept fichiers `.uid`, `game/tools/__pycache__/` et le binaire LibreSprite non suivis observés dans l’arbre de travail ne sont pas des assets de `game/assets`; ils sont préservés.

La purge a été exécutée et vérifiée dans le commit `fd1e4e6`, puis suivie par la génération et l’intégration des prototypes présentées dans la section suivante. Le smoke `res://tests/empty_asset_root_smoke.gd` documente l’état intermédiaire vide et ne constitue plus le critère d’intégration courant.

## Audit et bibliothèque intégrée

**[ÉTAT AU 2026-10-18 — intégration provisoire]** `docs/art/ASSET_MANIFEST.json` contient 308 IDs uniques : 92 assets pixel art, 141 entrées animation/VFX, 65 SFX et 10 musiques/stems. Les cinq skills locaux ont servi à générer les assets; les validations pixel art, animation et audio ont passé leurs rapports QA. Les sources, exports, sidecars et ressources `SpriteFrames` sont intégrés dans `game/assets/`. Cette intégration est un lot de prototypes accepté pour poursuivre la production; elle ne vaut pas approbation artistique ou canonique.

Le propriétaire a autorisé une portée de prototypes provisoires non canoniques pour l’armure du héros, les ennemis/boss par rôle et l’arène nuit violet/bleu. Les lignes joueur bas/gauche/droite/haut, idle 3 fps et marche 8 fps ont été retenues. L’acceptation technique et l’intégration sont donc séparées de `human_review_status=pending`, qui reste en attente de revue perceptuelle et d’écoute. Les fonts, composition/mix musical et certains détails de biome/boss/éléments sont toujours explicitement provisoires.

La galerie locale `build/assets/candidates/review/index.html` contient planches contact, feuilles d’animation, aperçus et lecteurs WAV. L’environnement courant n’expose pas de périphérique de lecture audio (`/dev/snd` ne contient pas de sortie), donc l’écoute en contexte demeure requise. Python standard, Godot 4.7.2, FFmpeg/FFplay et Audacity sont disponibles; aucun service cloud ni API payante n’est utilisé.

L’import Godot complet et CTest passent (**118/118**). L’export PCK `Linux/X11` a été généré avec succès; le preset inclut les VFX, l’audio et les fonts, mais exclut les sources éditables. Les registres `ASSET_FILE_REGISTER_CURRENT.csv` et `PROVENANCE_ASSETS.csv` ont été rafraîchis; leur vérificateur passe pour 308 assets créatifs actuels et 417 entrées historiques migrées/retirées.

## État des décisions

- **[VALIDÉ]** Art Bible : pixel art strict, palette maître de 32 couleurs, maximum 16 couleurs par sprite 32x32, joueur 32x32, tiles 16x16, glow uniquement dans les VFX, priorité à la lisibilité.
- **[VALIDÉ]** GDD : feedback audio avec SFX et musique EDM/synthwave adaptative.
- **[VALIDÉ — implémenté]** Métadonnées JSON par asset, staging ciblé, QA, acceptation provisoire distincte de revue humaine, intégration Godot ID-scopée et registre source/hash.
- **[PROPOSÉ]** Ordre bas/gauche/droite/haut et pivot central pour les prototypes non-joueur; idle 4 fps, déplacement 8 fps, attaque/spécial/mort 10 fps, VFX 12 fps. Ces choix ne sont pas canoniques.
- **[OUVERT]** Revue artistique/audio et seuils d’acceptation perceptuelle; les captures locales montrent les prototypes, mais l’audio n’a pas pu être écouté dans la session faute de sortie matérielle.
- **[OUVERT]** Les choix audio précis (gains, composition, format final) restent proposés malgré l’intégration et les validations numériques.

## Plan d’installation

1. Conserver les cinq skills versionnés dans `.agents/skills/`; dépendances détectées: Python standard, Godot 4.7.2, FontForge, FFmpeg/FFplay, LibreSprite 1.3 et Audacity; pas de dépendance globale Python à installer.
2. Génération ciblée staging: `generate_neon_arcade_art.py`, `generate_original_audio.py`, `generate_original_player_sheets.py`, `generate_dopamine_enemy_animation.py`, `generate_dopamine_misc_animation.py`, `generate_original_roster.py`, `generate_original_rewards.py`, `generate_original_title_skyline.py`, `generate_original_fonts.py`. Les primitives déterministes enregistrent la seed sans la consommer.
3. `integrate_asset_candidates.py` fournit un dry-run par IDs, vérifie hashes source/export, copie seulement les IDs explicitement acceptés dans le manifeste et bloque toute collision ou écrasement non géré; il préserve sources, sidecars JSON et ressources `SpriteFrames`.
4. Contrôles installés: `validate_dopamine_pixel_candidates.py`, `validate_dopamine_animation_candidates.py`, `validate_dopamine_audio_candidates.py`; utiliser après chaque lot.
5. L’import Godot réel couvre les 308 exports; 131 ressources `SpriteFrames` sont chargées, et CTest passe 118/118 avec les assets présents.
6. L’export PCK Linux/X11 a été créé; le registre de provenance et le rapport complet sont rafraîchis après chaque intégration.
