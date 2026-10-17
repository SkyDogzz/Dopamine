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
10. [Art Bible](docs/ART_BIBLE.txt) — direction visuelle validée, palette maître, résolution logique et contrats des assets/UI; [inventaire assets + UI](docs/art/INVENTAIRE_ASSETS_UI.md) — portée confirmée et couverture actuelle, avec le [registre de provenance des visuels](docs/art/PROVENANCE_ASSETS.csv) pour le gate P9.8.
11. [Goal principal de livraison complète](docs/planning/GOAL_PRINCIPAL.md) — objectif actif et reprise à partir de P5.
12. [Registre des décisions restantes](docs/planning/DECISIONS_RESTANTES.md) — questions à interviewer une par une, choix proposés et validations techniques à distinguer.
13. [Notices des dépendances et polices](THIRD_PARTY_NOTICES.md) — licences repérées et points de conformité à intégrer au paquet de livraison.
14. [Checklist de livraison](docs/release/RELEASE_CHECKLIST.md) — preuves disponibles et critères encore ouverts pour P9.8.
15. [Registre des courbes de progression](docs/planning/COURBES_PROGRESSION.md) — formules centralisées, statuts de validation et références code/GDD.

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
Le jeu utilise un viewport logique 640×360 et une fenêtre initiale 1280×720.
Depuis l’accueil, `JOUER` ouvre le hub de préparation et lance une run Survival avec la difficulté choisie. Le bouton `PLAY SURVIVAL` du Sandbox développeur ouvre toujours le prototype et son choix d’arme initial, sans `SaveService` ni progression normale; `ACCUEIL` revient au menu.
En Survival, le HUD garde un aperçu des statistiques à gauche; Tab ouvre leur détail sans interrompre la run, et Échap le ferme avant d'ouvrir la pause. Le menu de pause propose une vitesse de run de ×0,25 à ×4, le verrouillage des dégâts et la sélection automatique de la première option des coffres. La simulation de combat et le temps Godot suivent ce multiplicateur; le jeu revient à ×1 à la sortie de la run.
Le hub propose aussi `RUN TEMPORAIRE · SANS SAUVEGARDE` : cette partie démarre avec un profil vide en mémoire, en difficulté Easy, et ses récompenses de fin sont abandonnées sans modifier la sauvegarde normale.

Le preset `Linux/X11` permet d’exporter les données du projet en PCK avec `godot --headless --path game --export-pack "Linux/X11" ../build/linux/DopamineSurvivor.pck`. Ce PCK n’est pas un exécutable autonome. Pour compiler l’extension native release dans un répertoire distinct du build Debug, utilisez `cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DGODOTCPP_TARGET=template_release`, puis `cmake --build build/linux-release --parallel 4`. Avec les templates Linux 4.7.2 installés, l’export autonome `Linux/X11` a été produit; le parcours clavier sous Xvfb démarre une run Survival et charge la GDExtension release. Le rendu sur matériel réel, les contrôleurs physiques et une installation vierge restent à vérifier (voir `docs/qa/TESTS.md`).

Pour refaire le paquet de validation staging depuis le commit `HEAD` (build CMake Release vierge, export Linux filtré, notices, archive et smoke après extraction), avec Godot 4.7.2 et ses templates Linux installés :

```bash
GODOT_EXECUTABLE=tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 \
  tools/package_linux_staging.sh
```

Le script archive le commit, donc les changements non commités ne sont pas inclus. Il écrit une archive et son SHA-256 sous `build/linux/staging/`. Le paquet est un staging non versionné, pas une release ni un artefact à distribuer.

## Lancer sous Windows

Prérequis : Godot 4.7.2 standard pour Windows x86_64 avec son exécutable console (`Godot_v4.7.2-stable_win64_console.exe`) et ses export templates 4.7.2, Visual Studio 2022 avec la charge de travail **Desktop development with C++**, CMake 3.21+ et Git dans le `PATH`. Depuis PowerShell à la racine du dépôt :

```powershell
.\tools\build_windows.ps1 -GodotExecutable "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" -Export
```

Le script configure le build MSVC x64, compile les GDExtensions debug et release dans `game/bin/windows`, importe le projet et exécute un smoke qui instancie la simulation native. Avec `-Export` et les export templates 4.7.2 installés, il crée `build/windows/export/DopamineSurvivor.exe` puis lance le jeu exporté. Le preset Windows exclut `tests/`, `tools/` et `assets/source/` du paquet runtime, comme Linux. Sans `-Export`, il ouvre le projet dans Godot. Pour seulement compiler et vérifier, ajouter `-NoLaunch`. Si CMake signale un arbre Git `godot-cpp` incomplet (« unable to read tree »), le script supprime uniquement le clone FetchContent généré et retente la configuration. Le workflow [GitHub Actions Windows](.github/workflows/build-windows.yml) installe les templates, compile, exporte, ajoute un README de validation et les notices/licences référencées, archive et extrait le jeu dans un dossier temporaire, puis démarre l’exécutable extrait et publie l’artefact `dopamine-survivor-windows-x86_64`. Cet artefact reste non versionné et n’est pas la release `1.0.0`. Le parcours de build/export/extraction a réussi sur `windows-2022` au run [`39070143031`](https://github.com/SkyDogzz/Dopamine/actions/runs/39070143031); validation interactive sur matériel Windows reste à faire. Le build Debug et la run Windows du créateur sont aussi consignés dans [`docs/qa/TESTS.md`](docs/qa/TESTS.md).

Pour profiler une run Windows et écrire directement un CSV prêt à examiner ou committer :

```powershell
.\tools\profile_windows.ps1 -GodotExecutable "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

Le script compile l’extension Debug et les exécutables de test, exécute **tous les tests CTest enregistrés** séquentiellement, puis lance pour la capture la copie importée du projet validée par CTest. Les tests tournent dans `build/windows/profiling-test-workspace/game`, avec `docs/` placé à côté pour les contrôles qui lisent les références du dépôt. Chaque test Godot reçoit son propre dossier `APPDATA` temporaire sous `build/windows/test_appdata`, ensuite supprimé; les tests ne touchent donc pas au profil normal ni aux données d’un autre test. La copie du jeu reste dans le dossier `build/` ignoré par Git et son profil Godot unique est supprimé à la fermeture, ce qui permet de relancer CTest manuellement. Le script s’arrête si un test échoue. Il écrit ensuite `docs/qa/data/windows_survival_profile.csv`. Joue idéalement une **run temporaire sans sauvegarde**, en difficulté Normal et vitesse ×1; ferme le jeu quand tu as assez de combat mesuré. Le fichier est écrasé au prochain lancement. Il contient une ligne par seconde avec les temps de frame et de physique (moyenne, P95, maximum), FPS, compteurs de rendu, mémoire vidéo estimée, identité CPU/GPU, résolution et contexte Survival (vague, ennemis, projectiles, pause). La capture continue pendant les menus de pause et les choix; évite de les inclure dans la portion de combat que tu veux comparer. Ce CSV est du profilage de diagnostic : il ne mesure pas le temps GPU par frame et ne remplace pas le Visual Profiler Godot pour attribuer précisément le coût de rendu.

Vérifications ciblées :

```bash
ctest --test-dir build --output-on-failure
tools/run_godot_test.sh godot --headless --path game --script res://tests/sandbox_smoke.gd
tools/run_godot_test.sh godot --headless --path game --script res://tests/sandbox_ui_smoke.gd
tools/run_godot_test.sh godot --headless --path game --script res://tests/combat_catalog_smoke.gd
tools/run_godot_test.sh godot --headless --path game --script res://tests/survival_targeting_smoke.gd
```

Le wrapper arrête les tests qui dépassent 120 secondes (SIGTERM, puis SIGKILL après 5 secondes). Changez la limite avec `DOPAMINE_TEST_TIMEOUT=300s`, ou utilisez `DOPAMINE_TEST_TIMEOUT=0` pour la désactiver explicitement. `--stay-open` désactive automatiquement la limite, car ces smokes attendent une fermeture manuelle.

Pour lancer un combat Sandbox automatisé dans une fenêtre et garder le résultat (impact, mort et logs) à l’écran jusqu’à Échap :

```bash
tools/run_godot_test.sh godot --path game --script res://tests/sandbox_combat_smoke.gd -- --stay-open
```

Pour parcourir une run Survival de validation avec ses 24 vagues de 30 secondes, à vitesse ×4, dans une fenêtre :

```bash
tools/run_godot_test.sh godot --path game --script res://tests/survival_wave_director_smoke.gd -- --production-duration --stay-open
```

Le test simule les ennemis et les transitions de boss, puis attend Échap après l’écran de victoire. Il augmente les HP du joueur pour isoler la durée et les transitions ; ce n’est pas un test d’équilibrage.

Scénario headless avec export JSON des métriques (l’option `--output` peut aussi viser `user://sandbox/logs/...`) :

```bash
tools/run_godot_test.sh godot --headless --path game --script res://scripts/scenario_runner.gd -- \
  --scenario=res://scenarios/dev_sandbox.json --output=/tmp/dopamine-scenario.json
```

Si Godot est trouvé lors de la configuration CMake, `ctest` lance aussi l’import du projet, les deux smoke tests et ce scénario. Le runner et l’extension n’ont aucun accès au service de sauvegarde.
