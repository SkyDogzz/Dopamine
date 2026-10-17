# Baseline de performance natif

Mesure initiale de `SimulationCore`, sans rendu Godot. Le programme exécute deux charges déterministes de 300 pas de 1/60 s : 500 ennemis immobiles et 2 000 projectiles sans impact, puis 2 000 impacts Wildfire par pas contre 500 ennemis regroupés. Les projectiles sont recréés hors de la fenêtre mesurée; le second cas comprend la construction d’événements d’impact et le budget de 500 cibles secondaires par pas. Les temps couvrent `SimulationCore::advance` uniquement.

## Reproduire

```bash
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release
cmake --build build-release --target simulation_benchmark --parallel 4
./build-release/simulation_benchmark
```

## Première mesure

- Environnement : Linux x86_64, AMD EPYC-Milan virtualisé (8 CPU visibles), GCC 14.2.0, build Release.
- Sans impact : moyenne 0,087 ms ; P50 0,088 ms ; P95 0,097 ms ; P99 0,116 ms ; maximum 0,130 ms.
- Rafale Wildfire dense : moyenne 7,556 ms ; P50 7,514 ms ; P95 8,348 ms ; P99 9,074 ms ; maximum 10,075 ms.
- La rafale la plus dense reste sous le budget de 16,67 ms pour la simulation seule sur cet hôte.

Ce résultat valide le setup et fournit un premier repère CPU. Il ne valide pas la cible globale 60 FPS sur GPU intégré : rendu, GDExtension, worker, steering actif et matériel de référence ne sont pas couverts.

## Rafale Debug et collisions de corps immobiles — 2026-10-17

Environnement : Linux x86_64, AMD EPYC-Milan virtualisé avec 8 CPU visibles, GCC 14.2.0, build Debug. Chaque mesure couvre 300 pas à 60 Hz et uniquement `SimulationCore::advance`. Le benchmark répète 2 000 impacts Wildfire concentrés sur 500 ennemis immobiles.

| Version / état | Répétition | Moyenne | P50 | P95 | P99 | Maximum |
|---|---:|---:|---:|---:|---:|---:|
| Référence `1304c27` | 1 | 72,714 ms | 72,018 ms | 77,872 ms | 89,301 ms | 95,438 ms |
| HEAD avant correctif | 1 | 120,418 ms | 119,236 ms | 131,622 ms | 145,149 ms | 158,744 ms |
| HEAD avant correctif | 2 | 120,390 ms | 119,086 ms | 127,609 ms | 133,293 ms | 151,222 ms |
| Après sortie anticipée | 1 | 73,042 ms | 72,426 ms | 79,297 ms | 90,406 ms | 98,179 ms |
| Après sortie anticipée | 2 | 73,770 ms | 72,823 ms | 82,531 ms | 89,430 ms | 94,767 ms |

Cause : `resolve_enemy_body_collisions` reconstruisait l’index spatial et parcourait les voisins même si aucun ennemi n’avait bougé. La méthode quitte maintenant avant ces opérations lorsque tous les ennemis sont immobiles. `simulation_core` et `simulation_worker` passent (2/2 CTest). Les moyennes de rafale reviennent près de la référence `1304c27`, avec une baisse de 39 % par rapport aux deux essais avant le correctif.

La rafale concentrée reste très au-dessus de 16,67 ms/frame. Elle regroupe toutes les cibles et tous les impacts au même point; elle est extrême et ne représente pas une vague Survival. Ce résultat ne valide pas la cible globale à 60 FPS sur iGPU; une charge représentative avec steering et rendu Godot reste requise.

## Limite de l’environnement de travail — 2026-10-17

L’environnement utilisé pour la reprise expose 8 vCPU AMD EPYC-Milan sous KVM, sans `DISPLAY` et sans `perf`. Il ne permet donc pas de profiler le rendu Godot sur le GPU iGPU de référence. Les essais Xvfb précédents utilisent `llvmpipe` et ne remplacent pas cette mesure. Le profilage représentatif CPU/GPU doit être exécuté sur la machine de référence; ne pas extrapoler les chiffres du CPU virtualisé à cette cible.

Recontrôle lors de la reprise du goal : `/dev/dri/card0` et `renderD128` sont présents, mais `lspci` identifie uniquement un adaptateur Virtio 1.0 (`1af4:1050`) sous KVM. Aucun accès à l’identité ou aux compteurs du GPU hôte n’est exposé; ni `DISPLAY`, ni `perf`, `nvidia-smi`, `radeontop` ou `intel_gpu_top` ne sont disponibles. La présence de ces nœuds DRM ne constitue donc pas une mesure de l’iGPU cible. Le profilage GPU de référence reste **[OUVERT]**.

## Comparaison contrôlée des dix armes — 2026-10-17

Le survey `game/tests/combat_weapon_balance_survey.gd` exécute les dix armes via `SurvivalSession`, seules, dans une session sans service de progression ni écriture de sauvegarde. Chaque scénario dure 18 s simulées et utilise 24 cibles immobiles à 58 ou 112 unités du joueur, avec 1 000 000 HP chacune. Le joueur reste immobile et invulnérable; aucun spawn, XP, coffre, bonus permanent ou équipement n’intervient. La simulation et l’horloge Godot sont accélérées à ×4. Pour chaque arme, le script relève le niveau 1 sans relique, le niveau 5 avec sa relique niveau 5 sans collecter l’évolution, puis le même build avec l’évolution collectée. La mesure de sortie est le dommage attribué à l’arme divisé par le temps actif; les dégâts de statut et effets de zone observés par le chemin standard de session sont inclus.

Commande de reproduction complète (30 scénarios; le timeout supérieur est requis par le wrapper) :

```bash
DOPAMINE_TEST_TIMEOUT=300s tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 \
  --headless --path game --script res://tests/combat_weapon_balance_survey.gd
```

Pour un seul prototype, ajouter `-- --weapon=lightning_conductor` (ID remplaçable par l’un des dix IDs du catalogue). Résultats observés, en dégâts/s :

| Arme | Niveau 1 | Niveau 5 + relique 5 | Évoluée |
|---|---:|---:|---:|
| Lightning Conductor | 40,77 | 115,27 | 182,29 |
| Inferno Sprayer | 11,10 | 16,51 | 190,16 |
| Crimson Daggers | 122,83 | 298,96 | 538,71 |
| Minigun | 19,27 | 43,46 | 54,32 |
| Toxic Cloud | 16,99 | 24,86 | 31,83 |
| Sawblades | 8,89 | 19,93 | 33,27 |
| Meteor Staff | 58,09 | 110,11 | 142,75 |
| Prism Laser | 18,12 | 27,18 | 78,78 |
| Void Orb | 15,14 | 44,26 | 83,56 |
| Frost Nova | 46,09 | 95,31 | 118,62 |

Le cas groupé favorise particulièrement les attaques capables de toucher plusieurs cibles; l’évolution d’Inferno en est un signal net. Ces valeurs décrivent ce scénario synthétique, ne comparent pas des armes dans des runs représentatives et ne valident aucun chiffre proposé. Elles ne justifient pas seules un changement de tuning. Les champs `loop_interval_*` imprimés par le script sont l’espacement mural entre reprises de `process_frame` en headless, pas du temps CPU de frame ni un profil GPU. La calibration comparative en runs représentatives et le profilage CPU/GPU sur matériel de référence restent **[OUVERTS]**.

## Smoke rendu Godot sous Xvfb

Le test CTest `render_visual_smoke` ouvre la scène Sandbox en fenêtre 1280×800, alimente la simulation avec 500 ennemis et 2 000 projectiles, puis vérifie le contenu des batches MultiMesh et la couleur d’un pixel ennemi dans l’image rendue. La capture est écrite dans `/tmp/dopamine-render-visual-smoke.png`.

Pour lancer le même scénario dans une fenêtre interactive depuis un terminal graphique, puis la garder ouverte jusqu’à Échap :

```bash
godot --path game --script res://tests/render_visual_smoke.gd -- --stay-open
```

- Environnement : Godot 4.7.2, OpenGL Compatibility, Mesa 25.0.7 `llvmpipe` (rendu logiciel), Xvfb.
- Résultat : frame rendue et vérifiée visuellement ; CTest a terminé le smoke en 1,56 s lors du dernier run complet.
- Limite : cette exécution valide le chemin de rendu et la scène à pleine charge, mais son FPS logiciel n’est pas représentatif du GPU de référence et ne valide pas la cible 60 FPS.
