# Plan d’implémentation : `survival-hub`

**Statut : terminé.** Le hub et son intégration Survival sont livrés; voir [`INTEGRATION-ui-refonte.md`](INTEGRATION-ui-refonte.md).

**Addendum 2026-10-16 :** la demande validée du GDD de présenter les records est couverte par une vue locale Armorless, en lecture seule. Elle réutilise les données déjà persistées et n’ajoute aucun transfert au Sandbox.

## Objectif et limites

Relier **Jouer** au hub de préparation Survival, transférer une difficulté autorisée vers la run normale et limiter la modification d’équipement permanent et de compétences au hub. Les décisions [VALIDÉ], les réglages [PROPOSÉ] et les comportements [OUVERT] restent tels que consignés dans [`SPEC-survival-hub.md`](SPEC-survival-hub.md).

Le Sandbox reste hors du parcours et des données du hub. Succès et Bestiaire restent des contrôles inertes. Les multiplicateurs GDD seront centralisés comme réglages provisoires [PROPOSÉ]; aucune règle spéciale Chaos ne sera ajoutée.

## Découpage vertical

### Tranche A — Contrat de difficulté et déblocages

Définir une source unique de données pour les cinq difficultés et leurs facteurs provisoires. Étendre le profil normal de façon non destructive pour mémoriser la difficulté maximale débloquée (Easy par défaut). Raccorder l’octroi de récompense à la difficulté de la run afin qu’une victoire ne débloque que la suivante; défaite, abandon et récompense répétée n’avancent pas le profil.

Avant le code, vérifier le format de profil courant, l’idempotence des récompenses et l’ordre d’application des facteurs (PV, dégâts, densité, Essence, Powder). Les tests de migration et de progression utiliseront des profils temporaires isolés, jamais le profil de l’utilisateur.

### Tranche B — Hub et navigation

Créer le hub comme scène propriétaire de `ProgressionService`, charger le profil normal et afficher la sélection des difficultés déverrouillées/verrouillées avec leurs conditions. Réutiliser les panneaux d’équipement et d’arbre de compétences existants; fermeture et retour restaurent le focus. Succès et Bestiaire sont focalisables, indiqués comme indisponibles et sans callback fonctionnel. **Jouer** ouvre le hub; le retour renvoie à l’accueil.

Une erreur de profil s’affiche sans fabriquer de profil de secours ni autoriser un lancement qui contourne les services normaux.

### Tranche C — Préparation et démarrage de run

Ajouter une action explicite **Lancer la run**. Transmettre la difficulté retenue à l’entrée/session normale; appliquer les facteurs centralisés pertinents à la simulation et aux récompenses. Garder le choix d’arme initial au démarrage de run. Retirer les contrôles et chemins d’ouverture de modification permanente depuis la session en cours; les bonus sélectionnés avant lancement sont ceux chargés par cette run.

### Tranche D — Régression et checkpoint

Exécuter les tests ciblés du hub, du profil, de l’entrée et de la session, puis la régression Survival et le smoke Sandbox d’isolation. Inspecter les changements de dépendances et de sauvegarde. Vérifier l’usage clavier/souris/manette, le focus visible et les résolutions UI prises en charge; noter explicitement les vérifications matérielles indisponibles. Mettre à jour les références utiles, faire une revue de diff, puis arrêter pour revue utilisateur avant de commencer le module suivant.

## Séquencement et dépendances

1. Tranche A précède le hub : le hub ne doit pas réinventer la persistance ou l’ordre des déblocages.
2. Tranche B dépend du contrat de profil de A et du signal `play_requested` de `launch-navigation`.
3. Tranche C dépend de A et B; son intégration doit continuer d’utiliser l’entrée Survival normale.
4. Tranche D couvre l’ensemble après les tranches précédentes.

Les tâches détaillées, critères, fichiers probables et vérifications sont dans [`todo-ui-survival-hub.md`](todo-ui-survival-hub.md). Les fichiers probables y sont indicatifs : confirmer les propriétaires réels des responsabilités avant chaque tranche.

## Risques et réponses

| Risque | Réponse |
|---|---|
| Migration ou déblocage altère un profil existant. | Migration additive et tests ciblés sur chaque version précédente, avec fichiers temporaires isolés. |
| Récompense idempotente sans tenir compte de la difficulté. | Faire entrer l’identifiant de difficulté dans le contrat de récompense et couvrir les répétitions. |
| Multiplicateurs appliqués deux fois ou au mauvais endroit. | Centraliser les facteurs et tester séparément simulation et récompense; ne pas dupliquer les valeurs dans l’UI. |
| Équipement permanent encore modifiable en run par un chemin indirect. | Supprimer les points d’entrée de run et tester les signaux/contrôles, pas seulement leur visibilité. |
| Couplage du Sandbox à la progression. | Garder `ProgressionService` dans le parcours normal uniquement; vérifier statiquement les dépendances Sandbox. |
| Écritures headless instables dans l’environnement courant. | Utiliser des fixtures temporaires isolées; si la contrainte `user://` observée précédemment persiste, isoler clairement le blocage et compléter par vérification statique sans prétendre que le smoke a réussi. |

## Gate de validation

Ce plan et sa liste de tâches sont exécutés, avec commits poussés sur `origin`. Le goal principal et ses plans restent inchangés et en pause.
