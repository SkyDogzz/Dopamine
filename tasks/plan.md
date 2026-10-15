# Plan d’implémentation — premier playable

## Objectif

Livrer d’abord un Sandbox développeur autonome, puis le premier playable Survival, en gardant un cœur de simulation partagé et sans capacité d’écriture de progression dans le Sandbox. Développement Linux-first ; Godot 4.7.2, C++23 et GDExtension sont les cibles verrouillées après le spike P0.

## Architecture de travail

- Godot/GDScript possède l’interface et les Nodes ; le C++ possède l’état mutable de simulation sur son thread dédié.
- Un cœur C++ sans dépendance Godot contient l’état et les règles réutilisables par les modes.
- Le pont GDExtension valide les commandes et publie des snapshots immuables vers Godot.
- Le Sandbox ne reçoit aucun accès au service de sauvegarde normale.
- Les nombres marqués proposés dans le GDD restent des valeurs de départ, pas des décisions validées.

## Tâches

### Phase 0 — Fondations Linux (terminée)

- [x] Vérifier la compilation C++23, la compatibilité Godot 4.7.2/GDExtension et le chargement headless sous Linux.
- [x] Créer le projet Godot et verrouiller `godot-cpp` au commit testé.

### Phase 1 — Cœur de simulation partagé

- [x] Définir et tester les `EntityId` index/génération, le stockage SoA minimal et spawn/despawn/reset.
- [x] Ajouter le thread de simulation, commandes ordonnées, pause/reprise/step explicite, arrêt propre et snapshots cohérents.
- [x] Exposer le contrat natif minimal à Godot et documenter les règles de propriété/thread.

### Phase 2 — Sandbox développeur MVP

- [x] Construire une scène de laboratoire utilisable sans sauvegarde avec spawn, despawn, pause, step, vitesse et reset.
- [x] Ajouter l’inspecteur d’entité, les métriques et les logs.
- [x] Ajouter des scénarios headless et un export de métriques ; vérifier l’absence d’accès aux sauvegardes normales.
- [x] Checkpoint : exécuter et inspecter une simulation sans Survival ni état persistant.

### Phase 3 — Combat core jouable

- [x] Ajouter le spatial hash uniforme minimal et des tests ciblés de requête de rayon.
- [x] Ajouter la poursuite d’une cible de mode et la séparation locale via un index construit une fois par passe.
- [x] Ajouter les projectiles ECS, leur expiration, le swept circle et les événements dégâts/mort acquittables.
- [x] Ajouter le calcul pur et testable du HP decay, sans attribuer au cœur l’autorité sur le HP joueur.
- [x] Ajouter les menaces aux événements de mort et calculer le soin par kill proposé sans muter le HP joueur.
- [x] Ajouter au cœur les profils provisoires Chaser, Sprinter, Tank et Shooter ; les rendre appelables depuis le Sandbox.
- [x] Ajouter une scène joueur Godot avec mouvement configurable WASD/manette ; garder l’autorité du transform dans Godot.
- [x] Relier le transform Godot du joueur au steering de l’ECS dans une scène Survival, en préservant les vitesses de profil proposées.
- [ ] Ajouter les comportements d’ennemis autres que la poursuite ; arbitrer la synchronisation du joueur/boss.
- [x] Intégrer HP decay et soins aux événements de combat et à l’horloge active de `SurvivalSession`, avec HP possédé côté Godot.
- [x] Ajouter un prototype automatique Lightning Conductor configurable ; la cadence, les dégâts et l’interprétation des deux chaînes restent **[PROPOSÉS]**.
- [ ] Compléter les modificateurs de dégâts, lifesteal, statuts et collisions joueur.
- [ ] Tester les règles indépendamment dans le Sandbox et respecter les budgets de simulation.

### Phase 4 — Premier playable Survival

- [ ] Ajouter vagues, XP, chests et contenu minimal de trois armes/reliques selon les données de référence.
- [ ] Ajouter boss, HUD, fin de run et sauvegarde minimale isolée du Sandbox.
- [ ] Vérifier une run Survival complète de 24 vagues et les critères QA associés.
- [ ] Checkpoint final : build Linux, démarrage sans save existante, run complète et régression Sandbox.

## Risques

| Risque | Mitigation |
|---|---|
| Accès Godot depuis le worker | Le worker ne manipule que des types C++ standard ; publier des snapshots sous verrou court. |
| P0 incomplet sur une nouvelle machine | Garder les commandes d’import, de build et de lancement documentées et tester sur projet propre. |
| GDD mélange valeurs retenues et proposées | N’utiliser les propositions que comme valeurs provisoires et conserver leur statut dans les données/docs. |
| Sandbox altère la progression | Ne pas lui fournir d’API de save ; ajouter un test d’isolation avant l’intégration des récompenses. |

## Vérification

- Test ciblé après chaque tranche de logique (ECS, commandes, worker, combat).
- Smoke test Godot headless après changement du pont ou des scènes.
- Batterie plus complète aux checkpoints Sandbox puis Survival ; benchmark de charge aux étapes P2/P4.
- Commit par tranche cohérente. Ne pas pousser tant qu’aucune remote n’est configurée.
