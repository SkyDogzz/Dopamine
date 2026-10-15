# ADR-009 — Sauvegardes et progression

**Statut : ACCEPTÉ** · **Date : 2026-10-15**

## Décisions

- JSON versionné + écriture atomique
- Plusieurs slots indépendants
- Migrations versionnées automatiques
- Fichier temporaire + backup + checksum
- Interface cloud prévue, implémentation différée

## Conséquences

Ces choix servent de contraintes aux interfaces, tests et étapes de livraison. Les paramètres numériques et bibliothèques non explicitement choisis restent à valider.
