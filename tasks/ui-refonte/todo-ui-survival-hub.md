# Tâches : `survival-hub`

**Statut : proposé pour validation utilisateur.** Les tâches ne sont pas autorisées à démarrer avant validation du plan et de cette liste.

## Tâche 1 — Données de difficulté et contrat de profil

**Description :** Centraliser les données des cinq difficultés et étendre le profil normal pour mémoriser les déblocages séquentiels, avec migration additive.

**Critères d’acceptation :**
- [ ] Easy est débloquée dans un profil neuf; les difficultés suivantes sont verrouillées dans l’ordre convenu.
- [ ] La migration conserve toutes les données existantes et initialise correctement les nouveaux champs.
- [ ] Les multiplicateurs numériques sont centralisés, utilisés comme valeurs provisoires [PROPOSÉ] et non dupliqués dans l’interface.
- [ ] Les données du Sandbox ne sont ni lues ni modifiées.

**Vérification :** Tests ciblés du profil neuf et des versions migrées, avec fichiers temporaires isolés; test de cohérence de la table de facteurs; inspection des dépendances Sandbox/progression.

**Dépendances :** aucune.

**Fichiers probables :** `game/scripts/progression_service.gd`, nouveau script ou ressource de données de difficulté si le code existant ne fournit pas de propriétaire approprié, tests progression ciblés.

**Portée estimée :** M.

## Tâche 2 — Déblocage après victoire

**Description :** Associer la difficulté au résultat de run et débloquer uniquement la difficulté suivante après victoire, en conservant l’idempotence des récompenses.

**Critères d’acceptation :**
- [ ] La victoire sur une difficulté débloque la suivante, sans sauter de niveau.
- [ ] Défaite et abandon ne changent pas les déblocages.
- [ ] Une récompense répétée pour le même run n’accorde pas de nouveau déblocage.
- [ ] Le comportement Chaos spécial reste [OUVERT] et n’est pas inventé.

**Vérification :** Tests ciblés victoire/défaite/abandon/doublon pour chaque frontière utile de progression.

**Dépendances :** Tâche 1.

**Fichiers probables :** `game/scripts/progression_service.gd`, `game/scripts/survival_session.gd` ou propriétaire du résultat de run, smokes de progression.

**Portée estimée :** M.

## Tâche 3 — Hub de préparation et navigation

**Description :** Créer le hub, raccorder Jouer/retour, présenter les difficultés et offrir l’accès aux panneaux existants avant la run.

**Critères d’acceptation :**
- [ ] Jouer ouvre le hub; retour vers l’accueil restaure un focus visible.
- [ ] Survival est le seul mode jouable présenté.
- [ ] Les difficultés déverrouillées sont sélectionnables et les autres indiquent la condition de déblocage.
- [ ] Les panneaux Équipement et Compétences existants sont accessibles et utilisables dans le hub; fermeture rend le focus au contrôle d’origine.
- [ ] Succès et Bestiaire sont visibles et focalisables, mais ne déclenchent aucune action ni chargement de donnée dédiée.
- [ ] Une erreur de chargement du profil n’entraîne ni profil de secours ni contournement de progression.
- [ ] Souris, clavier et manette peuvent atteindre les contrôles avec focus visible.

**Vérification :** Smoke du parcours hub, profil neuf/migré, difficulté sélectionnée/verrouillée, contrôles inertes, panneaux et retour/focus.

**Dépendances :** Tâches 1 et 2; contrat `play_requested` du module `launch-navigation`.

**Fichiers probables :** nouvelle scène/script du hub, `game/scripts/launch_menu.gd`, `game/scripts/equipment_inventory_panel.gd`, `game/scripts/skill_tree_panel.gd`, nouveaux smokes UI.

**Portée estimée :** L.

## Tâche 4 — Lancement et difficulté dans la run normale

**Description :** Lancer explicitement une run normale depuis le hub avec la difficulté sélectionnée et appliquer les facteurs à la session et aux récompenses.

**Critères d’acceptation :**
- [ ] Le bouton **Lancer la run** transmet la difficulté à l’entrée et la session.
- [ ] Les facteurs PV, dégâts, densité et récompenses sont consommés une seule fois par leurs systèmes propriétaires.
- [ ] Le choix d’arme initial existant reste présenté au démarrage.
- [ ] Les bonus d’équipement et de compétences configurés dans le hub sont chargés au démarrage de run.
- [ ] Les points d’entrée permettant de modifier équipement permanent ou arbre de compétences pendant une run sont absents/inaccessibles, y compris par contrôles clavier/manette.
- [ ] Le Sandbox n’est pas utilisé comme raccourci de lancement et ne reçoit aucun accès à la progression normale.

**Vérification :** Smoke hub→entrée→session couvrant difficulté, choix d’arme et bonus; tests de contrôle d’accès en run; inspection de l’application des facteurs.

**Dépendances :** Tâches 1–3.

**Fichiers probables :** `game/scripts/survival_entry.gd`, `game/scripts/survival_session.gd`, `game/scripts/wave_director.gd` ou propriétaires existants des statistiques/récompenses, smokes d’entrée/session.

**Portée estimée :** L.

## Tâche 5 — Régression et checkpoint utilisateur

**Description :** Valider les parcours concernés, mettre à jour les références et présenter un état prêt à revue.

**Critères d’acceptation :**
- [ ] Les smokes ciblés et régressions Survival pertinentes passent; les échecs environnementaux sont reproduits et consignés sans être présentés comme succès.
- [ ] La séparation Sandbox/progression normale est vérifiée statiquement et par smoke adapté.
- [ ] La navigation est revue aux résolutions UI de référence, et les limites de vérification matérielle sont documentées.
- [ ] Les docs de référence et statuts [VALIDÉ]/[PROPOSÉ]/[OUVERT] restent exacts.
- [ ] Diff revue, commit explicite créé et poussé sur `origin`; l’implémentation s’arrête pour revue utilisateur avant le module suivant.

**Vérification :** Smokes du hub, profil, entrée, session, équipements/compétences et Sandbox; régression Survival adaptée; `git diff --check`; revue du diff.

**Dépendances :** Tâches 1–4.

**Fichiers probables :** documents de référence concernés, `tasks/ui-refonte/todo-ui-survival-hub.md` et tests affectés.

**Portée estimée :** M.
