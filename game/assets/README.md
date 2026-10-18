# Assets — démarrage à vide

Les exports visuels, sources graphiques, fontes et fichiers audio ont été purgés pour reconstruire le jeu depuis zéro.

Une référence runtime vers un asset absent signifie que cet asset n’a pas encore été généré. Le jeu doit rester lançable sans ressources créatives; les systèmes visuels utilisent des placeholders dessinés par code et l’audio reste silencieux jusqu’à intégration d’un asset passé par la QA.

Les générateurs sont conservés dans `game/tools/`. Les règles visuelles et audio sont dans `docs/ART_BIBLE.txt` et `docs/specs/SPEC-local-asset-generation.md`; les registres historiques de hashes/provenance restent dans `docs/art/`.

Après génération, garder sources, paramètres, seed et métadonnées dans le dépôt. Importer un asset dans ce répertoire seulement après validation et acceptation.
