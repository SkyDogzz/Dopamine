# ADR-014 — Sandbox-first development

**Statut : ACCEPTÉ** · **Date : 2026-10-15**

## Décisions

- Construire un Sandbox développeur MVP juste après les fondations, avant Survival complet
- Tous les systèmes de combat doivent être testables isolément
- Sandbox développeur et Sandbox joueur partagent le même cœur de simulation
- Sandbox développeur : spawn, pause, step, vitesse, inspecteur, métriques, logs
- Sandbox joueur : interface accessible et isolation stricte de la progression normale

**Portée :** l’orientation Sandbox-first est retenue ; le périmètre précis de chaque phase reste ajustable.

## Conséquences

Ces choix servent de contraintes aux interfaces, tests et étapes de livraison. Les paramètres numériques et bibliothèques non explicitement choisis restent à valider.
