# Tâches — `ui-settings`

Plan associé : [`plan-ui-settings.md`](plan-ui-settings.md) · Spec : [`SPEC-ui-settings.md`](SPEC-ui-settings.md)

**Statut : proposition à valider.** Aucun code ne commence avant validation de cette liste.

## Tâche 1 — Écrire les smokes de contrat (RED)

**Description :** écrire d’abord des smokes séparés pour le service de préférences et le panneau Options. Constater les échecs attendus tant que service/scène manquent.

**Critères d’acceptation :**

- [ ] `settings_service_smoke.gd` vérifie l’instanciation isolée, les valeurs par défaut, la validation, l’application des réglages, la sauvegarde/relecture et le retour aux valeurs sûres pour une configuration invalide.
- [ ] `ui_settings_smoke.gd` vérifie le thème partagé, les deux réglages, le focus initial et une demande de fermeture distincte de la reprise de run.
- [ ] Les deux smokes échouent sur les contrats manquants avec des messages lisibles, pas à cause d’une erreur du runner.
- [ ] Le test de service utilise un chemin de configuration temporaire; aucun fichier utilisateur réel ni `user://saves` n’est altéré.

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

- [ ] `Settings` charge/enregistre deux préférences uniquement dans `user://settings.cfg` via `ConfigFile`; aucun chemin ni appel `SaveService`/progression n’est utilisé.
- [ ] L’absence ou l’invalidité du fichier, un volume hors `[0,100]` ou un type invalide retombent sur fenêtre et volume 100 % **[PROPOSÉS]**.
- [ ] Les setters bornent et appliquent les valeurs aux API natives `DisplayServer` et au bus `Master`; 0 % donne un niveau fini de silence; conversion `linear_to_db` et valeur de repli sont documentées comme **[PROPOSÉES]**.
- [ ] Le changement est sauvegardé et rechargé dans un nouveau service; le test emploie son propre fichier temporaire.
- [ ] Le smoke du service passe sous Godot headless et ne modifie aucun fichier sous `user://saves`.

**Vérification :**

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit
XDG_DATA_HOME=/tmp/dopamine-ui-settings-service tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/settings_service_smoke.gd
```

**Dépendances :** tâche 1.

**Fichiers prévus :** `game/scripts/settings_service.gd`, `game/scripts/settings_service.gd.uid`, `game/project.godot`, `game/tests/settings_service_smoke.gd`.

**Portée estimée :** moyenne, un service et son enregistrement.

## Checkpoint — Service

- [ ] Le smoke a d’abord échoué sur les contrats manquants, puis passe après le service.
- [ ] Les données sont limitées à deux préférences et restent hors de `user://saves`.
- [ ] Les tests utilisent un profil utilisateur temporaire et ne remplacent pas les réglages personnels.

## Tâche 3 — Construire le panneau Options (GREEN)

**Description :** créer le panneau natif réutilisable, le connecter au singleton et faire passer son smoke sans y intégrer la navigation de l’accueil ou de Survival.

**Critères d’acceptation :**

- [ ] La scène charge `dopamine_ui.tres` et n’affiche que plein écran, volume général et retour.
- [ ] Les contrôles montrent leur état actuel, prennent le focus dans un ordre cohérent et mettent à jour `Settings` à chaque changement.
- [ ] Le bouton Retour et `ui_cancel` émettent la même demande de fermeture; le panneau ne reprend et ne met en pause aucune simulation.
- [ ] Le smoke vérifie le thème, les contrôles, le focus initial, la mise à jour des préférences, la demande de fermeture et les bindings A/B déclarés dans `InputMap`.
- [ ] Le smoke tourne avec un `XDG_DATA_HOME` temporaire et restaure les états globaux modifiés, sans écrire dans le profil utilisateur réel.

**Vérification :**

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit
XDG_DATA_HOME=/tmp/dopamine-ui-settings-panel tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/ui_settings_smoke.gd
```

**Dépendances :** tâches 1 et 2.

**Fichiers prévus :** `game/scenes/options_panel.tscn`, `game/scripts/options_panel.gd`, `game/scripts/options_panel.gd.uid`, `game/tests/ui_settings_smoke.gd`.

**Portée estimée :** moyenne, scène et script natifs.

## Tâche 4 — Revue, documentation et checkpoint

**Description :** revoir le panneau aux trois tailles, exécuter les vérifications disponibles, documenter les limites réelles et préparer l’intégration dans les futurs écrans appelants.

**Critères d’acceptation :**

- [ ] Import Godot, les deux smokes et les smokes de régression pertinents passent.
- [ ] Le panneau est lancé fenêtré à 1280×800, 960×600 et 1600×900; aucune erreur de script et aucun débordement.
- [ ] Les deux contrôles sont parcourus à la souris, au clavier et à la manette physique lorsque le matériel est disponible; limites matérielles consignées sans les marquer réussies.
- [ ] Le plein écran réel et la sortie audio sont vérifiés sur le matériel disponible; les résultats headless sont explicitement séparés de ces vérifications physiques.
- [ ] `docs/architecture/INTERFACES.md` décrit le contrat restreint de `Settings` et de `OptionsPanel`; `docs/qa/TESTS.md` ne rapporte que les vérifications exécutées.
- [ ] Le checkpoint n’affirme pas le gel de simulation en pause : ce parcours d’intégration est vérifié lors de `survival-pause`.
- [ ] Build et CTest sont exécutés si les binaires sont disponibles; leur indisponibilité est consignée au lieu d’être traitée comme une réussite.

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

- [ ] Les tâches 1–4 satisfont les critères vérifiables de la spec; limites matérielles et critères reportés sont indiqués.
- [ ] Import, smokes et build/CTest disponibles ont des résultats datés et consignés.
- [ ] Le contrat reste limité aux préférences système; l’isolation Sandbox/progression est conservée.
- [ ] Les changements cohérents sont committés puis poussés sur `origin`.
- [ ] Revue utilisateur avant de rédiger le plan `launch-navigation`.
