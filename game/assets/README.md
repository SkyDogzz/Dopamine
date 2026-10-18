# Assets — bibliothèque provisoire intégrée

Les assets de jeu sont générés localement par les cinq skills Dopamine puis importés ici aux destinations du manifeste `docs/art/ASSET_MANIFEST.json`. Les 308 exports actuels ont passé leur QA technique et sont intégrés sous portée prototype provisoire autorisée par le propriétaire. Ils restent non canoniques quand le GDD ou l’Art Bible laisse un choix ouvert.

Les sources éditables et métadonnées par asset sont conservées sous `game/assets/source/` et à côté des exports. Seeds, paramètres, recettes et états d’acceptation sont tracés dans le manifeste et les sidecars JSON. L’index de revue visuelle/audio local est généré sous `build/assets/candidates/review/index.html` (dossier de build ignoré par Git).

`human_review_status=pending` signifie que la revue visuelle/audio reste à faire; les validations techniques ne remplacent pas cette revue. Pour modifier un asset, générer uniquement son ID en staging, lancer `dopamine-asset-qa`, puis utiliser `game/tools/integrate_asset_candidates.py` avec une acceptation explicite et un dry-run. Ne pas écraser les assets non ciblés.
