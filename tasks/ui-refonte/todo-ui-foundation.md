# Tâches — `ui-foundation`

Plan associé : [`plan-ui-foundation.md`](plan-ui-foundation.md) · Spec : [`SPEC-ui-foundation.md`](SPEC-ui-foundation.md)

## Tâche 1 — Écrire le smoke de contrat (RED)

**Description :** commencer par un smoke qui capture le contrat observable de la fondation, puis constater son échec avant la création de la scène et du thème.

**Critères d’acceptation :**

- [ ] Le smoke tente de charger la scène et vérifie l’existence du Theme et des contrôles principaux ainsi que le focus initial.
- [ ] Le smoke échoue sur l’état actuel car la scène de prévisualisation n’existe pas; l’échec est celui attendu et non une erreur du runner.
- [ ] Le smoke laisse une assertion lisible pour chaque contrat plutôt qu’un test désactivé ou un faux positif.

**Vérification RED :**

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/ui_foundation_smoke.gd
```

**Dépendances :** aucune.

**Fichiers prévus :** `game/tests/ui_foundation_smoke.gd`.

**Portée estimée :** petite, 1 fichier.

## Tâche 2 — Créer le thème partagé

**Description :** créer la ressource `Theme` native qui expose une palette sémantique pixel art néon et les styles d’interface communs nécessaires aux écrans futurs.

**Critères d’acceptation :**

- [ ] Les couleurs sémantiques de fond, surface, texte, texte secondaire, accent, alerte et bordure sont définies en un seul endroit.
- [ ] Les contrôles Label, Button, PanelContainer et champs (`LineEdit`, `OptionButton`, `SpinBox`) ont des styles de base cohérents; Button expose normal, hover, pressed, focus et disabled.
- [ ] Le style de focus est visible par contour ou forme et contraste, et ne dépend pas uniquement d’un changement de couleur.
- [ ] La palette existante sert de point de départ; aucun nombre de gameplay ou accès aux saves n’est introduit.

**Vérification :** importer le Theme sous Godot 4.7.2; l’échec RED de la tâche 1 reste attendu tant que la scène manque.

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit
```

**Dépendances :** tâche 1.

**Fichiers prévus :** `game/themes/dopamine_ui.tres`.

**Portée estimée :** petite, 1 fichier.

## Tâche 3 — Ajouter la prévisualisation et faire passer le smoke (GREEN)

**Description :** construire la scène isolée avec le thème partagé et faire passer le smoke de contrat.

**Critères d’acceptation :**

- [ ] La scène utilise des Containers pour son layout et charge explicitement `dopamine_ui.tres`.
- [ ] Elle montre une action primaire, une action secondaire, un contrôle désactivé, des titres/texte secondaire, un champ et une surface de panneau.
- [ ] Le premier contrôle interactif reçoit le focus à l’ouverture; les contrôles de la scène restent accessibles à la souris/clavier/manette.
- [ ] La scène peut être lancée seule sans initialiser `CombatSimulation`, `SaveService` ou `ProgressionService`.
- [ ] Le smoke RED passe et confirme le chargement du thème, les contrôles principaux et le focus initial; il ne prétend pas valider le rendu ou la présence physique d’une manette.

**Vérification :**

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/ui_foundation_smoke.gd
```

**Dépendances :** tâches 1 et 2.

**Fichiers prévus :** `game/scenes/ui_foundation_preview.tscn`, `game/scripts/ui_foundation_preview.gd`.

**Portée estimée :** moyenne, 2 fichiers.

## Checkpoint — Après les tâches 1–3

- [ ] Le test a d’abord échoué sur le contrat manquant, puis passe après l’implémentation.
- [ ] L’import Godot et le smoke ciblé passent.
- [ ] La scène reste isolée de la simulation et des services de progression.

## Tâche 4 — Revue visuelle, entrée et checkpoint

**Description :** corriger les problèmes révélés par les vérifications ciblées, enregistrer les résultats, puis lancer la suite plus complète au checkpoint de fondation.

**Critères d’acceptation :**

- [ ] La revue à 1280×800, 960×600 et 1600×900 confirme absence de débordement, lisibilité et ordre visuel cohérent.
- [ ] Les contrôles sont parcourus et activés à la souris, au clavier et à la manette; le focus reste visible et ne saute pas hors de la scène.
- [ ] Toute impossibilité matérielle de tester une vraie manette est consignée explicitement et n’est pas présentée comme une réussite.
- [ ] Les résultats réellement exécutés sont ajoutés à `docs/qa/TESTS.md`; les smokes historiques non rejoués ne sont pas re-déclarés comme verts.
- [ ] Le build existant et la suite CTest passent après les changements du checkpoint.

**Vérification :**

```bash
cmake --build build --parallel 4
ctest --test-dir build --output-on-failure
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path game --scene res://scenes/ui_foundation_preview.tscn --windowed --resolution 1280x800
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path game --scene res://scenes/ui_foundation_preview.tscn --windowed --resolution 960x600
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path game --scene res://scenes/ui_foundation_preview.tscn --windowed --resolution 1600x900
```

Répéter les trois commandes de lancement fenêtré après toute correction visuelle.

**Dépendances :** tâches 1, 2 et 3.

**Fichiers prévus :** jusqu’à cinq fichiers déjà créés/modifiés dans les tâches précédentes, plus `docs/qa/TESTS.md` si la revue est exécutée.

**Portée estimée :** moyenne, revue et documentation de checkpoint.

## Checkpoint — `ui-foundation`

- [ ] Les tâches 1–4 satisfont les critères de la spec.
- [ ] Import Godot, smoke, build et CTest ont des résultats consignés avec environnement/date.
- [ ] Le rendu et la navigation clavier/manette ont fait l’objet d’une revue; les limites matérielles éventuelles restent explicites.
- [ ] Les documents sont à jour et le checkpoint est committé puis poussé sur `origin`.
- [ ] Revue utilisateur avant de commencer le module `ui-settings`.
