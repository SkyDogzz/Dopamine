# Plan d’implémentation : `launch-navigation`

**Statut : approuvé par l’utilisateur.** Implémentation suivie dans [`todo-ui-launch-navigation.md`](todo-ui-launch-navigation.md).

## Vue d’ensemble

Remplacer le démarrage direct dans le Sandbox développeur par un accueil, relier Options au panneau existant, et fournir des transitions explicites entre accueil et Sandbox. Le hub Survival reste la propriété du module suivant; ce plan crée uniquement le contrat de demande de navigation pour **Jouer**.

## Décisions d’architecture proposées

- Faire de la nouvelle scène d’accueil la `run/main_scene` de Godot; conserver `main.tscn` comme Sandbox développeur.
- Utiliser le thème partagé `dopamine_ui.tres` et les contrôles natifs `Control`/`Button`; ne pas introduire de framework ni de navigation abstraite.
- Garder **Jouer** comme signal/contrat émis par l’accueil, raccordé à la scène du hub lors de `survival-hub`; aucune scène ou donnée factice.
- Le propriétaire de l’accueil instancie `OptionsPanel`, retire le panneau à sa fermeture et restaure le focus sur Options.
- La navigation vers/depuis le Sandbox reste une transition de scène seulement; pas d’accès aux services de progression ou à `SaveService`.
- Ajouter dans l’en-tête Sandbox un retour simple vers l’accueil; la refonte visuelle du Sandbox est reportée à `sandbox-ui`.

## Ordre d’implémentation

1. Ajouter une scène/script d’accueil minimal avec les quatre destinations confirmées, thème partagé, ordre de focus et contrat `play_requested`.
2. Intégrer Options avec cycle d’ouverture/fermeture et restauration du focus; vérifier les interactions et la disposition.
3. Changer la scène principale, brancher l’accès au Sandbox et le retour depuis le Sandbox; ajouter Quitter.
4. Faire une revue ciblée, exécuter les vérifications et régressions prévues, corriger, mettre à jour les références et consigner limites matérielles.

## Risques et mitigations

| Risque | Impact | Réponse |
|---|---|---|
| Le hub n’existe pas encore. | Le bouton Jouer ne peut pas encore changer de scène. | Tester le signal public `play_requested`; effectuer le raccordement réel au module `survival-hub`. |
| Options est `Control` plein écran et peut remplacer l’accueil. | Focus perdu ou écran parent détruit. | Garder l’accueil propriétaire du panneau; fermer sur signal, puis rendre explicitement le focus au bouton Options. |
| Le Sandbox est encore central dans les conventions actuelles. | Un parcours oublié peut continuer à contourner l’accueil. | Vérifier `run/main_scene`, chemin accueil → Sandbox → accueil, et garder le bouton Survival existant hors du chemin d’accueil ou le retirer selon le contrat validé du module. |
| Le retour Sandbox nécessite de toucher `main.gd`/`main.tscn`. | Risque d’effet de bord sur les outils. | Limiter le changement à un bouton de navigation et à son callback; exécuter les smokes Sandbox existants. |

## Vérification et checkpoint

- Smoke UI ciblé couvrant présence des destinations, focus et contrat **Jouer**.
- Smoke d’intégration couvrant scène principale, Options open/close, Sandbox aller/retour et Quitter via vérification isolée du callback.
- Régression `sandbox_smoke.gd`, `sandbox_ui_smoke.gd` et tests d’entrée Survival pertinents.
- Vérification statique de l’absence de nouveaux liens vers `SaveService` et les services de progression depuis le Sandbox.
- Revue fenêtrée aux résolutions 1280×800, 960×600 et 1600×900, si l’environnement graphique reste disponible.
- Revue manette/souris sur matériel réel; si indisponible, consigner cette limite au checkpoint sans prétendre l’avoir vérifiée.
- Arrêt après cette tranche pour revue du résultat avant de passer à `survival-hub`.

## Questions ouvertes

- La spec laisse ouverte une confirmation avant **Quitter** et le retour visuel en cas d’échec de chargement. Le plan suit les comportements proposés (fermeture directe, messages d’erreur natifs/log) sans construire de dialogue supplémentaire; tout besoin contraire doit être levé avant approbation.
- Le signal `play_requested` est une étape d’intégration temporaire jusqu’au module hub; aucun hub factice n’est inclus.

## Liste de tâches

Voir [`todo-ui-launch-navigation.md`](todo-ui-launch-navigation.md), préparée à valider en même temps que ce plan.
