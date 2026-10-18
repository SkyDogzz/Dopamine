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

**[EN COURS] Audit du 2026-10-18 :** `docs/art/ASSET_MANIFEST.json` contient 308 IDs uniques issus du GDD, de l’Art Bible et des ressources runtime; 141 entrées couvrent animations et VFX. Tous les 63 chemins littéraux trouvés dans les scripts, scènes, thèmes et données figurent au manifeste. `game/tools/build_asset_manifest.py` reconstruit le backlog et `game/tools/validate_asset_manifest.py` vérifie les IDs, champs, statuts et skills affectés. Les sorties n’ont pas encore été générées ni validées. Les dimensions/timings laissés ouverts sont `null` et portent un blocage explicite.

Les cinq skills ont été lus intégralement. Ils spécifient leur méthode mais n’exposent pas encore de CLI stable pour staging, génération par ID, seeds en ligne de commande, import ou rapport QA. Les générateurs locaux existants écrivent en partie directement dans les chemins runtime et n’écrivent pas les métadonnées requises; ils doivent être adaptés avant de servir d’interfaces de production. LibreSprite 1.3 fonctionne via `APPIMAGE_EXTRACT_AND_RUN=1`; Python 3.13, FFmpeg 7.1.5, FFplay, Audacity (`/usr/bin/audacity`) et Godot 4.7.2 sont disponibles. Aucun GPU NVIDIA n’est détecté; le travail visuel/audio doit fonctionner sur CPU. Le conteneur n’a pas de `DISPLAY`; la lecture audio réelle n’a pas encore été vérifiée. Les tests numériques ne remplacent pas l’écoute.

**[OUVERT — préproduction visuelle]** La tenue exacte du héros, l’ordre des directions et les timings joueur, les animations d’attaque/mort, l’identité du premier biome, les détails canoniques des boss et le mapping couleur-élément sont laissés ouverts par les références. Le brief du premier lot est demandé au propriétaire avant toute production de masse. Voir les questions de production dans le journal du goal.

## État des décisions

- **[VALIDÉ]** Art Bible : pixel art strict, palette maître de 32 couleurs, maximum 16 couleurs par sprite 32x32, joueur 32x32, tiles 16x16, glow uniquement dans les VFX, priorité à la lisibilité.
- **[VALIDÉ]** GDD : feedback audio avec SFX et musique EDM/synthwave adaptative.
- **[PROPOSÉ]** Métadonnées JSON par asset, staging candidats, et statuts candidate/accepted/retired.
- **[OUVERT]** Ordre universel des directions, pivots, timing hors animations joueur, méthode de revue artistique/audio et seuils d’acceptation perceptuelle.
- **[OUVERT]** Les choix audio précis (gains, composition, format final) ne deviennent pas validés par l’existence des anciens candidats.

## Plan d’installation

1. Conserver les cinq skills versionnés dans `.agents/skills/`; ne pas installer de dépendances globales.
2. Utiliser les générateurs existants, puis compléter leurs interfaces de sélection d’IDs, seed explicite et sortie staging.
3. Ajouter un orchestrateur minimal `game/tools/asset_pipeline.py` pour générer, valider, accepter/importer et régénérer par ID, avec garde contre les modifications hors cible.
4. Étendre les validateurs pour lire la palette/règles et vérifier la provenance, les feuilles, le WAV et les boucles.
5. Migrer les références Godot, puis exécuter l’import headless et les vérifications ciblées correspondantes.
6. Exécuter la purge demandée seulement après que le projet fonctionne avec les sorties de remplacement et que le diff de purge a été examiné.
