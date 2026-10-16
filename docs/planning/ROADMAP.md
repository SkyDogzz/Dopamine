# Roadmap complète — Dopamine Survivor, GDD v1.6

Cette roadmap transforme le [GDD consolidé v1.6](../gdd/GDD_v1.6.md), l’architecture, les ADR et les documents QA en travaux ordonnés et vérifiables. Elle décrit l’état constaté dans le dépôt au 2026-10-16 ainsi que le chemin restant. Elle ne remplace pas les décisions de ces documents.

**Ordre de travail :** Linux-first ; Sandbox développeur MVP d’abord ; Survival jouable ensuite ; contenu P5 avant progression P6. Le cœur de simulation est partagé, mais la progression et les sauvegardes normales restent inaccessibles au Sandbox. Le goal principal actif couvre les jalons P5 à P9.

## Comment lire l’audit

- **Présent** : code ou données identifiables dans le dépôt. Cela ne certifie pas l’équilibrage ni le fonctionnement à l’exécution.
- **Prototype** : un chemin fonctionne pour un sous-ensemble, avec contenu ou contrat incomplet.
- **À faire** : aucune implémentation suffisante n’a été trouvée dans les scènes/scripts/données inspectés.
- **QA historique** : `docs/qa/TESTS.md` décrit un test réellement exécuté antérieurement. Les coches ne signifient pas qu’il a été relancé pendant cet audit.
- **[VALIDÉ] / [PROPOSÉ] / [OUVERT]** décrivent le statut de conception du GDD, pas l’état d’implémentation. Une valeur proposée codée en dur reste proposée.

L’audit initial était statique. Les tranches Minigun, Toxic Cloud, Sawblades et Meteor Staff ont été vérifiées sous Godot 4.7.2 depuis `tools/local/godot-4.7.2/` avec les smokes ciblés et les tests natifs concernés. Cela ne revalide pas les autres preuves d’exécution archivées dans les QA. Aucun statut de conception n’est promu par cette roadmap.

## Résumé d’avancement vérifié

| Jalon | État du code constaté | Ce qui manque pour le fermer |
|---|---|---|
| P0 Fondations | **Présent, Linux documenté** | Reproductibilité sur installation propre et build/chargement Windows. |
| P1 Sandbox développeur MVP | **Présent et bien couvert historiquement** | Continuer d’exposer les nouveaux systèmes et maintenir l’isolation au fil des intégrations. |
| P2 Simulation/combat | **Fondation présente, couverture partielle** | Diversité des IA, règles complètes d’ennemis/boss, instrumentation et performance iGPU. |
| P3 Prototype de combat | **Dix paires et dix évolutions de prototype présentes** | Contrats génériques, retours visuels par niveau, ciblage fidèle, mesures DPS détaillées. |
| P4 Vertical slice Survival | **Boucle de run prototype présente** | Boss réels, difficulté sélectionnable, run équilibrée et vérifiée sans harness. |
| P5 Contenu v1.6 | **Non livré** | Les dix paires ont un prototype ; ciblage/feedback par niveau, réactions, contenu ennemi/boss et validations de run restent incomplets. Le Dopamine Core a un sprite dédié, mais son combat et la sortie P5 ne sont pas validés de bout en bout. |
| P6 Progression permanente | **Prototype anticipé seulement** | Catalogue complet, règles et contenus validés, récompenses calibrées et effets uniques actifs. |
| P7 Modes Endless | **À faire** | Armorless complet ; arbitrages nécessaires pour Endless standard. |
| P8 Sandbox Lab joueur | **À faire au-delà des outils développeur P1** | Builds libres, presets/import/export, copie de save, snapshots complets et règles de sécurité. |
| P9 Qualité et livraison | **Partiel** | Performance sur vrai iGPU, accessibilité/VFX/audio, stabilité prolongée et Windows. |

### Lecture rapide : livré, prototype ou survolé

**Bien intégré comme fondation :** simulation native découplée de Godot, worker, commandes/snapshots, limites de charge, outils Sandbox, loop de run Survival, pause/chest/XP, dix armes et effets de combat de base, sauvegarde versionnée, premiers écrans d’équipement.

**Intégré en prototype, à ne pas confondre avec une feature finie :** boss (patterns en phases, mais vérification du combat complet et équilibrage manquants), XP auto-bonus, loot/probabilités, dix évolutions, Void Orb à attraction/percée, Frost Nova avec Chill/Absolute Zero, Sawblades à ricochets/Razorstorm, Meteor Staff en zone/Starfall fragmenté, Toxic Cloud en champ persistant, équipement et enhancement, deux nodes de skill tree, famille Exterminator, effets uniques, récompenses de run. Les paramètres restent souvent **[PROPOSÉS]**.

**Survolé ou absent par rapport au GDD :** 3 armes et 3 reliques associées restantes ; Minigun, Toxic Cloud, Sawblades et Meteor Staff n’ont pas encore de feedback visuel par niveau ; Magnet Heart n'agit que sur XP (autres pickups et impulsion de niveau 5 absents) ; animation/identité spécifique à chaque niveau ; la mécanique orbitale Crimson Daggers/Bloodstorm est maintenant prototypée, avec équilibrage et feedback visuel encore à revoir ; 8–12 familles ennemies et leurs rôles ; élites à affixes ; charges mobiles du Pulse Warden ; loot de boss et run complète vérifiés sans harness ; difficultés ; réactions élémentaires nommées ; tree ~120 nodes ; achievements ~120 familles ; modes Endless ; Sandbox Lab joueur ; performance iGPU et build Windows.

## Dépendances principales

```text
P0 outils/build
 └─ P1 cœur + Sandbox développeur
     └─ P2 simulation/combat, dégâts/statuts et observabilité
         └─ P3 contrats des armes/reliques, évolution et mesure
             └─ P4 boucle Survival verticale
                 └─ P5 catalogue de contenu + ennemis/boss
                     ├─ P6 progression persistante complète
                     ├─ P7 Armorless (après règles de run et équipements)
                     └─ P8 Sandbox Lab (après contrats/configurations de tous les systèmes)
P9 vérifie et calibre les tranches livrables, puis la version complète.
```

P6 a déjà du code anticipé, mais le chemin nominal reste P5 puis P6. P7 standard ne doit pas commencer avant résolution des sujets **[OUVERTS]**. Les travaux P8 peuvent avancer sur l’architecture après les contrats partagés, sans donner au Sandbox de droit d’écrire les sauvegardes normales.

## P0 — Fondations techniques et dépôt

**Intention :** pouvoir importer, compiler et lancer Dopamine de manière reproductible sous Linux avec Godot 4.7.2, GDExtension et C++23.

### État constaté

- Projet Godot et GDExtension déclarés dans `game/` ; cœur C++ et cible native séparés.
- `godot-cpp` est verrouillé et les commandes Linux sont documentées.
- QA historique : compilation C++23 GCC 14.2, import Godot headless et chargement de l’extension.
- Le cœur natif n’inclut pas Godot et ne lie pas `godot-cpp` selon l’architecture/QA.

### Travaux restants

- [ ] **P0.1 — Inventaire Linux**
  - [ ] Noter les versions de Godot, CMake, compilateur et dépendance native réellement utilisées.
  - [ ] Vérifier les commandes de clone, configure, build, import et lancement sur un clone propre.
  - [ ] Documenter où vont les binaires locaux et les données `user://`.
- [ ] **P0.2 — Dépendances**
  - [ ] Lister les paquets système requis et les dépendances récupérées par CMake.
  - [ ] Vérifier que le commit de `godot-cpp` reste verrouillé et que la config explique les erreurs de téléchargement.
- [ ] **P0.3 — Artefacts locaux**
  - [ ] Vérifier `.gitignore` pour les builds CMake, imports Godot et binaires de runtime.
  - [ ] Vérifier qu’un import/build ne laisse aucun fichier généré suivi par Git.
- [ ] **P0.4 — Compatibilité Windows**
  - [ ] Configurer puis compiler avec la chaîne Windows convenue.
  - [ ] Lancer l’éditeur et confirmer le chargement de la GDExtension sous Windows.
  - [ ] Consigner les écarts au build Linux sans changer la cible plateforme implicitement.
- [ ] **P0.5 — Automatisation éventuelle**
  - [ ] Décider si les builds Linux/Windows doivent être automatisés.
  - [ ] Si oui, créer un job minimal par plateforme qui configure, compile et charge le projet.

**Critère de sortie :** un clone propre s’importe, se compile et démarre sous Linux ; compatibilité Windows séparément vérifiée avant livraison Windows.

## P1 — Cœur partagé et Sandbox développeur MVP

**Intention :** disposer du premier environnement de combat observable, sans sauvegarde ni progression normale.

### État constaté

- Le Sandbox expose spawn/despawn, kill all, pause/reprise, Step explicite, vitesse, reset, sélection/inspection d’entité, métriques et logs.
- Il y a des scénarios JSON et une exportation de résultats.
- Le cœur natif utilise worker dédié, handles index/génération, snapshots immuables, files bornées et arrêt coordonné.
- L’isolation des saves est décrite comme vérifiée par slot sentinelle dans la QA historique ; les scripts de Sandbox ne reçoivent pas le service de progression.

### Travaux/critères de maintien

- [ ] **P1.1 — Contrat des commandes**
  - [ ] Répertorier les commandes Sandbox exposées et leurs paramètres.
  - [ ] Pour chaque commande, vérifier une entrée valide et une entrée invalide.
  - [ ] Vérifier qu’un rejet ne modifie pas partiellement l’état.
- [ ] **P1.2 — Observable par défaut**
  - [ ] Vérifier que spawn, dégât, mort, pause, step, vitesse et reset apparaissent dans les métriques/logs utiles.
  - [ ] Vérifier l’inspecteur après sélection, despawn et réutilisation d’un handle.
- [ ] **P1.3 — Scénarios de simulation**
  - [ ] Ajouter un scénario JSON reproductible pour chaque nouvelle règle de combat partagée.
  - [ ] Exporter les événements et métriques attendus, sans dépendance au profil utilisateur.
- [ ] **P1.4 — Barrière de sauvegarde**
  - [ ] Vérifier statiquement qu’aucun service de save n’est injecté dans l’entrée Sandbox.
  - [ ] Lancer le smoke d’isolation avec un profil Survival sentinelle et comparer les octets avant/après.
- [ ] **P1.5 — Checkpoint Sandbox**
  - [ ] Lancer les smokes natifs et GDScript pertinents.
  - [ ] Ouvrir la scène sous résolution documentée et vérifier les contrôles essentiels.

**Critère de sortie :** les critères MVP listés dans `docs/qa/TESTS.md` restent verts à l’exécution ; aucun accès save requis.

## P2 — Simulation de combat et contrats d’état

**Intention :** porter dans le cœur partagé les comportements déterministes/observables qui doivent être réutilisés par Sandbox et les modes.

### État constaté

- Présent : ECS minimal, spatial hash, poursuite/séparation, projectiles ECS, collisions balayées, pipeline de dégâts, événements acquittables, durée de vie et DoT générique.
- Survival possède le HP joueur dans Godot et transmet une cible de steering ; l’autorité et la synchronisation joueur/boss restent à garder explicites selon `ARCHITECTURE.md`.
- L’HP decay et les soins par menace sont utilisés avec des valeurs **[PROPOSÉES]**.
- Quatre profils natifs existent : Chaser, Sprinter, Tank, Shooter ; cela ne couvre pas les 8–12 familles validées au lancement.
- Il n’y a pas un système complet de réaction élémentaire ; les réactions nommées sont **[PROPOSÉES]** dans le GDD.

### Travaux

- [ ] **P2.1 — Contrat des états de combat**
  - [ ] Lister les statuts nécessaires aux armes planifiées, en commençant par Burn et Bleed déjà utilisés.
  - [ ] Pour chaque statut, fixer les champs minimaux : durée, intervalle, puissance, cible admissible.
  - [ ] Écrire un test court pour application, expiration et remplacement/rafraîchissement.
- [ ] **P2.2 — Événements et dégâts**
  - [ ] Documenter les champs obligatoires d’un événement damage/death/status.
  - [ ] Vérifier l’identifiant stable et l’acquittement sans double consommation.
  - [ ] Couvrir une cible morte/handle obsolète et une source DoT.
- [ ] **P2.3 — Effets en chaîne**
  - [ ] Cartographier les chemins qui peuvent engendrer de nouveaux dégâts/événements.
  - [ ] Définir les budgets et le comportement de refus avant d’ajouter des réactions nouvelles.
  - [ ] Garder les réactions nommées du GDD hors du code tant que leur statut reste **[PROPOSÉ]**.
- [ ] **P2.4 — IA typées**
  - [ ] Décrire le comportement observable des ennemis distance, soutien et explosif.
  - [ ] Implémenter une politique à la fois et l’exposer via un scénario Sandbox.
  - [ ] Vérifier qu’une identité d’ennemi ne dépend pas seulement d’une vitesse/HP distincte.
- [ ] **P2.5 — Autorité d’état**
  - [ ] Établir une source d’autorité par état joueur/boss/simulation.
  - [ ] Documenter les commandes et snapshots à la frontière Godot/C++.
  - [ ] Tester pause, reprise et destruction pendant une commande en attente.
- [ ] **P2.6 — Robustesse temporelle**
  - [ ] Vérifier les pas 1/120, 1/60, 1/30 et un grand delta pour une attaque/status représentatif.
  - [ ] Couvrir expiration et plusieurs ticks dus dans un même pas.
  - [ ] Vérifier refus atomique quand le budget d’événements est dépassé.
- [ ] **P2.7 — Profilage**
  - [ ] Relancer le benchmark natif sur une configuration enregistrée.
  - [ ] Mesurer CPU, GPU et frame-time dans Godot sur la machine iGPU de référence.
  - [ ] Consigner P50/P95/P99, charge et limites matérielles.

**Critère de sortie :** les comportements réellement retenus sont inspectables, bornés, cohérents avec leur horloge et testés sous différents pas de simulation.

## P3 — Contrats de contenu prototype, évolution et DPS

**Intention :** valider un petit nombre de parcours complets et les outils qui permettront d’industrialiser le catalogue P5.

### État constaté

- `survival_loadout.gd` expose dix paires implémentées dans le catalogue, niveau maximal 5, cinq slots et deux armes de départ codées.
- Huit paires ont maintenant un prototype de combat : Lightning Conductor/Storm Core, Inferno Sprayer/Infernal Heart, Crimson Daggers/Blood Chalice, Minigun/Overdrive Engine, Toxic Cloud/Plague Mask, Sawblades/Magnetic Coil, Meteor Staff/Celestial Eye et Prism Laser/Prism Crystal. Les réglages restent **[PROPOSÉS]** ; l’orbite Crimson Daggers/Bloodstorm est implémentée et couverte par des smokes ciblés.
- Les QA historiques couvrent impacts, dégâts, lifesteal, brûlure, saignement, explosion Wildfire et branches Infinite Circuit.
- Le DPS Sandbox documenté additionne les événements de dégâts sur le temps simulé, mais n’est pas un panneau complet par arme, statut, critique et fenêtre.
- La définition de contenu reste principalement dans des constantes/scripts ; catalogue data-driven complet non établi.

### Travaux

- [ ] **P3.1 — Schéma de contenu**
  - [ ] Définir les champs d’une arme, relique et évolution avec exemples des trois paires actuelles.
  - [ ] Valider les IDs, valeurs manquantes et références invalides au chargement.
  - [ ] Déplacer une seule paire vers les données pour éprouver le schéma avant conversion générale.
- [ ] **P3.2 — Niveaux et feedback**
  - [ ] Vérifier les choix d’amélioration de niveau 1 à 5 sur une arme prototype.
  - [ ] Ajouter un retour visuel/UI distinct à chaque augmentation.
  - [ ] Vérifier niveaux max et absence d’offre d’amélioration impossible.
- [ ] **P3.3 — Évolution**
  - [ ] Vérifier le passage au niveau 5 sans relique : pas d’évolution.
  - [ ] Vérifier le passage au niveau 5 avec relique déjà possédée : évolution immédiate.
  - [ ] Vérifier l’acquisition de la relique après niveau 5 : évolution immédiate, niveau conservé.
  - [ ] Vérifier qu’une évolution ne se déclenche qu’une fois et ne consomme pas la relique.
- [ ] **P3.4 — Bloodstorm conforme**
  - [x] Remplacer les projectiles en éventail par des dagues orbitantes autour du joueur.
  - [x] Vérifier l’orbite, les collisions sur deux cibles distinctes, le saignement et le lifesteal sur les événements de dégâts.
  - [ ] Conserver les nombres de dégâts au statut **[PROPOSÉ]**.
- [ ] **P3.5 — Règles du draft normal/Sandbox**
  - [ ] Refuser le doublon en Survival normal.
  - [ ] Autoriser le doublon dans le contexte Sandbox seulement.
  - [ ] Exclure les choix niveau max et appliquer la règle des armes niveau 5.
- [ ] **P3.6 — DPS et instrumentation**
  - [ ] Attribuer un identifiant source aux dégâts d’une arme prototype.
  - [ ] Afficher le total et le DPS sur une fenêtre explicitement nommée.
  - [ ] Vérifier séparément critique, DoT et dégâts d’évolution.
- [ ] **P3.7 — Décisions et checkpoint**
  - [ ] Comparer le contrat aux ADR acceptés et proposer une mise à jour ADR-014 si nécessaire.
  - [ ] Garder ADR-015/016 au statut proposé tant que leur contenu n’est pas décidé.
  - [ ] Exécuter les scénarios Sandbox des trois paires avant de clore le prototype.

**Critère de sortie :** les trois paires prototypes respectent les comportements validés et passent par les mêmes règles partagées Sandbox/Survival.

## P4 — Vertical slice du mode Survival

**Intention :** compléter un parcours de run classique de 24 vagues qui prouve la boucle de jeu, sans prétendre que l’équilibre ou le contenu final sont achevés.

### État constaté

- Présent : entrée Survival, déplacement clavier/manette, HP decay, dégâts de contact/invulnérabilité, HP/XP/HUD, orbes XP, chests en monde, modal trois choix, loadout et écran de résultat.
- Le directeur déroule 24 vagues de 30 s et s’arrête aux transitions mid-boss/final boss.
- Les boss sont des placeholders avec HP et transitions, pas des combats en phases.
- La QA historique décrit une run accélérée et un parcours à durée simulée nominale, avec HP joueur renforcés et traitement harness. Ce n’est pas une preuve de run équilibrée ni de difficulté normale.
- Le joueur choisit parmi deux armes codées en dur ; le choix du pool est encore **[PROPOSÉ]**.

### Travaux

- [ ] **P4.1 — Démarrage de run**
  - [ ] Vérifier l’entrée Survival et le choix entre les deux armes affichées.
  - [ ] Parcourir choix et validation au clavier, flèches et manette.
  - [ ] Confirmer le loadout et le HUD au début de run.
- [ ] **P4.2 — Boucle d’une vague**
  - [ ] Jouer une vague sans harness et vérifier le timer de 30 secondes simulées.
  - [ ] Vérifier spawn, déplacement ennemi, dégâts, XP, soins et mort du joueur.
  - [x] Smoke ciblé sous Godot : 20 secondes de simulation en Normal, immobile avec l’arme de départ, XP/coffres hors de portée; le joueur combat et subit des dégâts avant toute amélioration. Cela ne remplace pas le parcours sans harness ni l’équilibrage complet.
  - [ ] Vérifier les pauses de menu/chest et la reprise de l’horloge attendue.
- [ ] **P4.3 — Coffres**
  - [ ] Vérifier drop, rayon de collecte, modal à trois choix et reprise.
  - [ ] Vérifier inventaire plein et aucune option éligible.
  - [ ] Vérifier qu’un choix de niveau 5/relique déclenche l’évolution requise.
- [ ] **P4.4 — Mid-boss**
  - [ ] Faire apparaître le mid-boss à la vague 12.
  - [ ] Vérifier pause du timer, HP affichés et reprise après sa mort.
  - [ ] Implémenter et vérifier des phases lisibles sans figer les patterns proposés.
- [ ] **P4.5 — Boss final et résultats**
  - [ ] Faire apparaître le boss final à la vague 24.
  - [ ] Vérifier la victoire après défaite du boss et traitement des coffres garantis.
  - [ ] Vérifier RUN OVER par mort, écran de résultat et redémarrage local.
- [ ] **P4.6 — Horloges/XP/récompenses**
  - [ ] Vérifier HP decay actif en gameplay et suspendu pendant vraies pauses.
  - [ ] Isoler la règle de gain d’XP et garder sa courbe au statut proposé jusqu’à décision.
  - [ ] Vérifier qu’un `run_id` ne crédite pas deux fois les gains persistants.
- [ ] **P4.7 — Checkpoint vertical slice**
  - [ ] Jouer une run complète sans hausse forcée de HP ni actions automatiques de harness.
  - [ ] Relancer les smokes ciblés Survival, chests, résultat et contrôles.
  - [ ] Consigner les limites d’équilibrage et les bugs restant ouverts.

**Critère de sortie :** Survival se joue bout en bout avec règles lisibles et transitions cohérentes. Une run harness ne ferme pas les critères de balancing.

## P5 — Contenu de combat v1.6 : armes, reliques, ennemis et boss

**Intention :** atteindre la quantité et la variété du GDD. Le code actuel contient dix prototypes de paires ; P5 n’est donc pas livré.

### P5.1 — Catalogue de dix armes et onze reliques

Catalogue d’évolution défini dans le GDD :

| Arme | Relique associée | Évolution | État au code-audit |
|---|---|---|---|
| Lightning Conductor | Storm Core | Infinite Circuit | Prototype présent ; QA historique ciblée. |
| Inferno Sprayer | Infernal Heart | Wildfire | Prototype présent ; QA historique ciblée. |
| Crimson Daggers | Blood Chalice | Bloodstorm | Dagues orbitantes natives autour du joueur, percent chaque cible au plus une fois ; Bloodstorm ajoute Bleed et une durée plus longue. Rayon, vitesse angulaire et durées **[PROPOSÉS]**. |
| Void Orb | Singularity | Event Horizon | Prototype d’orbe lente perçante; champ d’attraction natif. Les valeurs d’attaque, durée, rayon et force sont **[PROPOSÉES]**. |
| Frost Nova | Frozen Crown | Absolute Zero | Prototype présent : onde circulaire de dégâts et Chill natif ralentissant les ennemis ; Absolute Zero améliore les dégâts reçus sur cibles gelées et produit un shatter de zone à leur mort. Valeurs **[PROPOSÉES]** configurables. |
| Minigun | Overdrive Engine | Redline | Prototype ajouté : tirs mono-cible, progression de cadence proposée, Redline accélère en continu ; valeurs configurables et **[PROPOSÉES]**. QA smoke ciblée. |
| Meteor Staff | Celestial Eye | Starfall | Prototype présent : tir sur groupe et explosion bornée ; Celestial Eye augmente les zones et peut doubler l'impact au niveau 5 ; Starfall envoie 2 fragments par défaut (maximum configurable 8) vers des cibles proches. Tous les réglages **[PROPOSÉS]**. |
| Sawblades | Magnetic Coil | Razorstorm | Prototype présent : lames natives ricochets sur cibles vivantes non déjà touchées ; dégâts, cadence, vitesse et nombre de rebonds **[PROPOSÉS]**. Magnetic Coil augmente la vitesse des projectiles, bonus linéaire **[PROPOSÉ]** ; Razorstorm ajoute un rebond. Effets d'homing et feedback par niveau restent à faire. |
| Toxic Cloud | Plague Mask | Pandemic | Le projectile devient un champ visuel persistant après impact et empoisonne les nouvelles cibles ; Pandemic transmet le DoT à la mort vers 3 cibles au plus. La durée/rayon restent **[PROPOSÉS]** et les statuts multiples **[OUVERTS]**. |
| Prism Laser | Prism Crystal | Spectrum Collapse | Prototype de rayon continu sur cible prioritaire ; l’évolution ajoute des faisceaux secondaires distincts. Cadence, dégâts, progression et bonus **[PROPOSÉS]**. |
| — | Magnet Heart (relique utilitaire) | Aucune | Disponible ; rayon XP augmenté avec valeur **[PROPOSÉE]** configurable ; autres pickups et impulsion absents. |

Travail requis :

- [x] **P5.1.1 — Définitions catalogue** — les dix armes et leurs dix reliques associées, plus Magnet Heart sans paire, sont définies et les relations sont vérifiées au chargement.
- [x] **P5.1.2 — Schéma et activation** — JSON Schema draft 2020-12 formalisé dans `game/data/combat_catalog.schema.json`; le chargeur runtime rejette types, champs et références d’évolution invalides, vérifie les associations arme/relique et n’expose que les entrées marquées disponibles. Les dix prototypes actuels et Magnet Heart sont exposés ; chaque nouveau prototype doit être activé explicitement.
- [x] **P5.1.3 — Minigun + Overdrive Engine → Redline (prototype)** — tir automatique, bonus de cadence Overdrive linéaire et cadence Redline croissante en tir continu ; chiffres de départ configurables et **[PROPOSÉS]**.
- [x] **P5.1.4 — Toxic Cloud + Plague Mask → Pandemic (prototype)** — l’impact applique le DoT partagé et transforme le projectile en champ persistant qui empoisonne une fois chaque cible entrante ; le champ est visible et sa capture/restauration est couverte. Pandemic transmet toujours le poison à la mort (3 cibles maximum). Rayon, durée totale du projectile et application unique par cible **[PROPOSÉS]** ; statuts simultanés **[OUVERTS]**.
- [x] **P5.1.5 — Sawblades + Magnetic Coil → Razorstorm (prototype)** — projectile natif ricoche vers des ennemis vivants non encore touchés ; Magnetic Coil augmente la vitesse des projectiles et l’évolution ajoute un rebond. Valeurs **[PROPOSÉES]**.
- [x] **P5.1.6 — Meteor Staff + Celestial Eye → Starfall (prototype)** — l'attaque vise un groupe et inflige des dégâts d'explosion ; Starfall lance deux fragments par défaut, avec maximum configurable de huit, vers les cibles proches. Bonus de zone, chance de double impact et valeurs de dégâts **[PROPOSÉS]**.
- [x] **P5.1.7 — Prism Laser + Prism Crystal → Spectrum Collapse (prototype)** — rayon visuel suit la cible prioritaire et dégâts répétés passent par les projectiles natifs ; l'évolution ajoute jusqu'à deux cibles secondaires configurables. Bonus de critique et valeurs d'attaque/progression **[PROPOSÉS]**.
- [x] **P5.1.8 — Void Orb + Singularity → Event Horizon (prototype)** — projectiles lents persistants traversent des cibles distinctes et les attirent dans un champ natif borné ; Event Horizon augmente le rayon et la force. Réglages **[PROPOSÉS]**.
- [x] **P5.1.8 — Crimson Daggers + Blood Chalice → Bloodstorm (prototype)** — dagues natives orbitantes centrées sur le joueur et perçantes ; Bloodstorm ajoute Bleed et prolonge leur présence. Rayon 30, vitesse angulaire 5 rad/s, durées 0,8/2,4 s **[PROPOSÉS]** ; mouvement et capture/restauration couverts par `simulation_core`, contact et Bleed par `survival_weapon_catalog_smoke`.
- [x] **P5.1.9 — Frost Nova + Frozen Crown → Absolute Zero (prototype)** — pulsation de zone avec Chill natif (durée, ralentissement et vulnérabilité) ; Absolute Zero produit un shatter borné quand une cible gelée meurt. Le statut est inclus dans les snapshots et le drapeau d'événement ; aucune réaction élémentaire n'est activée. Tous les chiffres sont **[PROPOSÉS]** et configurables.
- [x] **P5.1.9 — Feedback Minigun/Toxic Cloud/Sawblades/Meteor Staff/Prism/Void Orb** — vérifié par `survival_weapon_catalog_smoke.gd`, `survival_hud_smoke.gd` et `render_batching_smoke.gd` : projectiles distincts présents ; l’anneau intérieur animé du nuage Pandemic suit le temps de simulation et se fige en pause (**[PROPOSÉ]**, période 1,2 s) ; le HUD affiche niveau et EVO pour les dix armes ; les impacts dédiés grandissent de 6 % par niveau (**[PROPOSÉ]**) ; Redline a un lot distinct avec silhouette Minigun teintée rouge néon (**[PROPOSÉ]**).
- [x] **P5.1.10 — Ciblage des armes**
  - [x] Documenter le ciblage actuellement codé avant le comportement visuel : Lightning choisit comme première cible le membre le plus proche du joueur dans la grappe vivante la plus dense à portée, puis chaîne vers les cibles distinctes les plus proches (**[PROPOSÉ]**) ; Inferno vise la plus haute menace dans sa portée et départage à égalité par la proximité (**[PROPOSÉ]**) ; Toxic vise l’ennemi vivant aux PV les plus élevés et départage à égalité par la proximité (**[PROPOSÉ]**) ; Crimson vise l’ennemi vivant aux PV les plus faibles dans sa portée et départage à égalité par la proximité (**[PROPOSÉ]**) ; Void choisit l’ennemi vivant le plus éloigné dans sa portée (**[PROPOSÉ]**) et applique ensuite sa règle native ; Sawblades choisit la cible accessible qui ouvre la grappe la plus dense dans le rayon de rebond, départagée par la proximité, puis retombe sur la cible la plus proche si aucune grappe n’existe (**[PROPOSÉ]**) ; Minigun acquiert la cible vivante la plus proche et la conserve jusqu’à sa mort ou sa sortie de portée (**[PROPOSÉ]**) ; Meteor vise le membre le plus proche du joueur dans le groupe vivant le plus dense et dirige l’explosion vers le centroïde de ce groupe (**[PROPOSÉ]**) ; Prism vise la cible la plus proche du joueur dans le groupe vivant le plus dense, puis centre ses faisceaux secondaires autour d’elle (**[PROPOSÉ]**) ; Frost est une zone centrée sur le joueur sans cible visée.
  - [x] Satisfaire le critère **[VALIDÉ]** de ciblage propre aux dix armes : Lightning (grappe chainable), Inferno (menace max), Crimson (PV min), Void (plus lointaine), Frost (zone centrée joueur), Minigun (plus proche avec verrou), Meteor (centroïde de groupe), Sawblades (rebond vers grappe), Toxic (PV max) et Prism (PV max dans la grappe dense). Ces règles de prototype sont **[PROPOSÉES]**; leurs valeurs et leur efficacité comparative restent **[OUVERTES]**.
  - [x] Implémenter un prototype par politique réutilisable et exposer ses cibles dans Sandbox. Les neuf configurations nearest, farthest, highest threat, highest HP, lowest HP et les quatre variantes spécialisées sont partagées avec le Sandbox; sa sonde règle portée et rayon de grappe et affiche la cible/centroïde. Ces règles restent **[PROPOSÉES]**.
  - [x] Vérifier les armes orbitantes et longue portée avec placements différents. `survival_weapon_catalog_smoke.gd` couvre le ciblage faible PV des Crimson Daggers, Void Orb, Minigun, Lightning, Sawblades, Meteor et Prism; les sélecteurs ignorent les cibles mortes encore présentes dans le snapshot.
  - [x] Réduire uniformément les portées de ciblage par `180/620` (−71 %) afin que les cibles primaires restent dans le rayon visible de l’écran; borner aussi les bonus de portée, Frost Nova, les faisceaux Prism et les rebonds Lightning. Les réglages Sandbox restent indépendants.
- [x] **P5.1.11 — Niveaux et feedback des autres armes** — les niveaux 2–5 des dix armes suivent les valeurs proposées chargées par arme depuis `game/data/weapon_progression.json`; dégâts, bonus de niveau, feedback HUD et rendu sont couverts par les smokes ciblés ci-dessous.
  - [x] Inferno applique les effets proposés des niveaux 2–5 : +20 % dégâts directs, +15 % portée (plafonnée au rayon visible), +20 % largeur de jet et +25 % dégâts de Burn. Le smoke vérifie la cible permise par le bonus de portée, les dégâts/largeur du projectile et le DoT niveau 5; ces chiffres restent **[PROPOSÉS]**.
  - [x] Crimson Daggers applique les effets proposés : +20 % dégâts au niveau 2, une troisième dague au niveau 3, +20 % de vitesse orbitale au niveau 4 et +25 % de dégâts au niveau 5. Bloodstorm conserve ces bonus; le smoke vérifie le nombre, les dégâts et la vitesse orbitale via le snapshot. Chiffres **[PROPOSÉS]**.
  - [x] Lightning Conductor applique les effets proposés : +20 % dégâts au niveau 2, un rebond au niveau 3, −15 % de cooldown au niveau 4 et +25 % dégâts au niveau 5. Le smoke vérifie dégâts, rebonds disponibles et délai entre tirs; chiffres **[PROPOSÉS]**.
  - [x] Void Orb applique les effets proposés : +20 % dégâts au niveau 2, +20 % rayon d’attraction au niveau 3, +15 % durée au niveau 4 et +25 % force au niveau 5. Le niveau 1 ne reçoit plus ce bonus anticipé; le smoke vérifie dégâts, rayon, durée et force. Chiffres **[PROPOSÉS]**.
  - [x] Prism Laser applique les effets proposés : +20 % dégâts au niveau 2, +20 % portée au niveau 3, +15 % vitesse de suivi visuel du faisceau au niveau 4 et +25 % dégâts au niveau 5. Le dernier effet est interprété comme une vitesse de suivi en unités/s, les projectiles gardent leur cadence et leur vitesse propres. Smoke dégâts/portée/suivi; chiffres et interprétation **[PROPOSÉS]**.
  - [x] Ajouter un feedback HUD à l’acquisition et à chaque niveau gagné sur arme/relique; toast lié au temps de simulation et figé en pause.
  - [x] Les impacts dédiés des dix armes reprennent le niveau de leur arme et grossissent de 6 % par niveau, sans changer dégâts, collision ou cadence (**[PROPOSÉ]**).
  - [x] Les onze reliques appliquent leur bonus de stat globale à chacun des cinq niveaux; `survival_weapon_catalog_smoke.gd` vérifie l’accumulation par niveau. Les valeurs restent **[PROPOSÉES]** et ne sont pas déclarées équilibrées.
  - [x] Les dix évolutions changent le rendu du projectile : les neuf formes dédiées sont routées vers leur sprite et Redline conserve la silhouette Minigun avec une teinte rouge néon (**[PROPOSÉ]**); smokes `render_batching_smoke.gd` et `survival_weapon_catalog_smoke.gd`.
  - [x] Les offres de niveau 5 nomment également leur effet numérique et l’évolution requise pour Minigun, Toxic Cloud, Sawblades, Meteor Staff et Frost Nova; vérifié dans `survival_loadout_smoke.gd`.
- [x] **P5.1.12 — Règle d’évolution/catalogue**
  - [x] L’évolution définie au catalogue est proposée après le niveau 5 de l’arme et de sa relique; `survival_weapon_catalog_smoke.gd` vérifie les deux ordres d’acquisition pour les dix paires.
  - [x] L’offre d’évolution n’applique que le bonus de dégâts de l’arme correspondante (**[PROPOSÉ]**, +25 %); aucune hausse avant collecte, aucun bonus sur les neuf autres armes.
  - [x] Vérifier conservation des niveaux 5, non-consommation de la relique, offre unique et impossibilité de reprendre une arme ou évolution déjà au maximum.
- [ ] **P5.1.13 — Magnet Heart et pickups**
  - [x] Ajouter Magnet Heart comme relique utilitaire sans évolution et l'inclure dans les offres Survival.
  - [x] Appliquer le bonus de rayon **[PROPOSÉ]** configurable de 25 % par niveau aux orbes XP.
  - [x] Vérifier orbe XP et chest séparément : le bonus n'élargit jamais le rayon du chest.
  - [x] Au niveau 5, déclencher une impulsion **[PROPOSÉE]** de 20 s à 300 % du rayon XP, visualisée par un anneau; la durée suit l'horloge de simulation et gèle en pause, sans déplacer/téléporter les objets.
  - [ ] Étendre l'attraction aux soins, ressources, monnaies et bonus temporaires lorsqu'ils existent.
- [ ] **P5.1.14 — Slots et effets de capacité**
  - [x] Vérifier cinq slots de reliques en run normale ; `survival_loadout_smoke.gd` couvre cinq reliques distinctes, refuse une sixième et ne propose plus de nouvel item quand les slots sont pleins.
  - [x] Tester l’extension Legendary/Mythic avec `expanded_loadout` équipé : +1 arme et +1 relique, plafond six, doublons dédupliqués; contrat et valeurs restent **[PROPOSÉS]** dans `EFFETS_UNIQUES_P6.md`. Couvert par `survival_unique_effects_smoke.gd` et `survival_loadout_smoke.gd`.
  - [x] Vérifier l’absence de cumul automatique d’un même effet unique actif ; `progression_service_smoke.gd` équipe deux items Legendary avec `overflow_shield` et vérifie que l’effet n’est exposé qu’une fois.
- [ ] **P5.1.15 — Statut du balancing**
  - [x] Charger les multiplicateurs, ajouts et valeurs par palier depuis `game/data/weapon_progression.json`; le chargement valide version, dix IDs, niveaux 1–5 et valeurs finies/positives, et échoue visiblement si la configuration est invalide.
  - [x] Garder les valeurs marquées **[PROPOSÉES]** jusqu’à leur décision formelle; `survival_weapon_catalog_smoke.gd` vérifie aussi qu’une valeur modifiée dans la configuration change le résultat calculé.

### P5.2 — Statuts et synergies

- [ ] **P5.2.1 — Contrats de statut**
  - [x] Lister les statuts implémentés pour les paires : Burn (Inferno/Wildfire), Poison (Toxic/Pandemic), Bleed (Bloodstorm) et Chill (Frost/Absolute Zero). Les paires sans statut restent sans effet inventé.
  - [x] Vérifier la durée, le tick, le remplacement et l’affichage des DoT : le DoT existant est remplacé, son identité et ses horloges sont publiées dans le snapshot, et un anneau dédié l’indique en Survival. L’empilement simultané reste **[OUVERT]**. Les paramètres chiffrés demeurent **[PROPOSÉS]**.
  - [x] Vérifier application, expiration et exclusion des cibles mortes avant connexion aux armes.
- [x] **P5.2.2 — Synergies émergentes**
  - [x] Les chemins existants consomment les événements standards : lifesteal sur damage, contagion Pandemic sur dégâts/statut et mort, Absolute Zero sur mort d’une cible Chill, fragments Starfall sur impact et chaînes Lightning sur dégâts. Les événements DoT portent maintenant leur identité jusqu’au damage/death.
  - [x] Vérifier que ces comportements utilisent les contrats d’évolution/statut existants; aucune réaction élémentaire proposée n’est activée. Les évolutions et paramètres de prototype gardent leur statut **[PROPOSÉ]** là où le GDD ne les valide pas.
- [ ] **P5.2.3 — Réactions proposées**
  - [x] Garder Thermal Shock, Toxic Ignition, Shatter, Electroplague, Gravity Collapse et Hemorrhage désactivées tant que non validées.
  - [ ] Faire arbitrer chaque réaction avant son implémentation.
  - [x] Garder Overcharge bloquée par son statut **[OUVERT]**.
- [ ] **P5.2.4 — Causalité et dégâts**
  - [ ] Ajouter un ID de chaîne et un budget aux réactions seulement après validation du contrat.
  - [x] Vérifier événements directs, DoT létal, lifesteal, mort et attribution XP sans double crédit; `survival_damage_causality_smoke.gd` compte une seule mort/orbe XP par cible directe et DoT, et `survival_lifesteal_smoke.gd` couvre le soin.

### P5.3 — Coffres et économie de run

- [ ] **P5.3.1 — Éligibilité des offres**
  - [x] Produire trois choix distincts quand au moins trois choix existent ; test ciblé des armes niveau max, slots pleins et absence de choix éligibles.
  - [x] Ajouter la préférence synergie comme poids multiplicatifs et tirage pondéré sans remise; tous les poids restent strictement positifs et aucune offre éligible n’est supprimée.
  - [x] Vérifier objets niveau max, slots pleins et arme niveau 5 sans relique. La relique garde ses offres même lorsque l’arme est niveau 5.
  - Les poids par défaut du GDD (**[PROPOSÉS]**) sont configurables dans Survival : amélioration possédée ×1,5, relique liée à une arme possédée ×2, arme liée à une relique possédée ×1,5, évolution prête/proche ×1,25, plafond combiné ×3. « Proche » signifie ici que le choix amène les deux membres d’une paire non évoluée au niveau 4 ou plus; cette interprétation reste **[PROPOSÉE]**.
- [ ] **P5.3.2 — Pause et reprise**
  - [x] Suspendre la simulation et vérifier que ses horloges ne progressent pas pendant le modal; `survival_chest_smoke.gd` contrôle aussi l’horloge active affichée.
  - [x] Vérifier la reprise après sélection et le rejet d’une liste/sélection invalide dans `survival_chest_smoke.gd`; un choix invalide conserve le modal et la pause. `survival_pause_inventory_smoke.gd` confirme le retour vers le menu Pause, le focus et la simulation toujours figée.
- [ ] **P5.3.3 — Évolution post-choix**
  - [x] Pour les dix paires, vérifier qu’une arme nouvellement acquise au niveau 1 n’offre pas l’évolution même si sa relique est déjà niveau 5; l’offre apparaît au niveau 5 de l’arme.
  - [x] Vérifier l’offre après chaque chemin de niveaux de l’arme, et après acquisition/amélioration de la relique jusqu’au niveau 5.
  - [x] Ouvrir un vrai coffre d’arme, afficher l’unique évolution devenue éligible et la collecter; `survival_weapon_catalog_smoke.gd` vérifie que le combo s’active après cette collecte.
- [ ] **P5.3.4 — Probabilités**
  - [x] Garder les taux de drop, le filet anti-malchance et les poids d’offres accessibles en configuration; `survival_chest_director_smoke.gd` et `survival_loadout_smoke.gd` couvrent ces paramètres.
  - [x] Intégrer `free_first_chest_reroll` au premier coffre de run via P6.5; le comportement reste **[PROPOSÉ]** et est couvert par `free_chest_reroll_smoke.gd`.
  - [ ] Faire arbitrer les valeurs nécessaires avant leur verrouillage; les coefficients restent **[PROPOSÉS]**.
- [ ] **P5.3.5 — Collecte**
  - [x] Préserver le rayon séparé `chest_collection_radius`.
  - [x] Vérifier par régression qu'un pickup très élevé n'attire pas un chest éloigné.
  - [x] Vérifier la collecte à proximité et l'ouverture du choix ; l'interaction manuelle reste facultative selon le GDD.

### P5.4 — Ennemis, élites et boss

**Avancement :** le roster de vague comprend huit familles : Chaser, Sprinter, Tank, Shooter, Buffer, Exploder, Shielder et Summoner. Shooter télégraphie ses tirs ; Buffer augmente de 20 % la vitesse alliée dans son aura de 150 ; Shielder réduit à 65 % les dégâts reçus par les alliés couverts par son aura de 150 ; les deux auras cessent à la mort de leur source. Summoner (42 HP, vitesse 42, menace 2,5) annonce une position de spawn, puis invoque des adds (12 HP, vitesse 90, menace 0,5), avec trois invocations actives globalement au maximum. Les élites génériques (50 HP, menace 3) tirent désormais l’un de six affixes **[PROPOSÉS]** : Hasted (100 px/s), Armored (75 px/s, 65 % des dégâts reçus), Regenerating (1 % des PV max régénéré par seconde simulée), Volatile (explosion de 18 dégâts, rayon 82, sans chaîne), Shielded (anneau visible, 50 % des dégâts reçus) ou Split-on-Death (deux adds soumis à la limite globale). L’affixe est publié dans le snapshot. Le directeur les fait apparaître selon un cooldown, un plafond actif et un budget égal à la population de la vague ; le coût de menace est 3. Il utilise le chemin de récompense élite existant. Le profil **Exploder** (30 HP, vitesse 60, menace 2) s’approche, déclenche un fuse de 0,8 s dans un rayon de 110 et inflige 18 dégâts dans un rayon de 82 ; le cercle de souffle est visible, la pause fige le fuse, et sortir du rayon esquive le souffle. Le Pulse Warden et le Dopamine Core possèdent chacun un prototype d’attaques en trois phases; le Core a un sprite dédié. Les charges mobiles du Warden restent à faire. Les valeurs, rayons, délais, plafonds et chances de spawn de ces prototypes restent **[PROPOSÉS]**.

- [ ] **P5.4.1 — Familles ennemies**
  - [x] Valider les profils Sandbox Chaser (mêlée), Sprinter (rapide, faible HP) et Tank par spawn et snapshots; `simulation_core_test` vérifie steering à la vitesse du profil et mort typée pour chacun. `survival_combat_visual_smoke.gd` vérifie les trois routes de sprites dédiées. Les profils, valeurs et contre-jeu de l’archétype rapide restent **[PROPOSÉS]**.
  - [x] Ajouter une famille distance avec projectile télégraphié.
  - [x] Ajouter un profil de soutien Buffer avec aura de vitesse visible et bornée.
  - [x] Ajouter le prototype Exploder avec fuse et souffle esquivables **[PROPOSÉS]**.
  - [x] Compléter le roster à huit familles et vérifier les profils par scénario Sandbox.
  - [x] Smoke Survival seedé : la vague 20 génère les huit familles du roster avec le chemin de spawn de run et la simulation native; le test vérifie leur présence, pas les probabilités d’équilibrage **[PROPOSÉES]**.
- [ ] **P5.4.2 — Interactions ennemies**
  - [x] Ajouter un buff de soutien visible et borné.
  - [x] Ajouter Shielder : réduction de dégâts bornée dans une aura et retirée à sa mort **[PROPOSÉ]**.
  - [x] Ajouter Summoner avec position télégraphiée et maximum global de trois adds actifs **[PROPOSÉ]**.
  - [x] Tester destruction du soutien et fin de son effet.
- [ ] **P5.4.3 — Élites**
  - [x] Définir la compatibilité du prototype : `elite` accepte Hasted, Armored, Regenerating, Volatile, Shielded et Split-on-Death; les familles ordinaires et les affixes non implémentés sont refusés.
  - [x] Implémenter la sélection aléatoire entre Hasted, Armored, Regenerating, Volatile, Shielded et Split-on-Death sur l’unique famille élite; Hasted passe à 100 px/s, Armored se déplace à 75 px/s et reçoit 65 % des dégâts, Regenerating récupère 1 % de ses PV max par seconde simulée et Volatile explose à sa mort (18 dégâts, rayon 82, sans chaîne), Shielded réduit les dégâts reçus à 50 % avec un anneau visible et Split-on-Death demande deux adds dans la limite globale **[PROPOSÉS]**.
  - [x] Générer le prototype Hasted avec plafond actif et cooldown **[PROPOSÉS]**.
  - [x] Appliquer le budget proposé : somme des menaces actives + coût élite ≤ population cible de la vague.
  - [x] Vérifier affixe visible, profil de vitesse, mort et récompense élite.
- [ ] **P5.4.4 — Mid-boss**
  - [x] Définir les phases proposées et rendre leurs transitions visibles dans le HUD/télégraphes.
  - [x] Implémenter les attaques de phase en tranches testables, dont la charge mobile télégraphiée de phase 3.
  - [x] Vérifier timer de vague suspendu pendant le boss, decay actif, puis reprise des spawns réguliers après la vague 12.
  - Prototype Pulse Warden : phases affichées selon les PV (seuils 66 % / 33 % **[PROPOSÉS]**), salve radiale annoncée en phase 1, alternance tir ciblé/charge avec invocation bornée en phase 2, puis alternance salve radiale/charge en phase 3. La charge trace sa trajectoire, déplace l’entité sous steering natif pendant 0,28 s et reprend ensuite le steering joueur. Les smokes vérifient télégraphie, gel en pause, transitions, invocation, charges des phases 2–3, gel du timer de vague durant les boss, maintien du decay et reprise des spawns réguliers après le mid-boss; patterns et valeurs demeurent **[PROPOSÉS]**.
- [ ] **P5.4.5 — Boss final**
  - [x] Définir et implémenter trois phases selon les PV : rayon puis zone esquivable, spirale tirée en salves successives avec invocation en phase 2, puis rayon/zone combinés avec spirale ; télégraphes et HUD de phase vérifiés. Motifs, seuils, dégâts et cadence **[PROPOSÉS]**.
  - [x] Smoke boss : les phases 2 et 3 saturent le plafond global d’invocations proposé à trois, rejettent les suivantes et réutilisent une place après la mort d’un add.
- [x] Le run accéléré `survival_wave_director_smoke.gd` observe et traite les deux familles de boss jusqu’à la victoire; ce parcours reste assisté et ne ferme pas P5.V3.
  - [x] Remplacer l’apparence placeholder du Core par le sprite dédié `boss_dopamine_core` et vérifier sa route dans le renderer ainsi que PNG/source Aseprite, dimensions et palette.
  - [x] Vérifier par `survival_final_boss_loot_smoke.gd` la défaite du Core, les deux coffres garantis configurables consommés l’un après l’autre, puis l’écran de victoire; la validation en run sans harness reste dans P5.V3.
  - Prototype en cours : le Dopamine Core dispose de trois phases, de rayons/zones télégraphiés et esquivables, d’une spirale en tirs successifs et d’invocations en phases 2–3. Le smoke confirme le plafond d’invocations partagé en phases 2–3 ; son identité visuelle est un prototype dédié, sans validation de canon. Tous ces patterns et nombres restent **[PROPOSÉS]**.
- [ ] **P5.4.6 — Difficultés**
  - [x] Persister la difficulté maximale débloquée (Easy initialement) et transmettre la difficulté choisie du hub à la run.
  - [x] Après une victoire contre le boss de vague 24, débloquer uniquement la difficulté suivante; refuser les récompenses d’une difficulté verrouillée avec `difficulty_locked`. Une défaite ne débloque rien.
  - [x] Vérifier que HP, dégâts ennemis, densité et récompenses utilisent leurs multiplicateurs séparés; les résultats Easy, Normal et Chaos ont un test dédié.
  - [x] Inclure les smokes de profil, d’unlock et de session dans CTest; l’unlock verrouillé vérifie explicitement l’erreur `difficulty_locked`.
  - Les règles de déblocage sont **[VALIDÉES]**; les multiplicateurs du GDD restent **[PROPOSÉS]**.

### Vérification et sortie P5

- [x] **P5.V1 — Validation du catalogue**
  - [x] Exécuter un scénario Sandbox headless par arme via `sandbox_weapon_scenario_runner.gd`. Chaque fixture instancie la vraie session Survival sans `ProgressionService`, équipe une arme/relique en mémoire, déclenche l’attaque de production et vérifie au moins un impact.
  - [x] Valider les dix JSON et rejeter les identifiants d’arme/relique incompatibles, les niveaux hors limite, les positions non finies et les listes de cibles vides; smoke dédié dans `sandbox_weapon_scenario_validation_smoke.gd`.
  - [x] Vérifier relique, niveaux et évolution par paire dans `survival_weapon_catalog_smoke.gd`.
  - [x] Vérifier Magnet Heart avec XP et chest dans `survival_chest_smoke.gd`.
- [x] **P5.V2 — Validation des ennemis**
  - [x] Vérifier le roster des huit familles et faire apparaître chacun des six affixes élite dans le scénario Sandbox `enemy_profiles_smoke.json`; `simulation_core_test` couvre leurs effets natifs.
  - [x] Vérifier les attaques esquivables, réactions bornées et plafonds d’invocation dans `survival_exploder_smoke.gd`, `survival_boss_attack_smoke.gd` et `simulation_core_test`.
  - [x] Parcourir sous smoke les phases du Pulse Warden et du Dopamine Core.
  - [x] Exécuter `survival_elite_smoke.gd` sous Godot 4.7.2 : l’affixe Split-on-Death génère deux adds sous le plafond global.
- [ ] **P5.V3 — Run de bout en bout**
  - [x] Défaite en interface réelle, Easy avec Lightning Conductor, profil `XDG_DATA_HOME` isolé, verrouillage de vie et choix auto désactivés : écran RUN OVER à la vague 2 après 00:45 et 14 éliminations; le panneau a affiché +13 Essence et +18 Basic Powder.
  - [ ] Jouer jusqu’à la victoire en interface réelle, sans harness, HP forcés, choix automatiques ou boss tué par script.
  - [ ] Vérifier en interface réelle le choix d’un coffre, la remise des récompenses et leur idempotence.
- [ ] **P5.V4 — Revue et checkpoint**
  - [x] Consigner les validations et les limites sans changer les statuts de décision du GDD.
  - [x] Relancer la suite CTest complète : 66/66 passent en séquentiel le 2026-10-16 après correction du redémarrage de run. Le benchmark natif sur 500 ennemis/2 000 projectiles mesure la rafale d’impacts avant/après optimisation; résultats et limites consignés dans `docs/qa/TESTS.md`.
  - [x] Corriger l’arc Lightning qui retouchait sa source à courte distance; smoke natif ciblé et catalogue vérifiés, 10 répétitions consécutives puis CTest complet 67/67.
  - [x] Corriger le travail de zone devenu inutile après saturation du budget d’explosions et committer ce checkpoint documenté.
  - [ ] Faire le parcours sans assistance de P5.V3 et réaliser les scénarios d’armes dans le Sandbox avant de clore le jalon.

**Critère de sortie :** dix armes, onze reliques, leurs évolutions, 8–12 familles, élites et boss utilisables dans une run complète ; Sandbox et progression séparés. Après P5, poursuivre P6–P9 selon le goal principal actif.

## P6 — Progression permanente (code anticipé, jalon incomplet)

**Intention :** transformer le prototype de profil v5, équipement, enhancement, arbre et succès en boucle complète et calibrée. L’existence du service ne signifie pas la fermeture du jalon.

### État actuel et écarts

- `SaveService` possède format versionné/checksum/backup et QA historique de migration/altération.
- `ProgressionService` possède des profils v6 avec difficulté maximale débloquée (Easy par défaut), récompenses de run, idempotence par `run_id`, inventaire, six slots, cinq raretés, stat lines, enhancement, conversion Powder, deux nodes de prototype et Exterminator. La règle [VALIDÉE] de déblocage séquentiel après victoire sur le boss de vague 24 est codée; les récompenses d’une difficulté verrouillée sont refusées. Les facteurs de difficulté [PROPOSÉS] sont centralisés et appliqués à la simulation ainsi qu’aux récompenses. Le hub injecte profil et difficulté dans la run; le raccourci Sandbox fonctionne sans service de progression.
- Le générateur choisit les poids de rareté par difficulté et vague, selon une règle **[PROPOSÉE]**; la pénalité de mort précoce et la calibration statistique/équilibrage des plages restent à faire.
- Les achievements ne couvrent qu’un compteur de kills avec quatre paliers ; ce n’est pas le catalogue cible de 100–150 familles.
- Les nodes sont deux prototypes, pas le graphe interconnecté de 100–150.
- Cinq effets uniques ont un chemin gameplay prototype vérifié; `revive_knockback` reste stockable pour préserver les profils existants, mais n’est plus sélectionnable tant que son comportement n’est pas défini. Les chiffres de ces prototypes restent **[PROPOSÉS]**.
- Des bonus de stat sont consommés dans Survival ; `pickup_radius_pct` augmente actuellement le rayon des orbes XP seulement et le chest a son propre rayon.

### Travaux

- [x] **P6.1 — Équipement de run classique**
  - [x] Tester chacun des six slots et le remplacement d’une pièce du même slot.
  - [x] Vérifier qu’une run finie (victoire ou défaite) donne une seule pièce.
  - [x] Vérifier que les lignes d’un objet n’ont pas de statistique dupliquée.
- [ ] **P6.2 — Rareté et rolls**
  - [x] Ajouter difficulté et vague aux entrées du générateur; les poids **[PROPOSÉS]** du GDD sont sélectionnés par difficulté et déplacent 1 point de Normal vers les autres raretés à chaque tranche de six vagues atteintes (jusqu’à quatre points en vague 24).
  - [ ] Implémenter la pénalité de mort précoce après validation des règles.
  - [x] Smoke ciblé vérifie les poids Easy/Chaos, la conservation de la somme à 100 %, l’effet de vague sur le tirage seedé et les poids proposés par difficulté; cela ne constitue pas un calibrage statistique.
  - [x] `equipment_rarity_smoke.gd` vérifie par seed 20 000 tirages sur les cinq difficultés aux vagues 1 et 24 dans une tolérance statistique; les probabilités et la règle de progression restent **[PROPOSÉES]**, non calibrées.
- [ ] **P6.3 — Application des statistiques**
  - [x] `equipment_stats_smoke.gd` équipe une seule stat par profil et ouvre une vraie session Survival pour vérifier l’effet de HP, mobilité, dégâts, cadence, critiques, soin, aire, cooldown, XP, rayon de ramassage et vitesse projectile.
  - [x] `survival_chest_smoke.gd` vérifie l’application du rayon de ramassage aux XP, dont l’impulsion Magnet Heart, puis confirme qu’un grand rayon ne collecte jamais un coffre hors de sa portée dédiée.
- [ ] **P6.4 — Enhancement**
  - [x] `equipment_enhancement_smoke.gd` vérifie une ligne +0..+10 avec Basic, Refined, Pure et Prismatic, y compris le +8 % par niveau.
  - [x] Le smoke vérifie réussite, échec normal, échec critique avec protection au niveau 0, et réussite garantie après neuf échecs.
  - [x] Le smoke vérifie la table proposée de coûts pour chaque rareté/niveau, les conversions 10:1 vers le tier suivant et le refus de conversion depuis Prismatic.
  - [x] Prototype d’économie choisi : vente contre Essence seule (5/10/20/40/80 selon rareté), démantèlement contre Powder seule selon `PROPOSITION_P5.md`; la vente demande confirmation et ne rembourse pas les enhancements. Rendements et chances restent **[PROPOSÉS]**, à calibrer.
  - [x] `equipment_economy_smoke.gd` vérifie les ventes par rareté, l’impossibilité de repayer une pièce supprimée et le rejet d’un `fail_streak` supérieur à 9, garde-fou de la tentative garantie.
- [ ] **P6.5 — Effets uniques**
  - [x] `EFFETS_UNIQUES_P6.md` inventorie les six IDs actifs, leurs prérequis, déclencheurs, portée/limites, feedback et statuts **[PROPOSÉ]**; `revive_knockback` est identifié comme legacy sans gameplay.
  - [x] `survival_unique_effects_smoke.gd` vérifie les prérequis équipés, la portée visible et le cooldown de Lightning Burst, puis le gating par évolution, le feedback et l'activation unique d'Evolution Shockwave; `survival_inventory_smoke.gd`, `survival_elite_smoke.gd` et `free_chest_reroll_smoke.gd` couvrent Overflow Shield, Elite Haste et le reroll.
  - [x] `elite_haste` est chargé depuis un équipement unique équipé, déclenché par la mort d’un élite et actif 3 secondes simulées avec +15 % de mobilité **[PROPOSÉ]**; `survival_elite_smoke.gd` vérifie activation et expiration.
  - [x] `free_first_chest_reroll` relance une fois les options du premier coffre de run sans répéter les choix affichés; le run reste en pause. `free_chest_reroll_smoke.gd` couvre profil équipé, activation clavier, options inédites et absence de bouton aux coffres suivants; comportement **[PROPOSÉ]**.
  - [x] Retirer `revive_knockback` du choix des nouveaux effets sans supprimer la compatibilité de lecture des profils qui le stockent; vérifié par `progression_service_smoke.gd`.
  - [x] Vérifier non-cumul automatique et extensions de capacité réelles : le smoke équipe deux pièces porteuses du même effet, confirme la déduplication et applique six armes/reliques au maximum. Extension **[PROPOSÉE]**.
- [ ] **P6.6 — Skill tree**
  - [ ] Établir le schéma node/prérequis/coût/effet.
  - [ ] Ajouter et tester une tranche de branche à la fois jusqu’à la cible décidée (100–150).
  - [ ] Vérifier coût, déblocages, bonus appliqué et respec gratuit.
  - [ ] Mesurer le bonus cumulatif avant de fermer l’arbre.
- [ ] **P6.7 — Achievements**
  - [x] Établir le schéma JSON métrique/catégorie/secret/agrégation/paliers/récompenses, aligné sur `AchievementDefinition` du GDD.
  - [x] Migrer Exterminator en première famille `combat` chargée depuis `game/data/achievement_catalog.json`; seuils et bonus de l’exemple restent **[PROPOSÉS]**.
  - [ ] Étendre à une famille par catégorie puis vers la cible 100–150; la répartition de catégories reste **[PROPOSÉE]**.
  - [ ] Vérifier seuils, quatre paliers, attribution unique et cumul des bonus.
- [ ] **P6.8 — Sauvegarde et migrations**
  - [x] `progression_service_smoke.gd` couvre une fixture pour chaque profil supporté v1–v5 et vérifie migration vers v6, données conservées et champs ajoutés.
  - [x] Vérifier migration, sauvegarde, backup et restauration après corruption : `save_service_smoke.gd` couvre l’enveloppe générique; `progression_service_smoke.gd` récupère maintenant un profil complet via un nouveau SaveService/ProgressionService et valide ses ressources, runs récompensées et équipements.
  - [x] Vérifier idempotence d’un même `run_id` après recréation du service et rechargement du slot, sans nouveau gain de ressources ni pièce d’équipement.
- [ ] **P6.9 — Calibration**
  - [ ] Collecter des builds sans bonus, moyens et fortement avancés.
  - [ ] Comparer survie/dégâts/temps de run sur chaque difficulté disponible.
  - [ ] Ajuster uniquement les paramètres dont le statut autorise l’équilibrage.

**Critère de sortie :** boucle permanente complète, compréhensible, migrable, idempotente et calibrée sans fuite vers Sandbox.

## P7 — Endless standard et Endless Armorless

### P7A — Armorless (règles centrales validées)

- [ ] **P7A.1 — Règles du mode**
  - [x] Ajouter le choix Armorless au hub et transmettre le mode à la session; le profil reste disponible pour les systèmes autorisés.
  - [x] Désactiver les bonus d'équipement et effets uniques permanents pendant le mode; conserver les bonus déjà acquis du skill tree et des achievements.
  - [x] Vérifier dans `survival_armorless_mode_smoke.gd` que skill tree et achievement mastery gardent leurs bonus actifs.
  - [x] Ajouter au directeur un profil Armorless optionnel : cycle de boss toutes les 12 vagues sans victoire forcée après la vague 24; profil Survival inchangé. La cadence de boss reste une valeur **[PROPOSÉE]** du GDD.
- [ ] **P7A.2 — Draft temporaire**
  - [x] Générer trois propositions indépendantes depuis le pool d'équipement Armorless. Le tableau de rareté et les multiplicateurs de difficulté utilisent les valeurs GDD **[PROPOSÉES]** et restent identifiés comme tels dans le code.
  - [x] Ajouter l’état temporaire de run : accepte trois propositions à slots indépendants (doublons permis), consomme le draft au choix, remplace l'objet temporaire si son slot est déjà occupé et conserve un objet par slot.
  - [x] Ouvrir le draft à chaque transition de vague, suspendre la simulation, appliquer le choix et les stat lines; smoke end-to-end dans `survival_armorless_mode_smoke.gd`.
  - [x] Effacer les objets temporaires en fin de run; vérification automatisée dans `armorless_run_state_smoke.gd` et le smoke end-to-end.
- [ ] **P7A.3 — Flux**
  - [x] Ajouter un solde Flux en mémoire de run et le gain après chaque vague, avec validation et anti-double-crédit. Formule GDD **[PROPOSÉE]**.
  - [x] Améliorer une ligne temporaire avec consommation du coût, progression +8 % par niveau et plafond +10. Coûts et chances restent **[PROPOSÉS]**.
  - [x] Vérifier réussite garantie par pity, échec, échec critique et disparition du Flux en fin de run avec `armorless_run_state_smoke.gd`.
  - [x] Rendre les améliorations temporaires accessibles depuis l'inventaire de pause Armorless; afficher coût/solde, résultat, focus restauré et simulation toujours suspendue.
- [ ] **P7A.4 — Longue durée**
  - [x] Vérifier que le directeur Armorless enchaîne cinq cycles de boss aux vagues 12, 24, 36, 48 et 60 sans terminer la run : `armorless_wave_director_smoke.gd`.
  - [x] Vérifier que le budget de population ne bloque pas les spawns et que la densité suit la difficulté : `survival_wave_spawn_smoke.gd` et `survival_difficulty_session_smoke.gd`.
  - [ ] Vérifier HP decay sans reset, pauses boss et budgets de densité.
  - [ ] Tester plusieurs cycles de boss et scaling proposé.
- [ ] **P7A.5 — Récompenses ouvertes**
  - [ ] Décider quels gains permanents sont attribués à Armorless.
  - [ ] Vérifier qu’aucun équipement permanent n’est accordé avant validation explicite.
- [ ] **P7A.6 — Validation**
  - [ ] Tester une vague, une transition boss, un draft, une amélioration et la mort.
  - [ ] Tester une session longue et l’idempotence des résultats/classements.

### P7B — Endless standard (contrat ouvert)

- [ ] **P7B.1 — Arbitrages avant code**
  - [ ] Décider déblocage et lancement depuis menu.
  - [ ] Décider continuation après vague 24 et état du build/HP.
  - [ ] Décider sortie, records, cadence boss et récompenses.
  - [ ] Donner un statut explicite aux règles de difficulté/scaling.
- [ ] **P7B.2 — Implémentation post-décision**
  - [ ] Ajouter chaque mode d’entrée comme parcours séparé vérifiable.
  - [ ] Tester transition Survival→Endless et lancement menu indépendamment.
  - [ ] Vérifier records et récompenses idempotents.

**Critère de sortie :** Armorless conforme aux règles validées et propositions clairement paramétrées ; Endless standard seulement après arbitrages.

## P8 — Sandbox Lab destiné au joueur

P1 livre le Sandbox développeur et ne remplace pas cette feature produit.

- [ ] **P8.1 — Entrée et contexte isolé**
  - [x] Ajouter l’accès distinct Sandbox Lab au menu avant sélection/création de save; l’entrée `SANDBOX DEV` reste le Sandbox développeur P1.
  - [x] Ajouter `SandboxLabContext` mémoire : il valide le preset, héberge une session Survival sans service de progression/save, désactive vagues/coffres normaux et gèle le HP; il ne crédite aucune progression et remplace un preset seulement en pause.
  - [x] Smoke dédié utilise un `XDG_DATA_HOME` isolé, vérifie le spawn et le stockage local du preset; aucune donnée n’est écrite sous `user://saves`.
- [ ] **P8.2 — Build et configuration**
  - [x] Ajouter `SandboxBuild` comme modèle isolé : armes/reliques, évolutions appariées, stats personnalisées finies et équipements de test; validation atomique avant remplacement.
  - [x] Ajouter un éditeur JSON initial et appliquer armes/reliques (niveaux 1–5), évolutions appariées, équipements et stats personnalisées à la session de combat existante.
  - [ ] Ajouter des contrôles visuels par objet/stat et overrides LIVE/REBUILD/RESTART; niveaux au-delà de 5 restent à implémenter dans le combat.
  - [ ] Ajouter overrides LIVE d’un paramètre à la fois.
  - [ ] Ajouter overrides REBUILD/RESTART avec validation atomique.
- [ ] **P8.3 — Presets et share codes**
  - [x] Ajouter `sandbox_preset_service.gd` : schéma version 1 fermé, exemple minimal et modes Survival/Endless/Armorless.
  - [x] Exporter/importer JSON limité à 1 Mio et refuser champs inconnus, types et métadonnées invalides.
  - [x] Ajouter `DSLAB1:` avec DEFLATE, Base64URL, SHA-256 d’intégrité et décompression plafonnée; smoke de round-trip et corruption.
  - [x] Borner récursivement profondeur (16), collections (256 éléments chacune) et types JSON autorisés; tests hostiles ciblés.
  - [x] Ajouter `SandboxPresetStore` pour sauvegarder, lister, charger et supprimer les presets sous `user://sandbox/presets`; noms bornés et écriture temporaire validée.
  - [x] Brancher les actions preset/share code à l’écran Lab; ajouter l’import JSON par sélecteur de fichier avec validation bornée avant application et l’export JSON par sélecteur de destination.
  - [ ] Vérifier absence de script, chemin local et donnée privée.
- [ ] **P8.4 — Import de sauvegarde**
  - [ ] Lire un profil normal en lecture seule.
  - [ ] Construire une copie Sandbox modifiable.
  - [ ] Comparer la sauvegarde source avant/après et tester import invalide.
- [ ] **P8.5 — Outils de simulation**
  - [x] Ajouter God Mode commutable qui ne verrouille que le HP de la session Lab isolée; Survival normal n’est pas modifié.
  - [x] Première tranche UI ajoute pause, vitesse, spawn d’ennemis, kill all, clear projectiles et reset à la session de combat isolée.
  - [ ] Ajouter reset cooldowns, commandes de vague et God Mode persistant à travers les imports de preset.
  - [ ] Ajouter logs RNG et DPS par fenêtre/source.
- [ ] **P8.6 — Snapshots**
  - [ ] Lister l’état minimal à capturer, y compris RNG, clocks, queues et build.
  - [ ] Capturer puis restaurer sans perte sur une scène simple.
  - [ ] Vérifier reprise avec commandes en attente et version incompatible.
  - [ ] Documenter les limites de déterminisme.
- [ ] **P8.7 — Limites et sécurité**
  - [ ] Mesurer les ressources d’une commande extrême.
  - [ ] Ajouter avertissement puis hard cap pour chaque ressource retenue.
  - [ ] Tester qu’un preset hostile n’exécute aucune action ni accès fichier arbitraire.
- [ ] **P8.8 — Validation d’isolation**
  - [ ] Vérifier absence d’Essence/Powder, achievements officiels et leaderboard.
  - [ ] Tester import, partage, snapshot et reset sans modifier une save normale.

**Critère de sortie :** expérimentations librement configurables, persistables/partageables et isolées de la progression normale.

## P9 — Équilibrage, accessibilité, polish et livraison

- [ ] **P9.1 — Équilibrage combat**
  - [ ] Collecter DPS/survie par arme et archétype sur une configuration documentée.
  - [ ] Comparer les dix armes et leurs évolutions sur scénarios équivalents.
  - [ ] Ajuster les valeurs proposées via données de balance, pas par changements cachés.
- [ ] **P9.2 — Économie et durée**
  - [ ] Mesurer durée réelle d’une run et fréquence de choix chest.
  - [ ] Mesurer Essence/Powder et progression de profils de niveaux différents.
  - [ ] Vérifier paramètres de soin/decay/lifesteal en modes retenus.
- [ ] **P9.3 — Présentation audiovisuelle**
  - [ ] Vérifier feedback des dégâts directs/critique/statut.
  - [ ] Vérifier télégraphes au milieu d’effets chargés.
  - [ ] Ajouter options de réduction VFX et régler audio par vague/boss.
  - [ ] Remplacer progressivement les assets placeholders, un lot visuel par lot.
- [ ] **P9.4 — Accessibilité et commandes**
  - [ ] Parcourir menus et choix uniquement au clavier.
  - [ ] Parcourir les mêmes écrans à la manette avec focus visible.
  - [ ] Vérifier contraste, taille/hiérarchie HUD et réglages d’effets.
- [ ] **P9.5 — Performance**
  - [ ] Fixer le matériel iGPU de référence et la scène de charge.
  - [ ] Mesurer frame-time CPU/GPU, mémoire, P50/P95/P99.
  - [ ] Refaire les mesures après optimisations et archiver la configuration.
- [ ] **P9.6 — Stabilité/saves**
  - [ ] Faire un soak test de run et de Sandbox.
  - [ ] Tester sauvegarde interrompue, backup, restauration et migrations.
  - [ ] Vérifier double récompense et clôture propre des threads.
- [ ] **P9.7 — Plateformes**
  - [ ] Refaire build Linux propre sur machine propre.
  - [ ] Refaire build Windows propre et lancer la GDExtension.
  - [ ] Tester contrôles, chemins et rendu sur les deux plateformes.
- [ ] **P9.8 — Préparation de livraison**
  - [ ] Établir checklist release et versions d’artefacts.
  - [ ] Vérifier contenu, dépendances, licences, sauvegarde et notes de version.
  - [ ] Préparer publication après validation des critères, sans la confondre avec un build local.

**Critère de sortie :** critères de contenu, stabilité, performance, plateformes et QA mesurés, datés et approuvés.

## Registre des décisions et pièges d’implémentation

- Les dix armes + Magnet Heart font onze reliques au total : dix reliques associées et une utilitaire. Cinq slots normaux sont une capacité, pas une taille de catalogue.
- Les exceptions de capacité Legendary/Mythic v1.5 ne s’activent que si l’effet correspondant fonctionne et suit sa règle de non-cumul.
- Les réactions entre statuts ne sont pas une autorisation d’implémenter les exemples nommés : ces exemples restent **[PROPOSÉS]** ; Overcharge est **[OUVERT]**.
- Les valeurs de progression, poids de loot, chances et patterns des boss demeurent proposés/ouverts tant que les docs ne disent pas explicitement le contraire.
- Le coffre doit rester hors de tout rayon d’attraction et de collecte de pickup ; code actuel sépare rayon chest et XP. Régression à protéger dès qu’un autre collectible apparaît.
- Le Prototype P6 existant est anticipé : il ne prouve pas que P5 ou P6 est achevé.
- Les coches QA historiques sont datées ; absence d’outil dans l’environnement empêche de les revalider à chaque audit documentaire.
- Les statuts des ADR existants restent intacts. ADR-015 à ADR-018 dans les documents de travail restent des propositions jusqu’à décision formelle.

## Méthode d’avancement

1. Choisir une tranche petite, ordonnée par les dépendances ci-dessus ; ne pas commencer un travail dépendant d’un **[OUVERT]** avant l’arbitrage nécessaire.
2. Définir critères d’acceptation, fichiers/systèmes concernés et vérification avant de coder.
3. Faire une vérification ciblée après chaque tranche ; lancer la batterie plus large aux checkpoints P3/P4/P5/P6/P7/P8/P9.
4. Indiquer séparément code écrit, test exécuté, environnement et date ; ne pas cocher sur la seule présence de code.
5. Revoir les docs de contrat dès qu’une interface ou décision change.
6. Faire un commit explicite à chaque tranche cohérente et pousser sur `origin` selon `AGENTS.md` lorsque la remote est disponible.

## Références

- [GDD v1.6](../gdd/GDD_v1.6.md) et [index des versions historiques](../gdd/archive/VERSIONS.md)
- [Architecture](../architecture/ARCHITECTURE.md), [interfaces natives/Godot](../architecture/INTERFACES.md), [dépendances](../architecture/DEPENDANCES_ET_DEPOT.md)
- [Registre ADR](../adr/README.md), [tests d’acceptation](../qa/TESTS.md), [performance](../qa/PERFORMANCE.md), [risques](RISQUES.md)
- [Plan d’implémentation](../../tasks/plan.md), [suivi du goal](../../tasks/todo.md)
