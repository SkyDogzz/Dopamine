# Roadmap complète — Dopamine Survivor, GDD v1.6

Cette roadmap transforme le [GDD consolidé v1.6](../gdd/GDD_v1.6.md), l’architecture, les ADR et les documents QA en travaux ordonnés et vérifiables. Elle décrit l’état constaté dans le dépôt au 2026-10-17 ainsi que le chemin restant. Elle ne remplace pas les décisions de ces documents.

**Ordre de travail :** Linux-first ; Sandbox développeur MVP d’abord ; Survival jouable ensuite. Le module UI **PHUB — Run Stat Hub** est une tranche indépendante déjà priorisée après le HUD Survival et peut être implémentée avant la clôture des jalons P5/P6. Pour les jalons de contenu et progression, garder le contenu P5 avant la progression P6. Le cœur de simulation est partagé, mais la progression et les sauvegardes normales restent inaccessibles au Sandbox. Le goal principal actif couvre les jalons P5 à P9.

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
| P5 Contenu v1.6 | **Contenu et prototypes intégrés; checkpoint ouvert** | Les dix paires, leurs prototypes d’évolution et les huit familles/boss sont présentes; les trois mutations Chaos supplémentaires sont implémentées et couvertes par smokes. Restent la calibration représentative, run Chaos ressentie et profilage sur iGPU cible. Le stress test concentré dépasse le budget d’une frame et ne représente pas une vague. |
| P6 Progression permanente | **Boucle fonctionnelle implémentée; calibration incomplète** | Équipement, économie prototype, 100 nodes, 100 familles d’achievements, récompenses et migrations sont implémentés et couverts par smokes. Restent les décisions économiques ouvertes et la calibration représentative des profils et budgets de puissance. |
| P7 Modes Endless | **Prototypes Armorless et Endless standard fonctionnels; validation incomplète** | Armorless possède drafts, Flux, récompenses et records; une run complète non assistée et la calibration des formules proposées restent requises. Endless standard est jouable depuis le hub et après une victoire Survival; ses paramètres restent **[PROPOSÉS]**, à calibrer, et sa validation de run représentative reste à faire. |
| P8 Sandbox Lab joueur | **P8.1–P8.8 implémentés** | Builds, trois modes (Survival, Endless standard et Armorless), presets/import/export, import de profil en lecture seule, snapshots et contrôles de simulation sont couverts par des smokes d’isolation. Endless s’exécute dans le contexte isolé sans service de progression/sauvegarde normale. |
| P9 Qualité et livraison | **Partiel** | Performance sur vrai iGPU, accessibilité/VFX/audio, soak graphique sur matériel cible et Windows. |

### Lecture rapide : livré, prototype ou survolé

**Bien intégré comme fondation :** simulation native découplée de Godot, worker, commandes/snapshots, limites de charge, outils Sandbox, loop de run Survival, pause/chest/XP, dix armes et leurs paires de reliques/évolutions en prototypes de combat, sauvegarde versionnée, premiers écrans d’équipement.

**Fonctionnel mais non calibré :** boss et leurs patterns, probabilités de loot, dix évolutions et effets uniques; équipement/enhancement et économie, arbre à 100 nœuds, 100 familles d’achievements et récompenses de run; mode Armorless et Sandbox Lab isolé. Les paramètres restent souvent **[PROPOSÉS]** et les validations de run complète ou de matériel cible ne sont pas remplacées par les smokes.

**Survolé, ouvert ou non validé :** pickups de soin/ressources/monnaies non encore définis; équilibrage des armes, boss, loot et progression; équilibrage des réactions dont les paramètres Overcharge restent **[PROPOSÉS]**; extension éventuelle de l’arbre et des achievements vers 120 (cible **[PROPOSÉE]**); partie Armorless complète sans assistance; validation représentative d’Endless standard et calibration de ses paramètres **[PROPOSÉS]**; validation CPU/GPU sur iGPU cible et livraison Windows. Le Sandbox Lab joueur n’est plus à faire : ses critères P8.1–P8.8 sont cochés et ses smokes ciblés sont consignés dans la QA.

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

## PHUB — Hub des statistiques de run

**Priorité :** tranche UI à prendre avant de reprendre le travail nominal P5/P6. Ce module ne remplace pas ces jalons et ne prétend pas les clore. Sa spec d'implémentation est [`tasks/ui-refonte/SPEC-run-stat-hub.md`](../../tasks/ui-refonte/SPEC-run-stat-hub.md), liée depuis la [carte des capacités UI](../../UI_CAPABILITY_MAP.md).

- [x] Afficher à gauche un hub compact des statistiques effectives de la run.
- [x] Ouvrir avec Tab un panneau en lecture seule indiquant les totaux et les contributions de la progression de run (XP incluse), l'équipement, les achievements et le skill tree. Le niveau XP et le nombre de bonus automatiques appliqués sont indiqués explicitement.
- [x] Garder le gameplay actif et les horloges en marche pendant l'affichage du panneau.
- [x] Vérifier navigation clavier/manette, lisibilité à 640×360 et agrandissement, et isolation stricte du Sandbox.
- [x] Implémenter les bonus automatiques d'XP selon la rotation fixe validée; `survival_xp_run_bonuses_smoke.gd` couvre les douze statistiques, la répétition du cycle, les PV proportionnels, le hub et la remise à zéro entre deux runs.

La rotation et les incréments automatiques sont **[VALIDÉS]** par l’extension GDD du 2026-10-16. Leur balance reste à surveiller lors des runs représentatives P6.9; cela ne change pas le statut des paramètres de combat **[PROPOSÉS]**.

P6 a déjà du code anticipé, dont la rotation automatique des bonus XP **[VALIDÉE]**, mais le chemin nominal reste P5 puis P6. P7 standard ne doit pas commencer avant résolution des sujets **[OUVERTS]**. Les travaux P8 peuvent avancer sur l’architecture après les contrats partagés, sans donner au Sandbox de droit d’écrire les sauvegardes normales.

## P0 — Fondations techniques et dépôt

**Intention :** pouvoir importer, compiler et lancer Dopamine de manière reproductible sous Linux avec Godot 4.7.2, GDExtension et C++23.

### État constaté

- Projet Godot et GDExtension déclarés dans `game/` ; cœur C++ et cible native séparés.
- `godot-cpp` est verrouillé et les commandes Linux sont documentées.
- QA historique : compilation C++23 GCC 14.2, import Godot headless et chargement de l’extension.
- Le cœur natif n’inclut pas Godot et ne lie pas `godot-cpp` selon l’architecture/QA.

### Travaux restants

- [ ] **P0.1 — Inventaire Linux**
  - [x] Noter les versions de Godot, CMake, compilateur et dépendance native du build vierge du 2026-10-17 dans `docs/qa/TESTS.md`.
  - [x] Vérifier clone, configure, build, import, lancement headless et CTest depuis un clone Git neuf; un échec CTest isolé n’a pas reproduit et reste documenté dans `docs/qa/TESTS.md`.
  - [x] Documenter les répertoires de build/runtime et données `user://` Linux dans `docs/qa/TESTS.md`; `.godot/` et les binaires de plateforme sont ignorés.
- [ ] **P0.2 — Dépendances**
  - [x] Consigner les prérequis Linux (CMake ≥3.21, Git, compilateur C++23, Godot pour import/smokes) et la dépendance `godot-cpp` FetchContent dans `docs/qa/TESTS.md`.
  - [x] Vérifier le SHA `b8530af7546a3fcae80cef2477526569fd42ffc2` dans `CMakeLists.txt` et le build vierge; la procédure de récupération après échec est documentée dans le README.
- [ ] **P0.3 — Artefacts locaux**
  - [x] Vérifier les exclusions `/build/`, `/game/.godot/`, `/game/bin/linux/` et `/game/bin/windows/`.
  - [x] Vérifier l’index Git après le build/import frais : aucun artefact généré n’est suivi; des UID Godot non suivis peuvent être produits et restent hors commit.
- [ ] **P0.4 — Compatibilité Windows**
  - [x] Ajouter `tools/build_windows.ps1`, les entrées Windows debug/release du `.gdextension`, le preset x86_64 et `.github/workflows/build-windows.yml` pour build MSVC et export autonome.
  - [ ] Exécuter le workflow sur un runner Windows et vérifier son artefact; le poste actuel est Linux et n’a pas MSVC/PowerShell.
  - [ ] Confirmer le chargement interactif de la GDExtension sous Windows.
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
  - [x] Répertorier les méthodes `CombatSimulation` et leurs paramètres principaux dans `docs/architecture/INTERFACES.md`.
  - [ ] Pour chaque commande, vérifier une entrée valide et une entrée invalide.
  - [x] Vérifier sur les entrées invalides typées que le rejet ne modifie ni séquence, ni métriques, ni temps, ni configuration; `sandbox_smoke.gd` couvre le pont GDExtension.
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
  - [x] Reconstruire et relancer le benchmark natif sur la configuration Linux Debug enregistrée; mesures et limites virtualisées dans [`docs/qa/PERFORMANCE.md`](../qa/PERFORMANCE.md).
  - [ ] Mesurer CPU, GPU et frame-time dans Godot sur la machine iGPU de référence.
  - [x] Consigner P50/P95/P99 du cœur natif, charge et limites de l’hôte virtualisé dans [`docs/qa/PERFORMANCE.md`](../qa/PERFORMANCE.md); le profil iGPU reste séparément ouvert.

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
  - [x] Vérifier l’entrée Survival et le choix entre les deux armes affichées; smoke automatisé vérifie le modal et l’équipement de l’offre effectivement sélectionnée.
  - [ ] Parcourir choix et validation au clavier, flèches et manette.
  - [x] Confirmer le loadout et le HUD au début de run après sélection clavier; le smoke confirme que seule l’arme choisie est équipée et que son abréviation apparaît dans le HUD.
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
| Frost Nova | Frozen Crown | Absolute Zero | Prototype présent : onde circulaire de dégâts et Chill natif ralentissant les ennemis ; Absolute Zero améliore les dégâts reçus sur cibles gelées et produit un shatter de zone à leur mort. La réaction Shatter directe est aussi implémentée pour Crimson Daggers, Minigun, Sawblades, Meteor Staff et Void Orb **[VALIDÉE]**; ses chiffres restent **[PROPOSÉS]** configurables. |
| Minigun | Overdrive Engine | Redline | Prototype ajouté : tirs mono-cible, progression de cadence proposée, Redline accélère en continu ; valeurs configurables et **[PROPOSÉES]**. QA smoke ciblée. |
| Meteor Staff | Celestial Eye | Starfall | Prototype présent : tir sur groupe et explosion bornée ; Celestial Eye augmente les zones et peut doubler l'impact au niveau 5 ; Starfall envoie 2 fragments par défaut (maximum configurable 8) vers des cibles proches. Tous les réglages **[PROPOSÉS]**. |
| Sawblades | Magnetic Coil | Razorstorm | Prototype présent : lames natives ricochets sur cibles vivantes non déjà touchées ; Magnetic Coil ajoute au niveau 5 un homing léger borné à la portée visible. Dégâts, cadence, vitesse, vitesse angulaire de homing et nombre de rebonds restent **[PROPOSÉS]** ; Razorstorm ajoute un rebond. |
| Toxic Cloud | Plague Mask | Pandemic | Le projectile devient un champ visuel persistant après impact et empoisonne les nouvelles cibles ; Pandemic transmet le DoT à la mort vers 3 cibles au plus. Tous les types distincts de DoT coexistent, et réappliquer un type remplace uniquement celui-là **[VALIDÉ, 2026-10-17]**. La durée/rayon restent **[PROPOSÉS]**. |
| Prism Laser | Prism Crystal | Spectrum Collapse | Prototype de rayon continu sur cible prioritaire ; l’évolution ajoute des faisceaux secondaires distincts. Cadence, dégâts, progression et bonus **[PROPOSÉS]**. |
| — | Magnet Heart (relique utilitaire) | Aucune | Disponible ; rayon XP augmenté avec valeur **[PROPOSÉE]** configurable ; Magnetic Pulse périodique prototype attire progressivement les orbes XP, autres catégories de pickups absentes. |

Travail requis :

- [x] **P5.1.1 — Définitions catalogue** — les dix armes et leurs dix reliques associées, plus Magnet Heart sans paire, sont définies et les relations sont vérifiées au chargement.
- [x] **P5.1.2 — Schéma et activation** — JSON Schema draft 2020-12 formalisé dans `game/data/combat_catalog.schema.json`; le chargeur runtime rejette types, champs et références d’évolution invalides, vérifie les associations arme/relique et n’expose que les entrées marquées disponibles. Les dix prototypes actuels et Magnet Heart sont exposés ; chaque nouveau prototype doit être activé explicitement.
- [x] **P5.1.3 — Minigun + Overdrive Engine → Redline (prototype)** — tir automatique, bonus de cadence Overdrive linéaire et cadence Redline croissante en tir continu ; chiffres de départ configurables et **[PROPOSÉS]**.
- [x] **P5.1.4 — Toxic Cloud + Plague Mask → Pandemic (prototype)** — l’impact applique le DoT partagé et transforme le projectile en champ persistant qui empoisonne une fois chaque cible entrante ; le champ est visible et sa capture/restauration est couverte. Pandemic transmet toujours le poison à la mort (3 cibles maximum). Tous les types distincts de DoT coexistent **[VALIDÉ, 2026-10-17]**. Rayon, durée totale du projectile et application unique par cible **[PROPOSÉS]**.
- [x] **P5.1.5 — Sawblades + Magnetic Coil → Razorstorm (prototype)** — projectile natif ricoche vers des ennemis vivants non encore touchés ; Magnetic Coil augmente la vitesse des projectiles et l’évolution ajoute un rebond. Au niveau 5, homing léger configurable (1 rad/s proposé) vers la cible vivante non encore touchée la plus proche dans le rayon de portée visible, vitesse conservée. Test cœur natif et smoke Survival; valeurs et balance **[PROPOSÉES]**.
- [x] **P5.1.6 — Meteor Staff + Celestial Eye → Starfall (prototype)** — l'attaque vise un groupe et inflige des dégâts d'explosion ; Starfall lance deux fragments par défaut, avec maximum configurable de huit, vers les cibles proches. Bonus de zone, chance de double impact et valeurs de dégâts **[PROPOSÉS]**.
- [x] **P5.1.7 — Prism Laser + Prism Crystal → Spectrum Collapse (prototype)** — rayon visuel suit la cible prioritaire et dégâts répétés passent par les projectiles natifs ; l'évolution ajoute jusqu'à deux cibles secondaires configurables. Bonus de critique et valeurs d'attaque/progression **[PROPOSÉS]**.
- [x] **P5.1.8 — Void Orb + Singularity → Event Horizon (prototype)** — projectiles lents persistants traversent des cibles distinctes et les attirent dans un champ natif borné ; Event Horizon augmente le rayon et la force. Réglages **[PROPOSÉS]**.
- [x] **P5.1.8 — Crimson Daggers + Blood Chalice → Bloodstorm (prototype)** — dagues natives orbitantes centrées sur le joueur et perçantes ; Bloodstorm ajoute Bleed et prolonge leur présence. Rayon 30, vitesse angulaire 5 rad/s, durées 0,8/2,4 s **[PROPOSÉS]** ; mouvement et capture/restauration couverts par `simulation_core`, contact et Bleed par `survival_weapon_catalog_smoke`.
- [x] **P5.1.9 — Frost Nova + Frozen Crown → Absolute Zero (prototype)** — pulsation de zone avec Chill natif (durée, ralentissement et vulnérabilité) ; Absolute Zero produit un shatter borné quand une cible gelée meurt. Le statut est inclus dans les snapshots et le drapeau d'événement. La réaction Shatter sur impacts directs est couverte séparément en P5.2.3. Les paramètres Absolute Zero restent **[PROPOSÉS]** et configurables.
- [x] **P5.1.9 — Feedback Minigun/Toxic Cloud/Sawblades/Meteor Staff/Prism/Void Orb** — vérifié par `survival_weapon_catalog_smoke.gd`, `survival_hud_smoke.gd` et `render_batching_smoke.gd` : projectiles distincts présents ; l’anneau intérieur animé du nuage Pandemic suit le temps de simulation et se fige en pause (**[PROPOSÉ]**, période 1,2 s) ; le HUD affiche niveau et EVO pour les dix armes ; les impacts dédiés grandissent de 6 % par niveau (**[PROPOSÉ]**) ; Redline a un lot distinct avec silhouette Minigun teintée rouge néon (**[PROPOSÉ]**).
- [x] **P5.1.10 — Ciblage des armes**
  - [x] Documenter le ciblage actuellement codé avant le comportement visuel : Lightning choisit comme première cible le membre le plus proche du joueur dans la grappe vivante la plus dense à portée, puis chaîne vers les cibles distinctes les plus proches (**[PROPOSÉ]**) ; Inferno vise la plus haute menace dans sa portée et départage à égalité par la proximité (**[PROPOSÉ]**) ; Toxic vise l’ennemi vivant aux PV les plus élevés et départage à égalité par la proximité (**[PROPOSÉ]**) ; Crimson vise l’ennemi vivant aux PV les plus faibles dans sa portée et départage à égalité par la proximité (**[PROPOSÉ]**) ; Void choisit l’ennemi vivant le plus éloigné dans sa portée (**[PROPOSÉ]**) et applique ensuite sa règle native ; Sawblades choisit la cible accessible qui ouvre la grappe la plus dense dans le rayon de rebond, départagée par la proximité, puis retombe sur la cible la plus proche si aucune grappe n’existe (**[PROPOSÉ]**) ; Minigun acquiert la cible vivante la plus proche et la conserve jusqu’à sa mort ou sa sortie de portée (**[PROPOSÉ]**) ; Meteor vise le membre le plus proche du joueur dans le groupe vivant le plus dense et dirige l’explosion vers le centroïde de ce groupe (**[PROPOSÉ]**) ; Prism vise la cible aux PV les plus élevés dans le groupe vivant le plus dense, puis centre ses faisceaux secondaires autour d’elle (**[PROPOSÉ]**) ; Frost est une zone centrée sur le joueur sans cible visée.
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
  - [x] Au niveau 5, déclencher périodiquement Magnetic Pulse **[PROPOSÉE]** dans 300 % du rayon XP; le cœur natif accélère progressivement les orbes XP vers le joueur, les collecte seulement dans le rayon XP normal, puis arrête leur mouvement à la fin de l'impulsion. L'anneau, le cycle, le mouvement et la collecte gèlent en pause; aucun chest n'est affecté. Intervalle 20 s, durée 1,5 s, accélération 600 et vitesse max 240 **[PROPOSÉS]** et configurables.
  - [x] Les trois synergies Magnet Heart + Magnetic Coil/Singularity/Celestial Eye sont **[VALIDÉES]** comme périmètre. Prototype configurable **[PROPOSÉ]** : deux reliques niveau 5, effet durant Magnetic Pulse, vitesse Coil ×1,5, attraction XP par le champ Void Orb/Event Horizon et rayon Celestial Eye ×1,5; smoke Survival vérifie seuils, vitesse/rayon et attraction vers le champ sans attirer les coffres.
  - [ ] Étendre l'attraction aux soins, ressources, monnaies et bonus temporaires lorsqu'ils existent.
- [x] **P5.1.14 — Slots et effets de capacité**
  - [x] Vérifier cinq slots de reliques en run normale ; `survival_loadout_smoke.gd` couvre cinq reliques distinctes, refuse une sixième et ne propose plus de nouvel item quand les slots sont pleins.
  - [x] Tester l’extension Legendary/Mythic avec `expanded_loadout` équipé : +1 arme et +1 relique, plafond six, doublons dédupliqués; contrat et valeurs restent **[PROPOSÉS]** dans `EFFETS_UNIQUES_P6.md`. Couvert par `survival_unique_effects_smoke.gd` et `survival_loadout_smoke.gd`.
  - [x] Vérifier l’absence de cumul automatique d’un même effet unique actif ; `progression_service_smoke.gd` équipe deux items Legendary avec `overflow_shield` et vérifie que l’effet n’est exposé qu’une fois.
- [x] **P5.1.15 — Statut du balancing**
  - [x] Charger les multiplicateurs, ajouts et valeurs par palier depuis `game/data/weapon_progression.json`; le chargement valide version, dix IDs, niveaux 1–5 et valeurs finies/positives, et échoue visiblement si la configuration est invalide.
  - [x] Garder les valeurs marquées **[PROPOSÉES]** jusqu’à leur décision formelle; `survival_weapon_catalog_smoke.gd` vérifie aussi qu’une valeur modifiée dans la configuration change le résultat calculé.

### P5.2 — Statuts et synergies

- [x] **P5.2.1 — Contrats de statut**
  - [x] Lister les statuts implémentés pour les paires : Burn (Inferno/Wildfire), Poison (Toxic/Pandemic), Bleed (Bloodstorm) et Chill (Frost/Absolute Zero). Les paires sans statut restent sans effet inventé.
  - [x] Vérifier la durée, le tick, le remplacement et l’affichage des DoT : tous les types distincts coexistent et tickent sur leurs horloges indépendantes **[VALIDÉ, 2026-10-17]**; réappliquer un type le remplace seul. Le test natif couvre Burn + Poison + Bleed, le remplacement isolé et le tick indépendant. Le snapshot publie tous les effets actifs et l’anneau Survival les distingue; les paramètres chiffrés des armes restent **[PROPOSÉS]**.
  - [x] Vérifier application, expiration et exclusion des cibles mortes avant connexion aux armes.
- [x] **P5.2.2 — Synergies émergentes**
  - [x] Les chemins existants consomment les événements standards : lifesteal sur damage avec taux global de base de 5 % **[PROPOSÉ]** auquel Blood Chalice ajoute son bonus, contagion Pandemic sur dégâts/statut et mort, Absolute Zero sur mort d’une cible Chill, fragments Starfall sur impact et chaînes Lightning sur dégâts. Les événements DoT portent maintenant leur identité jusqu’au damage/death.
  - [x] Vérifier que ces comportements utilisent les contrats d’évolution/statut existants; aucune réaction élémentaire proposée n’est activée. Les évolutions et paramètres de prototype gardent leur statut **[PROPOSÉ]** là où le GDD ne les valide pas.
- [ ] **P5.2.3 — Réactions proposées**
  - [x] Implémenter un prototype Thermal Shock : déclenchement par impact direct Burn↔Chill, bonus à 50 % du coup initial et cooldown local de 1 s **[PROPOSÉS]**; le DoT et l’impact de réaction ne chaînent pas.
  - [ ] Valider et équilibrer Thermal Shock sur des runs; neuf parcours exploratoires (six Easy, trois Normal) à ×1 avec loadout Burn/Chill forcé sont archivés dans `docs/qa/TESTS.md` et les fichiers `thermal_shock_run_survey_20261017.csv` / `thermal_shock_run_survey_normal_20261017.csv`. Ils ne changent pas le statut **[PROPOSÉ]** et ne remplacent pas une validation représentative.
  - [x] Toxic Ignition : explosion au coup direct appliquant le second statut sur une cible affectée par l’autre **[VALIDÉ]**; 50 % du coup déclencheur, rayon 60 px, statuts conservés et cooldown local d’une seconde **[VALIDÉS, 2026-10-16]**. Tous les DoT distincts coexistent et se remplacent par type **[VALIDÉ, 2026-10-17]**. L’explosion n’applique aucun statut et ne se chaîne pas récursivement. Vérifier sa calibration en run réelle.
  - [x] Shatter : coup direct des Crimson Daggers, Minigun, Sawblades, Meteor Staff ou Void Orb sur une cible gelée → dégâts bonus sur la cible et fragments vers les ennemis proches; les évolutions correspondantes sont incluses. Ticks DoT, sources élémentaires et chaîne des fragments exclus. Les chiffres restent **[PROPOSÉS]** configurables; `survival_weapon_catalog_smoke.gd` vérifie les sources, cibles, dégâts et budget de réaction.
  - [x] Electroplague **[VALIDÉE, 2026-10-17]** : un coup direct de Shock sur Poison propage le même effet à toutes les cibles ennemies vivantes dans un rayon de 60 px, sans plafond; aucun dégât direct, remplacement ou chaîne sur DoT. Implémentation et smoke dans `survival_weapon_catalog_smoke.gd`.
  - [x] Gravity Collapse **[VALIDÉE, 2026-10-17]** : un coup direct d’Impact sur une cible vivante dans le champ Void Orb/Event Horizon provoque immédiatement une explosion centrée sur elle; 50 % des dégâts déclencheurs à toutes les cibles vivantes à 60 px, cible centrale incluse une fois, sans coup direct additionnel ni chaîne. Le prototype accepte les impacts directs des armes hors Void Orb/Event Horizon et réactions **[PROPOSÉ]**; implémentation native bornée par le budget technique partagé et smoke catalogue.
  - [x] Hemorrhage **[VALIDÉ, 2026-10-17]** : un coup critique direct sur une cible Bleed provoque un tick supplémentaire immédiat sans changer sa durée ni chaîner. Le signal de critique explicite est porté par les projectiles/événements; le tick natif conserve l’horloge du statut. Testé dans `survival_weapon_catalog_smoke.gd` et les tests natifs.
  - [x] Overcharge **[VALIDÉE, 2026-10-17]** : tout coup direct électrique applique Shock pendant une seconde; un nouveau coup électrique sur la cible encore affectée déclenche une décharge de zone sans chaîne. Paramètres proposés/configurables : 50 % des dégâts déclencheurs, rayon 60 px et cooldown local 1 s. Smokes vérifient durée, cooldown, sources électriques croisées, exclusion DoT/non-électrique et dégâts bornés de l’aire.
- [x] **P5.2.4 — Causalité et dégâts**
  - [x] Toxic Ignition utilise le numéro séquentiel de l’impact déclencheur comme ID de chaîne et consomme son budget unique; le projectile de réaction et ses événements portent le même ID avec un budget restant de zéro. Un budget épuisé refuse tout nouveau déclenchement. Ces champs sont conservés par les snapshots/restaurations. Les réactions proposées ne reçoivent pas de contrat implicite : elles devront suivre cette règle après validation.
  - [x] Vérifier événements directs, DoT létal, lifesteal, mort et attribution XP sans double crédit; `survival_damage_causality_smoke.gd` compte une seule mort/orbe XP par cible directe et DoT, et `survival_lifesteal_smoke.gd` couvre le soin.

### P5.3 — Coffres et économie de run

- [x] **P5.3.1 — Éligibilité des offres**
  - [x] Produire trois choix distincts quand au moins trois choix existent ; test ciblé des armes niveau max, slots pleins et absence de choix éligibles.
  - [x] Ajouter la préférence synergie comme poids multiplicatifs et tirage pondéré sans remise; tous les poids restent strictement positifs et aucune offre éligible n’est supprimée.
  - [x] Vérifier objets niveau max, slots pleins et arme niveau 5 sans relique. La relique garde ses offres même lorsque l’arme est niveau 5.
  - Les poids par défaut du GDD (**[PROPOSÉS]**) sont configurables dans Survival : amélioration possédée ×1,5, relique liée à une arme possédée ×2, arme liée à une relique possédée ×1,5, évolution prête/proche ×1,25, plafond combiné ×3. « Proche » signifie ici que le choix amène les deux membres d’une paire non évoluée au niveau 4 ou plus; cette interprétation reste **[PROPOSÉE]**.
- [x] **P5.3.2 — Pause et reprise**
  - [x] Suspendre la simulation et vérifier que ses horloges ne progressent pas pendant le modal; `survival_chest_smoke.gd` contrôle aussi l’horloge active affichée.
  - [x] Vérifier la reprise après sélection et le rejet d’une liste/sélection invalide dans `survival_chest_smoke.gd`; un choix invalide conserve le modal et la pause. `survival_pause_inventory_smoke.gd` confirme le retour vers le menu Pause, le focus et la simulation toujours figée.
- [x] **P5.3.3 — Évolution post-choix**
  - [x] Pour les dix paires, vérifier qu’une arme nouvellement acquise au niveau 1 n’offre pas l’évolution même si sa relique est déjà niveau 5; l’offre apparaît au niveau 5 de l’arme.
  - [x] Vérifier l’offre après chaque chemin de niveaux de l’arme, et après acquisition/amélioration de la relique jusqu’au niveau 5.
  - [x] Ouvrir un vrai coffre d’arme, afficher l’unique évolution devenue éligible et la collecter; `survival_weapon_catalog_smoke.gd` vérifie que le combo s’active après cette collecte.
- [ ] **P5.3.4 — Probabilités**
  - [x] Garder les taux de drop, le filet anti-malchance et les poids d’offres accessibles en configuration; `survival_chest_director_smoke.gd` vérifie désormais aussi, sur 40 000 tirages seedés, les fréquences ordinaires/élites et l’indépendance des deux familles; `survival_loadout_smoke.gd` couvre les poids d’offres.
  - [x] Intégrer `free_first_chest_reroll` au premier coffre de run via P6.5; le comportement reste **[PROPOSÉ]** et est couvert par `free_chest_reroll_smoke.gd`.
  - [ ] Faire arbitrer les valeurs nécessaires avant leur verrouillage; les coefficients restent **[PROPOSÉS]**.
- [x] **P5.3.5 — Collecte**
  - [x] Préserver le rayon séparé `chest_collection_radius`.
  - [x] Vérifier par régression qu'un pickup très élevé n'attire pas un chest éloigné.
  - [x] Vérifier la collecte à proximité et l'ouverture du choix ; l'interaction manuelle reste facultative selon le GDD.
  - [x] Autoriser les drops d'armes/reliques dès qu'au moins une offre reste éligible, même si un profil débutant n'a pas encore trois options; vérifier la récompense élite avec ses deux armes et deux reliques de départ.

### P5.4 — Ennemis, élites et boss

**Avancement :** le roster de vague comprend huit familles : Chaser, Sprinter, Tank, Shooter, Buffer, Exploder, Shielder et Summoner. Shooter télégraphie ses tirs ; Buffer augmente de 20 % la vitesse alliée dans son aura de 150 ; Shielder réduit à 65 % les dégâts reçus par les alliés couverts par son aura de 150 ; les deux auras cessent à la mort de leur source. Summoner (42 HP, vitesse 42, menace 2,5) annonce une position de spawn, puis invoque des adds (12 HP, vitesse 90, menace 0,5), avec trois invocations actives globalement au maximum. Les élites génériques (50 HP, menace 3) tirent désormais l’un de six affixes **[PROPOSÉS]** : Hasted (100 px/s), Armored (75 px/s, 65 % des dégâts reçus), Regenerating (1 % des PV max régénéré par seconde simulée), Volatile (explosion de 18 dégâts, rayon 82, sans chaîne), Shielded (anneau visible, 50 % des dégâts reçus) ou Split-on-Death (deux adds soumis à la limite globale). L’affixe est publié dans le snapshot. Le directeur les fait apparaître selon un cooldown, un plafond actif et un budget égal à la population de la vague ; le coût de menace est 3. Il utilise le chemin de récompense élite existant. Le profil **Exploder** (30 HP, vitesse 60, menace 2) s’approche, déclenche un fuse de 0,8 s dans un rayon de 110 et inflige 18 dégâts dans un rayon de 82 ; le cercle de souffle est visible, la pause fige le fuse, et sortir du rayon esquive le souffle. Le Pulse Warden et le Dopamine Core possèdent chacun un prototype d’attaques en trois phases; le Core a un sprite dédié. La charge mobile télégraphiée du Warden est implémentée en phases 2 et 3 et vérifiée par `survival_boss_attack_smoke.gd`. Les valeurs, rayons, délais, plafonds et chances de spawn de ces prototypes restent **[PROPOSÉS]**.

- [x] **P5.4.1 — Familles ennemies**
  - [x] Valider les profils Sandbox Chaser (mêlée), Sprinter (rapide, faible HP) et Tank par spawn et snapshots; `simulation_core_test` vérifie steering à la vitesse du profil et mort typée pour chacun. `survival_combat_visual_smoke.gd` vérifie les trois routes de sprites dédiées. Les profils, valeurs et contre-jeu de l’archétype rapide restent **[PROPOSÉS]**.
  - [x] Ajouter une famille distance avec projectile télégraphié.
  - [x] Ajouter un profil de soutien Buffer avec aura de vitesse visible et bornée.
  - [x] Ajouter le prototype Exploder avec fuse et souffle esquivables **[PROPOSÉS]**.
  - [x] Compléter le roster à huit familles et vérifier les profils par scénario Sandbox.
  - [x] Smoke Survival seedé : la vague 20 génère les huit familles du roster avec le chemin de spawn de run et la simulation native; le test vérifie leur présence, pas les probabilités d’équilibrage **[PROPOSÉES]**.
- [x] **P5.4.2 — Interactions ennemies**
  - [x] Ajouter un buff de soutien visible et borné.
  - [x] Ajouter Shielder : réduction de dégâts bornée dans une aura et retirée à sa mort **[PROPOSÉ]**.
  - [x] Ajouter Summoner avec position télégraphiée et maximum global de trois adds actifs **[PROPOSÉ]**.
  - [x] Tester destruction du soutien et fin de son effet.
- [x] **P5.4.3 — Élites**
  - [x] Définir la compatibilité du prototype : `elite` accepte Hasted, Armored, Regenerating, Volatile, Shielded et Split-on-Death; les familles ordinaires et les affixes non implémentés sont refusés.
  - [x] Implémenter la sélection aléatoire entre Hasted, Armored, Regenerating, Volatile, Shielded et Split-on-Death sur l’unique famille élite; Hasted passe à 100 px/s, Armored se déplace à 75 px/s et reçoit 65 % des dégâts, Regenerating récupère 1 % de ses PV max par seconde simulée et Volatile explose à sa mort (18 dégâts, rayon 82, sans chaîne), Shielded réduit les dégâts reçus à 50 % avec un anneau visible et Split-on-Death demande deux adds dans la limite globale **[PROPOSÉS]**.
  - [x] Générer le prototype Hasted avec plafond actif et cooldown **[PROPOSÉS]**.
  - [x] Appliquer le budget proposé : somme des menaces actives + coût élite ≤ population cible de la vague.
  - [x] Vérifier affixe visible, profil de vitesse, mort et récompense élite.
- [x] **P5.4.4 — Mid-boss**
  - [x] Définir les phases proposées et rendre leurs transitions visibles dans le HUD/télégraphes.
  - [x] Implémenter les attaques de phase en tranches testables, dont la charge mobile télégraphiée de phase 3.
  - [x] Vérifier timer de vague suspendu pendant le boss, decay actif, puis reprise des spawns réguliers après la vague 12.
  - Prototype Pulse Warden : phases affichées selon les PV (seuils 66 % / 33 % **[PROPOSÉS]**), salve radiale annoncée en phase 1, alternance tir ciblé/charge avec invocation bornée en phase 2, puis alternance salve radiale/charge en phase 3. La charge trace sa trajectoire, déplace l’entité sous steering natif pendant 0,28 s et reprend ensuite le steering joueur. Les smokes vérifient télégraphie, gel en pause, transitions, invocation, charges des phases 2–3, gel du timer de vague durant les boss, maintien du decay et reprise des spawns réguliers après le mid-boss; patterns et valeurs demeurent **[PROPOSÉS]**.
- [x] **P5.4.5 — Boss final**
  - [x] Définir et implémenter trois phases selon les PV : rayon puis zone esquivable, spirale tirée en salves successives avec invocation en phase 2, puis rayon/zone combinés avec spirale ; télégraphes et HUD de phase vérifiés. Motifs, seuils, dégâts et cadence **[PROPOSÉS]**.
  - [x] Smoke boss : les phases 2 et 3 saturent le plafond global d’invocations proposé à trois, rejettent les suivantes et réutilisent une place après la mort d’un add.
- [x] Le run accéléré `survival_wave_director_smoke.gd` observe et traite les deux familles de boss jusqu’à la victoire; ce parcours reste assisté et ne ferme pas P5.V3.
  - [x] Remplacer l’apparence placeholder du Core par le sprite dédié `boss_dopamine_core` et vérifier sa route dans le renderer ainsi que PNG/source Aseprite, dimensions et palette.
  - [x] Vérifier par `survival_final_boss_loot_smoke.gd` la défaite du Core, les deux coffres garantis configurables consommés l’un après l’autre, puis l’écran de victoire; la validation en run sans harness reste dans P5.V3.
  - Prototype en cours : le Dopamine Core dispose de trois phases, de rayons/zones télégraphiés et esquivables, d’une spirale en tirs successifs et d’invocations en phases 2–3. Le smoke confirme le plafond d’invocations partagé en phases 2–3 ; son identité visuelle est un prototype dédié, sans validation de canon. Tous ces patterns et nombres restent **[PROPOSÉS]**.
- [x] **P5.4.6 — Difficultés**
  - [x] Persister la difficulté maximale débloquée (Easy initialement) et transmettre la difficulté choisie du hub à la run.
  - [x] Après une victoire contre le boss de vague 24, débloquer uniquement la difficulté suivante; refuser les récompenses d’une difficulté verrouillée avec `difficulty_locked`. Une défaite ne débloque rien.
  - [x] Vérifier que HP, dégâts ennemis, densité et récompenses utilisent leurs multiplicateurs séparés; les résultats Easy, Normal et Chaos ont un test dédié.
  - [x] Inclure les smokes de profil, d’unlock et de session dans CTest; l’unlock verrouillé vérifie explicitement l’erreur `difficulty_locked`.
  - Les règles de déblocage sont **[VALIDÉES]**; les multiplicateurs du GDD restent **[PROPOSÉS]**.
  - [x] Chaos : Buffer, Shielder et Summoner ont une chance d’apparition multipliée par 1,5 **[PROPOSÉ]**; les élites tirent deux affixes distincts dont les effets se combinent; les boss cyclent leurs patterns existants sans répétition immédiate. Le follow-up reste après deux attaques normales; HP, vitesse de boss et plafond global d’invocations ne sont pas modifiés. Smokes ciblés `survival_wave_spawn_smoke.gd`, `survival_elite_smoke.gd` et `survival_boss_attack_smoke.gd`.
  - [ ] Équilibrer le multiplicateur de soutien et les combinaisons d’affixes, puis vérifier les mutations en run Chaos représentative. Quatre paires exploratoires Chaos/Normal à loadout forcé terminent toutes avant la vague 3; résultats et limites consignés dans `docs/qa/TESTS.md` et `docs/qa/data/thermal_shock_chaos_vs_normal_20261017.csv`, sans calibration.

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
- [x] **P5.V3 — Run de bout en bout**
  - [x] Défaite en interface réelle, Easy avec Lightning Conductor, profil `XDG_DATA_HOME` isolé, verrouillage de vie et choix auto désactivés : écran RUN OVER à la vague 2 après 00:45 et 14 éliminations; le panneau a affiché +13 Essence et +18 Basic Powder.
  - [x] Le créateur confirme le 2026-10-17 une victoire en interface réelle sans assistance, un choix manuel de coffre, et les récompenses persistées sans duplication après relance. Rapport utilisateur consigné dans `docs/qa/TESTS.md`; difficulté, arme, plateforme et montants ne sont pas précisés.
- [ ] **P5.V4 — Revue et checkpoint**
  - [x] Consigner les validations et les limites sans changer les statuts de décision du GDD.
  - [x] Relancer la suite CTest complète : 66/66 passent en séquentiel le 2026-10-16 après correction du redémarrage de run. Le benchmark natif sur 500 ennemis/2 000 projectiles mesure la rafale d’impacts avant/après optimisation; résultats et limites consignés dans `docs/qa/TESTS.md`.
  - [x] Corriger l’arc Lightning qui retouchait sa source à courte distance; smoke natif ciblé et catalogue vérifiés, 10 répétitions consécutives puis CTest complet 67/67.
  - [x] Corriger le travail de zone devenu inutile après saturation du budget d’explosions et committer ce checkpoint documenté.
  - [x] Après P5.2.4, recompiler avec CMake et exécuter CTest en séquentiel : 86/86 passent sous Godot 4.7.2; cela vérifie aussi les snapshots format 15 et les dix scénarios Sandbox d’armes.
  - [x] Après l’optimisation du résolveur de collisions, recompiler la GDExtension Linux et relancer CTest le 2026-10-17 : 86/86 passent en 60,45 s sous Godot 4.7.2.
  - [x] Revalider le checkout le 2026-10-17 : CTest passe 87/87 en 61,40 s. La répétition du smoke catalogue a révélé un fixture Thermal Shock intermittent (cibles quasi chevauchées); les cibles sont désormais espacées et les armes du fixture désactivées. Le catalogue passe dix exécutions consécutives.
  - [x] Enregistrer la confirmation utilisateur de P5.V3 (run de victoire, coffre, récompenses et relance) ; voir `docs/qa/TESTS.md`.
  - [x] Le créateur confirme le 2026-10-17 avoir terminé les vérifications manuelles demandées et que tout est bon; aucun détail par arme/build/difficulté/plateforme n’a été fourni (voir `docs/qa/TESTS.md`).
  - [x] Ajouter une comparaison reproductible de DPS pour les dix armes au niveau 1, niveau 5 + relique 5, et évoluées, sur cible unique, grappe fixe et Chasers mobiles; données et limites dans `docs/qa/PERFORMANCE.md`. Cette mesure de laboratoire ne valide pas le tuning.
  - [ ] Effectuer un profilage représentatif CPU/GPU et des armes avant de clore le jalon.
  - [x] Investiguer l’écart du benchmark natif Debug : le résolveur spatial parcourait les collisions de corps quand aucun ennemi ne bougeait. Sortie anticipée, tests core/worker 2/2; la rafale revient à 73,0–73,8 ms. Résultats et limites dans `docs/qa/PERFORMANCE.md`.

**Critère de sortie :** dix armes, onze reliques, leurs évolutions, 8–12 familles, élites et boss utilisables dans une run complète ; Sandbox et progression séparés. Après P5, poursuivre P6–P9 selon le goal principal actif.

## P6 — Progression permanente (code anticipé, jalon incomplet)

**Intention :** transformer le prototype de profil v5, équipement, enhancement, arbre et succès en boucle complète et calibrée. L’existence du service ne signifie pas la fermeture du jalon.

### État actuel et écarts

- `SaveService` possède format versionné/checksum/backup et QA historique de migration/altération.
- `ProgressionService` possède des profils v9 avec difficulté maximale débloquée (Easy par défaut), records Armorless/Endless séparés par difficulté, récompenses de run classiques idempotentes par `run_id`, inventaire, six slots, cinq raretés, stat lines, enhancement, conversion Powder, arbre de 100 nodes et achievements génériques de huit catégories. La règle [VALIDÉE] de déblocage séquentiel après victoire sur le boss de vague 24 est codée; les récompenses d’une difficulté verrouillée sont refusées. Les facteurs de difficulté [PROPOSÉS] sont centralisés et appliqués à la simulation ainsi qu’aux récompenses. Le hub injecte profil et difficulté dans la run; le raccourci Sandbox fonctionne sans service de progression.
- Le générateur choisit les poids de rareté par difficulté et vague et applique un prototype de pénalité aux défaites avant la vague 6; ces règles et coefficients sont **[PROPOSÉS]**, leur calibration statistique et l’équilibrage des plages restent à faire.
- Les achievements ont un évaluateur générique, des métriques de combat/profondeur/progression/difficulté et un premier suivi du build d’armes/reliques/évolutions/équipement. Le catalogue contient maintenant 100 familles, au plancher de la cible [VALIDÉE] de 100–150; 120 reste la cible éditoriale [PROPOSÉE].
- Les 100 nœuds sont définis et débloquables. Dans le panneau, quatre nœuds Core Stats ont une présentation en cartes de branche; les autres apparaissent dans une liste plate dont les infobulles nomment maintenant les prérequis. Le graphe et le budget cumulatif ne sont donc pas calibrés ni présentés comme une carte complète. Une extension vers environ 120 nœuds reste **[PROPOSÉE]**.
- Cinq effets uniques ont un chemin gameplay prototype vérifié; `revive_knockback` reste stockable pour préserver les profils existants, mais n’est plus sélectionnable tant que son comportement n’est pas défini. Les chiffres de ces prototypes restent **[PROPOSÉS]**.
- Des bonus de stat sont consommés dans Survival ; `pickup_radius_pct` augmente actuellement le rayon des orbes XP seulement et le chest a son propre rayon.

### Travaux

- [x] **P6.1 — Équipement de run classique**
  - [x] Tester chacun des six slots et le remplacement d’une pièce du même slot.
  - [x] Vérifier qu’une run finie (victoire ou défaite) donne une seule pièce.
  - [x] Vérifier que les lignes d’un objet n’ont pas de statistique dupliquée.
- [ ] **P6.2 — Rareté et rolls**
  - [x] Ajouter difficulté et vague aux entrées du générateur; les poids **[PROPOSÉS]** du GDD sont sélectionnés par difficulté et déplacent 1 point de Normal vers les autres raretés à chaque tranche de six vagues atteintes (jusqu’à quatre points en vague 24).
  - [x] Ajouter au prototype une pénalité de rareté lors d’une défaite avant la vague 6 : poids Mystic+ réduits jusqu’à 50 % en vague 1 puis remontant linéairement à la normale en vague 6; aucune pénalité sur une victoire. Règle et coefficients **[PROPOSÉS]**, calibration toujours requise.
  - [x] Smoke ciblé vérifie les poids Easy/Chaos, la conservation de la somme à 100 %, l’effet de vague sur le tirage seedé et les poids proposés par difficulté; cela ne constitue pas un calibrage statistique.
  - [x] `equipment_rarity_smoke.gd` vérifie par seed 20 000 tirages sur les cinq difficultés aux vagues 1 et 24 dans une tolérance statistique; les probabilités et la règle de progression restent **[PROPOSÉES]**, non calibrées.
- [x] **P6.3 — Application des statistiques**
  - [x] `equipment_stats_smoke.gd` équipe une seule stat par profil et ouvre une vraie session Survival pour vérifier l’effet de HP, mobilité, dégâts, cadence, critiques, soin, aire, cooldown, XP, rayon de ramassage et vitesse projectile.
  - [x] `survival_chest_smoke.gd` vérifie l’application du rayon de ramassage aux XP, dont l’impulsion Magnet Heart, puis confirme qu’un grand rayon ne collecte jamais un coffre hors de sa portée dédiée.
- [ ] **P6.4 — Enhancement**
  - [x] `equipment_enhancement_smoke.gd` vérifie une ligne +0..+10 avec Basic, Refined, Pure et Prismatic, y compris le +8 % par niveau.
  - [x] Le smoke vérifie réussite, échec normal, échec critique avec protection au niveau 0, et réussite garantie après neuf échecs.
  - [x] Le smoke vérifie la table proposée de coûts pour chaque rareté/niveau, les conversions 10:1 vers le tier suivant et le refus de conversion depuis Prismatic.
  - [x] Prototype d’économie choisi : vente contre Essence seule (5/10/20/40/80 selon rareté), démantèlement contre Powder seule selon `PROPOSITION_P5.md`; la vente demande confirmation et ne rembourse pas les enhancements. Rendements et chances restent **[PROPOSÉS]**, à calibrer.
  - [x] `equipment_economy_smoke.gd` vérifie les ventes par rareté, l’impossibilité de repayer une pièce supprimée et le rejet d’un `fail_streak` supérieur à 9, garde-fou de la tentative garantie.
  - [x] Modéliser l'espérance de tentatives, de Powder et de niveaux perdus pour une ligne +0→+10 avec une chaîne de Markov absorbante; résultats et script dans `docs/qa/TESTS.md` et `game/tests/enhancement_economy_expected_cost.gd`. Cette mesure suit les valeurs **[PROPOSÉES]**, sans calibrer les gains de poudre ni le rythme ressenti.
- [ ] **P6.5 — Effets uniques**
  - [x] `EFFETS_UNIQUES_P6.md` inventorie les six IDs actifs, leurs prérequis, déclencheurs, portée/limites, feedback et statuts **[PROPOSÉ]**; `revive_knockback` est identifié comme legacy sans gameplay.
  - [x] `survival_unique_effects_smoke.gd` vérifie les prérequis équipés, la portée visible et le cooldown de Lightning Burst, puis le gating par évolution, le feedback et l'activation unique d'Evolution Shockwave; `survival_inventory_smoke.gd`, `survival_elite_smoke.gd` et `free_chest_reroll_smoke.gd` couvrent Overflow Shield, Elite Haste et le reroll.
  - [x] `elite_haste` est chargé depuis un équipement unique équipé, déclenché par la mort d’un élite et actif 3 secondes simulées avec +15 % de mobilité **[PROPOSÉ]**; `survival_elite_smoke.gd` vérifie activation et expiration.
  - [x] `free_first_chest_reroll` relance une fois les options du premier coffre de run sans répéter les choix affichés; le run reste en pause. `free_chest_reroll_smoke.gd` couvre profil équipé, activation clavier, options inédites et absence de bouton aux coffres suivants; comportement **[PROPOSÉ]**.
  - [x] Retirer `revive_knockback` du choix des nouveaux effets sans supprimer la compatibilité de lecture des profils qui le stockent; vérifié par `progression_service_smoke.gd`.
  - [x] Vérifier non-cumul automatique et extensions de capacité réelles : le smoke équipe deux pièces porteuses du même effet, confirme la déduplication et applique six armes/reliques au maximum. Extension **[PROPOSÉE]**.
- [ ] **P6.6 — Skill tree**
  - [x] Établir le schéma node/prérequis/coût/effet; les valeurs générées et les coûts sont explicitement **[PROPOSÉS]**.
  - [x] Étendre la branche Core Stats à quatre nodes avec Fleet Footed (+2 % vitesse, 110 Essence) et Steady Aim (+1 point de critique, 140 Essence); prérequis, bonus et coûts **[PROPOSÉS]**, vérifiés jusqu'à leur application en Survival/Armorless et au respec.
  - [x] Ajouter des branches prototypes de déblocage d’équipement, en commençant par Crimson Daggers (130 Essence après Vitality) et Blood Chalice (160 Essence après Crimson Daggers), puis étendre les branches séquentielles aux autres entrées du catalogue. L’ordre et les coûts sont **[PROPOSÉS]**.
  - [x] Les profils normaux commencent avec Lightning Conductor, Inferno Sprayer, Storm Core et Infernal Heart; les autres armes et reliques se débloquent par le skill tree et rejoignent les offres/choix initiaux. Le Sandbox conserve le catalogue complet puisqu’il n’injecte aucun service de progression.
  - [x] Étendre les branches de déblocage aux 10 armes et 11 reliques Survival : chaque entrée non starter a un nœud, un prérequis séquentiel dans sa branche et un remboursement au respec. Les coûts augmentent avec la profondeur; cet ordre et ces valeurs sont **[PROPOSÉS]** et restent à calibrer.
  - [x] Générer les boutons d’équipement depuis les métadonnées de nœuds; `progression_service_smoke.gd`, `survival_loadout_smoke.gd` et `skill_tree_panel_visual_smoke.gd` couvrent le catalogue complet, le filtrage des tirages et les IDs émis par les boutons.
  - [x] Atteindre 100 nœuds : 83 Core Stats (Vitality et 19 rangs HP; Focused Training et 20 rangs dégâts; Fleet Footed et 20 rangs vitesse; Steady Aim et 20 rangs critique) et 17 déblocages équipement. Le total de 100 est **[VALIDÉ]** dans la plage GDD; la répartition est **[PROPOSÉE]**.
  - [x] Acheter chaque nœud dans l’ordre de prérequis, appliquer les bonus, déverrouiller les 10 armes/11 reliques et rendre tous les coûts au respec gratuit; `progression_service_smoke.gd` couvre le graphe complet.
  - [x] Rendre les prérequis explicites dans les infobulles des 94 nœuds générés; `skill_tree_panel_visual_smoke.gd` vérifie un rang de statistique et un déblocage d’arme sans modifier les règles d’achat.
  - [x] `survival_armorless_mode_smoke.gd` vérifie l’application de tous les bonus persistants et le catalogue complet en Survival et Armorless; le Sandbox reste sans ProgressionService.
  - [x] La somme linéaire indicative des bonus complets donne 29,7 points (10,7 % HP + 9 % dégâts + 6 % vitesse + 4 points de critique); c’est un proxy **[PROPOSÉ]**, pas une mesure d’équivalence de puissance.
  - [x] Analyse arithmétique des coûts **[PROPOSÉS]** : 15 900 Essence pour 100 nœuds, dont 4 160 pour 17 déblocages équipement; à 88 Essence par victoire normale vague 24, un déblocage équipement coûte en moyenne 2,78 victoires équivalentes. `progression_service_smoke.gd` verrouille ce calcul.
  - [ ] Cette moyenne ignore défaites, vente d’équipement et temps de jeu; elle ne prouve pas le rythme ressenti et ne remplace pas les parcours réels de P6.9.
  - [ ] Calibrer la puissance réelle des profils débutant/moyen/complet dans P6.9; décider ensuite si le graphe doit s’étendre au-delà de 100 vers la cible éditoriale **[PROPOSÉE]** d’environ 120.
- [ ] **P6.7 — Achievements**
  - [x] Établir le schéma JSON métrique/catégorie/secret/agrégation/paliers/récompenses, aligné sur `AchievementDefinition` du GDD.
  - [x] Remplacer le suivi isolé d’Exterminator par des métriques et paliers génériques; profils version 8 et migration additive v1–v7, vérifiés par fixtures dédiées.
  - [x] Ajouter 83 familles prototypes dans les huit catégories du découpage **[PROPOSÉ]** du GDD, dont douze compteurs de kills par type d’ennemi, dix suivis de dégâts par arme, dix compteurs de kills par arme, onze records de niveau de relique, dix suivis d’évolution par arme, onze compteurs d’équipements récompensés par rareté et slot, et dix suivis de runs/victoires de boss par difficulté. Les compteurs d’équipement et de difficulté sont dérivés par `ProgressionService`, pas injectables par `run_metrics`. Seuils et bonus restent **[PROPOSÉS]**.
  - [x] Étendre à 100 familles : records de niveau maximal pour chacune des dix armes, éliminations par chacun des six affixes élite et diversité cumulée des six affixes. `progression_service_smoke.gd` vérifie les paliers, le rejet de la variété dérivée falsifiée et la migration des profils v7 à 83 familles; `survival_elite_smoke.gd` vérifie l’enregistrement issu d’une vraie élimination et le niveau d’arme enregistré à la fin de run. Ces nouveaux seuils et bonus restent **[PROPOSÉS]**.
  - [x] Reconstituer les bonus de tous les tiers au chargement, compter les paliers débloqués une fois par run idempotente et les résumer à l’écran de résultat.
  - [x] Ajouter les métriques de build d’armes, reliques et évolutions au bilan de run, ainsi que le suivi de la pièce d’équipement garantie; les entrées métriques inconnues ou invalides sont refusées avant toute sauvegarde.
  - [x] Atteindre le plancher validé de 100 familles; la cible éditoriale de 120 est **[PROPOSÉE]**. Les métriques, seuils et récompenses restent **[PROPOSÉS]** et nécessitent une calibration.
- [x] **P6.8 — Sauvegarde et migrations**
  - [x] `progression_service_smoke.gd` couvre une fixture pour chaque profil supporté v1–v6 et vérifie migration vers v9, données conservées et champs ajoutés; `armorless_records_smoke.gd` couvre en plus la migration v7→v9.
  - [x] Vérifier migration, sauvegarde, backup et restauration après corruption : `save_service_smoke.gd` couvre l’enveloppe générique; `progression_service_smoke.gd` récupère maintenant un profil complet via un nouveau SaveService/ProgressionService et valide ses ressources, runs récompensées et équipements.
  - [x] Vérifier idempotence d’un même `run_id` après recréation du service et rechargement du slot, sans nouveau gain de ressources ni pièce d’équipement.
- [ ] **P6.9 — Calibration**
  - [x] Ajouter `game/tests/progression_balance_survey.gd`, un relevé reproductible en sandbox de profil : nouveau profil, profil intermédiaire (44 nodes Core Stats, 8 % PV / 6 % dégâts / 4 % vitesse / 2,5 points de critique) et arbre complet (100 nodes, 10,7 % PV / 9 % dégâts / 6 % vitesse / 4 points de critique). Il utilise les vrais bonus du service de progression, des sauvegardes temporaires dédiées et ne persiste aucune récompense de run.
  - [x] Comparer une baseline immobile sur les cinq difficultés, trois seeds appariés entre profils. Les résultats détaillés et leurs limites sont consignés dans `docs/qa/TESTS.md`.
  - [x] Ajouter un parcours scripté de déplacement carré, piloté par les actions clavier en jeu, et collecter un premier relevé exploratoire sur les trois profils et cinq difficultés. Cette mesure ne constitue pas une simulation de joueur humain.
  - [x] Ajouter un protocole `kite` au survey : à intervalles simulés réguliers, le contrôleur réel recule et décrit une tangente autour de l’ennemi vivant le plus proche. Trois seeds frais Easy ont produit des runs mobiles sans assistance; ce premier échantillon reste exploratoire.
  - [x] Étendre le survey à 45 runs mobiles appariés (3 profils × 5 difficultés × 3 seeds) sans invincibilité ni kills scriptés; médianes et limites sont consignées dans `docs/qa/TESTS.md`. Aucun tuning **[PROPOSÉ]** n’est modifié.
  - [x] Ajouter un contrôle `loot` au survey : il vise l’orbe XP ou le coffre le plus proche, garde les rayons de collecte normaux et esquive les ennemis proches; le pilote Easy puis les 45 runs appariées (3 profils × 5 difficultés × 3 seeds) sont archivés dans `docs/qa/data/` et leurs limites sont consignées dans `docs/qa/TESTS.md`.
  - [x] Seed explicitement les RNG de la session, du loadout et du coffre avant de démarrer le survey; `loot` s’exécute à ×1 et sa vitesse est inscrite dans le CSV. La répétabilité du contrôleur piloté par frames reste ouverte (voir `progression_balance_loot_repeatability_seed_20261017.csv`).
  - [ ] Collecter des parcours représentatifs avec déplacement joueur et plusieurs seeds; le parcours carré n’est pas un modèle de navigation/évitement humain et le baseline immobile ne mesure pas la durée d’une run complète.
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
  - [x] Vérifier dans une session Armorless que le temps actif et le HP decay continuent en état boss pendant que l'horloge de vague reste gelée, puis continuent après la transition sans reset.
  - [x] Vérifier que la population proposée continue de croître après la vague 24 et que les PV ennemis restent au plafond proposé ×12; les smokes Survival vérifient aussi que le budget ne bloque pas les spawns et que la densité suit la difficulté.
  - [x] Smoke d'intégration accéléré : une session Armorless traverse 12 drafts et choix d'équipement, le boss de vague 12 puis reprend en vague 13; la fin nettoie équipement/Flux temporaires sans ProgressionService ni écriture de save.
  - [x] Mode `--production-duration` : la session traverse 60 vagues de 30 secondes simulées, les 60 drafts et les boss des vagues 12/24/36/48/60 à vitesse ×4; le fixture verrouille les PV, désactive les drops de coffres classiques et tue les boss par script. Cela vérifie les transitions de durée longue, pas la survivabilité ni une partie joueur.
  - [x] Ajouter un survey Armorless sans HP verrouillés ni kills de boss scriptés; il seed les RNG de session/loadout/drafts et mesure des vagues de durée réelle. Malgré cela, un même seed varie avec le pilotage par actions/cadence des frames; les parcours Easy restent exploratoires et ne ferment pas la validation humaine ni ne justifient seuls un changement des multiplicateurs **[PROPOSÉS]** (détails dans `docs/qa/TESTS.md`).
  - [x] Comparer le contrôleur kite à un parcours immobile au seed 20261018, à vitesse ×1 : l’immobile meurt vague 1 après 11,73 s (7 kills); le kite meurt vague 2 après 43,91 s (5 kills). Le même seed kite varie aussi entre exécutions; aucune calibration n’est autorisée par ces parcours synthétiques.
  - [ ] Parcourir une session Armorless complète en durée de production avec ses drafts, ses boss et ses pauses de choix, sans invulnérabilité ni kills scriptés.
- [ ] **P7A.5 — Récompenses ouvertes**
  - [x] Décision utilisateur **[VALIDÉE, 2026-10-16]** : accorder Essence, Powder et achievements à la fin de run Armorless, sans équipement permanent.
  - [x] Appliquer les récompenses et métriques d’achievements avec l’anti-double-attribution partagé; Armorless conserve ses records par difficulté et n’incrémente pas les métriques d’équipement permanent.
  - [x] Afficher ressources, achievements et record dans le résultat de run sans ligne d’équipement.
  - [x] Vérifier qu’un run au-delà de la vague 24 garde sa vague complète pour achievements et calcul de récompenses, sans bonus de boss final ni déblocage de difficulté.
  - [x] Étendre `armorless_records_smoke.gd` pour verrouiller les récompenses **[PROPOSÉES]** aux vagues 24 et 25 sur Easy–Chaos, sans traiter ces valeurs comme calibrées.
  - [x] Vérifier que l’équipement temporaire et le Flux restent supprimés à la fin de run.
  - [ ] Calibrer la formule d’Essence/Powder **[PROPOSÉE]** pour le mode sans fin; elle est linéaire après la vague 24.
- [ ] **P7A.6 — Validation**
  - [x] Tester une vague, une transition boss, un draft, une amélioration et la défaite; `armorless_session_cycle_smoke.gd`, `survival_armorless_mode_smoke.gd` et `armorless_run_state_smoke.gd` couvrent ces chemins.
  - [x] Vérifier l’idempotence des classements avec `armorless_records_smoke.gd`.
  - [ ] Valider une longue session Armorless intégrée en durée de production; les cinq cycles boss jusqu’à la vague 60 sont actuellement couverts par le directeur, pas par une partie complète.
  - [x] Enregistrer et afficher les records locaux Armorless par difficulté, triés par vague puis temps et kills; `armorless_records_smoke.gd` vérifie le classement, l’isolation des récompenses, l’idempotence, le refus des données invalides et la migration v7→v9.
  - [x] Afficher dans le hub le record Armorless de la difficulté sélectionnée; les smokes couvrent la mise à jour par profil et le layout à 640×360, 1280×720 et 1920×1080.
  - [x] Ajouter une vue en lecture seule comparant les records des cinq difficultés; clavier/manette, restauration du focus et layout 640×360, 1280×720 et 1920×1080 sont couverts par les smokes du hub.
  - [ ] Une session Armorless complète reste à valider. Les catégories de récompenses permanentes sont **[VALIDÉES]** : Essence, Basic Powder et achievements, sans équipement; seuls les montants/formules du mode sans fin restent **[PROPOSÉS]** à calibrer.

### P7B — Endless standard (prototype fonctionnel, réglages proposés)

- [ ] **P7B.1 — Contrat de prototype**
  - [x] Prototype **[PROPOSÉ]** choisi sous délégation : déblocage après victoire Survival, lancement depuis le hub ou continuation après le boss, armes/reliques niveau 1 depuis le hub et build/HP conservés en continuation; mort/abandon, records par difficulté, récompenses sans bonus de boss final/équipement garanti.
  - [x] Réutiliser Easy–Chaos; scaling existant jusqu’à 24 puis +5,5 % HP ennemis par vague; mid-boss toutes les 12 vagues, y compris aux vagues 24 et 36. La croissance HP reste **[PROPOSÉE]**.
- [x] **P7B.2 — Prototype implémenté**
  - [x] Ajouter un lancement Endless dans le hub, verrouillé avant victoire Survival; l’entrée réutilise le service de progression normal et la difficulté choisie.
  - [x] Après victoire Survival, proposer `CONTINUE AS ENDLESS`; créditer la victoire, démarrer un nouvel ID de run à la vague 25, conserver HP/build/niveaux, reprendre la simulation et éviter le double crédit Survival. Smoke dans `endless_standard_session_smoke.gd`.
  - [x] Ajouter une smoke de bout en bout pour mort/abandon, résultat, persistance et continuation.
  - [x] Ajouter migration additive du profil v8→v9, records séparés par difficulté et récompenses idempotentes sans équipement garanti; smokes dédiés passent.
  - [x] Ouvrir le mode Endless standard au Sandbox Lab comme troisième mode exécutable; conserver diagnostics, PV verrouillés, coffres normaux désactivés et aucune injection de service de progression/sauvegarde. Les règles de P7B restent **[PROPOSÉES]**.

**Critère de sortie :** Armorless conforme aux règles validées et propositions clairement paramétrées; Endless standard jouable depuis le hub et en continuation immédiate, vérifié pour mort/abandon et persistance. Calibration et maîtrise répétable restent explicitement ouvertes.

## P8 — Sandbox Lab destiné au joueur

P1 livre le Sandbox développeur et ne remplace pas cette feature produit.

- [x] **P8.1 — Entrée et contexte isolé**
  - [x] Ajouter l’accès distinct Sandbox Lab au menu avant sélection/création de save; l’entrée `SANDBOX DEV` reste le Sandbox développeur P1.
  - [x] Ajouter `SandboxLabContext` mémoire : il valide le preset, héberge une session Survival, Endless standard ou Armorless sans service de progression/save, désactive les coffres normaux et gèle le HP; il ne crédite aucune progression et remplace un preset seulement en pause. Les règles d’Endless standard restent identifiées **[PROPOSÉES]**.
  - [x] Smoke dédié utilise un `XDG_DATA_HOME` isolé, vérifie le spawn et le stockage local du preset; aucune donnée n’est écrite sous `user://saves`.
- [x] **P8.2 — Build et configuration**
  - [x] Ajouter des contrôles visuels au Lab pour sélectionner une arme/relique et son niveau, ajouter une stat, puis appliquer le build à la session isolée en pause. Les valeurs restent des outils expérimentaux **[PROPOSÉES]**.
  - [x] Ajouter l’édition d’un équipement de test par slot/stat et des overrides LIVE isolés pour les statistiques existantes; `sandbox_lab_smoke.gd` vérifie l’effet en combat des 12 statistiques, y compris l’isolation du rayon XP et du rayon de coffre, avec actualisation dédiée des dégâts, vitesse et HP maximum.
  - [x] Ajouter l’override LIVE typé `enemy_hp` (×0,1–×1000) au preset et au Lab : il ne change que les HP des ennemis créés ensuite par Spawn; les clés sans contrat runtime et les valeurs hors bornes sont rejetées.
  - [x] Ajouter l’override LIVE typé `enemy_speed` (×0,1–×10) au preset et au Lab; seul le mouvement des ennemis créés ensuite par Spawn change, profils et affixes compris.
  - [x] Régler la taille des lots Spawn dans le Lab (1–500 par commande), la persister dans les presets et valider la limite native de 500 commandes/2 500 entités.
  - [x] Persister le profil ennemi sélectionné par Spawn dans les presets/snapshots; valider les neuf profils ordinaires/Elite et restaurer la sélection sans affecter les vagues normales.
  - [x] Choisir les six affixes Elite existants pour Spawn, les conserver dans preset/snapshot et n’activer le contrôle que sur le profil Elite; leurs effets gardent le statut **[PROPOSÉ]** du GDD.
  - [x] Ajouter Mid Boss et Final Boss au Spawn du Lab; ils apparaissent un à la fois avec les PV de boss configurés pour Survival, et l’option boss reste dans les presets. Les patrons et paramètres de combat conservent leurs statuts de conception existants.
  - [x] Ajouter l’override LIVE typé `contact_damage_per_hit` (0–1000) au preset et au Lab; il s’applique à la prochaine collision de la session isolée et vaut zéro par défaut.
  - [x] Ajouter l’override LIVE `health_decay_multiplier` (×0–×10) au preset et au Lab; il modifie le decay HP uniquement lorsque les diagnostics Sandbox sont activés. Valeur par défaut ×1, limite technique de l’outil.
  - [x] Ajouter `wave_spawning_enabled` (booléen, défaut faux) au preset et au Lab; l’activer réutilise le directeur de vagues Survival uniquement dans la session Sandbox isolée, et snapshots/restauration conservent le réglage.
  - [x] Exposer la seed du preset comme réglage RESTART; elle s’applique au Reset, est persistée, et invalide/refuse un snapshot tant que le redémarrage n’a pas eu lieu.
  - [x] Définir et documenter les cycles LIVE/REBUILD/RESTART et leurs limites de contenu dans `docs/architecture/INTERFACES.md`; les smokes Lab, preset et snapshot vérifient leur validation et leur application atomique. Les niveaux >5 ne sont pas pris en charge car le GDD fixe le niveau maximum à cinq.
  - [x] Ajouter un sélecteur visible et navigable clavier/manette pour les trois modes exécutables Survival, Endless standard et Armorless; le mode choisi est intégré aux presets appliqués/exportés.
  - [x] Ajouter `SandboxBuild` comme modèle isolé : armes/reliques, évolutions appariées, stats personnalisées finies et équipements de test; validation atomique avant remplacement.
  - [x] Ajouter un éditeur JSON initial et appliquer armes/reliques (niveaux 1–5), évolutions appariées, équipements et stats personnalisées à la session de combat existante.
  - [x] Implémenter REBUILD par application en pause du champ `initial_build` et RESTART par seed en attente jusqu’au Reset; le combat conserve le maximum validé de cinq niveaux.
  - [x] Ajouter des overrides LIVE sélectionnables par statistique; ils restent transitoires et sont effacés lors d’une reconstruction du build.
  - [x] Valider atomiquement les champs LIVE, REBUILD et RESTART; les valeurs invalides laissent la session active et son snapshot inchangés.
- [x] **P8.3 — Presets et share codes**
  - [x] Ajouter `sandbox_preset_service.gd` : schéma version 1 fermé et modes Survival/Endless/Armorless; les trois modes sont exécutables dans le contexte Lab isolé.
  - [x] Exporter/importer JSON limité à 1 Mio et refuser champs inconnus, types et métadonnées invalides.
  - [x] Ajouter `DSLAB1:` avec DEFLATE, Base64URL, SHA-256 d’intégrité et décompression plafonnée; smoke de round-trip et corruption.
  - [x] Borner récursivement profondeur (16), collections (256 éléments chacune) et types JSON autorisés; tests hostiles ciblés.
  - [x] Ajouter `SandboxPresetStore` pour sauvegarder, lister, charger et supprimer les presets sous `user://sandbox/presets`; noms bornés et écriture temporaire validée.
  - [x] Brancher les actions preset/share code à l’écran Lab; ajouter l’import JSON par sélecteur de fichier avec validation bornée avant application et l’export JSON par sélecteur de destination.
  - [x] Refuser récursivement dans les payloads les champs nommés comme script, commande, chemin système ou donnée d'identité; les codes ne sérialisent que les champs du schéma public v1 et aucun service de save/progression n'est injecté.
- [x] **P8.4 — Import de sauvegarde**
- [x] Ajouter `SaveService.read_slot_read_only` : lit et vérifie le slot courant sans migration, restauration de backup ni écriture; le smoke couvre un ancien payload et un slot courant corrompu.
- [x] Ajouter `IMPORT NORMAL PROFILE · READ ONLY` au Sandbox Lab : lit le slot courant, valide strictement le profil courant en mémoire et refuse les profils anciens/incomplets sans les migrer.
- [x] Construire une copie Sandbox modifiable contenant starters, unlocks d'armes/reliques du skill tree, bonus stats d'achievements/skill tree et équipement équipé; les ressources et l'historique de progression ne sont pas copiés.
- [x] Comparer la sauvegarde source avant/après et tester import courant, profil ancien et profil invalide; le contexte/session Lab ne reçoit toujours aucun service de save/progression.
- [x] **P8.5 — Outils de simulation**
  - [x] Ajouter God Mode commutable qui ne verrouille que le HP de la session Lab isolée; Survival normal n’est pas modifié.
  - [x] Première tranche UI ajoute pause, vitesse, spawn d’ennemis, kill all, clear projectiles et reset à la session de combat isolée.
  - [x] Ajouter `RESET COOLDOWNS` au Sandbox Lab; la commande réinitialise les dix horloges d’attaque de la session isolée et ne touche ni la progression ni les sauvegardes normales.
  - [x] Ajouter `JUMP WAVE` dans le Lab, avec cible 1–999, remise à zéro du timer et retour à l’état vague; les spawns automatiques restent désactivés. Le smoke couvre aussi le rejet des cibles hors plage.
  - [x] Ajouter `RESTORE HP` pour remplir les PV du joueur Lab sans modifier le bouclier ni avancer simulation/horloges; une session terminée exige Reset. La commande reste un prototype **[PROPOSÉ]** du GDD.
  - [x] Préserver le réglage God Mode lors d’un import de preset qui reconstruit la session; la régression vérifie le cas désactivé.
  - [x] Afficher les DPS 1 s, 10 s et cumulés, ventilés par type de source arme/évolution/effet; afficher un journal RNG contextualisé à seed fixe. Les échantillons DPS sont limités aux dix dernières secondes (4096 maximum) et le journal conserve 256 tirages, dont les six plus récents sont visibles.
- [x] **P8.6 — Snapshots**
  - [x] Inventorier l’état minimal à capturer, y compris RNG, horloges, queues et build; contrat et lacunes actuelles consignés dans [`SANDBOX_SNAPSHOT.md`](SANDBOX_SNAPSHOT.md).
  - [x] Exposer le checkpoint natif et capturer/restaurer sans perte une scène simple; `sandbox_snapshot_smoke.gd` vérifie un ennemi et l’état pause.
  - [x] Vérifier le rejet de version incompatible par l’API Godot, ainsi que commandes en attente et séquences dans `simulation_worker_test`; `sandbox_snapshot_smoke.gd` couvre aussi la barrière Godot→worker, les commandes soumises avant capture et la séquence après restauration.
  - [x] Documenter format opaque en mémoire, état hors worker et limites du déterminisme dans `SANDBOX_SNAPSHOT.md`; le Lab capture/restaure maintenant en mémoire l’état natif, la session Godot (RNG, horloges, joueur, vague), le build et les overrides LIVE.
  - [x] Ajouter `CAPTURE SNAPSHOT` / `RESTORE SNAPSHOT`, disponibles en pause; vérifier la reprise complète et le rejet sans mutation d’une version inconnue, d’un build dépassant les slots ou d’une évolution avant que l’arme et sa relique soient toutes deux niveau 5.
- [x] **P8.7 — Limites et sécurité**
  - [x] Mesurer le plafond de 2 500 entités (500 ennemis + 2 000 projectiles) : RSS haut de page 7 960 KiB sur Linux Debug; métriques et limites dans `docs/qa/PERFORMANCE.md`.
  - [x] Pour le quota ECS utilisé par l’outil Spawn, avertir quand un lot ne tient plus et conserver le hard cap natif de 2 500; les limites internes de commandes/événements restent bornées par le worker. Calibration des seuils et politiques de surcharge toujours **[OUVERTES]** sur matériel cible.
  - [x] `sandbox_preset_smoke.gd` rejette clés de script/commande/chemin/données privées, profondeur/collections/taille hors limites et share codes corrompus; les presets ne contiennent que le schéma public fermé et ne déclenchent pas d’action ou d’accès fichier arbitraire.
- [x] **P8.8 — Validation d’isolation**
  - [x] Vérifier l’absence de `ProgressionService` et `SaveService` dans la session/context Lab; aucun crédit Essence/Powder, achievement ou leaderboard n’est raccordé à cette route.
  - [x] Vérifier que preset, build de combat, reset et capture/restauration snapshot préservent octet pour octet un slot normal sentinelle; les tests de partage/import preset et d’import profil read-only couvrent aussi checksum/validation et source inchangée. Les tests tournent avec `XDG_DATA_HOME` isolé.

**Critère de sortie :** expérimentations librement configurables, persistables/partageables et isolées de la progression normale.

## P9 — Équilibrage, accessibilité, polish et livraison

- [ ] **P9.1 — Équilibrage combat**
  - [x] Collecter DPS/survie par arme et archétype sur une configuration documentée; matrice stationnaire de 360 cas et pilote orbit sur 12 archétypes dans `docs/qa/data/`, limites dans `docs/qa/TESTS.md`.
  - [x] Comparer les dix armes aux niveaux 1, 5+relique 5 et évolution sur formations `single`, `cluster` et `approach` avec `combat_weapon_balance_survey.gd`; les valeurs brutes et les limites sont consignées dans `docs/qa/TESTS.md`. Une collecte par cas reste exploratoire et ne calibre pas les paramètres proposés.
  - [ ] Ajuster les valeurs proposées via données de balance, pas par changements cachés.
- [ ] **P9.2 — Économie et durée**
  - [ ] Mesurer durée réelle d’une run et fréquence de choix chest.
  - [ ] Mesurer Essence/Powder et progression de profils de niveaux différents.
  - [ ] Vérifier paramètres de soin/decay/lifesteal en modes retenus.
- [ ] **P9.3 — Présentation audiovisuelle**
  - [ ] Vérifier feedback des dégâts directs/critique/statut.
  - [x] Les impacts critiques réutilisent le sprite d'impact de l'arme à 1,45× (**[PROPOSÉ]**, sans nouvelle couleur); `survival_visual_effects_smoke.gd` vérifie qu'un événement critique d'un projectile natif Minigun atteint le renderer, compare le nombre de pixels rendus normal/critique et confirme que la simulation reste en pause et que le flux RNG ne change pas. La lisibilité sur GPU cible reste à vérifier.
  - [x] Ajouter un screen shake caméra visuel sur les impacts directs, proportionnel aux dégâts et plafonné à 3 px; les réglages de départ (0,02 px/dégât, durée 0,12 s simulée) restent **[PROPOSÉS]** et configurables. `survival_visual_effects_smoke.gd` vérifie le plafond, le retour à l’offset de base, le respect des effets réduits et l’absence de mutation de la simulation.
  - [x] Vérifier par rendu que les indicateurs Burn, Poison, Bleed, Chill et Shock apparaissent autour des ennemis et restent visibles avec les effets décoratifs réduits; `survival_impact_status_visual_smoke` compare l’image aux mêmes ennemis sans statut. Leur mapping couleur reste **[OUVERT]** selon l’Art Bible.
  - [x] Vérifier les télégraphes au milieu d’effets chargés; `survival_combat_visual_smoke.gd` rend maintenant la charge du Pulse Warden sur la capture du combat dense et confirme un pixel du télégraphe dans l’image.
  - [x] Vérifier le rendu des faisceaux primaire et secondaire Prism, y compris lorsque les effets décoratifs sont réduits; `survival_combat_visual_smoke.gd` confirme leurs pixels centraux dans les deux captures. Leur couleur reste **[OUVERTE]** selon l’Art Bible.
  - [x] Ajouter une option VFX persistante dans Options : trails, impacts décoratifs, pixels de mort, arcs Lightning et flashs Pandemic sont masqués; télégraphes et cues de gameplay restent visibles. Le périmètre/default restent **[PROPOSÉS]** et sont couverts par `survival_visual_effects_smoke.gd` et `ui_settings_smoke.gd`.
  - [ ] Régler l’audio par vague/boss.
  - [ ] Remplacer progressivement les assets placeholders, un lot visuel par lot.
  - [x] Remplacer le placeholder du Pulse Warden par un prototype non canonique 96×96, palette maître 16 couleurs, source Aseprite éditable et route de renderer vérifiée; l’identité visuelle reste **[OUVERTE]**. Les deux exports placeholder historiques restent archivés mais ne sont pas utilisés en jeu.
- [ ] **P9.4 — Accessibilité et commandes**
  - [x] Vérifier par événements synthétiques dans `survival_hub_smoke.gd` l’accès clavier/manette à Succès et Bestiaire, leur focus visible et leur inertie à l’activation souris/clavier/manette; les périphériques physiques restent à tester.
  - [x] Vérifier dans `skill_tree_panel_visual_smoke.gd` une navigation à la flèche et au D-pad, puis l’activation Entrée/A d’un nœud avec son ID stable; le test observe le signal sans acheter le nœud ni modifier un profil.
  - [x] Vérifier dans `equipment_panel_visual_smoke.gd` l’activation clavier/manette d’une action et le déplacement du focus au D-pad; seuls les signaux sont observés, sans équiper ni démanteler l’objet.
  - [x] Vérifier dans `ui_settings_smoke.gd` les flèches du volume, Espace/A du plein écran et Échap/B pour fermer les Options; les préférences du smoke sont réinitialisées.
  - [x] Vérifier dans `run_result_panel_smoke.gd` la reprise au clavier, le déplacement D-pad vers quitter puis A, et la fermeture par B; seuls les signaux de navigation sont déclenchés.
  - [x] Vérifier dans `survival_pause_smoke.gd` flèche bas/Entrée pour ouvrir Options, A pour ses contrôles, Échap/B pour revenir/reprendre, et Espace/A pour les réglages de pause; les horloges et positions sont assertées gelées.
  - [x] Vérifier dans `survival_pause_inventory_smoke.gd` Entrée pour ouvrir l’inventaire, flèche/D-pad pour parcourir les objets et B pour fermer; A sur un objet en lecture seule ne change pas le loadout.
  - [x] Parcourir le flux clavier accueil → Options → hub → choix de l’arme de départ → coffre → pause → Options → inventaire de run → reprise dans `keyboard_menu_journey_smoke.gd`; les panneaux Équipements et Arbre de compétences sont couverts par `survival_hub_smoke.gd`. Cette preuve synthétique ne valide pas encore le rendu ni les périphériques sur matériel réel (P9.7).
  - [x] Parcourir les mêmes écrans au D-pad/A/B avec focus visible vérifié dans `gamepad_menu_journey_smoke.gd`; la validation d’une manette physique et du rendu sur écran réel reste en P9.7.
  - [x] Contrôler le contraste des labels `InactiveButton`, `Button` désactivé et `OptionButton` désactivé; `survival_hub_smoke.gd` impose 4,5:1 minimum. Les valeurs utilisent maintenant `#A5AEC3` de la palette ART_BIBLE, avec 6,94:1 sur le fond `#1B2340`.
  - [x] Vérifier le contraste configuré des libellés de santé, XP, équipement, temps, vague et difficulté du HUD; `survival_hud_smoke.gd` impose 4,5:1 contre le fond CompactPanel.
  - [x] Vérifier le contraste composite du HUD santé/XP/loadout, méta et badge contre les quatre fonds de scène de la palette ART_BIBLE; `survival_hud_smoke.gd` compose la couleur des panneaux puis exige 4,5:1 pour chaque libellé.
  - [ ] Vérifier la taille/hiérarchie du HUD et les réglages d’effets sur écran réel.
- [ ] **P9.5 — Performance**
  - [ ] Fixer le matériel iGPU de référence et la scène de charge.
  - [ ] Mesurer frame-time CPU/GPU, mémoire, P50/P95/P99.
  - [x] Refaire trois mesures P50/P95/P99 du cœur natif sur l’hôte KVM courant et consigner leur variabilité dans `docs/qa/PERFORMANCE.md`; cette baseline ne couvre ni une vague représentative ni le GPU de référence.
  - [ ] Refaire les mesures après optimisations et archiver la configuration.
- [x] **P9.6 — Stabilité/saves**
  - [x] Ajouter et exécuter `cmake --build build --target stability_soak`, cible opt-in hors CTest rapide : 600,4 s Survival/46 sessions, 129,2 s Endless/10, 130,2 s Armorless/10 et 600,1 s Sandbox/40 lots d’ennemis, sans mutation détectée de `user://saves`; détail et limites dans `docs/qa/TESTS.md`.
  - [x] Tester un fichier temporaire de sauvegarde partiellement écrit, un slot absent avec backup valide, la restauration, le nettoyage au prochain enregistrement et les migrations; limites du scénario dans `docs/qa/TESTS.md`.
  - [x] Vérifier l’idempotence des récompenses après redémarrage du service et l’arrêt/join du worker, y compris sous soumission concurrente; `progression_service_smoke.gd` et `simulation_worker` couvrent ces chemins.
- [ ] **P9.7 — Plateformes**
  - [x] Refaire le build et l’export Linux depuis un snapshot Git propre avec un répertoire CMake vierge sur l’hôte courant; le probe release instancie `CombatSimulation` dans une session. La compilation et les limites sont consignées dans `docs/qa/TESTS.md`.
  - [x] Exclure les répertoires de développement `tests/`, `tools/` et `assets/source/` du preset d’export Linux; vérifier le démarrage de l’exécutable filtré et consigner le delta de taille dans `docs/qa/TESTS.md`.
  - [ ] Refaire build Linux et parcours sur une machine distincte; l’hôte de validation courant est virtualisé.
  - [x] Ajouter un preset Linux/X11 et une route `linux.release.x86_64` pour la GDExtension; le PCK 4.7.2 s’exporte sans warning, se charge avec le runtime Linux et l’extension debug, et les quatre checks import/Sandbox/catalogue passent. C’est une validation de pack et de chargement sur l’hôte courant, pas un export autonome.
  - [ ] Refaire build Windows propre et lancer la GDExtension.
  - [ ] Tester contrôles, chemins et rendu sur les deux plateformes.
  - [x] Vérifier le SHA-512 officiel des templates Godot 4.7.2, installer le template Linux release x86_64, exporter `build/linux/export/DopamineSurvivor.x86_64` et lancer le menu trois frames en headless; détails dans `docs/qa/TESTS.md`.
  - [x] Confirmer que le processus autonome mappe `libdopamine.linux.template_release.x86_64.so`. La vérification directe d’instanciation de `CombatSimulation`, d’abord restée ouverte après ce seul contrôle de chargement, a ensuite été réalisée dans une session reconstruite avec le même template release et la même extension; voir la preuve du snapshot propre ci-dessus et `docs/qa/TESTS.md`.
  - [x] Naviguer par entrée clavier synthétique depuis l’accueil, passer par le hub et démarrer une run Survival depuis l’exécutable exporté; le HUD `IN RUN` et l’arme de départ s’affichent sans erreur d’indisponibilité de `CombatSimulation`.
  - [x] Copier l’exécutable et son sidecar GDExtension vers un répertoire extérieur au dépôt, démarrer avec un `XDG_DATA_HOME` vierge et quitter proprement. Cette relocation vérifie l’absence de dépendance aux chemins du checkout, mais reste sur le même hôte.
  - [ ] Refaire le parcours clavier/contrôleur et le rendu sur un poste Linux avec matériel réel; le contrôle courant utilise Xvfb/Mesa llvmpipe.
- [ ] **P9.8 — Préparation de livraison**
  - [x] Établir [`docs/release/RELEASE_CHECKLIST.md`](../release/RELEASE_CHECKLIST.md); le choix de version d’artefact reste **[OUVERT]** et n’est pas inventé.
  - [x] Comparer l’inventaire Godot au template Linux release 4.7.2 effectivement utilisé; autres templates et inclusion des notices dans les paquets restent à vérifier.
  - [x] Vérifier un paquet Linux staging non versionné avec notices, extraction propre et démarrage headless; ce n’est pas l’artefact final. Détails dans `docs/qa/TESTS.md`.
  - [x] Reconstruire et vérifier un nouveau staging depuis le commit `86351b6` avec CMake vierge : Release, archive filtrée, notices/licences, dépendances, SHA-256 et démarrage extrait passent. Ce paquet reste non versionné et non distribuable.
  - [ ] Vérifier contenu, dépendances, licences, sauvegarde et notes de version.
  - [ ] Préparer publication après validation des critères, sans la confondre avec un build local.

**Critère de sortie :** critères de contenu, stabilité, performance, plateformes et QA mesurés, datés et approuvés.

## Registre des décisions et pièges d’implémentation

- Les dix armes + Magnet Heart font onze reliques au total : dix reliques associées et une utilitaire. Cinq slots normaux sont une capacité, pas une taille de catalogue.
- Les exceptions de capacité Legendary/Mythic v1.5 ne s’activent que si l’effet correspondant fonctionne et suit sa règle de non-cumul.
- Les réactions nommées encore marquées **[PROPOSÉES]** ne sont pas une autorisation implicite de les implémenter. Overcharge est maintenant **[VALIDÉE]** comme règle, avec ses paramètres de prototype toujours **[PROPOSÉS]**.
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
