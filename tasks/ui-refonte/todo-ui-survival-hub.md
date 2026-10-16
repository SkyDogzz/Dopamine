# Tâches : `survival-hub`

**Statut : terminé.** Les tâches d’implémentation et d’intégration sont achevées; revue matérielle documentée comme non effectuée.

## Tâche 1 — Données de difficulté et contrat de profil

**Description :** Centraliser les données des cinq difficultés et étendre le profil normal pour mémoriser les déblocages séquentiels, avec migration additive.

**Critères d’acceptation :**
- [x] Easy est débloquée dans un profil neuf; les difficultés suivantes sont verrouillées dans l’ordre convenu.
- [x] La migration conserve toutes les données existantes et initialise correctement les nouveaux champs.
- [x] Les multiplicateurs numériques sont centralisés, marqués [PROPOSÉ] et non dupliqués dans l’interface.
- [x] Les données du Sandbox ne sont ni lues ni modifiées.

**Vérification :** `survival_difficulty_profile_smoke.gd` passe sous Godot 4.7.2 (profil neuf, migration v2/v5 et conservation de données); `progression_service_smoke.gd` et l’import headless de l’éditeur passent aussi.

**Dépendances :** aucune.

**Fichiers probables :** `game/scripts/progression_service.gd`, nouveau script ou ressource de données de difficulté si le code existant ne fournit pas de propriétaire approprié, tests progression ciblés.

**Portée estimée :** M.

## Tâche 2 — Déblocage après victoire

**Description :** Associer la difficulté au résultat de run et débloquer uniquement la difficulté suivante après victoire, en conservant l’idempotence des récompenses.

**Critères d’acceptation :**
- [x] Une victoire vague 24 sur la difficulté maximale débloquée ouvre uniquement la suivante; la condition vague 24 demeure [PROPOSÉE] par la spec.
- [x] Défaite et abandon ne changent pas les déblocages.
- [x] Une récompense répétée pour le même run n’accorde pas de nouveau déblocage.
- [x] Le comportement Chaos spécial reste [OUVERT] et n’est pas inventé.

**Vérification :** `survival_difficulty_unlock_smoke.gd` passe sous Godot 4.7.2 : défaite, victoire avant vague 24, victoire Easy→Normal, impossibilité de sauter à Hard, victoire Normal→Hard, doublon sans progression et ID invalide.

**Dépendances :** Tâche 1.

**Fichiers probables :** `game/scripts/progression_service.gd`, `game/scripts/survival_session.gd` ou propriétaire du résultat de run, smokes de progression.

**Portée estimée :** M.

## Tâche 3 — Hub de préparation et navigation

**Description :** Créer le hub, raccorder Jouer/retour, présenter les difficultés et offrir l’accès aux panneaux existants avant la run.

**Critères d’acceptation :**
- [x] Jouer ouvre le hub; retour vers l’accueil restaure un focus visible.
- [x] Survival est le seul mode jouable présenté.
- [x] Les difficultés déverrouillées sont sélectionnables et les autres indiquent la condition de déblocage.
- [x] Les panneaux Équipement et Compétences existants sont accessibles et utilisables dans le hub; fermeture rend le focus au contrôle d’origine.
- [x] Succès et Bestiaire sont visibles et focalisables, mais ne déclenchent aucune action ni chargement de donnée dédiée.
- [x] Une erreur de chargement du profil n’entraîne ni profil de secours ni contournement de progression.
- [x] Les contrôles utilisent les commandes natives et le focus visible du thème partagé; validation automatisée souris/clavier/manette couverte par contrôles focusables. Essai matériel manette indisponible et consigné dans le bilan final.

**Vérification :** `survival_hub_smoke.gd` passe : profil neuf ou illisible, difficultés sélectionnée/verrouillées puis déblocage, Succès/Bestiaire inertes, panneaux et restauration du focus; la revue matérielle reste non effectuée et est consignée dans le bilan final.

**Dépendances :** Tâches 1 et 2; contrat `play_requested` du module `launch-navigation`.

**Fichiers probables :** nouvelle scène/script du hub, `game/scripts/launch_menu.gd`, `game/scripts/equipment_inventory_panel.gd`, `game/scripts/skill_tree_panel.gd`, nouveaux smokes UI.

**Portée estimée :** L.

## Tâche 4 — Lancement et difficulté dans la run normale

**Description :** Lancer explicitement une run normale depuis le hub avec la difficulté sélectionnée et appliquer les facteurs à la session et aux récompenses.

**Critères d’acceptation :**
- [x] Le bouton **Lancer la run** transmet la difficulté à l’entrée et la session.
- [x] Les facteurs PV, dégâts, densité et récompenses sont consommés une seule fois par leurs systèmes propriétaires.
- [x] Le choix d’arme initial existant reste présenté au démarrage.
- [x] Les bonus d’équipement et de compétences configurés dans le hub sont chargés au démarrage de run.
- [x] Les points d’entrée permettant de modifier équipement permanent ou arbre de compétences pendant une run sont absents/inaccessibles, y compris par contrôles clavier/manette.
- [x] Le Sandbox n’est pas utilisé comme raccourci de lancement et ne reçoit aucun accès à la progression normale.

**Vérification :** `survival_hub_smoke.gd`, `survival_difficulty_session_smoke.gd`, `survival_difficulty_unlock_smoke.gd`, `survival_run_meta_access_smoke.gd` et `survival_entry_smoke.gd` passent sous Godot 4.7.2. Les multiplicateurs normal/Hard sont couverts pour les récompenses; Easy pour PV/dégâts/densité. Le run conserve l’écran de choix d’arme et reçoit les bonus persistants.

**Dépendances :** Tâches 1–3.

**Fichiers probables :** `game/scripts/survival_entry.gd`, `game/scripts/survival_session.gd`, `game/scripts/wave_director.gd` ou propriétaires existants des statistiques/récompenses, smokes d’entrée/session.

**Portée estimée :** L.

## Tâche 5 — Régression et checkpoint utilisateur

**Description :** Valider les parcours concernés, mettre à jour les références et présenter un état prêt à revue.

**Critères d’acceptation :**
- [x] Les smokes ciblés et régressions Survival pertinentes passent; les limites de vérification sont consignées sans être présentées comme succès.
- [x] La séparation Sandbox/progression normale est vérifiée statiquement et par smoke adapté.
- [x] La navigation tient dans les viewports UI de référence; essai matériel manette et capture fenêtrée restent non vérifiés.
- [x] Les docs de référence et statuts [VALIDÉ]/[PROPOSÉ]/[OUVERT] restent exacts.
- [x] Diff revue, commit explicite créé et poussé sur `origin`; l’utilisateur a validé le passage au module suivant.

**Vérification :** Les tests ciblés du hub et ses intégrations ont passé à leur livraison. Lors de la clôture du 2026-10-16, la suite intégrée de 21 smokes a aussi passé, dont `survival_hub_smoke`, `survival_hub_layout_smoke`, `launch_navigation_smoke`, `survival_entry_smoke`, `survival_inventory_smoke`, `survival_starting_weapon_smoke`, `survival_run_result_smoke`, `sandbox_smoke` et `sandbox_ui_smoke`. La disposition est couverte aux viewports de référence par les smokes de layout. Une revue a corrigé un appel de dégâts de contact inatteignable; le smoke de difficulté couvre ce cas. La revue matérielle d’une vraie manette reste indisponible.

**Dépendances :** Tâches 1–4.

**Fichiers probables :** documents de référence concernés, `tasks/ui-refonte/todo-ui-survival-hub.md` et tests affectés.

**Portée estimée :** M.
