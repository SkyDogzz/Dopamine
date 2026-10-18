# Sources Aseprite originales

Les fichiers Aseprite de ce dossier sont les sources éditables des PNG associés, générées par `game/tools/generate_neon_arcade_art.py`. Le générateur lit uniquement la palette maître de l’Art Bible et les rôles inscrits dans son code; il ne charge aucun asset raster préexistant, aucune référence visuelle ni aucune recette historique.

Pour reconstruire toutes les familles prises en charge :

```sh
python3 game/tools/generate_neon_arcade_art.py
```

Pour une famille ciblée, préciser `catalog`, `projectiles`, `vfx`, `environment`, `boss`, `ui` ou `roles`. Les prototypes de boss restent génériques et ne définissent pas leur identité canonique.
