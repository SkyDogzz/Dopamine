# Audit des remplacements d’assets

**Date : 2026-10-18.** Point de reprise du goal de remplacement ciblé. Cet audit distingue le remplacement et le QA technique de l’acceptation artistique et auditive.

## Mise à jour de suivi — revue humaine non reçue

Le 2026-10-18, les registres courants et l’environnement de revue ont été revérifiés. Les 356 entrées du manifeste sont toujours intégrées (`integrated`), validées techniquement (`passed`) et acceptées uniquement pour la production provisoire (`accepted_for_provisional_production`); les 356 ont `human_review_status=pending`. Les captures et planches archivées permettent une inspection visuelle représentative, mais ne constituent pas l’acceptation globale du propriétaire. L’environnement ne possède pas de sortie PCM (`/dev/snd` expose seulement `seq` et `timer`), donc aucun son ne peut être approuvé à l’écoute depuis cet environnement.

La demande de revue n’a pas produit de choix d’acceptation ni de liste d’IDs à corriger. En conséquence, aucun asset n’est modifié ni promu en « approuvé ». Les assets restent des propositions provisoires; les choix canoniques encore ouverts (héros, boss, biome, détails d’animation et mix) restent non tranchés. Reprendre uniquement sur les IDs signalés par le propriétaire, ou mettre à jour l’acceptation après revue humaine effective.

**Limite de clôture :** l’audit peut conclure qu’aucun asset hérité/non remplacé requis ni défaut technique connu ne reste dans les registres actuels, mais il ne peut pas établir une acceptation perceptuelle/auditive humaine. Le goal ne peut donc pas être déclaré complet avant cette revue ou une décision explicite de laisser ces propositions provisoires hors acceptation.

## État constaté

- `ASSET_MANIFEST.json` contient 356 IDs uniques; leurs 356 chemins runtime existent et sont marqués `integrated`. Les 356 entrées ont `validation_status=passed` et `acceptance_status=accepted_for_provisional_production`; leur `human_review_status` reste `pending`.
- Les registres de provenance et migration passent : les 356 assets courants correspondent à leurs sources/hashes, et les 417 entrées créatives de l’instantané historique ont une migration ou un retrait enregistré.
- La comparaison SHA-256 avec le registre initial trouve zéro empreinte identique. C’est une preuve de non-réutilisation exacte, pas une évaluation de ressemblance visuelle ni de qualité artistique.
- Les références connues ne pointent pas vers des chemins manquants selon le validateur de manifeste et le smoke de portée d’intégration.
- Les captures et planches existantes représentent les prototypes non canoniques autorisés. Les décisions encore ouvertes sur le héros, les boss, le biome, les animations, les fontes et le mix restent des propositions; aucune identité canonique n’est créée par cet audit.

## Revalidation locale des fichiers intégrés

Les rapports d’ancienne génération sous `build/assets/candidates/` n’étaient pas présents dans le checkout. Pour vérifier les exports actuels sans les régénérer, les fichiers intégrés et leurs sources ont été présentés en lecture seule aux validateurs locaux dans des répertoires temporaires.

- 90 PNG statiques : palette maître, transparence, limite de couleurs des sprites 32×32, hash PNG et signature/hash de source Aseprite — **passé**.
- 131 feuilles animées : palette, grille, taille de frame, limite de couleurs par frame, frames non vides et distinctes par rangée, hash PNG et source Aseprite — **passé**.
- 133 WAV intégrés : manifeste/sidecar, SHA-256, PCM16 mono 44,1 kHz, signal non silencieux et non écrêté, SFX distincts, longueur des cinq stems synchronisés et limites de boucle — **passé** via `python3 game/tools/validate_original_audio.py`.
- Les 125 SFX respectent la durée documentée de 45–950 ms, à l’arrondi d’un demi-échantillon près; aucun ne dépasse 0,26 % d’échantillons exactement nuls. Mesure indicative des couches musicales : 76,38 % d’échantillons nuls dans `music_stem_boss`, 44,43 % dans `music_stem_rhythm` et 32,04 % dans `music_stem_arp`. Ces silences peuvent refléter l’arrangement sparse des couches; seule l’écoute peut dire s’ils donnent des pauses excessives.
- Le pack de revue local a été régénéré depuis les assets intégrés : 9 planches, 90 cartes visuelles, 131 prévisualisations animées et 133 lecteurs audio. Reproduction : `python3 game/tools/create_asset_review_pack.py`; sortie locale ignorée par Git : `build/assets/candidates/review/index.html`.
- `validate_asset_manifest.py`, `validate_asset_provenance_registry.py`, `validate_no_legacy_asset_hash_reuse.py` et `asset_integration_scope_smoke.py` — **passés**.

Godot 4.7.2 a été lancé depuis `/tmp`; la GDExtension Debug a été compilée dans `game/bin/linux/` depuis la dépendance Godot-C++ épinglée par CMake. L’import éditeur, les smokes d’assets ciblés, le smoke des fontes et la suite complète CTest **121/121** passent.

## Reste avant acceptation complète

- Revue visuelle du propriétaire sur les planches/captures et les animations en jeu; les validations mécaniques ne prouvent pas la lisibilité ou la cohérence perçue.
- Écoute humaine des SFX, de la musique et des transitions en contexte; cet environnement n’a pas de sortie audio PCM.
- Toute correction issue de ces revues doit cibler seulement les IDs signalés; préserver les autres exports validés.

- Demande de revue envoyée; aucun choix d’acceptation ni IDs à corriger reçu à la date de cette mise à jour.

**Statut :** aucune lacune de remplacement ou d’intégration détectée dans l’audit courant. Les preuves techniques sont à jour; le goal reste ouvert jusqu’à l’acceptation humaine visuelle et auditive ou jusqu’à ce que les choix en attente soient explicitement documentés comme non acceptés.
