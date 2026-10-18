# Spec: `equipment-screen` — Personnage, slots et comparaison d’équipement

## Objectif

Créer une vraie page d’équipement hors run. À gauche, afficher la représentation du personnage et ses six emplacements avec la pièce équipée. À droite, présenter la liste des pièces possédées pouvant être équipées sur l’emplacement choisi. La sélection montre les statistiques avant/après; l’utilisateur peut équiper, remplacer ou retirer la pièce.

## Stack et emplacement

Godot 4.7.2, scènes `Control`, GDScript; branchement au hub et au `ProgressionService` existant (`equipment_inventory_panel.tscn`, `survival_hub.gd`). Modèle GDD `EquipmentInstance`; sauvegarde versionnée ADR-009.

## Commandes de vérification

- `godot --headless --editor --path game --quit`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/progression_service_smoke.gd`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/equipment_stats_smoke.gd`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/equipment_slots_smoke.gd`
- Ajouter ou adapter un smoke d’écran couvrant les six slots, filtres, comparaison et opérations d’équipement.

## Structure et contrats

- Slots : helmet, armor, gloves, boots, amulet, ring; sélection d’un slot filtre la liste au type compatible.
- La comparaison calcule les stats actuelles avec la pièce équipée et les stats résultantes en remplaçant celle-ci par la sélection; afficher valeurs avant/après et variation positive/négative clairement.
- La prévisualisation est sans mutation; la confirmation appelle le service existant; après succès la page reflète le profil persistant.
- Inclure états vide, aucun équipement compatible, erreur de chargement et échec d’action.
- Respecter les règles de rareté/effets et l’inventaire permanent illimité. Équipement reste inaccessible en cours de run.

## Style et interaction

Composition personnage + six slots à gauche, liste sélectionnable à droite, résumé comparatif toujours visible et action primaire explicite. À 640×360, adapter le contenu avec panneaux/tabulation/scroll plutôt que réduire le texte sous le seuil lisible. Support souris/clavier/manette et focus visible.

GDScript utilise `snake_case`; l’écran garde sélection et prévisualisation comme état d’affichage, et demande mutation via signaux vers le service autoritaire.

## Stratégie de vérification

Vérifier chaque slot, sélection/filtrage, pièce déjà équipée, slot vide, remplacement, retrait, stat positive, négative et inchangée, effet unique, échec de sauvegarde et navigation. Confirmer par une comparaison de référence que la prévisualisation exclut l’ancienne pièce et n’applique la nouvelle qu’une fois.

## Limites

- Toujours respecter les six slots et l’équipement hors run.
- Toujours utiliser le calculateur/service autoritaire des stats afin d’éviter la divergence entre preview et run.
- Définir la représentation du personnage à partir des assets effectivement disponibles; ne pas prétendre que l’équipement change visuellement le sprite si le jeu ne le fait pas.
- Ne pas réinventer la formule d’agrégation d’équipement ou les arrondis sans arbitrage/documentation.

## Critères de réussite

- Les six slots, équipement actuel, liste filtrée, actions d’équipement/remplacement/retrait sont utilisables.
- L’aperçu avant/après correspond exactement aux valeurs appliquées après confirmation, y compris équipement vide et bonus uniques.
- Aucun changement n’est sauvegardé tant que l’action n’est pas confirmée; l’état du profil se rafraîchit après opération.
- Parcours clavier/manette/souris, layouts ciblés et états d’erreur sont validés.

## Questions ouvertes

- Quel asset représente le personnage équipé et les superpositions de pièces sont-elles une exigence visuelle ou une représentation schématique suffit-elle ?
- Les fonctions existantes de vente, démantèlement et enhancement restent accessibles; leur placement exact (fiche secondaire ou écran dédié) peut suivre le design final sans supprimer ces parcours.
