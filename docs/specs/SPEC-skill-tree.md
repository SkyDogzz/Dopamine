# Spec: `skill-tree` — Page d’arbre de compétences ramifié

## Objectif

Remplacer la vue actuelle de nœuds par une véritable page qui représente les compétences comme un arbre interconnecté avec des branches visibles, des prérequis compréhensibles et des états de nœud lisibles. Permettre les actions de déblocage et le respec selon les règles déjà définies.

## Stack et emplacement

Godot 4.7.2, `Control`, GDScript et système de progression existant (`game/scripts/progression_service.gd`, `game/scenes/skill_tree_panel.tscn`). Données structurées selon le modèle GDD `SkillNode {id, cost, prerequisites, effects}` et sauvegarde versionnée selon ADR-009.

## Commandes de vérification

- `godot --headless --editor --path game --quit`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/progression_service_smoke.gd`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/skill_tree_panel_visual_smoke.gd`
- Smokes de skill tree pour prérequis, déblocage, respec, sauvegarde/migration, navigation et layouts.

## Structure et contrats

- Montrer liens/branches, nœuds acquis, disponibles, verrouillés et sélection courante; afficher coût, effet, prérequis et solde.
- Débloquer uniquement si les prérequis et ressources sont satisfaits; respecter le respec complet gratuit et l’indépendance avec Achievement Mastery.
- Conserver la participation du skill tree aux modes qui l’autorisent; Sandbox utilise ses données isolées et n’altère pas les sauvegardes normales.
- Utiliser la donnée et le service progression comme autorité; ne pas dupliquer la logique économique dans l’UI.

## Style et règles de contenu

Branches visibles, nœuds espacés, navigation claire à 640×360 et possibilité d’explorer les zones plus larges sans cacher le statut sélectionné. Style Neon Arcade et focus visible.

GDScript utilise `snake_case`; les IDs de nœuds restent des identifiants de données, et la scène émet un signal de demande plutôt que de modifier directement le profil.

## Stratégie de vérification

Vérifier la validité du graphe (identifiants uniques, références de prérequis valides, absence de cycles ou cycles explicitement pris en charge), achats/refus, respec, persistence, contrôle souris/clavier/manette et lisibilité sur les viewports ciblés.

## Limites

- Toujours respecter les contrats validés GDD de progression (100 nœuds conservés au lancement; respec gratuit; tous les nœuds peuvent finir par être acquis) et l’isolation Sandbox.
- Toujours distinguer les règles `[VALIDÉ]` des coûts/bonus `[PROPOSÉ]`.
- Faire trancher les règles d’allocation/effets/coûts lorsqu’elles sont nécessaires à l’implémentation.
- Ne jamais inventer les 100 définitions de nœuds ni interpréter la cible 120 comme un contenu validé.

## Critères de réussite

- La page ressemble visuellement à un arbre ramifié et rend compréhensibles les prérequis et états.
- Les actions ont les mêmes résultats que le service de progression, sont sauvegardées correctement et restent séparées du Sandbox.
- Le graphe existant est présenté sans fabriquer de nœuds ou d’effets non décidés.
- Les parcours et layouts sont validés par smokes et revue visuelle.

## Questions ouvertes

- Le GDD indique 100–150 nœuds avec lancement à 100, tandis que le jeu actuel doit être audité : confirmer les définitions réellement implémentées, leur disposition logique et quels paramètres restent proposés.
- Choix de mise en page (vue panoramique, zoom, navigation par branches) et seuils de densité à définir en conception si l’arbre actuel ne suffit pas.
