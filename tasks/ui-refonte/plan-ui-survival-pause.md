# Plan d’implémentation — `survival-pause`

**Statut : terminé.** Pause, Options, inventaire et abandon sont livrés; voir [`INTEGRATION-ui-refonte.md`](INTEGRATION-ui-refonte.md).

Spec de référence : [`SPEC-survival-pause.md`](SPEC-survival-pause.md).

## Objectif et limites

Créer un menu pause de run, son inventaire de loadout en lecture seule, l’intégration du panneau Options existant et une sortie d’abandon confirmée. Le contrôleur de session reste propriétaire de l’état pause; la présentation ne modifie pas les règles de combat ni la progression. Le Sandbox reste inchangé et isolé.

## État du code observé

- `game/scripts/survival_session.gd` gère déjà Échap via `_manually_paused` et `simulation.pause()/resume()`, mais n’affiche pas de panneau pause. Les choix de départ, coffres et résultats ont déjà des gardes/modaux dédiés.
- Le `_process` de session lit `simulation.snapshot()` et calcule les deltas à partir de `simulation_time`; `player_active_time` et le directeur de vague dépendent de cet état. La suspension de la simulation est donc la frontière à préserver et à tester.
- `game/scripts/options_panel.gd` émet `close_requested`, ferme aussi via `ui_cancel` et ne connaît pas la simulation. La session peut instancier `game/scenes/options_panel.tscn` au-dessus de son panneau pause.
- `SurvivalLoadout` expose `owned_weapons()`, `owned_relics()`, `weapon_level()` et `relic_level()`. Les noms, comportements et icônes sont actuellement stockés derrière des champs privés, tandis que `game/scripts/combat_catalog.gd` charge les définitions canoniques de `game/data/combat_catalog.json`.
- Le catalogue lie chaque arme à `relic_id` et `evolution_id`; les définitions de relique indiquent leur arme associée. Le seuil d’évolution actif dans la session doit être confirmé dans le code avant implémentation; la présentation ne doit pas le réinventer.
- `ProgressionService.award_survival_run()` est appelé dans `_finish_run()`. Abandonner ne doit pas appeler ce chemin ni une variante de récompense; la navigation doit abandonner la scène/session sans injecter un nouveau service.
- `launch_menu.tscn` est la destination confirmée de retour à l’accueil.

## Découpage vertical proposé

### Tranche A — Contrat de pause et gel des horloges

Créer un smoke d’intégration pour ouvrir Échap, fermer Échap/Reprendre et préserver l’état simulation/temps à travers plusieurs frames. Ajouter ensuite une seule source de vérité UI pour pause manuelle et montrer/masquer le menu. Conserver la priorité des choix d’arme initial, coffre et résultat; Échap ne doit pas fermer ces couches ni reprendre une run déjà suspendue pour un autre motif.

### Tranche B — Options au-dessus de Pause

Intégrer la scène Options existante comme couche au-dessus de Pause. Vérifier que fermeture par Retour/Échap enlève seulement Options, que la simulation reste suspendue et que le focus revient au bouton Options. Ne dupliquer ni le service ni le panneau de réglages.

### Tranche C — Inventaire runtime en lecture seule

Établir dans le smoke les données catalogue attendues, puis afficher les armes et reliques du `SurvivalLoadout` courant avec icône, nom, niveau, description et statut d’évolution. Exposer une projection/read-only du catalogue uniquement si nécessaire; garder les opérations de mutation hors de l’API UI. Le lien arme/relique et la condition d’évolution doivent provenir d’une règle canonique existante ou être isolés dans le propriétaire métier s’il manque un accès propre, et non dupliqués dans la scène.

### Tranche D — Confirmation d’abandon

Ajouter une confirmation annulable, avec focus/restauration cohérents. Le chemin de confirmation libère la run et va à l’accueil sans appeler `_finish_run()` ni enregistrer une victoire/récompense; couvrir également l’état de profil avant/après et l’absence de simulation encore active.

### Tranche E — Intégration, régression et checkpoint

Valider pause → Options → pause, pause → inventaire → pause, annulation d’abandon et abandon → accueil. Rejouer les smokes de choix initial, coffre, HUD, résultat, simulation et isolation Sandbox/progression. Vérifier bornes et navigation aux viewports de référence, relire le diff, mettre à jour QA/architecture si un contrat change, puis commit/push et arrêt pour revue utilisateur avant `sandbox-ui`.

## Séquencement et dépendances

1. A pose l’état pause et son invariant temporel qui conditionnent toutes les autres vues.
2. B et C dépendent de A, mais sont indépendantes entre elles.
3. D dépend de A pour empêcher la reprise accidentelle et constitue une sortie terminale distincte du résultat normal.
4. E dépend de toutes les tranches et vérifie les frontières Sandbox et progression.

Les tâches détaillées et les commandes de contrôle seront décrites séparément dans [`todo-ui-survival-pause.md`](todo-ui-survival-pause.md), après validation du présent plan. Vérifier les chemins et propriétaires réels avant chaque changement; ne pas agrandir les APIs de chargement sans nécessité.

## Fichiers envisagés

- `game/scripts/survival_session.gd` et `game/scenes/survival_session.tscn` pour orchestration/session et couches UI.
- Un panneau pause et un panneau inventaire dédiés (`game/scenes/` et `game/scripts/`) si le layout dans la scène existante devient difficile à maintenir.
- `game/scripts/survival_loadout.gd` / `game/scripts/combat_catalog.gd` uniquement pour fournir une projection de catalogue en lecture seule si les interfaces actuelles ne suffisent pas.
- Smokes ciblés dans `game/tests/` couvrant pause/Options, inventaire catalogue/évolution et abandon; réutiliser les smokes existants plutôt que recopier leurs fixtures.
- `docs/qa/TESTS.md` et/ou `docs/architecture/INTERFACES.md` uniquement si les contrats publics ou instructions de validation changent.

## Vérification

Utiliser le binaire local Godot 4.7.2 :

```bash
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit
tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/survival_pause_smoke.gd
```

Le checkpoint doit aussi lancer les smokes ciblés sur options, inventaire, départ, coffre, HUD, résultat, horloges, hub/entrée et Sandbox; lancer `ctest --test-dir build --output-on-failure` aux avancées majeures si `ctest` et build sont disponibles. Vérifier les bornes à 960×600, 1280×800 et 1600×900. Parcourir à la souris, au clavier et à la manette quand le matériel est disponible; les limites headless ne comptent pas comme vérification physique.

## Risques et réponses

| Risque | Réponse prévue |
|---|---|
| Pause UI et pause de simulation divergent, ou Échap reprend un autre modal. | Centraliser la transition dans la session et tester l’ordre des modaux ainsi que les snapshots de simulation avant/après. |
| Options absorbe Échap ou déclenche la reprise derrière lui. | Fermer seulement Options, garder Pause visible et vérifier focus + horloges dans un smoke intégré. |
| La vue inventaire duplique une règle d’évolution ou donne une fausse évolution. | Consommer le catalogue et la règle runtime canonique; si cette règle n’est pas exposée, documenter le petit contrat métier avant de l’ajouter. |
| Abandon appelle une récompense ou laisse la simulation vivante. | Garder abandon hors du chemin `_finish_run()` et contrôler le profil, la scène cible et l’arrêt runtime après confirmation. |
| La pause crée un chemin de progression depuis le Sandbox. | Modifier uniquement la session normale; conserver les constructeurs Sandbox sans `SaveService`/`ProgressionService` et exécuter le smoke d’isolation. |

## Gate de validation

La checklist a été exécutée tâche par tâche; les commits sont poussés sur `origin`. Le goal principal reste inchangé et en pause.
