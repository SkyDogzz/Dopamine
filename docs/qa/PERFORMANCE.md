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

## Smoke rendu Godot sous Xvfb

Le test CTest `render_visual_smoke` ouvre la scène Sandbox en fenêtre 1280×800, alimente la simulation avec 500 ennemis et 2 000 projectiles, puis vérifie le contenu des batches MultiMesh et la couleur d’un pixel ennemi dans l’image rendue. La capture est écrite dans `/tmp/dopamine-render-visual-smoke.png`.

Pour lancer le même scénario dans une fenêtre interactive depuis un terminal graphique, puis la garder ouverte jusqu’à Échap :

```bash
godot --path game --script res://tests/render_visual_smoke.gd -- --stay-open
```

- Environnement : Godot 4.7.2, OpenGL Compatibility, Mesa 25.0.7 `llvmpipe` (rendu logiciel), Xvfb.
- Résultat : frame rendue et vérifiée visuellement ; CTest a terminé le smoke en 1,56 s lors du dernier run complet.
- Limite : cette exécution valide le chemin de rendu et la scène à pleine charge, mais son FPS logiciel n’est pas représentatif du GPU de référence et ne valide pas la cible 60 FPS.
