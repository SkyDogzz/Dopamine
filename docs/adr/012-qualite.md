# ADR-012 — Tests et performances

**Statut : ACCEPTÉ** · **Date : 2026-10-15**

## Décisions

- GPU intégré milieu de gamme + 16 Go RAM comme référence
- 60 FPS avec 500 ennemis et 2 000 projectiles
- Godot profiler + Tracy C++ + compteurs custom
- Tests unitaires, intégration, headless et benchmarks
- GitHub Actions Windows + Linux

## Conséquences

Ces choix servent de contraintes aux interfaces, tests et étapes de livraison. Les paramètres numériques et bibliothèques non explicitement choisis restent à valider.
