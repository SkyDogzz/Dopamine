# Sources visuelles générées par code

Les fichiers Aseprite de ce dossier sont les exports éditables de formes pixel dessinées par `game/tools/generate_original_visuals.gd`. Le générateur n’ouvre ni ne dérive aucune image de référence externe. Il lit le registre uniquement pour sélectionner les chemins d’assets à reconstruire.

Pour reproduire les 58 assets concernés depuis la racine du dépôt :

```sh
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tools/generate_original_visuals.gd
```

Ces sources établissent une chaîne de création locale vérifiable. La revue visuelle de release reste nécessaire pour confirmer lisibilité et cohérence avec l’Art Bible.
