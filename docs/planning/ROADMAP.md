# Roadmap complète — Dopamine Survivor, GDD v1.6

Cette roadmap transforme le [GDD consolidé v1.6](../gdd/GDD_v1.6.md), l’architecture, les ADR et les documents QA en travaux ordonnés et vérifiables. Elle décrit l’état constaté dans le dépôt au 2026-10-15 ainsi que le chemin restant. Elle ne remplace pas les décisions de ces documents.

**Ordre de travail :** Linux-first ; Sandbox développeur MVP d’abord ; Survival jouable ensuite ; contenu P5 avant progression P6. Le cœur de simulation est partagé, mais la progression et les sauvegardes normales restent inaccessibles au Sandbox. La consigne de portée active est de s’arrêter après P5.

## Comment lire l’audit

- **Présent** : code ou données identifiables dans le dépôt. Cela ne certifie pas l’équilibrage ni le fonctionnement à l’exécution.
- **Prototype** : un chemin fonctionne pour un sous-ensemble, avec contenu ou contrat incomplet.
- **À faire** : aucune implémentation suffisante n’a été trouvée dans les scènes/scripts/données inspectés.
- **QA historique** : `docs/qa/TESTS.md` décrit un test réellement exécuté antérieurement. Les coches ne signifient pas qu’il a été relancé pendant cet audit.
- **[VALIDÉ] / [PROPOSÉ] / [OUVERT]** décrivent le statut de conception du GDD, pas l’état d’implémentation. Une valeur proposée codée en dur reste proposée.

L’audit courant est statique. Godot/Godot 4 n’est pas détecté dans le PATH de cet environnement ; les tests GDScript et la scène fenêtrée n’ont donc pas été relancés. Les preuves d’exécution citées ci-dessous sont celles archivées dans les QA précédentes. Aucun statut de conception n’est promu par cette roadmap.

## Résumé d’avancement vérifié

| Jalon | État du code constaté | Ce qui manque pour le fermer |
|---|---|---|
| P0 Fondations | **Présent, Linux documenté** | Reproductibilité sur installation propre et build/chargement Windows. |
| P1 Sandbox développeur MVP | **Présent et bien couvert historiquement** | Continuer d’exposer les nouveaux systèmes et maintenir l’isolation au fil des intégrations. |
| P2 Simulation/combat | **Fondation présente, couverture partielle** | Diversité des IA, règles complètes d’ennemis/boss, instrumentation et performance iGPU. |
| P3 Prototype de combat | **Trois paires et trois évolutions de prototype présentes** | Contrats génériques, retours visuels par niveau, ciblage fidèle, mesures DPS détaillées. |
| P4 Vertical slice Survival | **Boucle de run prototype présente** | Boss réels, difficulté sélectionnable, run équilibrée et vérifiée sans harness. |
| P5 Contenu v1.6 | **Non livré** | 7 armes, 8 reliques, Magnet Heart, contenu complet de progression/évolutions, 8–12 familles ennemies et boss multi-phases. |
| P6 Progression permanente | **Prototype anticipé seulement** | Catalogue complet, règles et contenus validés, récompenses calibrées et effets uniques actifs. |
| P7 Modes Endless | **À faire** | Armorless complet ; arbitrages nécessaires pour Endless standard. |
| P8 Sandbox Lab joueur | **À faire au-delà des outils développeur P1** | Builds libres, presets/import/export, copie de save, snapshots complets et règles de sécurité. |
| P9 Qualité et livraison | **Partiel** | Performance sur vrai iGPU, accessibilité/VFX/audio, stabilité prolongée et Windows. |

### Lecture rapide : livré, prototype ou survolé

**Bien intégré comme fondation :** simulation native découplée de Godot, worker, commandes/snapshots, limites de charge, outils Sandbox, loop de run Survival, pause/chest/XP, trois armes et effets de combat de base, sauvegarde versionnée, premiers écrans d’équipement.

**Intégré en prototype, à ne pas confondre avec une feature finie :** boss (apparition/HP/transition, mais pas leurs patterns), XP auto-bonus, loot/probabilités, trois évolutions, équipement et enhancement, deux nodes de skill tree, famille Exterminator, effets uniques, récompenses de run. Les paramètres restent souvent **[PROPOSÉS]**.

**Survolé ou absent par rapport au GDD :** 7 armes et 8 reliques restantes dont Magnet Heart ; animation/identité spécifique à chaque niveau ; dagues réellement orbitantes dans Bloodstorm (le code actuel tire des projectiles en éventail) ; 8–12 familles ennemies et leurs rôles ; élites à affixes ; boss à phases ; difficultés ; réactions élémentaires nommées ; tree ~120 nodes ; achievements ~120 familles ; modes Endless ; Sandbox Lab joueur ; performance iGPU et build Windows.

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

- [ ] Documenter les versions réellement détectées et une procédure de machine Linux propre, incluant import, build, lancement et répertoire de données.
- [ ] Distinguer les dépendances récupérées par CMake des dépendances préinstallées ; rendre leur résolution et leurs erreurs lisibles.
- [ ] Construire le projet et charger l’extension sous Windows selon ADR-013 avant de revendiquer la plateforme.
- [ ] Ajouter une vérification automatisée Linux/Windows si la stratégie de livraison le demande ; ne pas introduire CI comme décision produit implicite.
- [ ] Vérifier les artefacts générés et les chemins utilisateur pour qu’aucun build local ou save ne pollue le dépôt.

**Critère de sortie :** un clone propre s’importe, se compile et démarre sous Linux ; compatibilité Windows séparément vérifiée avant livraison Windows.

## P1 — Cœur partagé et Sandbox développeur MVP

**Intention :** disposer du premier environnement de combat observable, sans sauvegarde ni progression normale.

### État constaté

- Le Sandbox expose spawn/despawn, kill all, pause/reprise, Step explicite, vitesse, reset, sélection/inspection d’entité, métriques et logs.
- Il y a des scénarios JSON et une exportation de résultats.
- Le cœur natif utilise worker dédié, handles index/génération, snapshots immuables, files bornées et arrêt coordonné.
- L’isolation des saves est décrite comme vérifiée par slot sentinelle dans la QA historique ; les scripts de Sandbox ne reçoivent pas le service de progression.

### Travaux/critères de maintien

- [ ] Garder chaque nouvelle commande contrôlée, bornée, observable et rejetée sans mutation partielle en cas de configuration invalide.
- [ ] Pour chaque nouveau comportement de combat, proposer un scénario Sandbox reproductible ou expliquer pourquoi il ne relève pas de la simulation partagée.
- [ ] Vérifier à toute intégration de progression qu’aucun chemin Sandbox ne charge `SaveService`, n’émet une récompense officielle ou ne modifie un profil.
- [ ] Conserver l’inspection et les logs utiles aux événements de dégâts, statuts, morts, pickups et boss.

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

- [ ] Définir séparément états/effets : dégâts directs, DoT, Shock, Burn, Bleed, Poison, Freeze, knockback et résistances nécessaires aux armes réellement retenues.
- [ ] Décider/consigner si un statut remplace, cumule, rafraîchit ou empile ses instances ; garder les réactions nommées non implémentées tant qu’elles ne sont pas validées.
- [ ] Définir les enveloppes d’événements, IDs/idempotence, ordre des modificateurs et budgets des effets en chaîne selon ADR-007 et les ADR proposés.
- [ ] Ajouter des politiques d’IA d’ennemi distinctes (distance, soutien, explosif, etc.) sans confondre leur identité de données avec un type de mouvement générique.
- [ ] Maintenir les frontières d’autorité joueur/boss/simulation explicites, sans deux propriétaires d’un même état mutable.
- [ ] Tester scénarios de grandes avances, expirations, statuts concurrents, ennemis morts/handles périmés et budgets d’événements.
- [ ] Exposer les comportements testables dans Sandbox et ses métriques.
- [ ] Profiler les charges représentatives et relever P50/P95/P99 ; les benchmarks natifs existants ne prouvent pas le budget de frame GPU/CPU d’un iGPU.

**Critère de sortie :** les comportements réellement retenus sont inspectables, bornés, cohérents avec leur horloge et testés sous différents pas de simulation.

## P3 — Contrats de contenu prototype, évolution et DPS

**Intention :** valider un petit nombre de parcours complets et les outils qui permettront d’industrialiser le catalogue P5.

### État constaté

- `survival_loadout.gd` définit 3 armes, 3 reliques, niveau maximal 5, cinq slots et deux armes de départ codées.
- Les prototypes présents sont Lightning Conductor/Storm Core, Inferno Sprayer/Infernal Heart et Crimson Daggers/Blood Chalice ; l’évolution et les réglages restent provisoires.
- Les QA historiques couvrent impacts, dégâts, lifesteal, brûlure, saignement, explosion Wildfire et branches Infinite Circuit.
- Le DPS Sandbox documenté additionne les événements de dégâts sur le temps simulé, mais n’est pas un panneau complet par arme, statut, critique et fenêtre.
- La définition de contenu reste principalement dans des constantes/scripts ; catalogue data-driven complet non établi.

### Travaux

- [ ] Créer les contrats de données d’arme/relique/évolution : ID stable, cible, effets par niveau, conditions, source, icônes et statut de validation.
- [ ] Garder les comportements distincts et fortement influencés par le placement, comme demandé par le GDD.
- [ ] Vérifier chaque niveau 1–5 et rendre visible l’augmentation, même lorsque celle-ci est principalement statistique.
- [ ] Remplacer le tir en éventail des Crimson Daggers par le comportement orbitant requis pour Bloodstorm avant de déclarer cette paire conforme.
- [ ] Implémenter une seule évolution automatique à niveau 5 si la relique associée est possédée à n’importe quel niveau ; ne pas consommer la relique et conserver le niveau 5.
- [ ] Exclure les armes niveau 5 déjà évoluées ou en attente d’évolution des choix ordinaires, sans doublons normaux ; permettre les doublons uniquement dans Sandbox.
- [ ] Étendre les métriques DPS pour pouvoir isoler source, arme/évolution, cible, critique et statut si cela aide au balancing.
- [ ] Ajouter une couverture Sandbox aux niveaux, évolutions, synergies émergentes et effets secondaires bornés.
- [ ] Mettre à jour ADR-014 et proposer les ADR-015/016 seulement lorsque les contrats sont mûrs ; préserver leur statut documentaire.

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

- [ ] Vérifier le parcours normal au clavier/manette depuis l’entrée jusqu’à mort/victoire, sans injection de dégâts ni choix automatique du harness.
- [ ] Compléter les cas d’offre de chest vide, slots pleins, objets niveau 5, choix successifs, pause/reprise, rerolls et déclenchement immédiat de l’évolution.
- [ ] Implémenter les comportements de boss lisibles 2–3 phases et changements de patterns ; les patterns et noms doivent rester **[PROPOSÉS]** tant qu’ils ne sont pas décidés.
- [ ] Confirmer les horloges : timer de vague arrêté pendant boss ; HP decay actif pendant tout gameplay, suspendu sur vraie pause/choix/modal.
- [ ] Distinguer clairement victoire, défaite, reprise locale et crédit de récompense persistante idempotent.
- [ ] Remplacer le prototype d’XP auto-bonus par la règle retenue quand sa courbe et ses bonus auront été définis ; les valeurs restent proposées.
- [ ] Garder le contrat de sauvegarde hors du Sandbox et prévoir des essais de migration/reprise avant d’étendre les profils.

**Critère de sortie :** Survival se joue bout en bout avec règles lisibles et transitions cohérentes. Une run harness ne ferme pas les critères de balancing.

## P5 — Contenu de combat v1.6 : armes, reliques, ennemis et boss

**Intention :** atteindre la quantité et la variété du GDD. Le code actuel contient seulement les prototypes de trois paires ; P5 n’est donc pas livré.

### P5.1 — Catalogue de dix armes et onze reliques

Catalogue d’évolution défini dans le GDD :

| Arme | Relique associée | Évolution | État au code-audit |
|---|---|---|---|
| Lightning Conductor | Storm Core | Infinite Circuit | Prototype présent ; QA historique ciblée. |
| Inferno Sprayer | Infernal Heart | Wildfire | Prototype présent ; QA historique ciblée. |
| Crimson Daggers | Blood Chalice | Bloodstorm | Prototype présent ; dagues en éventail, alors que le GDD exige une tempête orbitale. |
| Void Orb | Singularity | Event Horizon | Absent. |
| Frost Nova | Frozen Crown | Absolute Zero | Absent. |
| Minigun | Overdrive Engine | Redline | Absent. |
| Meteor Staff | Celestial Eye | Starfall | Absent. |
| Sawblades | Magnetic Coil | Razorstorm | Absent. |
| Toxic Cloud | Plague Mask | Pandemic | Absent. |
| Prism Laser | Prism Crystal | Spectrum Collapse | Absent. |
| — | Magnet Heart (relique utilitaire) | Aucune | Absent. |

Travail requis :

- [ ] Porter le catalogue à 10 armes et 11 reliques sans remplir artificiellement les cases par des variantes de dégâts.
- [ ] Créer les politiques de ciblage et de déplacement propres aux armes ; l’efficacité doit dépendre notablement du positionnement.
- [ ] Définir/charger les niveaux 1–5, progressions visuelles, cinq niveaux de relique et évolution visuellement majeure.
- [ ] Implémenter la règle d’évolution automatique unique et le comportement du pool de chest indiqué en P3.
- [ ] Intégrer Magnet Heart aux offres sans paire d’évolution. Bonus de collecte limité aux collectibles autorisés par le GDD ; ne jamais attirer ni collecter un chest via `pickup_radius`.
- [ ] Conserver cinq slots de reliques normaux ; appliquer les extensions Legendary/Mythic uniquement si l’effet unique correspondant est réellement actif et conforme.
- [ ] Garder les chiffres des tables de progression comme **[PROPOSÉS]**, configurables, tant qu’ils ne sont pas arbitrés.

### P5.2 — Statuts et synergies

- [ ] Établir le besoin gameplay de chaque statut et les règles de cumul/rafraîchissement/durée avant de relier tout le catalogue.
- [ ] Distinguer les synergies émergentes de réactions élémentaires explicitement codées. Les réactions nommées en annexe restent **[PROPOSÉES]** ; Overcharge est **[OUVERT]**.
- [ ] Si les réactions sont validées plus tard, implémenter les limites de causalité, les budgets de chaîne et l’instrumentation avant de multiplier les sources de déclenchement.
- [ ] Couvrir dégâts directs, DoT, lifesteal et interactions avec les événements de mort sans double attribution.

### P5.3 — Coffres et économie de run

- [ ] Vérifier trois options uniques, préférence de synergie, anti-malchance, disponibilité lorsque slots pleins et exclusion des armes niveau 5 non évoluées.
- [ ] Assurer pause complète du gameplay pendant le choix ; un éventuel écran d’inventaire reprend seulement si la simulation tournait avant ouverture.
- [ ] Faire le check d’évolution après chaque acquisition/amélioration.
- [ ] Ne pas figer les taux 0,5 %, 15 %, poids, pity, rerolls ni substitution sans arbitrage : ce sont des nombres proposés/ouverts.
- [ ] Garder la collecte de chest à proximité ou interaction et son rayon propre. Code présent : `chest_collection_radius` est distinct du rayon d’orbes XP ; l’invariant doit rester couvert pour tout nouveau bonus.

### P5.4 — Ennemis, élites et boss

- [ ] Livrer 8–12 familles jouables couvrant au minimum mêlée, rapides, tanks, distance, soutien et explosifs avec rôles compréhensibles.
- [ ] Construire buffs, protection, invocations et interactions de groupe comme comportements bornés et visibles.
- [ ] Ajouter élites à affixes, budget de menace/cooldown et projectiles télégraphiés esquivables.
- [ ] Concevoir mid-boss vague 12 et boss final vague 24 avec 2–3 phases lisibles ; conserver les exemples de noms/patterns au statut proposé.
- [ ] Décliner les difficultés Easy → Normal → Hard → Nightmare → Chaos et déblocage séquentiel. Les multiplicateurs chiffrés restent proposés.
- [ ] Ne pas considérer les quatre profils natifs actuels comme catalogue final : ils ne donnent pas à eux seuls support, explosif, affixes, élites ou bosses multi-phases.

### Vérification et sortie P5

- [ ] Smoke unitaire de chaque arme/relique/niveau/évolution dans Sandbox ; comparer ciblage, événements et effets.
- [ ] Tests de coffres : slots/niveaux pleins, pas de doublon, pause, rerolls, évolution immédiate et exclusion absolue du chest du ramassage augmenté.
- [ ] Tests d’ennemis : chaque famille, affixes compatibles, télégraphes esquivables, invocation/effets bornés et boss multi-phases.
- [ ] Run Survival complète avec contenu de release, sans harness qui gonfle les HP, choisit les coffres ou tue les boss à la place du joueur.
- [ ] Revue des GDD, interfaces et ADR ; mise à jour des statuts sans convertir les propositions en décisions.
- [ ] Batterie de QA de checkpoint, suivi des performances et commit explicite du jalon.

**Critère de sortie :** dix armes, onze reliques, leurs évolutions, 8–12 familles, élites et boss utilisables dans une run complète ; Sandbox et progression séparés. À la fermeture de P5, s’arrêter conformément à la portée active.

## P6 — Progression permanente (code anticipé, jalon incomplet)

**Intention :** transformer le prototype de profil v5, équipement, enhancement, arbre et succès en boucle complète et calibrée. L’existence du service ne signifie pas la fermeture du jalon.

### État actuel et écarts

- `SaveService` possède format versionné/checksum/backup et QA historique de migration/altération.
- `ProgressionService` possède profils v5, récompenses de run, idempotence par `run_id`, inventaire, six slots, cinq raretés, stat lines, enhancement, conversion Powder, deux nodes de prototype et Exterminator.
- Le générateur choisit pour l’instant une distribution de rareté Normal fixe et propose les plages de rolls ; les changements de difficulté et pénalité de mort précoce manquent.
- Les achievements ne couvrent qu’un compteur de kills avec quatre paliers ; ce n’est pas le catalogue cible de 100–150 familles.
- Les nodes sont deux prototypes, pas le graphe interconnecté de 100–150.
- Quatre effets uniques ont un chemin gameplay prototype selon QA ; `free_first_chest_reroll` et `revive_knockback` sont stockables mais sans effet. `elite_haste` ne constitue pas un comportement vérifié tant que le système d’élites ne le déclenche pas.
- Des bonus de stat sont consommés dans Survival ; `pickup_radius_pct` augmente actuellement le rayon des orbes XP seulement et le chest a son propre rayon.

### Travaux

- [ ] Vérifier les six slots, unicité des lignes, valeurs, equip/replace, inventaire illimité et une pièce garantie après victoire comme défaite classique.
- [ ] Finaliser les rolls selon difficulté, vague et mort précoce, après calibration/validation des nombres proposés.
- [ ] Relier chaque stat aux systèmes concernés ; auditer spécifiquement HP, vitesse, critique, lifesteal, aire, cooldown, XP, projectile speed et pickups.
- [ ] Garder l’invariant : aucune stat/unique/skill/bonus de pickup ne collecte les coffres.
- [ ] Finaliser Powder, conversion 10:1, coût, succès, échec critique et garantie au dixième essai ; préserver les valeurs proposées et traiter l’économie anti-exploit ouverte.
- [ ] Arbitrer vente vs démantèlement et coûts/conditions de reroll d’effet unique.
- [ ] Développer et valider le graphe ~120 nodes (cible 100–150), prérequis, déblocages, respec gratuit et plafond de puissance.
- [ ] Développer et valider ~120 familles d’achievements (cible 100–150), quatre tiers, secrets, métriques idempotentes et plafond de bonus.
- [ ] Compléter effets uniques avec systèmes qui les déclenchent ou les laisser explicitement inéligibles ; aucun effet sélectionnable ne doit être silencieusement inerte.
- [ ] Vérifier migrations, sauvegarde atomique, backup, absence de double gain et reprise après fermeture.
- [ ] Mesurer les builds de référence à différentes difficultés et corriger les valeurs sans altérer leurs statuts.

**Critère de sortie :** boucle permanente complète, compréhensible, migrable, idempotente et calibrée sans fuite vers Sandbox.

## P7 — Endless standard et Endless Armorless

### P7A — Armorless (règles centrales validées)

- [ ] Ajouter mode autonome sans équipement permanent actif ; garder skill tree et Achievement Mastery actifs.
- [ ] Après chaque vague achevée, proposer trois équipements temporaires et en appliquer un ; gérer répétition de slots et absence de filet de sécurité.
- [ ] Implémenter Flux temporaire, amélioration temporaire jusqu’à +10, effets Legendary/Mythic et destruction des objets à la fin.
- [ ] Implémenter difficultés, bosses toutes les 12 vagues, HP decay persistant et budgets de densité.
- [ ] Isoler les récompenses persistantes : les gains d’Essence/Powder, achievements, records et absence d’équipement garanti restent à arbitrer lorsqu’ils sont marqués proposés.
- [ ] Couvrir run complète, draft, pause, mort, Flux, classement par difficulté et idempotence.

### P7B — Endless standard (contrat ouvert)

- [ ] Avant codage, trancher et documenter accès/déblocage, démarrage depuis menu vs continuation après vague 24, difficulté, sortie, records, cadence boss et récompenses.
- [ ] Après arbitrage, préserver les deux contextes de build tels que retenus : une entrée menu peut repartir niveau 1 tandis qu’une continuation peut conserver build/HP ; les propositions actuelles ne sont pas encore des règles.
- [ ] Ne pas assimiler les exemples de scaling/cycles à des décisions acceptées.

**Critère de sortie :** Armorless conforme aux règles validées et propositions clairement paramétrées ; Endless standard seulement après arbitrages.

## P8 — Sandbox Lab destiné au joueur

P1 livre le Sandbox développeur et ne remplace pas cette feature produit.

- [ ] Ouvrir Sandbox depuis le menu sans créer/lire un profil Survival.
- [ ] Fournir un build initial libre et des overrides live (LIVE/REBUILD/RESTART) transactionnels pour les familles du GDD.
- [ ] Ajouter presets versionnés, JSON et share code bornés ; valider toute charge entrante, interdire script, chemin arbitraire et données privées.
- [ ] Importer une sauvegarde normale uniquement en copie unidirectionnelle Normal → Sandbox ; original inchangé.
- [ ] Implémenter god mode, spawn/kill all, gestion de vagues, commandes de simulation, logs/RNG et DPS détaillé.
- [ ] Implémenter des snapshots complets comprenant simulation, état gameplay, commandes, horloges, RNG, configuration et build ; préciser déterminisme/reprise sans promettre un replay exact si la simulation est non déterministe.
- [ ] Séparer chemins `user://saves` et `user://sandbox`; ne jamais publier récompenses, succès officiels, records ni scores classés.
- [ ] Profiler puis fixer des hard caps qui protègent stabilité sans présenter les nombres indicatifs du GDD comme des garanties de performance.

**Critère de sortie :** expérimentations librement configurables, persistables/partageables et isolées de la progression normale.

## P9 — Équilibrage, accessibilité, polish et livraison

- [ ] Équilibrer rôles/viabilité des dix armes et reliques, synergies, RNG de chest et durée de run à partir de données de plusieurs profils.
- [ ] Calibrer HP decay, soins, dégâts de contact, lifesteal, XP, loot, économie et progression sur tous les niveaux de difficulté.
- [ ] Vérifier les retours de dégâts/critique, télégraphes, audio, VFX et options de réduction d’effets ; la direction artistique pixel art néon a des assets de prototype, pas l’ensemble final.
- [ ] Compléter navigation clavier, flèches, manette, focus, lisibilité HUD et contrôles/accessibilité selon GDD.
- [ ] Mesurer cible 60 FPS sur GPU intégré représentatif : temps CPU/GPU, P95/P99, densité ennemie/projectile et mémoire. Mesa/llvmpipe et benchmark natif ne remplacent pas ce test.
- [ ] Faire tests de charge prolongée, stabilité, progression et corruption/récupération de profil.
- [ ] Valider import/build/lancement Linux et Windows sur artefacts propres.
- [ ] Préparer la livraison commerciale/Steam après critères de release, sans confondre disponibilité d’un build local et validation de publication.

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
