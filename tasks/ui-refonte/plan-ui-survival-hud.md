# Plan d’implémentation : `survival-hud`

**Statut : terminé.** HUD, coffres et résultats sont livrés; voir [`INTEGRATION-ui-refonte.md`](INTEGRATION-ui-refonte.md).

## Objectif et limites

Refondre les présentations HUD, coffre et résultat de la run Survival, en gardant les systèmes actuels propriétaires des données et des règles. Les statuts et frontières de [`SPEC-survival-hud.md`](SPEC-survival-hud.md) prévalent : wireframes détaillés, compteur d’ennemis, dégâts agrégés et decay HP ne sont pas introduits dans cette tranche.

La run continue de se figer durant les choix de coffre, et reste arrêtée après son résultat. La pause et son inventaire détaillé restent au module `survival-pause`. Aucun chemin Sandbox → progression normale ne change.

## Découpage vertical proposé

### Tranche A — Contrat visuel HUD et état utile

Écrire d’abord un smoke de scène/layout, puis réorganiser la bande HUD en conservant ses propriétaires et ses signaux. Présenter l’état santé/bouclier, XP/niveau, temps actif, vague/état, difficulté et armes actuelles avec leur niveau/évolution lorsque les données sont déjà disponibles. Garder l’indicateur boss conditionnel. Ne calculer aucune donnée gameplay depuis la présentation.

Utiliser la donnée `difficulty_id` de la session. Pour les armes/reliques, préférer les icônes déjà référencées dans les définitions; l’HUD peut garder un résumé compact, sans remplacer l’inventaire détaillé de la pause. Ne pas ajouter un compteur de reliques ou une statistique si sa source canonique n’est pas directement disponible.

### Tranche B — Choix de coffre

Écrire/compléter les smokes du contrat `ChestChoice.present`, puis organiser le titre/type et les cartes d’offre en gardant les identifiants, descriptions, icônes et callback existants. Vérifier le focus initial, navigation entre offres, sélection à la souris et maintien de la pause jusqu’au choix. Aucun tirage, contenu ou effet de coffre ne change.

### Tranche C — Résultat de run

Écrire/compléter un smoke du panneau résultat, puis clarifier la hiérarchie victoire/défaite, résumé et récompenses. Afficher uniquement les montants et objets retournés par le résultat de progression; couvrir absence de profil, doublon et erreur de sauvegarde. Garder l’action de relance existante et la session arrêtée.

### Tranche D — Intégration, régression et checkpoint

Vérifier les transitions HUD → coffre → HUD et HUD → résultat, y compris l’arrêt des horloges pendant les modaux. Rejouer les smokes Survival ciblés et vérifier l’absence de dépendance Sandbox vers SaveService/progression. Contrôler le layout aux viewports de référence, relire le diff et consigner les essais matériel/fenêtrés indisponibles. Mettre à jour la documentation de référence seulement si un contrat change, puis committer/pousser cette tranche et s’arrêter pour revue utilisateur avant `survival-pause`.

## Séquencement et dépendances

1. A précède B et C : le HUD de base et ses conventions de focus constituent le langage visuel des overlays.
2. B peut rester isolée du modèle de run : elle affiche les offres reçues et renvoie seulement l’identifiant sélectionné.
3. C consomme le résultat produit par `ProgressionService`; elle ne doit ni recalculer ni enrichir arbitrairement les récompenses.
4. D vérifie l’intégration de toutes les tranches sans élargir la portée vers le menu pause.

Les tâches détaillées, critères d’acceptation, fichiers probables et commandes seront consignés dans [`todo-ui-survival-hud.md`](todo-ui-survival-hud.md) après approbation de ce plan. Confirmer les propriétaires/fichiers réels avant chaque tâche plutôt que suivre aveuglément la liste indicative.

## Risques et réponses

| Risque | Réponse |
|---|---|
| Le HUD recalcule ou diverge des données du combat. | N’afficher que l’état exposé par la session/loadout; garder le calcul dans son propriétaire. |
| Un changement du coffre altère le timing de simulation ou les offres. | Tester l’état pause et conserver le contrat des identifiants sélectionnés. |
| Le panneau de résultat masque un échec de sauvegarde. | Garder des états distincts pour récompense absente, doublon, réussite et erreur. |
| Un layout riche déborde sur les viewports compacts ou à forte densité de jeu. | Réduire le texte, utiliser une hiérarchie compacte et valider les bounds aux résolutions existantes. |
| Un résumé d’inventaire duplique le futur inventaire de pause. | Réserver l’HUD à l’état synthétique; détails complets dans `survival-pause`. |
| Une refonte UI crée une dépendance de progression dans le Sandbox. | Revue statique des dépendances et smoke Sandbox d’isolation. |

## Gate de validation

La checklist a été exécutée en incréments avec smokes et commits poussés sur `origin`. Le goal principal et ses plans restent inchangés et en pause.
