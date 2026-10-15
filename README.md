# Dopamine Survivor — Documentation de référence

**Édition : 2026-10-15.** Documentation du projet Godot 4.7.2 / C++23, architecture Sandbox-first.

## Ordre de lecture

1. [GDD complet v1.5](docs/gdd/GDD_v1.5.md) — règles de jeu et décisions de design.
2. [Architecture technique](docs/architecture/ARCHITECTURE.md) — frontières des systèmes, threading, ECS, rendu.
3. [Interfaces](docs/architecture/INTERFACES.md) — contrats entre Godot et la simulation.
4. [Dépendances et dépôt](docs/architecture/DEPENDANCES_ET_DEPOT.md).
5. [Registre ADR](docs/adr/README.md) — décisions techniques acceptées, y compris Sandbox-first.
6. [Roadmap Sandbox-first](docs/planning/ROADMAP.md).
7. [Risques](docs/planning/RISQUES.md) et [tests d'acceptation](docs/qa/TESTS.md).

## Statuts

- **ACCEPTÉ** : choix explicitement confirmé par le créateur.
- **PROPOSÉ** : recommandation technique, non encore validée.
- **OUVERT** : arbitrage à faire ou benchmark nécessaire.

**Attention :** le chapitre architecture du GDD v1.5 précède les 60 décisions techniques récentes. En cas de conflit, les ADR acceptés et `ARCHITECTURE.md` prévalent. Le mode Endless standard contient toujours des choix provisoires. Les chiffres d'équilibrage indiqués comme proposés ne sont pas définitifs.
