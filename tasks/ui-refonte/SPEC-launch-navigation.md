# Spec : `launch-navigation`

**Statut : approuvée par l’utilisateur.** Le plan et la liste de tâches ont aussi été approuvés avant le début du code.

## Statuts de référence

- **[VALIDÉ]** L’accueil propose **Jouer**, **Options**, **Quitter** et un accès discret au Sandbox développeur existant.
- **[VALIDÉ]** **Jouer** mène au hub décrit par le module `survival-hub`; Survival y est le seul mode jouable.
- **[VALIDÉ]** Les interfaces se naviguent à la souris, au clavier et à la manette, avec focus visible.
- **[VALIDÉ]** Le Sandbox développeur reste strictement isolé de `SaveService` et de la progression normale.
- **[PROPOSÉ]** L’accueil devient la scène principale de démarrage. Le Sandbox existant devient une destination atteinte par l’accès discret, plutôt que la scène affichée au démarrage.
- **[PROPOSÉ]** L’accès Sandbox est un lien/bouton secondaire visuellement moins saillant que Jouer.
- **[PROPOSÉ]** Un bouton **Accueil** est ajouté au Sandbox pour permettre le retour au menu sans lancer ni modifier une run.
- **[PROPOSÉ]** **Quitter** ferme immédiatement le jeu sans confirmation.
- **[OUVERT]** Confirmation éventuelle avant Quitter, et comportement des destinations si les scènes concernées échouent à se charger.

## Objectif

Remplacer l’entrée directe dans le Sandbox par un accueil cohérent, connecter cet accueil aux Options déjà implémentées et fournir une navigation explicite vers le hub Survival et le Sandbox développeur.

## Périmètre

- Créer un écran d’accueil dans le thème partagé, avec **Jouer**, **Options**, **Quitter** et un accès discret au Sandbox.
- Définir le contrat de navigation de **Jouer** vers le hub `survival-hub`. Ce module ne crée pas le contenu du hub; son intégration sera finalisée quand la scène du hub existera.
- Ouvrir le panneau Options existant et restaurer un focus cohérent à sa fermeture.
- Ouvrir la scène Sandbox développeur existante depuis l’accès secondaire.
- Ajouter au Sandbox un retour minimal vers l’accueil, sans toucher à ses outils de simulation ni à son modèle de données.
- Utiliser le mécanisme natif Godot de fermeture pour **Quitter**.
- Garder le menu adapté aux dimensions logiques existantes, au thème pixel art néon et aux entrées souris/clavier/manette.

## Hors périmètre

- Construire le hub, choisir une difficulté, gérer équipement/compétences, Succès, Bestiaire ou lancer une run; ces éléments relèvent de `survival-hub`.
- Refonte visuelle complète du Sandbox et modification de ses outils; elles relèvent de `sandbox-ui`.
- Données de profil, progression, sauvegarde ou toute dépendance du Sandbox vers `SaveService`.
- Nouveaux réglages Options, écran de crédits, actualités, compte utilisateur ou autres destinations non confirmées.
- Création de fonctionnalités fictives ou d’écrans provisoires pour les destinations qui n’existent pas encore.

## Contrat de navigation proposé

1. La scène principale ouvre l’accueil.
2. **Options** affiche `OptionsPanel`; **Retour** le ferme et rend le focus à Options.
3. **Jouer** émet une demande de navigation vers la destination du hub, sans embarquer de logique de sélection ou de lancement de run. La cible concrète sera raccordée avec `survival-hub`.
4. L’accès discret au Sandbox ouvre la scène développeur actuelle; le bouton **Accueil** revient à l’accueil.
5. **Quitter** appelle la fermeture native de l’application.

Jusqu’à l’intégration du module `survival-hub`, aucun hub factice n’est ajouté. Le raccordement de Jouer ne doit pas empêcher le menu et les autres destinations d’être utilisables dans ce module.

## Critères d’acceptation

- [ ] Au démarrage du projet, l’accueil apparaît au lieu du Sandbox.
- [ ] L’accueil affiche seulement les quatre destinations confirmées; l’accès Sandbox est moins saillant que Jouer.
- [ ] Options s’ouvre, fonctionne et se ferme via souris, clavier et manette; le focus revient au bouton Options.
- [ ] Le contrat de **Jouer** cible le futur hub sans créer de hub factice ni démarrer directement une run.
- [ ] L’accès Sandbox ouvre le Sandbox développeur actuel et **Accueil** revient au menu.
- [ ] Le parcours vers et depuis le Sandbox n’appelle pas `SaveService`, ne lit/écrit aucune progression et ne crée aucun pont vers ces systèmes.
- [ ] Quitter déclenche la fermeture native du jeu.
- [ ] Tous les contrôles interactifs ont un focus visible et un ordre de navigation cohérent; aucune destination confirmée n’est inaccessible sans souris.
- [ ] L’écran reste lisible dans les résolutions utilisées par les vérifications UI existantes.

## Vérifications prévues

- Smoke Godot ciblé du démarrage, des transitions vers Options et Sandbox, du retour à l’accueil et du contrat Jouer.
- Vérification statique de l’absence de dépendance Sandbox → `SaveService`/progression.
- Régression des smokes Sandbox et Survival pertinents.
- Revue fenêtrée aux résolutions déjà utilisées par `ui-foundation` et `ui-settings`; parcours matériel manette/souris si disponible.
- La fermeture native peut être vérifiée via un test isolé ou inspection du callback; le smoke ne doit pas fermer le processus de test parent.

## Risques et réponses

| Risque | Réponse |
|---|---|
| Le Sandbox reste accessible au lancement et contourne le nouvel accueil. | Changer la scène principale et conserver une entrée secondaire explicite vers la scène Sandbox existante. |
| Jouer pointe vers un hub encore absent. | Garder un contrat de navigation stable et raccorder la scène au module `survival-hub`; ne pas créer un faux hub. |
| La navigation Sandbox introduit un accès aux données de progression. | Limiter l’intégration aux transitions de scènes et contrôler les dépendances sans ajouter de service commun de progression. |
| Le bouton de retour devient un prétexte pour refaire tout le Sandbox trop tôt. | Ajouter uniquement une commande de retour minimale; conserver le reste de l’interface pour `sandbox-ui`. |

## Critère de sortie

Après validation de cette spec, produire le plan détaillé et la liste de tâches `launch-navigation`, les soumettre à validation, puis seulement commencer l’implémentation.
