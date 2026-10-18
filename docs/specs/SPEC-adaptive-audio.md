# Spec: `adaptive-audio` — Musique progressive et remplacement sonore

## Objectif

Remplacer tous les effets sonores et la musique par une direction arcade synthwave néon avec une base EDM. L’intensité musicale suit la progression de la run; les événements tels que l’apparition d’un boss font évoluer le morceau graduellement et de façon fluide, sans arrêt ni bascule brutale vers une piste indépendante.

## Stack et emplacement

Godot 4.7.2 audio buses/players; runtime sous `game/assets/audio/`; orchestration actuelle `game/scripts/adaptive_survival_music.gd`; appels SFX à inventorier. Le format source/audio et le workflow d’enregistrement ou synthèse restent ouverts.

### Décisions validées pour cette initiative (2026-10-18)

- **[VALIDÉ]** Produire les nouveaux SFX et la musique par synthèse procédurale originale, sans réutiliser les fichiers ni les recettes audio existants.
- **[VALIDÉ]** Après migration complète, supprimer les anciennes sources/recettes/références audio et visuelles du dépôt; préserver jusque-là les fichiers actifs et les preuves d'audit nécessaires.
- **[PROPOSÉ]** Candidats d’écoute en WAV PCM16, mono, 44,1 kHz; ce format n'est pas encore fixé comme contrat de livraison runtime.
- **[PROPOSÉ]** Premier prototype de musique : boucle de quatre mesures en 4/4 à 115 BPM, centre tonal Ré mineur, avec stems rythme, basse, pad, arpège et boss; un mix de préécoute additionne les couches avec gains provisoires. Ces choix servent au prototype uniquement et ne sont pas validés comme direction musicale finale.
- **[OUVERT]** Format source éditable, fréquence runtime, canaux et contrat final de boucle musicale; les arrêter avant la production finale de musique et du catalogue complet.
- **[OUVERT]** Méthode d'arrangement adaptatif, seuils de progression et calibration de mix; les valeurs du contrôleur actuel restent **[PROPOSÉES]**.

Production originale : `game/tools/generate_original_audio.py` écrit 38 SFX couvrant les 19 familles d’événements actives et cinq stems musicaux dans `game/assets/audio/original_procedural/`. L’algorithme emploie oscillateurs, enveloppes analytiques et bruit seedé par identifiant en bibliothèque standard Python; aucune recette ni sortie préexistante n’est lue. Les SFX sont distincts, déterministes, durent 45–950 ms et sont finis/non écrêtés. Leurs hash, RMS, pic et durée sont dans `sfx/manifest.json`; les stems et mix sont dans `music/manifest.json`. `python3 game/tools/validate_original_audio.py` vérifie les 44 WAV, l’unicité des SFX, les formats et raccords de boucle. L’autoload `Sfx` charge les 38 nouveaux fichiers par les familles existantes; cinq WAV musique sont maintenant chargés dans un seul `AudioStreamSynchronized`. La montée de vague augmente progressivement l’arpège; le contexte boss ouvre le cinquième stem par fondu, sans redémarrage du lecteur. L’ancien OGG et son import ont été retirés après recherche de références et consignation des hashes; les anciens WAV, recettes et outils de rendu SFX étaient déjà retirés. **[PROPOSÉ]** Les gains, composition et formats finaux restent des candidats non approuvés; aucune écoute de l’intégration dans un combat n’est attestée. **[OUVERT]** L’environnement ne possède pas de sortie ALSA/PulseAudio; une écoute humaine reste obligatoire.

## Commandes de vérification

- `godot --headless --editor --path game --quit`
- Tests unitaires de calcul d’intensité et smoke du contexte audio (menu, run active, pause, boss, fin de run).
- `python3 game/tools/validate_original_audio.py` — vérifier hashes, en-têtes, clipping, unicité SFX et raccord des boucles candidates.
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

Le smoke `adaptive_survival_music_smoke.gd` vérifie maintenant que la position de lecture continue d'avancer quand le contexte boss change; il confirme aussi que les cinq stems ont une boucle explicite, que le gain du stem boss évolue en fondu et que pause/fin cible le silence progressivement. L'API [`AudioStreamSynchronized` (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_audiostreamsynchronized.html) synchronise les sous-flux au lancement; [`AudioStreamWAV` (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_audiostreamwav.html) porte leurs limites de boucle. La vérification headless ne remplace pas l'écoute du mix.

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

- **[VALIDÉ]** Synthèse originale sans réutilisation des sources ou recettes audio existantes. **[OUVERT]** Formats source et runtime.
- Utiliser plusieurs stems/couches synchronisées, un arrangement évolutif unique ou une autre méthode de transition; choisir après inspection de Godot et des sources disponibles.
- Courbe d’intensité par vagues, seuils de boss et comportement des transitions menu/run/fin à définir et mesurer.

## Avancement audio (2026-10-18)

- **[VALIDÉ]** Les 38 anciens SFX et toutes les recettes/outils qui les ont produits ont été remplacés/retirés après migration. Le jeu garde les identifiants de famille et le mixage de priorité/voix; le nouvel autoload charge uniquement les créations originales.
- **[VALIDÉ — CONTRÔLE NUMÉRIQUE]** `sfx_service_assets_smoke.gd` confirme les 38 fichiers actifs sur 19 familles; le validateur confirme hashes, format PCM16 mono 44,1 kHz, samples finis/non écrêtés et sons distincts. Aucun résultat numérique ne vaut revue auditive.
- **[VALIDÉ — PAQUET]** L’export Linux/X11 ciblé `/tmp/dopamine-sfx.pck` contient les chemins SFX originaux vérifiés et exclut les chemins/recettes retirés.
- **[INTÉGRÉ, [PROPOSÉ]]** Les cinq stems synchronisés remplacent l’OGG; la progression de vague et le fondu de boss sont couverts par `adaptive_survival_music_smoke.gd`. Gains, composition et choix de format runtime restent proposés.
- **[OUVERT]** Écoute humaine du mix SFX/musique et des transitions sur appareil avec sortie, en menu, run, vague/boss, pause et fin; vérifier aussi que les cues de danger dominent la musique. L’environnement courant est headless et ne possède aucun périphérique ALSA/PulseAudio.
