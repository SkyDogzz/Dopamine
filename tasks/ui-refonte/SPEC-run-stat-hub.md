# Spec : `run-stat-hub`

**Statut : intention fonctionnelle validée; implémentation à faire.** Cette tranche rend les statistiques de la run visibles et explique leurs sources. Elle peut avancer avant la clôture de P5/P6; elle ne clôt ni ne remplace ces jalons.

## Décisions validées

- Pendant une run, un hub compact reste visible à gauche et affiche les statistiques courantes de la run.
- Le joueur appuie sur **Tab** pour ouvrir/fermer le détail des statistiques.
- Le panneau Tab est en lecture seule et ne met jamais la run en pause.
- Le détail présente les totaux et les contributions distinctes de la progression acquise pendant la run (XP incluse), de l'équipement permanent, des achievements et du skill tree.
- À chaque niveau d'XP, une statistique de combat ou utilitaire liée à la run reçoit automatiquement un bonus selon une rotation fixe, identique dans toutes les runs.
- Aucun toast, animation ou retour visuel ponctuel n'accompagne ce bonus. Les valeurs courantes se lisent dans le hub et leur attribution se consulte dans Tab.
- Le Sandbox reste strictement isolé de la progression normale et ne reçoit pas de dépendance à `SaveService` ou `ProgressionService`.

## Paramètres encore à définir

- Liste et ordre des statistiques de la rotation XP.
- Montant par statistique et éventuels caps.
- Statistiques exactes affichées dans le hub compact et leur format visuel.
- Disposition détaillée, regroupement et navigation de fermeture du panneau Tab.
- Règle de cumul/ordre des modificateurs lorsqu'une même statistique a plusieurs sources, dans les limites de l'architecture déjà documentées.

Les paramètres de rotation XP ne doivent pas être inventés ni présentés comme validés. L'implémentation peut commencer par le contrat de contribution par source et les panneaux de lecture, en conservant le bonus XP explicitement inactif tant que sa table n'est pas décidée.

## Contrat fonctionnel

1. Le hub gauche lit l'état effectif courant de la session et se met à jour quand ses sources changent, y compris lors d'un niveau XP ou d'une acquisition en run.
2. Tab affiche les valeurs totales ainsi que, pour chaque statistique prise en charge, les contributions par source validée. Une source sans contribution affiche zéro ou est omise de façon cohérente.
3. L'ouverture du détail n'altère ni l'état `paused`, ni les horloges, ni le multiplicateur de vitesse. Combat, déplacements, dégâts et collecte continuent.
4. Le panneau consomme des données de session en lecture seule. Il ne modifie ni profil, ni équipement permanent, ni arbre, ni achievements.
5. Le panneau se ferme par Tab et par la commande d'annulation existante; après fermeture le contrôle de run demeure utilisable.
6. La présentation reste lisible au viewport logique 640×360 et agrandie, suit l'Art Bible et expose un focus/navigation clavier-manette utilisable sans souris.
7. L'XP conserve son compteur et sa montée de niveau existants. L'absence de bonus XP configuré ne doit pas produire une valeur fictive ou un faux indicateur d'amélioration.

## Hors périmètre

- Refaire l'écran de pause ou l'inventaire de run existant.
- Ajouter des choix de bonus XP, des notifications de montée de niveau ou mettre le jeu en pause.
- Décider des valeurs d'équilibrage encore ouvertes dans le GDD.
- Afficher des données du Sandbox dans une run normale ou inversement.
- Implémenter le contenu complet P5 ou le catalogue complet de progression P6.

## Critères d'acceptation

- [ ] Le hub gauche présente les statistiques courantes de run sans masquer le joueur, les menaces ou les télégraphes.
- [ ] Tab ouvre et ferme le détail sans pause; les états de simulation et l'horloge continuent pendant qu'il est affiché.
- [ ] Les totaux sont cohérents avec les contributions séparées XP/run, équipement, achievements et skill tree.
- [ ] Les changements d'état pertinents rafraîchissent les valeurs affichées sans modifier les sources.
- [ ] Les entrées clavier/manette ont un focus visible; Tab ne casse pas les contrôles de déplacement ou de combat.
- [ ] Le comportement reste isolé du Sandbox et l'équipement/arbre/achievements restent non modifiables depuis ce panneau.
- [ ] Les layouts sont vérifiés à 640×360 et à une résolution agrandie.
- [ ] Les valeurs/ordre du bonus XP restent marqués à définir tant que l'arbitrage de balance n'est pas consigné dans le GDD.

## Point d'entrée d'implémentation

Lire `docs/gdd/GDD_v1.6.md` sections 02 et 15, `docs/architecture/INTERFACES.md` pour les sources de stats et le contrat de simulation, puis les scènes/scripts `survival_session`, HUD et inventaire de run. Le propriétaire doit agréger des contributions explicites plutôt que recalculer ou dupliquer les règles de gameplay dans les contrôles UI.
