# Tâches : `survival-hud`

Plan associé : [`plan-ui-survival-hud.md`](plan-ui-survival-hud.md) · Spec : [`SPEC-survival-hud.md`](SPEC-survival-hud.md)

**Statut : validé par l’utilisateur.** Implémentation incrémentale en cours; tâche 1 terminée.

## Tâche 1 — Contrat et refonte du HUD

**Description :** Ajouter d’abord un smoke observable du HUD puis réorganiser ses éléments persistants en consommant exclusivement les données de la session/loadout.

**Critères d’acceptation :**
- [x] Le smoke vérifie santé/bouclier, XP/niveau, temps, vague/état, difficulté et liste des armes/niveaux avec données de fixture déterministes.
- [x] La difficulté affichée vient de `session.difficulty_id`; évolution affichée uniquement quand les données de run l’indiquent déjà.
- [x] Le panneau boss est caché sans boss et reflète les HP/phase courants quand un boss est présent.
- [x] Aucun calcul gameplay, nouvelle statistique, contrôle de pause ou chemin de progression n’est ajouté au HUD.

**Vérification :** `survival_hud_smoke.gd` passe et vérifie santé/XP, timer, vague, difficulté, résumé d’armes, boss conditionnel et bounds des enfants du HUD à 960×600, 1280×800 et 1600×900. Passent aussi `survival_weapon_smoke.gd`, `survival_wave_director_smoke.gd`, `survival_difficulty_session_smoke.gd`, `survival_wave_duration_smoke.gd`, l’import headless Godot 4.7.2 et `git diff --check`.

**Dépendances :** spec et plan `survival-hud` validés; module `survival-hub` livré.

**Fichiers probables :** `game/scenes/survival_session.tscn`, `game/scripts/survival_session.gd`, `game/tests/survival_hud_smoke.gd`.

**Portée estimée :** M.

## Tâche 2 — Présentation et navigation des coffres

**Description :** Clarifier visuellement famille et choix d’un coffre, en conservant les identifiants, descriptions, ressources et règles actuels.

**Critères d’acceptation :**
- [ ] Les offres s’affichent comme choix distincts avec type de coffre, nom, description et icône lorsqu’elle existe.
- [ ] Le premier choix reçoit le focus; les offres sont parcourables au clavier/manette et activables à la souris.
- [ ] La sélection renvoie l’identifiant existant une seule fois; une présentation invalide ne relance pas la simulation.
- [ ] Le smoke vérifie que simulation et horloges restent suspendues jusqu’au choix, puis reprennent avec le comportement actuel.

**Vérification :** `survival_chest_smoke.gd`, test de contrat de `ChestChoice.present` si le smoke intégré ne couvre pas les rejets d’entrées invalides, et régression pause/horloges pertinente.

**Dépendances :** Tâche 1 pour cohérence du thème et du focus.

**Fichiers probables :** `game/scenes/chest_choice.tscn`, `game/scripts/chest_choice.gd`, `game/tests/survival_chest_smoke.gd` ou un smoke de contrat dédié.

**Portée estimée :** M.

## Tâche 3 — Résultat de run

**Description :** Hiérarchiser victoire/défaite, résumé et récompenses réelles, sans déplacer la propriété des données ni changer les actions existantes.

**Critères d’acceptation :**
- [ ] Le résultat distingue victoire et défaite, et présente vague, durée active et éliminations retournées par la session.
- [ ] Les états profil absent, récompense déjà accordée, succès de récompense et échec de sauvegarde restent distincts.
- [ ] Les récompenses et objets affichés proviennent uniquement du dictionnaire reçu; aucun montant n’est recalculé ou inventé.
- [ ] La session reste arrêtée; l’action existante de nouvelle run reste navigable avec focus visible.

**Vérification :** étendre `survival_run_result_smoke.gd` et tester directement les branches du panneau résultat qui ne sont pas atteignables dans un run complet sans fixture de service.

**Dépendances :** Tâche 1 pour conventions visuelles; indépendante fonctionnellement de la Tâche 2.

**Fichiers probables :** `game/scenes/run_result_panel.tscn`, `game/scripts/run_result_panel.gd`, `game/tests/survival_run_result_smoke.gd`.

**Portée estimée :** M.

## Tâche 4 — Intégration et checkpoint de revue

**Description :** Vérifier les trois présentations dans le parcours de run, corriger les régressions et consigner la revue avant le module suivant.

**Critères d’acceptation :**
- [ ] Les overlays HUD → coffre → HUD et HUD → résultat gardent l’état de pause et les horloges attendus.
- [ ] Les bounds et le focus sont validés aux trois viewports de référence; les essais physiques/fenêtrés indisponibles sont explicitement signalés.
- [ ] Les smokes Survival ciblés, smoke Sandbox d’isolation, import Godot et `git diff --check` passent; les échecs éventuels sont décrits sans les masquer.
- [ ] La revue confirme l’absence de changement aux règles, récompenses, choix de coffre, services de sauvegarde et frontières Sandbox/progression.
- [ ] Les références ne changent que si un contrat public évolue; commit explicite poussé sur `origin`, puis arrêt pour revue avant `survival-pause`.

**Vérification :** `survival_hud_smoke.gd`, `survival_chest_smoke.gd`, `survival_run_result_smoke.gd`, `survival_wave_duration_smoke.gd`, `sandbox_smoke.gd`, import headless Godot 4.7.2, `git diff --check`, revue du diff.

**Dépendances :** Tâches 1–3.

**Fichiers probables :** nouveaux smokes de layout/contrat, documents de référence si l’interface change, présente checklist.

**Portée estimée :** M.

## Gate d’implémentation

Après validation de cette checklist, suivre tâche par tâche le workflow smoke d’abord → changement minimal → vérification → revue. Ne pas démarrer `survival-pause` avant le checkpoint utilisateur de la Tâche 4. Garder le goal principal en pause et ses plans intacts.
