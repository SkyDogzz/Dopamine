# Plan d’implémentation — `ui-settings`

**Statut : terminé.** Le service, le panneau et les intégrations prévues sont livrés; voir [`INTEGRATION-ui-refonte.md`](INTEGRATION-ui-refonte.md).

## Vue d’ensemble

Ajouter un petit service de préférences utilisateur chargé au démarrage et un panneau Options réutilisable qui le consomme. Les deux réglages sont immédiatement appliqués par les API Godot. Le panneau reste sans autorité sur les écrans appelants : il peut demander sa fermeture, mais ne reprend aucune simulation et n’accède à aucun service de progression.

## État du code observé

- Godot 4.7.2 et les contrôles UI natifs sont déjà utilisés; `game/themes/dopamine_ui.tres` fournit la base de style.
- `game/project.godot` démarre directement `game/scenes/main.tscn`, sans autoload configuré.
- `SaveService` écrit sous `user://saves` et représente les données de progression; il n’existe pas de service de préférences ni de réglage actuel de fenêtre/audio.
- L’architecture attribue à Godot les responsabilités d’interface, d’entrées et d’audio; le Sandbox ne reçoit pas de capacité d’écriture aux sauvegardes normales.
- La scène principale est actuellement le Sandbox développeur; le menu de lancement et la pause seront consommés par des modules ultérieurs.

## Décisions d’implémentation proposées

- Ajouter un autoload `Settings` de petite taille, responsable uniquement de lecture/écriture de deux valeurs dans `user://settings.cfg`, avec `ConfigFile`. Ne pas modifier `SaveService` ou son format JSON.
- Charger et valider les préférences lors de l’initialisation de l’autoload; appliquer le plein écran et le volume avant l’affichage de la scène principale. Si la configuration est absente/invalide ou si une valeur est hors limites, utiliser fenêtre et volume 100 % **[PROPOSÉ]**.
- Exposer seulement `fullscreen_enabled`, `master_volume_percent`, `set_fullscreen_enabled(bool)` et `set_master_volume_percent(float)`; borner les valeurs et sauvegarder après modification. Garder l’état persistant comme source affichée quand le panneau est ouvert.
- Utiliser `DisplayServer.window_set_mode()` avec `WINDOW_MODE_EXCLUSIVE_FULLSCREEN`/`WINDOW_MODE_WINDOWED`, et le bus `Master` via `AudioServer`. Convertir 0 % en plancher de silence fini, et les autres valeurs avec `linear_to_db(percent / 100)` **[PROPOSÉ]**. Ces détails restent ajustables si le comportement varie selon la plateforme.
- Créer `OptionsPanel` comme scène `Control` attachée au Theme, avec une case de plein écran, un slider de volume et un bouton Retour. Il émet `close_requested`; le propriétaire restaure son écran et son focus. Le panneau gère `ui_cancel` comme demande de fermeture, sans appeler de logique de run.
- Le panneau reçoit les changements du singleton et resynchronise ses contrôles à l’ouverture. Toute entrée via le menu de pause sera intégrée/testée dans le module `survival-pause`.
- Tests headless utilisent un chemin de configuration temporaire pour éviter les préférences utilisateur réelles; utiliser les serveurs Godot disponibles sous headless pour vérifier la valeur appliquée, sans prétendre vérifier un comportement physique de fenêtre ou de haut-parleurs.

## Séquence de travail proposée

1. Écrire un smoke de contrat RED pour la configuration isolée, les valeurs par défaut, les bornes, le panneau, ses deux réglages et sa demande de fermeture.
2. Implémenter le service de préférences et son chargement précoce; vérifier défauts, valeurs valides et invalides, persistance et application audio/affichage sous les serveurs disponibles.
3. Construire `OptionsPanel` avec le Theme partagé, les deux réglages, les valeurs d’état visibles, le focus initial et une sortie par bouton/`ui_cancel`; faire passer le smoke.
4. Importer le projet et exécuter les smokes ciblés. Examiner les trois tailles de viewport, la navigation focus, les erreurs de configuration et l’isolation des saves.
5. Mettre à jour les contrats d’interface et le journal QA, puis committer/pousser le checkpoint. Reporter le test d’intégration pause à `survival-pause`.

## Fichiers envisagés

- `game/scripts/settings_service.gd` et l’entrée correspondante dans `game/project.godot`.
- `game/scenes/options_panel.tscn` et `game/scripts/options_panel.gd`.
- `game/tests/ui_settings_smoke.gd`.
- `docs/architecture/INTERFACES.md`, `docs/qa/TESTS.md` et les fichiers de tâches dédiés à `tasks/ui-refonte/`.

Les tâches seront séparées pour limiter chaque tranche à environ cinq fichiers maximum, hors documentation de QA/contrat nécessaire au checkpoint.

## Dépendances

`ui-foundation` fournit le thème et les mappings A/B. `launch-navigation` hébergera le panneau depuis l’accueil; `survival-pause` l’hébergera ensuite sans reprendre la simulation. Cette tranche ne modifie pas encore ces scènes appelantes.

## Vérification

Vérifications ciblées prévues avec Godot 4.7.2 :

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/ui_settings_smoke.gd
```

Au checkpoint, lancer les smokes pertinents et `ctest --test-dir build --output-on-failure` si `ctest` est disponible. Lancer le panneau fenêtré aux résolutions 1280×800, 960×600 et 1600×900. Parcourir les contrôles par souris, clavier et manette physique si le matériel est disponible. L’intégration de pause et le gel de ses horloges restent un critère du module `survival-pause`.

## Risques et réponses

| Risque | Impact | Réponse prévue |
|---|---|---|
| Le singleton de préférences devient un second système de sauvegarde de progression. | Couplage Sandbox/progression et données dupliquées. | Limiter son contrat à deux préférences d’affichage/audio dans un fichier distinct; aucune référence à `SaveService`, aux profils ou aux runs. |
| Options appelée depuis la pause ferme aussi la pause ou reprend le combat. | La run et ses horloges avancent derrière l’écran. | Faire émettre une demande de fermeture par le panneau et laisser le propriétaire piloter les écrans; test d’intégration au module pause. |
| Les modes d’affichage ou périphériques audio ne sont pas disponibles en headless. | Test automatisé donnerait une fausse confiance ou échouerait sans diagnostic. | Distinguer persistance/contrat testés sous headless des essais d’affichage/audio réels; consigner les limites de plateforme. |

## Points ouverts

- Courbe de volume et valeur initiale : proposition `linear_to_db` et 100 %, à conserver comme valeurs **[PROPOSÉES]** tant qu’elles ne sont pas confirmées comme décisions de design.
- Comportement précis du plein écran selon plateforme : s’en tenir aux API natives Godot et documenter les plateformes effectivement testées.

## Point de validation

La liste détaillée exécutée est dans [`todo-ui-settings.md`](todo-ui-settings.md); le gate est levé et les résultats figurent dans [`INTEGRATION-ui-refonte.md`](INTEGRATION-ui-refonte.md).
