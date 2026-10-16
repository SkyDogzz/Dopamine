# Spec : `survival-hud`

**Statut : implémentée et livrée.** HUD, coffre et résultat sont intégrés et vérifiés par smokes; les limites matérielles figurent dans le bilan UI.

## Statuts de référence

- **[VALIDÉ]** La direction reste pixel art néon, l’interface de run doit rester lisible à forte densité et être navigable souris/clavier/manette avec focus visible (ADR-011, GDD v1.6 et interview).
- **[VALIDÉ]** Un coffre distingue explicitement arme et relique; chaque choix décrit son effet. Choisir un coffre suspend la simulation et ses horloges.
- **[VALIDÉ]** Le résultat de run distingue victoire et défaite, présente résumé/récompenses disponibles, et ne reprend pas la simulation terminée.
- **[PROPOSÉ]** Réorganiser les composants existants en une hiérarchie compacte et persistante : santé/XP et progression de vague en premier, puis état de run, boss et équipement de run.
- **[PROPOSÉ]** Conserver seulement les informations déjà produites par les systèmes Survival. Aucun nouveau compteur, bonus ou comportement de combat n’est inventé pour remplir l’interface.
- **[OUVERT]** Wireframe final, affichage du nombre d’ennemis et réglages VFX restent ouverts dans le GDD; ce module ne les tranche pas.

## Objectif

Refondre les interfaces directement liées à une run Survival — HUD, choix de coffre et résultat — pour rendre leur état immédiatement lisible et leur présentation cohérente avec le thème UI partagé, sans modifier les règles de simulation ou de progression.

## Périmètre

- Réorganiser le HUD existant : santé/bouclier, XP/niveau, temps actif, vague et état de run, armes détenues et boss lorsqu’il est présent.
- Rendre visibles la difficulté choisie et les évolutions déjà reflétées dans les données de run si elles sont disponibles sans calcul métier supplémentaire.
- Recomposer l’écran de coffre autour de son type (arme/relique), des trois offres disponibles, de leurs icônes et de leurs descriptions, avec navigation et focus cohérents.
- Recomposer l’écran de résultat pour présenter victoire/défaite, vague atteinte, durée active, éliminations et récompenses réellement retournées par le service; préserver l’état d’échec de sauvegarde et les états sans profil.
- Garder les superpositions de coffre et de résultat compatibles avec les états de pause existants et les interactions souris/clavier/manette.
- Réutiliser le Theme partagé et les composants/données déjà présents; préserver la lisibilité aux viewports de référence du projet.

## Hors périmètre

- Menu de pause, panneau Options depuis la pause, inventaire de run détaillé et abandon; ces capacités appartiennent à `survival-pause`.
- Modification des règles de tirage, du contenu d’une offre, des récompenses, des difficultés, du combat, du timing ou de la simulation.
- Inventer l’affichage de dégâts agrégés, de decay HP, du nombre d’ennemis ou d’autres statistiques tant que leurs contrats/données ne sont pas établis.
- Endless, Armorless, Sandbox UI, nouveaux réglages VFX/audio, nouvelles armes/reliques ou nouveaux assets fonctionnels.

## Hypothèses techniques proposées

1. Garder `survival_session.gd` propriétaire des données de run et du rafraîchissement du HUD; les scènes de présentation affichent les valeurs qu’il leur transmet.
2. Garder `chest_choice.gd` propriétaire de l’interaction de sélection; enrichir son contrat de présentation seulement si le type de coffre ou les descriptions nécessaires n’y sont pas déjà disponibles.
3. Garder `run_result_panel.gd` comme présentation des résultats. La source de vérité des récompenses reste `ProgressionService` et ses retours; l’interface ne recalcule aucun montant.
4. Réutiliser le thème pixel art néon, les icônes d’armes/reliques existantes et les contrôles Godot natifs. N’ajouter aucune dépendance.
5. Ne jamais connecter les scènes HUD/coffre/résultat au `SaveService`; les données persistantes ne transitent que par les contrats existants du service de progression normal. Le Sandbox conserve son parcours isolé.

## Critères d’acceptation

- [x] Le HUD présente santé/bouclier, XP/niveau, temps, vague/état, difficulté sélectionnée et armes équipées sans chevauchement aux viewports validés.
- [x] L’indicateur de boss apparaît uniquement pendant le combat de boss et reflète les valeurs courantes; l’état de victoire/défaite reste distinct.
- [x] Chaque écran de coffre affiche clairement le type arme/relique, les offres existantes, leurs icônes si disponibles et une description compréhensible; aucune offre ni règle de choix n’est modifiée.
- [ ] Le focus initial et le parcours de sélection du coffre sont visibles et utilisables à la souris, au clavier et à la manette; les choix restent suspendus jusqu’à sélection valide.
- [x] L’écran de résultat affiche les données réelles de run et de récompense, couvre absence de profil, doublon et échec de sauvegarde, et garde la run arrêtée.
- [x] La refonte ne change aucune horloge, formule de dégâts, récompense, sélection d’objet ou progression de simulation.
- [x] Aucun nouvel accès du Sandbox à la progression normale ou au `SaveService` n’est introduit.
- [x] Les scènes restent cohérentes avec le Theme partagé et passent les smokes ciblés et les revues de layout disponibles.

## Commandes et vérification prévues

- Import : `tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path game --quit`
- Smokes ciblés : les tests Survival concernés, notamment coffre, run result, pause/simulation, et nouveaux smokes de contrat HUD si nécessaires.
- Vérifier les bounds/layout aux viewports de référence 960×600, 1280×800 et 1600×900, `git diff --check`, puis la revue du diff.
- Essayer en fenêtre et avec manette si disponibles; rapporter explicitement toute limite de matériel/headless.

## Style et organisation

- GDScript : `snake_case` pour fonctions/variables, scènes `.tscn` pour layouts Control, constantes en `UPPER_SNAKE_CASE`.
- Préférer les contrôles natifs Godot et le Theme existant aux wrappers ou composants supplémentaires à usage unique.
- Garder la présentation UI séparée des règles de combat et de récompense; aucun calcul gameplay dans un Label ou script de scène d’affichage.

## Limites

- **Toujours :** préserver pause/horloges, garder les données affichées issues de leur propriétaire, maintenir les entrées accessibles et l’isolation Sandbox.
- **Demander/valider avant :** toute nouvelle donnée de combat, tout changement de règle, toute promotion d’un paramètre **[PROPOSÉ]** ou arbitrage **[OUVERT]**.
- **Ne jamais :** inventer des récompenses ou options, contourner les services propriétaires, ou faire avancer la simulation pendant un choix/modal.

## Questions ouvertes

- Les wireframes détaillés et le nombre d’ennemis visibles restent explicitement **[OUVERTS]**. La spec propose de ne pas ajouter ces informations dans ce module.
- L’affichage des reliques dans le HUD doit rester compact et ne pas dupliquer l’inventaire détaillé, qui est réservé au menu pause. Le plan précisera l’usage des icônes et données existantes après validation de cette frontière.

## Critère de sortie

La spec, le plan et les tâches sont exécutés selon l’intention UI validée. Voir [`INTEGRATION-ui-refonte.md`](INTEGRATION-ui-refonte.md) pour les tests et limites.
