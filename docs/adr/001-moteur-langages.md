# ADR-001 — Moteur et langages

**Statut : ACCEPTÉ** · **Date : 2026-10-15**

## Décisions

- Godot 4.7.2 stable, version verrouillée
- Godot + simulation C++ GDExtension hybride
- GDScript pour gameplay haut niveau ; C++ pour simulation
- C++23
- Monorepo Godot + C++ + configs + tests

## Conséquences

Ces choix servent de contraintes aux interfaces, tests et étapes de livraison. Les paramètres numériques et bibliothèques non explicitement choisis restent à valider.
