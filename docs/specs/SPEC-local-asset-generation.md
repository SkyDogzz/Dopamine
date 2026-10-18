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

Chaque asset possède un identifiant stable, une source modifiable ou recette, un export candidat, une seed, des paramètres, une version de générateur, les hashes source/export, un rapport QA et l’état (`candidate`, `accepted`, `retired`). Les candidats sont produits en staging; seuls les assets acceptés sont copiés dans les chemins runtime. Une commande de régénération nomme les IDs cibles et ne réécrit aucun autre asset.

## Purge et redémarrage complet demandés

**Demande utilisateur :** tous les assets actuellement présents, qu’ils soient visuels ou audio, doivent être supprimés avant la nouvelle production.

L’inventaire au 2026-10-18 relève 407 fichiers sous `game/assets` : 169 sprites, 34 icônes, 2 fonds, 4 fontes, 92 fichiers audio et 105 sources créatives. Plusieurs sont référencés par scènes, scripts et thèmes Godot. Une suppression seule casserait donc l’import et le démarrage du projet.

La purge cible **tous** les visuels, sources graphiques, fontes, sons, musiques et sidecars d’import actuellement sous `game/assets`, sans conserver les anciens rendus comme secours. Les générateurs, palette de référence, contrats de gameplay, fichiers de configuration nécessaires au projet et registres d’audit/provenance sont conservés. `game/assets/README.md` devient une notice sur le répertoire vide et le workflow.

L’application reste lançable pendant la reconstruction : une référence d’asset absente signifie « pas encore créé ». Les scènes/scripts doivent utiliser des ressources facultatives (`load` vérifié à l’exécution), des placeholders simples dessinés par code pour le visuel et le silence pour audio. Le thème garde des fontes intégrées/standards lorsque les fontes du jeu sont absentes. Les espaces visuels/audio n’ont alors aucun placeholder exporté dans `game/assets`; les marqueurs visuels temporaires sont du code runtime et non des créations importées.

Avant la purge, on retire les `preload` obligatoires, les ressources de scènes/thème et les chargements audio non tolérants à l’absence. Les anciens hashes/usages sont déjà dans les registres d’audit et doivent rester consultables. Les sept fichiers `.uid`, `game/tools/__pycache__/` et le binaire LibreSprite non suivis observés dans l’arbre de travail ne sont pas des assets de `game/assets`; ils sont préservés.

La purge complète a été exécutée et vérifiée dans le commit `fd1e4e6`; `game/assets/` ne contient que deux notices. L’import headless et le smoke `res://tests/empty_asset_root_smoke.gd` passent.

## Audit et backlog courant

**[ÉTAT AU 2026-10-18 — candidats générés, revue requise]** `docs/art/ASSET_MANIFEST.json` contient 308 IDs uniques issus du GDD, de l’Art Bible et des ressources runtime; 141 entrées couvrent animations et VFX. Tous les 63 chemins littéraux trouvés dans les scripts, scènes, thèmes et données figurent au manifeste. `game/tools/build_asset_manifest.py` reconstruit le backlog et `game/tools/validate_asset_manifest.py` vérifie les IDs, champs, statuts et skills affectés. Les 308 entrées ont été générées en staging et leurs contrôles techniques passent : 92 visuels, 141 animations, 65 SFX et 10 fichiers musique/stems. Le rapport détaillé est `docs/art/ASSET_GENERATION_REPORT.json`; la page de revue locale (`build/assets/candidates/review/index.html`) contient les contact sheets, aperçus et lecteurs audio. Aucun candidat n’a été copié dans `game/assets`: intégration différée jusqu’à revue artistique/écoute, et le runtime garde sa sémantique « chemin absent = asset non recréé ».

Les cinq skills ont été lus intégralement. Les interfaces locales SFX, musique, art statique et QA disposent désormais d’une sortie staging, d’une sélection ciblée et/ou de rapports par asset. LibreSprite 1.3 ouvre le document Aseprite produit; Python 3.13, FFmpeg 7.1.5, FFplay, Audacity (`/usr/bin/audacity`) et Godot 4.7.2 sont disponibles. Aucun GPU NVIDIA n’est détecté; le travail visuel/audio fonctionne sur CPU. Le conteneur n’a pas de `DISPLAY`; la lecture audio réelle n’a pas encore été vérifiée. Les tests numériques ne remplacent pas l’écoute.

**[OUVERT — préproduction visuelle]** La tenue exacte du héros, l’ordre des directions et les timings joueur, les animations d’attaque/mort, l’identité du premier biome, les détails canoniques des boss et le mapping couleur-élément sont laissés ouverts par les références. Le propriétaire a autorisé des choix provisoires: joueur armure bleu nuit/cyan, accents magenta/jaune, lignes bas/gauche/droite/haut, idle 3 fps, marche 8 fps; les animations joueur d’attaque/mort demeurent des propositions. Monde nuit violet/bleu, boss par rôle et couleurs d’éléments sont non canoniques. Pour les animations non-joueur, ordre bas/gauche/droite/haut, pivot centre, idle 4 fps, déplacement 8 fps, attaque/special/mort 10 fps et VFX 12 fps sont documentés comme conventions provisoires.

## État des décisions

- **[VALIDÉ]** Art Bible : pixel art strict, palette maître de 32 couleurs, maximum 16 couleurs par sprite 32x32, joueur 32x32, tiles 16x16, glow uniquement dans les VFX, priorité à la lisibilité.
- **[VALIDÉ]** GDD : feedback audio avec SFX et musique EDM/synthwave adaptative.
- **[PROPOSÉ]** Métadonnées JSON par asset, staging candidats, et statuts candidate/accepted/retired.
- **[PROPOSÉ]** Ordre bas/gauche/droite/haut et pivot central pour les prototypes non-joueur; idle 4 fps, déplacement 8 fps, attaque/spécial/mort 10 fps, VFX 12 fps. Ces choix ne sont pas canoniques.
- **[OUVERT]** Revue artistique/audio et seuils d’acceptation perceptuelle; audio non écouté en contexte dans l’environnement sans DISPLAY.
- **[OUVERT]** Les choix audio précis (gains, composition, format final) ne deviennent pas validés par l’existence des anciens candidats.

## Plan d’installation

1. Conserver les cinq skills versionnés dans `.agents/skills/`; dépendances détectées: Python standard, Godot 4.7.2, FontForge, FFmpeg/FFplay, LibreSprite 1.3 et Audacity; pas de dépendance globale Python à installer.
2. Génération ciblée staging: `generate_neon_arcade_art.py`, `generate_original_audio.py`, `generate_original_player_sheets.py`, `generate_dopamine_enemy_animation.py`, `generate_dopamine_misc_animation.py`, `generate_original_roster.py`, `generate_original_rewards.py`, `generate_original_title_skyline.py`, `generate_original_fonts.py`. Les primitives déterministes enregistrent la seed sans la consommer.
3. `integrate_asset_candidates.py` fournit un dry-run par IDs, copie seulement des IDs explicitement acceptés dans le manifeste et bloque toute collision de destination ou écrasement de hash; il préserve sources, sidecars JSON et ressources `SpriteFrames`.
4. Contrôles installés: `validate_dopamine_pixel_candidates.py`, `validate_dopamine_animation_candidates.py`, `validate_dopamine_audio_candidates.py`; utiliser après chaque lot.
5. L’import Godot jetable des 376 exports et le chargement de 131 ressources `SpriteFrames` générées ont réussi. L’intégrateur ID-scopé passe en dry-run sur les 308 destinations, préserve les hashes préexistants et bloque toute écriture sans acceptation par ID. L’intégration runtime/références reste à faire après revue.
6. Exécuter la purge demandée seulement après que le projet fonctionne avec les sorties de remplacement et que le diff de purge a été examiné.
