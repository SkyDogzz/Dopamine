# Spec : `run-stat-hub`

**Statut : implémentation livrée; bonus automatique par niveau XP en attente de ses paramètres.** Cette tranche rend les statistiques de la run visibles et explique leurs sources. Elle peut avancer avant la clôture de P5/P6; elle ne clôt ni ne remplace ces jalons.

## Décisions validées

- Pendant une run, un hub compact reste visible à gauche et affiche les statistiques courantes de la run.
- Le joueur appuie sur **Tab** pour ouvrir/fermer le détail des statistiques.
- Le panneau Tab est en lecture seule et ne met jamais la run en pause.
- Le détail présente les totaux et les contributions distinctes de la progression acquise pendant la run (XP incluse), de l'équipement permanent, des achievements et du skill tree.
- À chaque niveau d'XP, une statistique de combat ou utilitaire liée à la run reçoit automatiquement un bonus selon une rotation fixe, identique dans toutes les runs.
- Aucun toast, animation ou retour visuel ponctuel n'accompagne ce bonus. Les valeurs courantes se lisent dans le hub et leur attribution se consulte dans Tab.
- Le Sandbox reste strictement isolé de la progression normale et ne reçoit pas de dépendance à `SaveService` ou `ProgressionService`.
- Dans les lignes détaillées, le libellé de statistique est seul sur sa ligne; dessous, l'icône de statistique précède la valeur totale. Chaque contribution présente une icône de source et sa valeur, sans texte de libellé. Des info-bulles conservent les noms pour la compréhension à la souris.

## Paramètres encore à définir

- Liste et ordre des statistiques de la rotation XP.
- Montant par statistique et éventuels caps.
- Statistiques exactes affichées dans le hub compact et leur format visuel.
- Navigation de fermeture du panneau Tab.
- Règle de cumul/ordre des modificateurs lorsqu'une même statistique a plusieurs sources, dans les limites de l'architecture déjà documentées.

La première présentation affiche Damage, Move Speed et Crit Chance dans le hub compact. Le panneau Tab détaille Damage, Move Speed, Attack Speed, Cooldown Reduction, Crit Chance, Crit Damage, Max HP, Area, Projectile Speed, XP Gain, XP Pickup Radius, Kill Healing et Lifesteal. Chaque statistique empile son libellé, l'icône et la valeur totale, puis les paires icône/valeur des sources non nulles : run (reliques/effets temporaires), équipement, achievements et skill tree. Le panneau est aligné à gauche pour laisser le centre de l'arène visible; son bouton Close reçoit le focus à l'ouverture.

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

- [x] Le hub gauche présente les statistiques courantes de run dans un panneau compact sous le HUD.
- [x] Tab ouvre/ferme le détail sans pause; Échap / Annuler ferme le détail avant d'ouvrir la pause.
- [x] Les totaux reprennent les bonus existants du run, de l'équipement, des achievements et du skill tree; les catégories sans contribution sont omises.
- [x] Les valeurs se rafraîchissent depuis la session en lecture seule, sans écrire dans les sources.
- [x] Tab donne le focus au bouton Close; les contrôles de déplacement restent gérés par la session.
- [x] Le composant reçoit uniquement un snapshot de statistiques; il n'a pas de référence aux services Save ou Progression et n'ajoute aucun accès depuis le Sandbox.
- [x] Le smoke vérifie le panneau au viewport logique 640×360 et à 960×600 / 1280×720.
- [x] Le panneau indique que le bonus automatique XP n'est pas configuré; l'ordre et les valeurs restent à définir dans le GDD.

## Point d'entrée d'implémentation

Le composant `game/scripts/run_stat_hub.gd` ne connaît que des données de présentation; `survival_session.gd` reste propriétaire des calculs et lui transmet le snapshot. Le bonus de niveau XP demeure inactif jusqu'à l'ajout d'une table de rotation décidée et documentée.
