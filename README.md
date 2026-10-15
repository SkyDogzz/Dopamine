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

## Développement Linux

Prérequis : Godot 4.7.2, CMake 3.21 ou supérieur, Git et un compilateur C++23. CMake récupère le commit verrouillé de `godot-cpp` lors de la configuration.

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel 4
godot --headless --editor --path game --quit
godot --path game
```

Le premier lancement de l’éditeur importe le projet et vérifie la GDExtension. Le dernier lancement ouvre le Sandbox développeur, sans sauvegarde.

Vérifications ciblées :

```bash
ctest --test-dir build --output-on-failure
godot --headless --path game --script res://tests/sandbox_smoke.gd
godot --headless --path game --script res://tests/sandbox_ui_smoke.gd
```
