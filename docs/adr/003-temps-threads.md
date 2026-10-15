# ADR-003 — Temps et multithreading

**Statut : ACCEPTÉ** · **Date : 2026-10-15**

## Décisions

- Simulation à delta variable
- Simulation sur thread dédié ; rendu Godot sur thread principal
- Parallélisation progressive après profiling
- Pas d’objectif de déterminisme

## Conséquences

Ces choix servent de contraintes aux interfaces, tests et étapes de livraison. Les paramètres numériques et bibliothèques non explicitement choisis restent à valider.
