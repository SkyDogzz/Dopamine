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

## Suite de la roadmap — phases v1.6

Le détail exhaustif et l’audit GDD/code sont dans [`docs/planning/ROADMAP.md`](../docs/planning/ROADMAP.md). Le découpage v1.6 place le contenu de dix armes, onze reliques, évolutions et ennemis en P5 ; la progression permanente est P6. Le prototype de progression déjà présent est un travail anticipé, non une clôture du jalon. Le goal principal actif poursuit P6–P9 après P5.

### P5 — Contenu de combat v1.6 (implémentation largement vérifiée, jalon encore ouvert)

- [x] Étendre le catalogue aux dix armes et onze reliques, dont Magnet Heart ; Bloodstorm utilise des dagues orbitantes et les dix évolutions possèdent leurs prototypes.
- [x] Implémenter et tester cinq niveaux, feedback, règles d’évolution et d’éligibilité des coffres.
- [x] Garder le rayon d’attraction XP séparé de la collecte des coffres ; les autres types de pickup restent **[OUVERTS]** jusqu’à leur définition.
- [x] Compléter les statuts partagés, synergies bornées, huit familles d’ennemis, six affixes d’élite et prototypes de boss multi-phases. Les paramètres marqués **[PROPOSÉS]** restent provisoires ; Shatter est validée et prototypée, tandis qu’Electroplague, Gravity Collapse et Hemorrhage restent en attente d’arbitrage.
- [x] Recompiler la GDExtension Linux après l’optimisation du cœur et exécuter CTest : 86/86 passent en séquentiel sous Godot 4.7.2 le 2026-10-17.
- [x] Le créateur confirme la victoire Survival sans assistance, le choix manuel d’un coffre et l’absence de doublon des récompenses après relance (2026-10-17; détails de build non fournis).
- [ ] Parcourir manuellement le catalogue dans le Sandbox interactif.
- [ ] Calibrer les prototypes sur des runs représentatives et consigner le profilage de performance requis.

### P6 — Progression permanente (prototype existant, jalon incomplet)

- [ ] Finaliser équipement, enhancement, économie, skill tree et achievements après résolution des points ouverts.
- [ ] Migrer/reprendre les profils, vérifier idempotence et calibrer les effets en run.

### P7 — Endless et Armorless

- [ ] Livrer Armorless selon ses règles validées et garder les nombres proposés configurables.
- [ ] Arbitrer le contrat Endless standard avant implémentation.

### P8 — Sandbox Lab complet

- [ ] Presets/codes versionnés et bornés, import en copie isolée, snapshots complets et reprise déterministe.

### P9 — Équilibrage, polish et livraison

- [ ] Mesures de performance sur matériel de référence, build Windows, régression, accessibilité et préparation de livraison.

Les détails, critères de sortie, risques et points ouverts sont dans la roadmap de référence. Ne pas commencer P6 avant fin de P5 ; chaque évolution du statut doit être vérifiée à l'exécution et documentée.
