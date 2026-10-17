# Spec : `survival-pause`

**Statut : implémentée et livrée.** Pause, Options, inventaire en lecture seule et abandon sont intégrés; les invariants de simulation et de progression sont vérifiés par smokes.

## Statuts de référence

- **[VALIDÉ]** Échap ouvre et ferme la pause d’une run. **Reprendre** reprend la run.
- **[VALIDÉ]** La pause propose **Reprendre**, **Options**, l’inventaire des armes/reliques équipées en lecture seule et **Abandonner** avec confirmation.
- **[VALIDÉ]** L’inventaire indique pour chaque arme et relique son icône, nom, niveau, évolution éventuelle et description.
- **[VALIDÉ]** L’équipement permanent et l’arbre de compétences ne sont pas modifiables pendant une run.
- **[VALIDÉ]** Confirmer l’abandon arrête la run et ramène à l’accueil sans accorder la récompense de victoire; annuler conserve la run en pause.
- **[VALIDÉ]** Ouvrir les Options depuis la pause ne fait avancer ni simulation ni horloges. En revenant des Options, la pause reste ouverte.
- **[VALIDÉ]** Le menu Pause permet de choisir la vitesse globale de run (×0,25, ×0,5, ×1, ×2, ×4); la simulation de combat et les traitements Godot suivent le même multiplicateur, qui revient à ×1 en quittant Survival.
- **[VALIDÉ]** Les interfaces sont navigables à la souris, au clavier et à la manette, avec un focus visible.
- **[VALIDÉ]** Le Sandbox développeur reste strictement isolé de `SaveService` et de la progression normale.
- **[PROPOSÉ]** L’état pause appartient à `survival_session.gd`; le panneau Options existant est réutilisé en superposition et rend le focus à son action d’origine.
- **[PROPOSÉ]** L’état d’évolution est dérivé du lien arme/relique et de `evolution_id` dans le catalogue, puis du niveau d’arme et du niveau de relique requis. Le catalogue demeure la source canonique; les règles métier ne sont pas recopiées dans les vues.
- **[OUVERT]** Aucune décision utilisateur ouverte n’empêche de spécifier le flux. Les détails visuels de disposition restent guidés par le thème partagé et seront fixés au plan/revue d’interface.
- **[PROPOSÉ]** Revue visuelle actuelle : carte Pause 270 px, titre 15 px, corps/contrôles 9 px; carte de confirmation 300 px; inventaire conserve son cadre 420×300 px avec noms à 10 px et détails à 9 px. Les tailles améliorent la lecture à 640×360, mais ne changent pas le flux ni les règles.

## Objectif

Donner accès à une pause de run complète, explicite et navigable, sans progression de la simulation tant que le menu Pause, Options ou l’inventaire sont affichés, et fournir une sortie d’abandon sûre.

## Périmètre

- Ajouter un panneau de pause au-dessus de la scène Survival, intégré au thème UI partagé.
- Faire d’Échap une bascule entre la run active et le panneau Pause. Les commandes de choix initial, coffre et résultat conservent leur priorité et ne sont pas détournées par le menu Pause.
- Proposer les actions **Reprendre**, **Options**, **Inventaire de run** et **Abandonner**.
- Ouvrir le panneau Options existant depuis Pause. Sa fermeture revient à Pause, restaure le focus sur Options et laisse la simulation/horloges figées.
- Présenter les armes et reliques actuellement possédées par le loadout de la run, en lecture seule, avec leurs données de catalogue et icônes existantes. Une run sans items d’une famille affiche un état vide simple.
- Présenter l’évolution effective seulement lorsque les conditions canoniques arme/relique du catalogue sont satisfaites; sinon afficher l’état de base et le niveau courant.
- Confirmer l’abandon avant de quitter. Annuler rend le focus à Abandonner et garde la run suspendue. Confirmer arrête la session et navigue vers `launch_menu.tscn`, sans appeler l’octroi des récompenses de fin de run.
- Conserver les réglages et commandes existants du panneau Options; ne pas exposer d’édition d’équipement permanent ni d’arbre de compétences depuis une run.
- Maintenir le focus visible, un ordre clavier/manette cohérent, des cibles souris utilisables et une adaptation aux viewports logiques de référence.

## Hors périmètre

- Modifier le contenu ou l’équilibrage du combat, les règles de progression, le loadout ou les critères de déblocage d’évolution.
- Ajouter à l’inventaire les objets permanents du profil; il ne montre que l’état runtime de cette run.
- Éditer l’équipement permanent, l’arbre de compétences ou toute sauvegarde depuis Pause.
- Modifier le Sandbox ou ajouter une dépendance de ce dernier à `SaveService`, `ProgressionService` ou au loadout Survival.
- Ajouter d’autres options, raccourcis configurables, remappage ou pause en réseau.
- Remplacer le panneau de résultats de fin de run ou permettre à Échap de fermer celui-ci.

## Parcours proposé

1. En run active, Échap marque la run comme mise en pause par le propriétaire de session, puis montre Pause et place le focus sur **Reprendre**.
2. **Reprendre** ou Échap ferme Pause, enlève l’état de pause manuelle et reprend la même simulation sans rattrapage du temps écoulé dans les menus.
3. **Options** ouvre `OptionsPanel` au-dessus de Pause. Le panneau Pause reste vivant dessous et la simulation demeure suspendue; **Retour** ou Échap ferme seulement Options et rend le focus à son bouton d’ouverture.
4. **Inventaire de run** ouvre une vue sans commandes de mutation, listant armes et reliques avec icône, nom, niveau, état d’évolution et description. Fermer revient au menu Pause avec focus sur Inventaire.
5. **Abandonner** ouvre une confirmation. Annuler revient à Pause. Confirmer libère la run courante et retourne à l’accueil sans passer par la récompense normale de fin de run.
6. Une nouvelle entrée en run crée une nouvelle session; aucune donnée d’inventaire runtime n’est transférée vers le Sandbox ni le profil permanent.

## Critères d’acceptation

- [x] Échap ouvre Pause pendant une run active; Échap et **Reprendre** restaurent la simulation sans saut d’horloge ni mouvement ennemi pendant l’intervalle suspendu.
- [x] La pause bloque toutes les horloges de jeu concernées, y compris le temps actif de run et de vague; les captures avant/après l’attente dans Pause/Options restent identiques.
- [x] Choix d’arme initial, coffre et écran de résultat conservent leurs états et priorités; Échap ne les ferme ni ne les remplace.
- [ ] Pause présente les quatre actions prévues et un focus initial visible; navigation souris/clavier/manette fonctionne et le focus est restauré à chaque retour.
- [x] Options fonctionne depuis Pause; fermer Options revient à Pause sans reprise, et changements de réglages restent ceux du panneau partagé.
- [x] L’inventaire liste exactement les armes et reliques possédées dans le loadout courant, avec les icônes, noms, niveaux et descriptions correspondant au catalogue.
- [x] L’évolution affichée reflète les prérequis canoniques du catalogue et le niveau runtime; les éléments incomplets ou non évolués ne sont pas présentés comme évolués.
- [x] Aucun contrôle de la pause ou de l’inventaire ne permet de modifier équipement permanent, arbre de compétences, loadout de run ou progression sauvegardée.
- [x] Abandonner exige une confirmation. Annuler conserve état et run; confirmer retourne à l’accueil, n’octroie aucune récompense de victoire et ne laisse pas de simulation active.
- [x] Les tests d’isolation continuent de démontrer qu’aucun chemin du Sandbox ne dépend de `SaveService` ou des services de progression.
- [x] L’interface reste lisible aux tailles de viewport de référence et conserve la direction pixel art néon et le focus visible.

## Vérifications prévues

- Smoke ciblé du cycle ouvrir/reprendre, ouverture Options/retour, inventaire (y compris évolution et états vides), confirmation/annulation d’abandon et retour accueil.
- Test ciblé d’invariance des horloges, positions d’ennemis, compteurs d’animation temporels et état de simulation pendant Pause et Options.
- Test de non-récompense d’abandon et régression du flux normal victoire/défaite dans `survival_run_result_smoke.gd`.
- Régression des smokes `survival_hud_smoke.gd`, `survival_chest_choice_smoke.gd`, `survival_starting_weapon_smoke.gd`, `survival_loadout_smoke.gd` et des tests de pause/horloge pertinents.
- Vérification statique des dépendances Sandbox/progression; revue fenêtrée aux résolutions UI de référence et parcours souris/clavier/manette lorsque disponible.
- Toute entrée ou plateforme matérielle non disponible est consignée comme non vérifiée, pas comme réussite.

## Risques et réponses

| Risque | Réponse |
|---|---|
| Le menu est affiché alors que l’horloge Simulation continue. | Faire de la session l’autorité de pause; vérifier snapshots de simulation et horloges de run après plusieurs frames suspendues, y compris quand Options est au-dessus. |
| Échap ferme plusieurs couches à la fois ou reprend depuis Options. | Gérer Échap par la couche UI au premier plan et restaurer le focus au propriétaire sans changer l’état pause de session. |
| L’abandon déclenche des récompenses ou laisse un identifiant de run incomplet. | Séparer explicitement navigation d’abandon et fin normale; vérifier le profil et l’état de simulation après confirmation. |
| L’UI duplique ou contredit les règles d’évolution. | Consommer les associations et identifiants canoniques de `combat_catalog.json`, et couvrir les prérequis dans un test ciblé. |
| Le menu Pause ouvre une voie d’édition de progression. | Fournir uniquement une projection des données runtime de `SurvivalLoadout`; ne pas injecter de service de progression ni d’inventaire permanent. |

## Critère de sortie

La spec, le plan et les tâches sont exécutés. Les tests d’intégration confirment les horloges gelées et la lecture seule de l’inventaire.
