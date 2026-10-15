# ADR-004 — Communication Godot/C++

**Statut : ACCEPTÉ** · **Date : 2026-10-15**

## Décisions

- Snapshots compacts et file d’événements
- Commandes Godot vers simulation ; événements et snapshots simulation vers Godot
- Propriété exclusive de chaque état mutable (conséquence proposée)
- Interdiction d’accéder aux SceneTree/Nodes depuis le worker (garde-fou proposé)

## Conséquences

Ces choix servent de contraintes aux interfaces, tests et étapes de livraison. Les paramètres numériques et bibliothèques non explicitement choisis restent à valider.
