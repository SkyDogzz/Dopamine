# Instructions pour les agents

- Commence par lire `README.md` et les documents de référence qu’il indique.
- Respecte les décisions marquées **ACCEPTÉ** dans les ADR et l’architecture. En cas de conflit avec le GDD, ces documents prévalent.
- Dans le GDD, distingue toujours **[VALIDÉ]**, **[PROPOSÉ]** et **[OUVERT]**. Ne présente pas une proposition comme une décision prise.
- Garde l’architecture Sandbox-first et l’isolation stricte entre le Sandbox et la progression normale.
- Si une tâche dépend d’un point **OUVERT**, signale-le et évite de trancher sans nécessité.
- Mets à jour la documentation de référence lorsqu’une décision ou une interface change.
- Fais un commit à chaque étape cohérente qui mérite d’être conservée, avec un message explicite.
- Pousse chaque commit sur la remote `origin`.
- Évite une grosse batterie de tests après chaque petite implémentation ; lance les vérifications adaptées aux changements, et la suite plus complète à chaque avancée majeure.
