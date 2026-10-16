# Spec : `ui-foundation`

**Statut : implémentée et livrée.** La spec a été validée dans la conversation; les critères automatisables sont vérifiés. Le parcours matériel souris/manette reste non vérifié faute de périphériques.

## Hypothèses

1. Le thème réutilise les contrôles natifs Godot `Control` et les assets déjà présents; aucune dépendance UI externe n’est nécessaire.
2. Le viewport logique reste à 1280×800 avec le stretch actuel (`canvas_items`, aspect `expand`). Les layouts doivent suivre la taille disponible sans redéfinir cette résolution.
3. En l’absence de maquettes externes, l’interface Sandbox actuelle sert de référence matérielle pour la palette pixel art néon; elle sera simplifiée et clarifiée, pas copiée telle quelle.
4. Ce module fournit les règles visuelles et de focus communes. Chaque module d’écran reste responsable de connecter ces règles à ses propres contrôles et comportements.

## Objectif

Donner à toutes les interfaces une base visuelle et d’interaction cohérente, réutilisable et lisible. Les joueurs doivent distinguer les actions principales, l’état de focus et les contrôles désactivés, et parcourir les contrôles au clavier ou à la manette.

## Stack technique

- Godot 4.7.2, GDScript et scènes `Control`, conformément à l’ADR-011 accepté.
- `InputMap` pour les actions de navigation UI; conserver l’abstraction d’actions existante.
- Thème et composants natifs Godot avant toute dépendance externe.
- Direction pixel art néon du GDD **[VALIDÉE]**; proportions, espacements et détails de thème restent **[PROPOSÉS]** jusqu’à revue visuelle.

## Critères d’acceptation

- [x] Un thème partagé fournit les couleurs, styles de texte, panneaux, boutons, champs et espacements nécessaires aux écrans de la carte.
- [x] Les styles distinguent au minimum les états normal, survol, pressé, focus et désactivé; le focus clavier/manette est visible sans dépendre uniquement de la couleur.
- [ ] Un parcours d’exemple utilisant les composants partagés se parcourt à la souris, au clavier et à la manette avec activation cohérente.
- [x] Les conteneurs et composants s’adaptent au viewport étendu; aucune géométrie d’écran complet ne repose uniquement sur des positions absolues.
- [x] Les textes secondaires restent lisibles sur les surfaces choisies et la hiérarchie visuelle donne priorité à l’action principale.
- [x] Les écrans existants peuvent adopter le thème sans devoir recopier des styles locaux divergents.
- [x] Aucun changement n’affecte la logique de simulation, les saves, les règles de progression ou l’isolation du Sandbox.

## Commandes

Depuis la racine du dépôt :

```bash
cmake --build build --parallel 4
godot --headless --editor --path game --quit
godot --path game
```

Vérification QA documentée pour les écrans interactifs, quand elle sera implémentée :

```bash
godot --headless --path game --script res://tests/ui_foundation_smoke.gd
ctest --test-dir build --output-on-failure
```

`ui_foundation_smoke.gd` est un test à ajouter seulement si la spec est approuvée. La revue visuelle et le parcours clavier/manette nécessitent aussi un lancement fenêtré; un lancement headless ne prouve pas le rendu.

## Structure du projet

- `game/scenes/` : scènes Godot et petits composants d’interface réutilisables.
- `game/scripts/` : logique GDScript associée aux scènes; nommage privé avec préfixe `_` suivant les scripts existants.
- `game/assets/` : assets visuels existants; pas de nouvel asset bitmap requis pour cette fondation.
- `game/tests/` : smokes Godot ciblés, dont le futur test de fondation UI si utile.
- `tasks/ui-refonte/` : specs et tâches propres à cette initiative, sans remplacer `tasks/plan.md` ni `tasks/todo.md` du goal principal.

Emplacement du thème partagé à définir au plan; privilégier une ressource Godot native dans `game/` et ne créer un composant dédié qu’en cas d’usage partagé réel.

## Conventions de code

GDScript typé, noms de fonctions et variables en `snake_case`, membres privés préfixés `_`, types explicites sur les références d’interface; suivre les scènes/scripts voisins et éviter les abstractions sans deuxième usage.

```gdscript
@onready var _start_button: Button = $Content/StartButton

func _ready() -> void:
	_start_button.grab_focus()
```

Les contrôles réutilisables restent composés de Nodes Godot natifs. Ne pas remplacer des boutons par des `Control` génériques cliquables.

## Stratégie de vérification

- Importer le projet sous Godot headless pour détecter les erreurs de ressource et de script.
- Ajouter un smoke ciblé seulement si une propriété de thème ou de focus peut être vérifiée de façon fiable sans fenêtre.
- Lancer le jeu fenêtré à 1280×800 et à une taille plus petite ainsi qu’une plus grande; vérifier débordement, lisibilité, redimensionnement et focus.
- Parcourir un écran représentatif uniquement à la souris, uniquement au clavier et uniquement à la manette; vérifier le focus visible et l’activation.
- Lors de l’intégration, lancer les tests pertinents après changement et la suite complète au checkpoint de la fondation.

## Limites

- **Toujours :** utiliser `Control` et `InputMap`; conserver les actions de mouvement existantes; réutiliser le thème/composants lorsqu’ils sont déjà suffisants; garder un focus visible; vérifier les changements de rendu.
- **Demander avant :** ajouter une dépendance UI, changer le viewport logique ou modifier un contrat de sauvegarde/progression.
- **Ne jamais :** donner au Sandbox un accès à `SaveService`; coder en dur des données de gameplay dans le thème; présenter des valeurs **[PROPOSÉES]** comme validées; ajouter des fonctions Succès/Bestiaire au nom de la cohérence UI.

## Hors périmètre

- Refonte des écrans eux-mêmes : accueil, hub, HUD, pause, coffre, résultat et Sandbox, spécifiés dans leurs modules respectifs.
- Options détaillées de remapping, réduction des flashs, taille UI et presets Low/Medium/High; l’ADR-011 les maintient comme décisions acceptées à terme, mais la portée confirmée de cette tranche d’Options est limitée au plein écran et au volume général.
- Wireframes détaillés, choix **[OUVERTS]** dans le GDD, qui ne sont pas nécessaires pour définir la fondation.

## Questions ouvertes

- Les contrastes exacts, espacements et tailles de texte seront-ils validés après une première maquette appliquée à un écran représentatif ? La proposition est de les revoir au checkpoint UI Foundation.

## Critères de réussite

Cette spec est satisfaite quand les critères d’acceptation sont vérifiés, que le thème est utilisable par les sept modules de la carte sans accès au système de progression depuis le Sandbox, et que la spec a été approuvée avant la planification.
