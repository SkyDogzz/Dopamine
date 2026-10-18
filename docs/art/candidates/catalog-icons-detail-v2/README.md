# Révision des icônes catalogue — v2

Retour propriétaire : les 48 icônes de la planche « Catalog icons » manquaient de détail. Cette passe ajoute des détails de construction/facettes et un modelé pixel cohérent.

- Revue côte à côte : `index.html` (actif à gauche, candidat à droite).
- IDs concernés : 20 icônes d’armes/évolutions, 11 reliques et 17 icônes UI.
- Les PNG et sources Aseprite de ce dossier sont des candidats seulement; aucun n’a remplacé les assets actifs.
- QA : `qa-report.json` — 48/48 passés, 32×32, palette maître, hashes source/export, 8–15 couleurs par icône; zéro hash PNG identique au registre initial.
- Génération reproductible : `python3 game/tools/generate_catalog_icon_detail_candidates.py --seed 4801 --out-root docs/art/candidates/catalog-icons-detail-v2`
- QA reproductible : `python3 game/tools/validate_dopamine_pixel_candidates.py docs/art/candidates/catalog-icons-detail-v2 --report docs/art/candidates/catalog-icons-detail-v2/qa-report.json`

Les candidats restent hors runtime jusqu’à acceptation visuelle.
