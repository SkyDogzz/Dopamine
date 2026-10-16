# Dépendances et structure du dépôt

## Versions et politiques

| Composant | Choix | Statut |
|---|---|---|
| Godot | 4.7.2 stable verrouillée | ACCEPTÉ |
| Langages | GDScript + C++23 | ACCEPTÉ |
| GDExtension | godot-cpp `b8530af7546a3fcae80cef2477526569fd42ffc2`, API 4.7 | ACCEPTÉ — build et chargement Linux vérifiés avec Godot 4.7.2 |
| Build C++ | CMake | ACCEPTÉ — spike Linux P0 compilé |
| Compilateurs | MSVC Windows, Clang/GCC Linux compatibles C++23 | PROPOSÉ |
| Tests C++ | doctest ou Catch2 | OUVERT |
| JSON | JSON Schema + validation runtime | ACCEPTÉ |
| JSON C++ | nlohmann/json ou autre parseur validé | OUVERT |
| Profiling | Godot profiler + Tracy + compteurs custom | ACCEPTÉ |
| CI | GitHub Actions Windows + Linux | ACCEPTÉ — workflow Windows compile et exporte le jeu x86_64; Linux reste à ajouter |
| ECS externe | Aucun (ECS maison) | ACCEPTÉ |
| Steamworks | Couche d'intégration optionnelle tardive | PROPOSÉ |

Ne pas inventer une compatibilité GDExtension sans compilation/test réel. Verrouiller les commits et licences des dépendances.

La dépendance `godot-cpp` est récupérée par CMake via le commit SHA ci-dessus. Ne pas activer `GIT_SHALLOW` avec ce hash : CMake ne prend en charge cette option qu’avec des branches ou tags nommés ([documentation CMake 3.21](https://cmake.org/cmake/help/v3.21/module/ExternalProject.html#git-tag)). Après un échec FetchContent, supprimer le dossier de build incomplet avant de reconfigurer afin d’écarter le clone partiel.

## Arborescence cible

```text
dopamine-survivor/
├── game/
│   ├── project.godot
│   ├── scenes/{main,player,bosses,arenas,modes}/
│   ├── scripts/{core,combat,progression,equipment,achievements,sandbox,saves}/
│   ├── ui/{components,menus,hud,sandbox}/
│   ├── shaders/
│   ├── resources/
│   └── assets/
├── native/
│   ├── CMakeLists.txt
│   ├── include/dopamine/{api,ecs,simulation,combat,physics,telemetry}/
│   ├── src/{gdextension,ecs,simulation,combat,physics,telemetry}/
│   └── tests/
├── config/{balance,weapons,relics,enemies,equipment,achievements,difficulties,modes,schemas}/
├── tests/{integration,headless,performance,save_migrations,fixtures}/
├── tools/{balance_validator,simulation_runner,benchmark,content_generator}/
├── docs/{gdd,architecture,adr,planning,qa}/
├── scripts/
├── third_party/
└── .github/workflows/build-windows.yml
```

## Pipeline CI recommandé

1. Valider format et schémas JSON.
2. Compiler C++23 et GDExtension Windows/Linux (workflow Windows présent; workflow Linux à ajouter).
3. Exécuter tests ECS/physique/combat en C++.
4. Démarrer Godot en mode headless pour tests d'intégration.
5. Exécuter benchmark court non bloquant et comparer métriques à un baseline versionné.
6. Vérifier migrations de sauvegardes et absence d'écriture permanente par Sandbox.
7. Produire artefacts de build avec versions du jeu, save et config distinctes.
