# Dopamine Survivor — Documentation de référence

**Édition : 2026-10-15.** Documentation du projet Godot 4.7.2 / C++23, architecture Sandbox-first.

## Ordre de lecture

1. [GDD complet v1.6](docs/gdd/GDD_v1.6.md) — règles de jeu et décisions de design.
2. [Archives et historique des GDD](docs/gdd/archive/README.md) — sources v1.0–v1.6 et fiabilité des reconstitutions.
3. [Architecture technique](docs/architecture/ARCHITECTURE.md) — frontières des systèmes, threading, ECS, rendu.
4. [Interfaces](docs/architecture/INTERFACES.md) — contrats entre Godot et la simulation.
5. [Dépendances et dépôt](docs/architecture/DEPENDANCES_ET_DEPOT.md).
6. [Registre ADR](docs/adr/README.md) — décisions techniques acceptées, y compris Sandbox-first.
7. [Roadmap GDD v1.6](docs/planning/ROADMAP.md).
8. [Risques](docs/planning/RISQUES.md) et [tests d'acceptation](docs/qa/TESTS.md).
9. [Intention de refonte UI](docs/planning/INTENTION_REFONTE_UI.md) et [carte des capacités UI](UI_CAPABILITY_MAP.md) — périmètre confirmé par interview; specs et avancement par module dans `tasks/ui-refonte/`.
10. [Art Bible](docs/ART_BIBLE.txt) — direction visuelle validée, palette maître, résolution logique et contrats des assets/UI.

## Statuts

- **ACCEPTÉ** : choix explicitement confirmé par le créateur.
- **PROPOSÉ** : recommandation technique, non encore validée.
- **OUVERT** : arbitrage à faire ou benchmark nécessaire.

**Attention :** le chapitre architecture du GDD v1.6 précède les 60 décisions techniques récentes. En cas de conflit, les ADR acceptés et `ARCHITECTURE.md` prévalent. Le mode Endless standard contient toujours des choix provisoires. Les chiffres d'équilibrage indiqués comme proposés ne sont pas définitifs.

## Développement Linux

Prérequis : Godot 4.7.2, CMake 3.21 ou supérieur, Git et un compilateur C++23. CMake récupère le commit verrouillé de `godot-cpp` lors de la configuration.

Le commit `godot-cpp` est épinglé par SHA. La récupération CMake n’utilise pas de clone superficiel, car [`GIT_SHALLOW` ne prend en charge que des noms de branches ou de tags](https://cmake.org/cmake/help/v3.21/module/ExternalProject.html#git-tag) avec `GIT_TAG`.

Si une récupération FetchContent échoue, supprimez le dossier `build` incomplet avant de reconfigurer pour éliminer son clone partiel : `rm -rf build`, puis reprenez les commandes ci-dessous.

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel 4
godot --headless --editor --path game --quit
godot --path game
```

Le premier lancement de l’éditeur importe le projet et vérifie la GDExtension. Le dernier lancement ouvre l’accueil. Le Sandbox développeur reste accessible par son entrée secondaire et fonctionne sans sauvegarde.
La fenêtre initiale reste en 1280×800 afin que toutes les interfaces existantes conservent leur mise en page. Le passage au viewport logique 640×360 de l’Art Bible attend l’adaptation responsive de chaque écran.
Depuis l’accueil, `JOUER` ouvre le hub de préparation et lance une run Survival avec la difficulté choisie. Le bouton `PLAY SURVIVAL` du Sandbox développeur ouvre toujours le prototype et son choix d’arme initial, sans `SaveService` ni progression normale; `ACCUEIL` revient au menu.
Le hub propose aussi `RUN TEMPORAIRE · SANS SAUVEGARDE` : cette partie démarre avec un profil vide en mémoire, en difficulté Easy, et ses récompenses de fin sont abandonnées sans modifier la sauvegarde normale.

Vérifications ciblées :

```bash
ctest --test-dir build --output-on-failure
godot --headless --path game --script res://tests/sandbox_smoke.gd
godot --headless --path game --script res://tests/sandbox_ui_smoke.gd
godot --headless --path game --script res://tests/combat_catalog_smoke.gd
```

Pour lancer un combat Sandbox automatisé dans une fenêtre et garder le résultat (impact, mort et logs) à l’écran jusqu’à Échap :

```bash
godot --path game --script res://tests/sandbox_combat_smoke.gd -- --stay-open
```

Pour parcourir une run Survival de validation avec ses 24 vagues de 30 secondes, à vitesse ×4, dans une fenêtre :

```bash
godot --path game --script res://tests/survival_wave_director_smoke.gd -- --production-duration --stay-open
```

Le test simule les ennemis et les transitions de boss, puis attend Échap après l’écran de victoire. Il augmente les HP du joueur pour isoler la durée et les transitions ; ce n’est pas un test d’équilibrage.

Scénario headless avec export JSON des métriques (l’option `--output` peut aussi viser `user://sandbox/logs/...`) :

```bash
godot --headless --path game --script res://scripts/scenario_runner.gd -- \
  --scenario=res://scenarios/dev_sandbox.json --output=/tmp/dopamine-scenario.json
```

Si Godot est trouvé lors de la configuration CMake, `ctest` lance aussi l’import du projet, les deux smoke tests et ce scénario. Le runner et l’extension n’ont aucun accès au service de sauvegarde.
