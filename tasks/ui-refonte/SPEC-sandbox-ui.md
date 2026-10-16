# Spec : `sandbox-ui`

**Statut : implémentée et livrée.** Refonte visuelle locale, smoke et isolation Sandbox vérifiés; aucune capacité de progression n’a été ajoutée.

## Statuts de référence

- **[VALIDÉ]** Refonte du Sandbox développeur déjà présent, accessible depuis son entrée discrète, avec ses fonctions de simulation conservées.
- **[VALIDÉ]** Isolation stricte du Sandbox vis-à-vis de `SaveService`, de la progression normale et du profil joueur.
- **[VALIDÉ]** Les interfaces gardent une direction pixel art néon, sont utilisables à la souris/clavier/manette et montrent le focus.
- **[PROPOSÉ]** Le Sandbox réutilise le Theme partagé, augmente la lisibilité des métriques et clarifie les actions via tooltips.
- **[OUVERT]** Aucun arbitrage de gameplay ou de données n’est requis par cette refonte visuelle.

## Objectif et portée

Clarifier l’interface du Sandbox développeur sans changer le cœur de simulation ni ses commandes : spawn, pause/reprise, step, vitesse, reset, inspecteur, steering, statuts, métriques et logs. Le Sandbox Lab joueur complet reste hors périmètre.

La scène adopte le Theme partagé avec ses styles de focus, les métriques s’organisent en grille et les commandes de simulation exposent leur rôle au survol. Les entrées et données demeurent celles des systèmes existants.

## Contraintes

- Ne pas ajouter de référence à `SaveService`, `ProgressionService` ou à l’équipement permanent.
- Ne pas changer de comportement, d’équilibrage, de contrat natif ou de données de simulation.
- Garder le focus initial, les contrôles natifs Godot et les tooltips de configuration existants.
- Ne pas élargir la portée au Sandbox Lab joueur P8.

## Vérification

Le smoke `sandbox_ui_smoke.gd` vérifie le Theme partagé, la grille de métriques, le focus initial, les commandes existantes et l’isolation par fixture de sauvegarde sentinelle. Compléter avec `sandbox_smoke.gd`, import Godot headless, recherche de références aux services de progression et `git diff --check`.
