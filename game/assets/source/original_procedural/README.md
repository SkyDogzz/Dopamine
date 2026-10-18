# Sources visuelles générées par code

Les fichiers Aseprite de ce dossier sont les exports éditables de formes pixel dessinées par `game/tools/generate_original_visuals.gd`. Le générateur n’ouvre ni ne dérive aucune image de référence externe. Il lit le registre uniquement pour sélectionner les chemins d’assets à reconstruire.

Les prototypes `elite_sprinter`, `boss_pulse_warden`, `boss_dopamine_core`, `boss_mid_placeholder` et `boss_final_placeholder` emploient des formes génériques de rôle. Ils ne définissent aucune identité de boss; le biome demeure ouvert. Reproduction ciblée : `--role-prototypes-only` ou `--environment-only`.

Pour reproduire les assets concernés depuis la racine du dépôt :

```sh
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tools/generate_original_visuals.gd
```

Ces sources établissent une chaîne de création locale vérifiable. La revue visuelle de release reste nécessaire pour confirmer lisibilité et cohérence avec l’Art Bible.
