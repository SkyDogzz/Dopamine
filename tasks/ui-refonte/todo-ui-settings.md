# Tâches — `ui-settings`

Plan associé : [`plan-ui-settings.md`](plan-ui-settings.md) · Spec : [`SPEC-ui-settings.md`](SPEC-ui-settings.md)

**Statut : terminé.** Le service et le panneau Options sont intégrés; les tests matériels d’affichage/audio et d’entrée restent non vérifiés.

## Tâche 1 — Écrire les smokes de contrat (RED)

**Description :** écrire d’abord des smokes séparés pour le service de préférences et le panneau Options. Constater les échecs attendus tant que service/scène manquent.

**Critères d’acceptation :**

- [x] `settings_service_smoke.gd` vérifie l’instanciation isolée, les valeurs par défaut, la validation, l’application des réglages, la sauvegarde/relecture et le retour aux valeurs sûres pour une configuration invalide.
- [x] `ui_settings_smoke.gd` vérifie le thème partagé, les deux réglages, le focus initial et une demande de fermeture distincte de la reprise de run.
- [x] Les deux smokes ont d’abord échoué sur le service/la scène manquants avec des messages lisibles, pas à cause d’une erreur du runner.
- [x] Les tests utilisent des chemins de configuration et profils utilisateur temporaires; aucun fichier utilisateur réel ni `user://saves` n’est altéré.

**Vérification RED :**

```bash
XDG_DATA_HOME=/tmp/dopamine-ui-settings-red tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/settings_service_smoke.gd
XDG_DATA_HOME=/tmp/dopamine-ui-settings-red tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/ui_settings_smoke.gd
```

**Dépendances :** spec et plan approuvés.

**Fichiers prévus :** `game/tests/settings_service_smoke.gd`, `game/tests/ui_settings_smoke.gd`.

**Portée estimée :** petite, deux tests.

## Tâche 2 — Implémenter le service de préférences (GREEN)

**Description :** ajouter le seul propriétaire des deux préférences, le charger avant la scène principale et passer le smoke du service.

**Critères d’acceptation :**

- [x] `Settings` charge/enregistre deux préférences uniquement dans `user://settings.cfg` via `ConfigFile`; aucun chemin ni appel `SaveService`/progression n’est utilisé.
- [x] L’absence ou l’invalidité du fichier, un volume hors `[0,100]` ou un type invalide retombent sur fenêtre et volume 100 % **[PROPOSÉS]**.
- [x] Les setters bornent et appliquent les valeurs aux API natives `DisplayServer` et au bus `Master`; 0 % donne −80 dB fini; conversion `linear_to_db` et valeur de repli sont documentées comme **[PROPOSÉES]**.
- [x] Le changement est sauvegardé et rechargé dans un nouveau service; le test emploie son propre fichier temporaire.
- [x] Le smoke du service passe sous Godot headless et ne modifie aucun fichier sous `user://saves`.

**Vérification :**

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit
XDG_DATA_HOME=/tmp/dopamine-ui-settings-service tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/settings_service_smoke.gd
```

**Dépendances :** tâche 1.

**Fichiers prévus :** `game/scripts/settings_service.gd`, `game/scripts/settings_service.gd.uid`, `game/project.godot`, `game/tests/settings_service_smoke.gd`.

**Portée estimée :** moyenne, un service et son enregistrement.

## Checkpoint — Service

- [x] Le smoke a d’abord échoué sur les contrats manquants, puis passe après le service.
- [x] Les données sont limitées à deux préférences et restent hors de `user://saves`.
- [x] Les tests utilisent un profil utilisateur temporaire et ne remplacent pas les réglages personnels.

## Tâche 3 — Construire le panneau Options (GREEN)

**Description :** créer le panneau natif réutilisable, le connecter au singleton et faire passer son smoke sans y intégrer la navigation de l’accueil ou de Survival.

**Critères d’acceptation :**

- [x] La scène charge `dopamine_ui.tres` et n’affiche que plein écran, volume général et retour.
- [x] Les contrôles montrent leur état actuel, prennent le focus dans un ordre cohérent et mettent à jour `Settings` à chaque changement.
- [x] Le bouton Retour et `ui_cancel` émettent la même demande de fermeture; le panneau ne reprend et ne met en pause aucune simulation.
- [x] Le smoke vérifie le thème, les contrôles, le focus initial, la mise à jour des préférences, la demande de fermeture, les bindings A/B et les géométries des trois viewports.
- [x] Le smoke tourne avec un `XDG_DATA_HOME` temporaire; les préférences temporaires n’écrivent pas dans le profil utilisateur réel.

**Vérification :**

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit
XDG_DATA_HOME=/tmp/dopamine-ui-settings-panel tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/ui_settings_smoke.gd
```

**Dépendances :** tâches 1 et 2.

**Fichiers prévus :** `game/scenes/options_panel.tscn`, `game/scripts/options_panel.gd`, `game/scripts/options_panel.gd.uid`, `game/tests/ui_settings_smoke.gd`, `CMakeLists.txt` (enregistrement CTest et profils utilisateur temporaires).

**Portée estimée :** moyenne, scène et script natifs.

## Tâche 4 — Revue, documentation et checkpoint

**Description :** revoir le panneau aux trois tailles, exécuter les vérifications disponibles, documenter les limites réelles et préparer l’intégration dans les futurs écrans appelants.

**Critères d’acceptation :**

- [x] Import Godot, les deux smokes et les smokes de régression pertinents passent.
- [x] Le panneau est lancé fenêtré à 1280×800, 960×600 et 1600×900; aucune erreur de script et aucun débordement.
- [x] Le parcours physique souris/clavier/manette n’a pas été effectué; cette limite est consignée sans revendiquer une réussite matérielle.
- [x] Le plein écran sur écran réel et la sortie audio sur périphérique réel restent non vérifiés; les résultats headless sont distingués.
- [x] `docs/architecture/INTERFACES.md` décrit le contrat restreint de `Settings` et de `OptionsPanel`; `docs/qa/TESTS.md` ne rapporte que les vérifications exécutées.
- [x] Le checkpoint n’affirme pas le gel de simulation en pause : ce parcours d’intégration est vérifié lors de `survival-pause`.
- [x] Build et CTest ont été tentés mais les binaires sont absents; cette limite est consignée, pas traitée comme une réussite.

**Vérification :**

```bash
cmake --build build --parallel 4
ctest --test-dir build --output-on-failure
```

Lancer en fenêtre aux résolutions prévues depuis la spec du plan; rejouer les smokes après toute correction. Ne pas écrire de résultats d’intégration pause dans le checkpoint de ce module.

**Dépendances :** tâches 1–3.

**Fichiers prévus :** `docs/architecture/INTERFACES.md`, `docs/qa/TESTS.md`, jusqu’à cinq fichiers source/test déjà listés si des corrections sont nécessaires.

**Portée estimée :** moyenne, revue d’interface et checkpoint.

## Checkpoint — `ui-settings`

- [x] Les tâches 1–4 sont achevées; revue physique et tests matériels restent à exécuter en environnement équipé.
- [x] Import et smokes sont consignés; build/CTest indisponibles faute des exécutables.
- [x] Le contrat reste limité aux préférences système; l’isolation Sandbox/progression est conservée.
- [x] Les changements cohérents sont committés puis poussés sur `origin`.
- [x] L’utilisateur a validé le passage au plan `launch-navigation`.
