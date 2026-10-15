# ADR-005 — Rendu et animations

**Statut : ACCEPTÉ** · **Date : 2026-10-15**

## Décisions

- MultiMeshInstance2D pour ennemis simples
- Batching MultiMesh + shaders pour projectiles
- Animation shader / atlas indexé par instance
- Shaders 2D + glow limité + particules GPU
- Résolution logique pixel art fixe et upscale entier si possible

## Conséquences

Ces choix servent de contraintes aux interfaces, tests et étapes de livraison. Les paramètres numériques et bibliothèques non explicitement choisis restent à valider.
