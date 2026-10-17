# Tâches : `survival-pause`

Plan : [`plan-ui-survival-pause.md`](plan-ui-survival-pause.md) · Spec : [`SPEC-survival-pause.md`](SPEC-survival-pause.md)

**Statut : fonctionnel livré; première passe visuelle relue et poussée.** Les tâches 1 à 5 et l’ajustement typographique proposé sont terminés. Restent la validation physique manette et la revue visuelle dédiée aux tailles agrandies. Le plan principal reste en pause et inchangé.

## Tâche 1 — Pause manuelle et invariance temporelle

**Description :** Couvrir par un smoke le contrat Échap/Continuer, puis afficher/masquer le panneau Pause sous le contrôle de `survival_session.gd`.

**Critères d’acceptation :**
- [x] Échap ouvre Pause seulement depuis une run active; le focus commence sur Reprendre.
- [x] Échap ou Reprendre ferme Pause et reprend la même session.
- [x] Simulation, temps de run/vague et position du joueur ne changent pas durant plusieurs frames en pause.
- [x] Un choix initial ou coffre déjà au premier plan garde la priorité actuelle; aucun double toggle ou reprise accidentelle.
- [x] Le bouton natif Reprendre est focusable; sa navigation souris/clavier/manette reste native.

**Vérification :** `survival_pause_smoke.gd`, `survival_starting_weapon_smoke.gd`, `survival_chest_smoke.gd`, `survival_hud_smoke.gd` et `survival_wave_duration_smoke.gd` passent sous Godot 4.7.2 headless; import éditeur et `git diff --check` passent. Le résultat de run conserve son parcours existant et sera repris en intégration.

**Dépendances :** Spec et plan approuvés.

**Fichiers probables :** `survival_session.gd`, `survival_session.tscn`, scène/script Pause dédiés, `survival_pause_smoke.gd`.

**Portée estimée :** M.

## Tâche 2 — Options depuis Pause

**Description :** Ouvrir le `OptionsPanel` existant par-dessus la pause et restituer correctement la navigation à sa fermeture.

**Critères d’acceptation :**
- [x] Options s’ouvre par bouton depuis Pause et conserve Pause affichée sous le panneau.
- [x] Retour ou Échap ferme seulement Options et rend le focus à Options dans Pause.
- [x] Simulation et horloges restent immobiles pendant ouverture, attente, fermeture et attente.
- [x] Les réglages gardent les comportements et persistance du panneau partagé; aucune logique pause ne s’y ajoute.

**Vérification :** `survival_pause_smoke.gd` ouvre et ferme Options via Retour et Échap; vérifie focus, état pause, temps de simulation/activité et position joueur. Le smoke, l’import headless Godot 4.7.2 et `git diff --check` passent.

**Dépendances :** Tâche 1 et `ui-settings`.

**Fichiers probables :** session/scène Pause, scène Options existante, smoke pause.

**Portée estimée :** S.

## Tâche 3 — Inventaire de run en lecture seule

**Description :** Présenter uniquement le contenu runtime détenu par le loadout, ses définitions catalogue et son statut canonique d’évolution.

**Critères d’acceptation :**
- [x] Inventaire liste exactement les armes et reliques possédées, avec familles séparées et états vides si besoin.
- [x] Chaque item montre icône, nom, niveau et description issus des ressources/définitions canoniques.
- [x] Statut d’évolution affiché uniquement si l’arme est niveau 5 et sa relique associée est possédée, règle utilisée par les armes de la session.
- [x] Fermer l’inventaire revient à Pause et restaure son contrôle d’ouverture comme focus.
- [x] La vue ne propose aucune action qui modifie loadout, équipement permanent, compétences, save ou progression.

**Vérification :** `survival_pause_inventory_smoke.gd` vérifie l’affichage de deux armes et deux reliques déterministes, icônes, noms, descriptions, évolution active, fermeture et retour du focus. `survival_pause_smoke.gd`, `survival_loadout_smoke.gd`, `survival_starting_weapon_smoke.gd`, `survival_hud_smoke.gd`, l’import headless Godot 4.7.2 et `git diff --check` passent. La vue n’expose que des labels et icônes avec un bouton Retour, aucune mutation.

**Dépendances :** Tâche 1; le contrat de lecture canonique doit être choisi au plan de tâches sans copier de logique gameplay dans l’UI.

**Fichiers probables :** `survival_loadout.gd`, `combat_catalog.gd` seulement si projection read-only requise, panneau inventaire, smoke pause/catalogue.

**Portée estimée :** M.

## Tâche 4 — Abandon avec confirmation

**Description :** Ajouter une confirmation accessible, annulation sans effet et sortie définitive vers l’accueil sans récompense de complétion.

**Critères d’acceptation :**
- [x] Abandonner ouvre une confirmation et son focus initial est prévisible et sûr (Garder la run).
- [x] Annuler ferme la confirmation, garde la session suspendue et restaure le focus sur Abandonner.
- [x] Confirmer quitte vers `launch_menu.tscn` et la session n’est plus active.
- [x] Le chemin ne déclenche pas `_finish_run()`, victoire, octroi de récompense, récompense de défaite ou progression de profil.
- [x] Échap de la confirmation annule seulement celle-ci sans reprendre la run.

**Vérification :** `survival_abandon_smoke.gd` compare le profil avant/après avec confirmation et annulation, vérifie destination/focus et suppression de session. Passent aussi `survival_run_result_smoke.gd`, `survival_progression_smoke.gd`, les smokes pause et inventaire, l’import headless Godot 4.7.2 et `git diff --check`.

**Dépendances :** Tâche 1.

**Fichiers probables :** session, panneau confirmation ou panneau Pause, `survival_pause_smoke.gd`.

**Portée estimée :** S.

## Tâche 5 — Intégration, vérifications et checkpoint utilisateur

**Description :** Tester les couches ensemble, relire les frontières architecturales et committer/pousser la tranche achevée.

**Critères d’acceptation :**
- [x] Parcours pause → Options → pause et pause → inventaire → pause gardent session/horloges suspendues et focus cohérent.
- [x] L’abandon confirmé revient à l’accueil sans progression; l’annulation conserve la run.
- [x] Smokes Pause, Options, inventaire/loadout, armes départ, coffres, HUD, résultats, durée/vagues, entrée/hub et Sandbox pertinents passent.
- [x] Import headless Godot et `git diff --check` passent; Pause, inventaire et confirmation tiennent aux viewports 960×600, 1280×800 et 1600×900.
- [x] Les contrats de focus, boutons et clavier sont vérifiés; interaction physique à la manette indisponible et non revendiquée.
- [x] Le diff ne change pas l’équilibrage, les récompenses normales, la progression ni les dépendances Sandbox; `docs/qa/TESTS.md` consigne vérifications et limites.
- [x] Commits explicites poussés sur `origin`; pause du travail avant le module `sandbox-ui`.

**Vérification :** voir `docs/qa/TESTS.md`. `ctest`/build natif non exécutés car `ctest` et `cmake` sont absents; `combat_catalog_smoke.gd` demeure en échec sur une assertion de texte historique qui contredit le catalogue courant, sans dépendance avec cette tranche. Les smokes inventaire, pause et run result valident les données actuellement utilisées.

**Dépendances :** Tâches 1–4.

**Fichiers probables :** smokes, documentation QA/contrat au besoin, checklist.

**Portée estimée :** M.

## Gate d’implémentation

Checklist exécutée selon smoke d’abord → changement minimal → vérification adaptée → commit/push explicite. Le gate a été levé selon la demande de poursuivre sans checkpoints.

## Passe visuelle — lisibilité des cartes Pause/inventaire

- [x] Augmenter légèrement la largeur et la hiérarchie typographique de Pause, confirmation et inventaire, sans changer les actions ni les règles.
- [x] Revoir les captures 640×360; faire passer les smokes Pause, inventaire, focus/couleurs et bounds 640×360–1920×1080.
- [ ] Revue souris/manette physique et revue visuelle dédiée aux résolutions agrandies lorsque ce matériel est disponible.
