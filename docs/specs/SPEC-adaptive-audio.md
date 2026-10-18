# Spec: `adaptive-audio` — Musique progressive et remplacement sonore

## Objectif

Remplacer tous les effets sonores et la musique par une direction arcade synthwave néon avec une base EDM. L’intensité musicale suit la progression de la run; les événements tels que l’apparition d’un boss font évoluer le morceau graduellement et de façon fluide, sans arrêt ni bascule brutale vers une piste indépendante.

## Stack et emplacement

Godot 4.7.2 audio buses/players; runtime sous `game/assets/audio/`; orchestration actuelle `game/scripts/adaptive_survival_music.gd`; appels SFX à inventorier. Le format source/audio et le workflow d’enregistrement ou synthèse restent ouverts.

### Décisions validées pour cette initiative (2026-10-18)

- **[VALIDÉ]** Produire les nouveaux SFX et la musique par synthèse procédurale originale, sans réutiliser les fichiers ni les recettes audio existants.
- **[VALIDÉ]** Après migration complète, supprimer les anciennes sources/recettes/références audio et visuelles du dépôt; préserver jusque-là les fichiers actifs et les preuves d'audit nécessaires.
- **[OUVERT]** Format source, fréquence runtime, canaux et format de boucle musicale; arrêter ces contrats avant la production finale de musique et du catalogue complet.
- **[OUVERT]** Méthode d'arrangement adaptatif, seuils de progression et calibration de mix; les valeurs du contrôleur actuel restent **[PROPOSÉES]**.

Prototype d'auteur indépendant : `game/tools/generate_original_audio.py` écrit un son prototype et 38 candidats couvrant les 19 familles SFX existantes, dans `game/assets/audio/original_procedural/`. L'algorithme emploie oscillateurs, enveloppes analytiques et un bruit transitoire à seed fixe via la seule bibliothèque standard Python; aucune recette ni sortie existante n'est lue. Les 38 WAV sont distincts et déterministes; format PCM16 mono 44,1 kHz, durée 45–950 ms, échantillons finis et non écrêtés. Chaque fichier a son hash, son niveau RMS/pic et sa durée dans `sfx/manifest.json`; la sortie est reproductible à l'identique. Une page d'aperçu est disponible à `preview.html`. **[PROPOSÉ]** Ces sons sont des candidats de synthèse, pas des remplacements approuvés. **[OUVERT]** Ils ne sont ni écoutés (aucun lecteur local dans l'environnement d'agent), ni intégrés ou mixés dans une run; ces validations restent obligatoires.

## Commandes de vérification

- `godot --headless --editor --path game --quit`
- Tests unitaires de calcul d’intensité et smoke du contexte audio (menu, run active, pause, boss, fin de run).
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/adaptive_survival_music_smoke.gd`
- Revue d’écoute sur transitions de progression et événements de boss; contrôles de pic, clipping, niveau perçu et mix sous les SFX.

## Structure et contrats

- Remplacer toutes les références audio actives, y compris tirs, impacts, dégâts, pickups, coffres, UI, boss et musique; maintenir volume/options et états actuels.
- Une identité EDM cohérente accompagne la run. Les vagues, progression et boss pilotent graduellement l’énergie, l’orchestration, la densité ou paramètres équivalents.
- À apparition d’un boss, la musique ne redémarre pas et ne passe pas brutalement à une piste indépendante; elle fait un fondu/crossfade ou une transition musicale continue avec tempo/phase cohérents.
- Pause, choix de coffre, résultat, victoire/défaite et retour menu gardent des comportements audio définis et testables.
- Les notifications audio de danger demeurent audibles au-dessus de la musique; le joueur garde le contrôle des volumes déjà disponibles.

## Style et règles de mix

Synthwave arcade néon, base EDM avec progression dramatique mais non intrusive. Les SFX de gameplay restent courts et reconnaissables, les télégraphes de boss prioritaires. Niveaux, filtres, sidechain/ducking et durée de fade à calibrer à l’écoute, non à inventer comme règles GDD.

GDScript conserve des fonctions de calcul de cible pures et des appels explicites de contexte audio; les assets audio sont référencés par chemin stable et leurs métadonnées restent séparées du code de mix.

## Stratégie de vérification

Tester calculs déterministes de cibles de progression indépendamment du mix; smoke de non-redémarrage de piste et de transition continue aux contextes; examiner les formes d’onde et l’écoute répétée aux niveaux de volume. Couvrir les effets SFX pour collisions simultanées et options de volume.

## Limites

- Toujours respecter le choix utilisateur : synthwave/EDM, progression de run, transitions fluides, aucun changement abrupt au spawn boss.
- Toujours vérifier les droits des sources audio et documenter provenance/licences.
- Garder les paramètres d’intensité proposés distincts des décisions confirmées; ne pas modifier les règles de jeu pour piloter la musique.
- Ne jamais imposer un changement de morceau non synchronisé ni faire masquer un télégraphe audio par la musique.

## Critères de réussite

- Tous les sons actifs ont été remplacés par un set cohérent et les références manquantes sont absentes.
- Une run entière donne une progression musicale perceptible liée à son contexte, avec transitions fluides lors des vagues et boss.
- La piste conserve sa continuité lors du spawn boss (pas de redémarrage ni saut brutal), reprend correctement après pause et se termine proprement.
- Les mix et effets importants restent audibles sans clipping et les volumes continuent de fonctionner.

## Questions ouvertes

- Production originale, synthèse procédurale ou sources sous licence; formats source et runtime.
- Utiliser plusieurs stems/couches synchronisées, un arrangement évolutif unique ou une autre méthode de transition; choisir après inspection de Godot et des sources disponibles.
- Courbe d’intensité par vagues, seuils de boss et comportement des transitions menu/run/fin à définir et mesurer.
