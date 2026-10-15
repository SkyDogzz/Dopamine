# ADR-006 — Collisions et physique

**Statut : ACCEPTÉ** · **Date : 2026-10-15**

## Décisions

- Physique custom ECS, sans CharacterBody2D par ennemi
- Spatial hash uniforme
- Tests géométriques custom + spatial hash pour projectiles
- Steering simple + séparation locale
- Swept collision pour projectiles rapides

## Conséquences

Ces choix servent de contraintes aux interfaces, tests et étapes de livraison. Les paramètres numériques et bibliothèques non explicitement choisis restent à valider.
