# Plan d’implémentation — `ui-foundation`

**Statut : approuvé par l’utilisateur.** Ce plan suit la spec approuvée [`SPEC-ui-foundation.md`](SPEC-ui-foundation.md). Il ne couvre pas les autres modules UI.

## Vue d’ensemble

Créer une ressource `Theme` Godot commune, puis une petite scène de prévisualisation qui prouve les états visuels et le focus sans modifier les interfaces de production qui seront refondues par leurs propres modules. La refonte est multi-module; cette première tranche livre seulement la fondation partagée.

## État du code observé

- `game/scripts/main.gd` construit aujourd’hui son propre `Theme` à l’exécution avec palette sombre, cyan, rose et ambre.
- Les scènes de Survival définissent plusieurs styles et tailles par overrides; certains scripts ajoutent des couleurs ou des `StyleBoxFlat` directement.
- Le projet configure un viewport logique 1280×800 et `canvas_items` avec aspect `expand`.
- Les scènes et scripts existants montrent l’usage de `Control`, `Container`, `focus_mode` et `grab_focus()`; aucun dossier `game/themes/` n’existe encore.

La palette présente dans `main.gd` sert de référence interne de départ. Ses valeurs restent **[PROPOSÉES]** pour le thème partagé jusqu’à la revue visuelle.

## Décisions d’architecture proposées

- Créer une ressource `Theme` native, chargée explicitement par les scènes consommatrices; ne pas introduire de plugin ni de système de composants génériques.
- Garder les contrôles Godot natifs. Le partage se fait d’abord par styles de Theme; un composant dédié ne sera ajouté que si plusieurs usages concrets le justifient.
- Ne pas appliquer la ressource globalement au projet pendant cette tranche. Les écrans de production seront migrés quand leurs modules respectifs les refondront, ce qui évite de changer le rendu des écrans hors de la tranche en cours.
- Ajouter une scène de prévisualisation isolée pour présenter texte, panneaux, bouton principal, états focus/désactivé et contrôles de formulaire à plusieurs tailles.
- Garder les actions d’interface Godot (`ui_accept`, navigation, `ui_cancel`) et les contrôles clavier/manette natifs; n’ajouter une action `InputMap` que si le parcours existant ne couvre pas l’usage après vérification.
- Reprendre la palette sombre/cyan/rose/ambre existante comme point de départ et régler les détails à partir de la revue sur écran réel.

## Séquence de travail proposée

1. Écrire d’abord un smoke qui formalise le contrat de la prévisualisation et constater son échec attendu faute de scène/thème.
2. Créer `game/themes/dopamine_ui.tres` avec couleurs sémantiques, styles de texte et surfaces de base, boutons couvrant leurs états et styles de champs/panneaux.
3. Créer une scène de prévisualisation simple, bâtie avec des conteneurs et contrôles natifs, attachant explicitement le thème partagé; faire passer le smoke.
4. Importer le projet, exécuter le smoke, puis examiner la scène à 1280×800, une taille plus petite et une plus grande; parcourir les contrôles au clavier et à la manette.
5. Ajuster contraste/espacement, mettre à jour la spec ou la QA si une décision d’interface change, puis créer le checkpoint.

## Dépendances

`ui-foundation` ne dépend d’aucun autre module. Tous les autres modules consommeront sa ressource de thème après ce checkpoint. Les smokes Survival et Sandbox demeurent des régressions pertinentes lorsque ces scènes migreront dans leurs propres modules.

## Découpage de tâches à détailler après approbation du plan

- Ressource de thème partagée : ressource et palette/states minimum.
- Prévisualisation et smoke : scène isolée, états illustrés et test headless.
- Revue visuelle et contrôles : tailles d’écran, focus clavier/manette, correction puis checkpoint.

Le détail des fichiers, critères par tâche et commandes exactes est inscrit dans [`todo-ui-foundation.md`](todo-ui-foundation.md).

## Vérification

Depuis la racine du dépôt, Godot 4.7.2 est disponible dans `tools/local/godot-4.7.2/` :

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/ui_foundation_smoke.gd
ctest --test-dir build --output-on-failure
```

La revue visuelle s’effectuera en lançant explicitement la scène de prévisualisation dans une fenêtre. Les parcours clavier et manette seront vérifiés séparément; le smoke headless ne les remplace pas.

Commande de revue à trois tailles, avec `--resolution` supporté par le binaire local :

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path game --scene res://scenes/ui_foundation_preview.tscn --windowed --resolution 1280x800
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path game --scene res://scenes/ui_foundation_preview.tscn --windowed --resolution 960x600
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path game --scene res://scenes/ui_foundation_preview.tscn --windowed --resolution 1600x900
```

## Risques et réponses

| Risque | Impact | Réponse prévue |
|---|---|---|
| Le thème global altère des interfaces dont le rendu est hors tranche. | Régression visuelle ou fonctionnelle. | Charger le thème uniquement dans la prévisualisation; migrer les écrans au fil de leurs modules. |
| Les couleurs néon ou les états de contrôle manquent de contraste. | Texte ou focus difficile à percevoir. | Comparer texte/surface et prévoir un contour de focus avec indicateur non chromatique; corriger à la revue visuelle. |
| Le parcours manette n’est pas identique sur toutes les scènes. | Menus difficiles à parcourir. | Tester un parcours avec vraie navigation UI et documenter toute limite des actions natives avant les modules consommateurs. |
| Le smoke ne peut pas prouver le rendu ou la présence d’une manette. | Confiance excessive dans les vérifications headless. | Séparer explicitement smoke headless et revue fenêtrée/manette dans la checklist. |

## Questions ouvertes

- Les dimensions précises de texte et espacements sont **[PROPOSÉES]** et seront présentées à la revue de la prévisualisation.
- Les options graphiques étendues restent **[VALIDÉES]** par l’ADR-011 à terme, mais leur écran d’options dépasse la portée confirmée de cette initiative, limitée au plein écran et au volume général.

## Point de validation

Les tâches détaillées sont dans [`todo-ui-foundation.md`](todo-ui-foundation.md). Après approbation de cette liste, implémenter chaque tranche avec ses vérifications et commits. Les specs et plans des autres modules attendent la fin du cycle de `ui-foundation`, selon l’ordre validé de la carte.
