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
- [x] Ajouter les dégâts de contact joueur-ennemi et l’invulnérabilité provisoires; suspendre les contrôles joueur en pause et après la fin.
- [x] Ajouter les contrôles Sandbox pour les modificateurs de dégâts/lifesteal/statuts; le lifesteal DoT et les statuts partagés sont couverts par les smoke tests.
- [x] Tester les règles indépendamment dans le Sandbox et respecter les budgets de simulation, y compris les plafonds d'entités, commandes et événements.

### Phase 4 — Premier playable Survival

- [x] Ajouter les orbes XP au cœur ECS partagé et le prototype de progression automatique avec paramètres **[PROPOSÉS]**.
- [x] Ajouter le directeur de vagues 24 × 30 s, spawn configurable selon les courbes **[PROPOSÉES]** et transitions de placeholders boss.
- [x] Poser le contrat testable du directeur de drop proposé et du modal à trois choix, sans accès aux saves Sandbox.
- [x] Relier les drops aux morts/pickup et appliquer les choix à un loadout de run avec capacités et niveaux plafonnés.
- [x] Ajouter les projectiles Inferno/Crimson et relier les trois reliques à des modificateurs provisoires vérifiés.
- [x] Ajouter l’écran de choix de départ et l’entrée vers Survival depuis le Sandbox; la paire de départ reste **[PROPOSÉE]**.
- [x] Implémenter les trois paires prototypes Lightning Conductor/Storm Core, Inferno Sprayer/Infernal Heart et Crimson Daggers/Blood Chalice, avec Infinite Circuit, Wildfire et Bloodstorm. Les valeurs de tuning restent **[PROPOSÉES]** et les autres paires restent hors vertical slice.
- [x] Ajouter un HUD Survival minimal pour le HP, temps actif, arme prototype, XP/niveau et état de run.
- [x] Afficher les HP courants/max des placeholders boss et distinguer l’état logique de victoire de la mort.
- [x] Ajouter un écran de fin avec résumé de run et redémarrage local sans sauvegarde.
- [x] Récompenses de boss par chests garantis et progression minimale persistée dans Survival ; le Sandbox n'a pas accès au service de sauvegarde et son test d'isolation protège un slot sentinelle.
- [ ] Définir les patterns détaillés des boss : point **[OUVERT]** dans le GDD; les boss du playable gardent leur comportement placeholder.
- [x] Vérifier une run Survival complète de 24 vagues et les critères QA associés, à durée nominale accélérée.
- [x] Checkpoint du premier playable : build Linux, démarrage Sandbox sans save, run complète et régression Sandbox.

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
- Commit par tranche cohérente ; pousser chaque commit lorsque `origin` est configurée.

## Suite de la roadmap — P5 à P8

Cette suite suit `docs/planning/ROADMAP.md` et ne transforme pas les points **[PROPOSÉ]** ou **[OUVERT]** du GDD en décisions. Les jalons historiques ci-dessus restent inchangés.

### P5 — Progression persistante

- [x] Étendre le profil versionné (v5) aux quatre poudres, nodes et progrès d'achievement ; migrer les profils existants sans perdre ressources/inventaire.
- [x] Ajouter l'amélioration +0..+10 par ligne, conversion 10:1, démantèlement et choix d'effet unique ; les chances/coûts proposés et le rendement provisoire restent étiquetés.
- [x] Ajouter deux nodes de compétences avec prérequis et respec gratuit ; coûts/bonus explicitement **[PROPOSÉS]**, graphe complet restant hors prototype.
- [x] Ajouter le compteur de kills idempotent, les quatre tiers Exterminator d'exemple et leurs bonus cumulés **[PROPOSÉS]**.
- [ ] Étendre le contenu aux 100–150 nodes et au catalogue complet d'achievements/effets ; calibrer équipement et économies selon les points **[OUVERTS]**.
- [ ] Vérifier migration, sauvegarde/reprise et absence de double attribution.

### P6 — Modes sans arbitrage implicite

- [ ] Implémenter Armorless selon les règles marquées **[VALIDÉ]** : départ sans équipement permanent, draft de trois objets après chaque vague, choix d'un seul, objets et Flux temporaires.
- [ ] Garder les taux de rareté, économie Flux, récompenses, scaling et difficulté proposés configurables et clairement identifiés.
- [ ] Ne pas ajouter l'entrée ni la poursuite Endless standard tant que ses règles **[OUVERTES]** n'ont pas été arbitrées.
- [ ] Ajouter les tests de draft, pauses, mort/victoire et non-persistance temporaire.

### P7 — Sandbox Lab

- [ ] Ajouter validation bornée, versionnée et isolée des presets JSON et codes de partage.
- [ ] Étendre la capture/restauration native au build et à l'état Godot pour produire un snapshot complet, puis vérifier reprise et isolation bit-à-bit des saves normales.
- [ ] Garder imports et exports Sandbox hors de `user://saves` et sans effets de progression officielle.

### P8 — Finition et plateformes

- [ ] Vérifier build et chargement GDExtension Windows avec outil disponible ou CI Windows.
- [ ] Mesurer CPU/GPU/P95/P99 et cible 60 FPS sur une machine de référence documentée ; le rendu logiciel ne suffit pas.
- [ ] Parcourir les lacunes de contenu, accessibilité/manette, équilibrage, longues runs et préparation Steam sans déclarer les seuils atteints sans mesures.

### Checkpoints

- [ ] Après chaque tranche P5/P6/P7 : tests ciblés, régression aux avancées majeures, commit explicite et push `origin`.
- [ ] À P8 : build Linux et Windows, suite complète, mesures de performance et revue de livraison.
