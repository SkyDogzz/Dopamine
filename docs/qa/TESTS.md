# Tests d'acceptation et validation

> Les cases cochées sont des exécutions historiques documentées. Lors de l’audit documentaire du 2026-10-15, Godot/Godot 4 n’est pas présent dans le PATH ; les smoke tests GDScript n’ont pas été relancés. Cette session vérifie les diffs et références, pas les résultats runtime historiques.

## Build et intégration

- [x] Linux P0 : Godot 4.7.2 charge la GDExtension C++23 après import headless du projet.
- [x] P1 ciblé : handles index/génération, snapshots immuables, spawn/despawn, kill all, step, pause/reprise, reset et arrêt du worker.
- [x] Capture/restauration native : capture cohérente à une barrière de commande, validation sans mutation partielle, reprise de la numérotation et exécution des commandes en attente après restauration ; API en mémoire, sans sérialisation fichier ni état gameplay Godot.
- [x] P1 intégration : GDScript charge `CombatSimulation`, soumet un spawn et reçoit le snapshot acquitté sous Godot headless.
- [x] P1 UI : scène Sandbox lançable sans save, inspection par sélection, despawn ciblé et kill all vérifiés sous Godot headless ; tooltips spawn, statut et réglage live vérifiés ; rendu revu à 1280×800.
- [x] Assets pixel art néon : sprites player/ennemis/boss placeholders/projectiles/XP/chests et icônes armes/reliques visibles ; lots MultiMesh par type et rendu de charge revérifiés à 1280×800.
- [x] P2 UI : le Sandbox applique un DoT configurable à l’entité sélectionnée, montre l’état dans l’inspecteur et reçoit un événement de tick identifié.
- [x] P1 scénario : runner JSON vérifie les attentes et exporte métriques, entités, événements et logs ; scénario steering valide la transaction `apply_sandbox_overrides`, ses valeurs de snapshot et le déplacement produit.
- [x] P2 ciblé : requêtes de rayon du spatial hash aux coordonnées négatives, bord de rayon et cellules ; les entités détruites sont exclues.
- [x] P2 ciblé : poursuite d’une cible explicite et séparation locale, y compris deux entités superposées ; scénario Godot headless vérifie les positions obtenues.
- [x] P2 ciblé : projectile rapide contre cible en mouvement, dégâts et mort séquencés, expiration, file d’événements acquittable et affichage Sandbox.
- [x] P2 ciblé : HP initial validé à 100 et fonction pure de HP decay aux exemples de 60 s et 720 s marqués proposés dans le GDD.
- [x] P2 ciblé : menace d’ennemi conservée jusqu’à l’événement de mort ; preview du soin proposé testée à T=1 et aux bornes de menace.
- [x] P3 ciblé : Survival applique le HP decay depuis l’horloge de simulation, le suspend en pause manuelle et pendant le choix initial, puis le reprend après validation ; le soin proposé d’un événement de mort est appliqué une fois.
- [x] P3 ciblé : Lightning Conductor cible deux ennemis distincts, tue les cibles avec ses projectiles et consomme les événements de mort pour le soin.
- [x] P3 UI : HUD Survival affiche le HP initial, l’état de run et les champs temps actif/arme prototype.
- [x] P3 XP : orbe ECS créée à la mort, collecte unique via événements acquittables, progression et HUD niveau vérifiés dans le smoke test Survival headless.
- [x] P3 vagues ciblé : progression de 24 vagues et transitions aux boss 12/24; timer bloqué pendant les placeholders et type d’ennemi préservé dans les événements de mort.
- [x] P4 horloge Survival : progression automatique depuis le temps simulé et arrêt/reprise du timer de vague vérifiés sous Godot headless avec une durée de vague de test réduite.
- [x] P4 run intégrée accélérée : parcours des 24 vagues, morts des deux boss, timer bloqué mais HP decay actif pendant les combats, choix des coffres et écran de victoire vérifiés.
- [x] P4 durée de vague intégrée : une vague configurée à 30 s ne passe à la suivante qu’après 30 s simulées ; vérifié à ×4 en environ 7,7 s réelles.
- [x] Le directeur conserve le reliquat d'un grand delta entre vagues ordinaires, s'arrête aux boss et ignore les durées/deltas non valides sans corrompre son état.
- [x] P3 intégration : traversal accéléré de la session Survival à travers 24 vagues, spawn/défaite des placeholders boss, écran victoire logique et pause finale.
- [x] P3 UI boss : la barre affiche les HP courants/max pour le mid-boss et le boss final; la victoire se distingue de RUN OVER.
- [x] P3 loot : tests des probabilités configurables, garanties et filet 60 s; test Survival death→drop→pickup→choix→application au loadout→reprise; le catalogue demeure **[PROPOSÉ]**.
- [x] P3 armes/reliques prototype : tests de collision/tuerie Inferno et Crimson, bonus de dégâts Storm Core/Infernal Heart, bonus de soin Blood Chalice, Bloodstorm niveau 5/relique avec saignement/lifesteal, Infinite Circuit niveau 5/Storm Core avec éclairs ramifiés, et Wildfire niveau 5/relique avec explosion et brûlure de zone. Les cibles initiales, branchements et dégâts/rayon d’explosion restent **[PROPOSÉS]**.
- [x] P3 flux de run : entrée Sandbox→Survival, choix parmi deux armes **[PROPOSÉES]**, résultat de défaite/victoire et vague finale enregistrée comme 24.
- [x] P3 boss final : une mort réelle génère les chests boss éligibles et la victoire attend la collecte et le choix de chaque chest.
- [x] P3 contact : collision joueur-ennemi, invulnérabilité temporaire, pause/reprise des contrôles et verrouillage après la fin vérifiés sous Godot 4.7.2 headless.
- [x] P3 contact : projectiles et orbes exclus; le rayon de contact enemy correspond au disque affiché (8 unités).
- [x] Survival clavier : WASD et flèches déplacent le joueur; les choix de départ et de chest se parcourent au clavier et se confirment avec Espace/Entrée.
- [x] P1 contrat natif : transaction complète de steering validée puis publiée atomiquement; transaction invalide ou mal typée conserve les valeurs précédentes.
- [x] P3 lifesteal : Blood Chalice soigne sur un événement de dégâts non létal; soft cap, efficacité au-dessus du cap et HP maximum vérifiés sous Godot 4.7.2 headless.
- [x] P3 Inferno : impact applique la brûlure configurée et ses ticks contribuent au lifesteal à 25 % du taux théorique.
- [x] Charge worker : 500 ennemis + 2 000 projectiles sont acceptés, le plafond de 2 500 entités est appliqué, puis 2 000 impacts se résolvent sans dépasser le budget réservé d’événements.
- [x] Linux : Godot 4.7.2 charge la GDExtension et GCC 14.2 compile le projet avec `-std=gnu++23`.
- [ ] Godot 4.7.2 charge la GDExtension sur Windows.
- [ ] Vérifier le build Windows et le couple compilateur/dépendances verrouillé.
- [x] Le worker natif ne dépend pas de Godot : ses deux sources n'incluent ni n'appellent l'API Godot; la cible `dopamine_simulation` ne lie pas `godot-cpp`.
- [x] `stop()` libère le worker sans deadlock pendant des soumissions concurrentes; test CTest répété 10 fois avec limite de 10 s.

## ECS / simulation

- [x] (2026-10-15) Frost Nova/Frozen Crown/Absolute Zero sous Godot 4.7.2 : Chill natif ralentit les cibles et se reflète dans le snapshot, Frozen Crown ajoute la vulnérabilité proposée, puis la mort gelée déclenche un shatter non récursif ; smokes de catalogue et tests natifs passés.
- [x] Catalogue de combat sous Godot 4.7.2 : dix armes, dix reliques associées et Magnet Heart sans paire ; validation des relations et disponibilité des dix paires prototypées plus Magnet Heart.
- [x] (2026-10-15) Minigun/Overdrive/Redline sous Godot 4.7.2 headless : impact d’un projectile Minigun et baisse du délai de tir avec Overdrive au niveau 2 et Minigun au niveau 5 ; réglages marqués **[PROPOSÉS]**.
- [x] (2026-10-15) Toxic Cloud/Plague Mask/Pandemic sous Godot 4.7.2 headless : poison direct et splash via DoT natif, puis transmission à la mort au niveau 5 ; réglages et limite de cibles **[PROPOSÉS]**.
- [x] Natif C++23 : projectile Toxic Cloud inflige son impact de zone puis émet les ticks DoT bornés par le chemin partagé.
- [x] (2026-10-15) Sawblades/Magnetic Coil/Razorstorm : test natif vérifie un ricochet après capture/restauration vers une seconde cible unique ; smoke Survival vérifie deux impacts et le rendu charge un asset SVG dédié. Réglages de rebonds/vitesse **[PROPOSÉS]**.
- [x] (2026-10-15) Meteor Staff/Celestial Eye/Starfall : smoke Survival vérifie une explosion limitée au groupe et les fragments sur deux cibles proches ; l'événement natif expose le type de sa source pour déclencher l'évolution. Valeurs **[PROPOSÉES]**.
- [x] (2026-10-15) Prism Laser/Prism Crystal/Spectrum Collapse : smoke Survival valide le tir prioritaire, deux cibles secondaires distinctes à l’évolution et les chemins de projectile natifs. Cadence, dégâts, progression et bonus de critique **[PROPOSÉS]**.
- [x] (2026-10-15) Void Orb/Singularity/Event Horizon : tests natifs vérifient attraction, impacts pénétrants sur cibles distinctes et capture/restauration ; smoke Survival valide le contrat GDExtension et les impacts. Rayon, force et progression **[PROPOSÉS]**.
- [x] Shooter P5 : télégraphe de visée avant le tir, pause du cycle, déplacement du projectile ECS, exclusion des dégâts sur les ennemis et collision/dégâts sur le joueur vérifiés par `simulation_core` et `survival_shooter_smoke` sous Godot 4.7.2 Linux. Dégâts, vitesse, rayon et cadence **[PROPOSÉS]**.
- [x] Buffer P5 : aura de 150 unités, vitesse d’alliés augmentée de 20 %, exclusion des ennemis hors rayon, fin du buff après la mort du soutien et capture/restauration vérifiées par `simulation_core`; snapshot/sprite par `survival_support_enemy_smoke`; profil par `sandbox_enemy_profiles_scenario`. `simulation_worker` vérifie aussi le format de capture 7. Stats et bonus **[PROPOSÉS]**.
- [x] Elite P5 : prototype Hasted visible, spawn après cooldown, budget de menace lié à la population de vague, maximum actif, mort via le pipeline commun et chest élite garanti dans le smoke. HP, vitesse, menace, intervalle, chance, limite et formule du budget restent **[PROPOSÉS]**.
- [x] Exploder P5 : profil du scénario, déclenchement de proximité, fuse et dégâts figés en pause, explosion une fois, fuite hors du rayon, élimination et conservation du flux kill/soin/XP/coffre vérifiés par `survival_exploder_smoke`. Stats, cadence, rayon, fuse et dégâts **[PROPOSÉS]**.
- [x] Shielder P5 : réduction de dégâts dans une aura, absence d’effet hors rayon, disparition immédiate à la mort du soutien, source conservée à la capture/restauration vérifiées par `simulation_core`; snapshot, indicateur et sprite par `survival_shielder_smoke`; profil par le scénario Sandbox. Rayon et multiplicateur **[PROPOSÉS]**.
- [x] Summoner P5 : quatre Summoners concurrents, position de spawn télégraphiée, pause du délai, plafond global de trois invocations, slot libéré puis réutilisé, profils et sprites vérifiés par `survival_summoner_smoke`; chiffres et plafond **[PROPOSÉS]**.

Pour le catalogue, la validation JSON et des références a aussi été vérifiée par script Python statique. Le smoke GDScript est enregistré dans CTest et a passé sous Godot 4.7.2 Linux.

- [x] ID index+génération rejette les handles obsolètes après réutilisation d’un index.
- [x] Spawn/despawn via worker et cœur natif ne casse aucun itérateur.
- [x] Les profils ennemis gardent leurs vitesses typées avec HP de vague multiplicatifs ; les multiplicateurs HP nuls ou non finis sont refusés.
- [x] Spatial hash trouve les cibles aux coordonnées négatives, au bord du rayon et aux frontières testées.
- [x] Swept collision détecte les projectiles rapides contre une cible en mouvement.
- [x] DoT partagé : ticks en temps simulé, durée, grand pas, remplacement, cible obsolète et événements identifiés.
- [x] Scénario Sandbox JSON applique un DoT, vérifie la santé restante et compte les événements de tick tagués.
- [x] Pas de simulation 1/120, 1/60, 1/30 et 100 ms : position, vitesse et HP restent finis; déplacement égal à la vitesse intégrée, sans saut; DoT indépendant du pas.
- [x] Timers de statuts exprimés en secondes, indépendants du nombre de frames pour les pas testés.
- [x] Les chaînes d'effets respectent le budget : le cœur refuse atomiquement un pas DoT trop riche, le worker explique le refus, un pas plus petit conserve tous les événements dus et les ticks s'arrêtent à l'expiration.

## Communication / rendu

- [x] Snapshots publiés restent immuables après l’étape suivante.
- [x] Les événements restent dans la file jusqu’à acquittement, indépendamment de l’ancienneté du snapshot consommé.
- [x] IDs/numéros de séquence identifient les événements et l’acquittement vide uniquement les événements déjà publiés.
- [x] Smoke Godot headless : 500 ennemis et 2 000 projectiles alimentent trois batches MultiMesh (ennemis, projectiles, orbes XP).
- [x] (2026-10-15) Smoke renderer Godot 4.7.2 : les projectiles Minigun ont un batch séparé qui charge leur texture SVG dédiée.
- [x] (2026-10-15) Smoke renderer Godot 4.7.2 : les projectiles Toxic Cloud ont un batch séparé qui charge leur texture SVG dédiée.
- [x] (2026-10-15) Smoke renderer Godot 4.7.2 : Sawblades/Razorstorm chargent leur batch et texture SVG dédiés.
- [x] (2026-10-15) Smoke renderer Godot 4.7.2 : météore et fragments Starfall utilisent des batches SVG séparés.
- [x] Smoke rendu fenêtré sous Xvfb/Mesa : 500 ennemis et 2 000 projectiles visibles à 1280×800 ; le test vérifie aussi la couleur d'un pixel ennemi connu.
- [ ] Mesurer la cible 60 FPS sur machine de référence et consigner CPU/GPU, P95/P99 ; le rendu logiciel llvmpipe ne valide pas cette cible.
- [x] Benchmark natif reproductible SimulationCore à 500 ennemis + 2 000 projectiles, avec charge sans impacts et rafale Wildfire dense, mesures P50/P95/P99 (voir `PERFORMANCE.md`).

## Sandbox-first

- [x] Sandbox démarre sans save : smoke de base sans `user://saves`; smoke UI séparé avec slot normal sentinelle prouvant que les interactions Sandbox ne changent aucun octet et n'ajoutent aucun fichier aux slots.
- [x] UI Sandbox : spawn, despawn, kill all, pause, reprise, step à durée explicite, vitesse ×2, reset des entités/horloges/overrides live et logs vérifiés sous Godot headless.
- [x] Contrat GDExtension `apply_sandbox_overrides` : quatre paramètres de steering validés avant soumission et exposés dans le snapshot; le worker rejette une configuration invalide sans commit partiel.
- [x] Sandbox applique un DoT configurable à l’entité sélectionnée et expose ses valeurs à l’inspecteur.
- [x] Transaction live de steering : changements UI valides appliqués ensemble et visibles dans le snapshot; entrée native invalide ou mal typée conserve toute la configuration précédente.
- [x] DPS moyen du Sandbox additionne les événements `damage` (dont DoT) et les divise par le temps simulé ; vérifié sur un Step explicite et remis à zéro avec la simulation.
- [x] Limites de ressources : files bornées à 2 048 commandes et 8 192 événements, 2 500 entités, budget de 6 000 événements par avance ; un batch de spawn qui dépasse le plafond ne crée aucune entité partielle et un Step trop coûteux préserve l’état. Vérifié dans le test du worker avec la charge 500 ennemis + 2 000 projectiles.
- [ ] Import d'une save produit une copie isolée ; original inchangé.
- [ ] Preset JSON et share code sont validés, versionnés, avec limites de taille.
- [ ] Snapshot complet reprend composants, queues, clocks, RNG et build.
- [ ] Sandbox ne génère ni équipement permanent, ni achievement officiel, ni classement.

## Progression et modes

- [x] Survival : run intégrée aux durées nominales de 24 × 30 s (720 s simulées, accélérées ×4), timer arrêté pendant les deux boss et HP decay actif. Le harness augmente les HP du joueur pour isoler le déroulement, applique les dégâts de test aux placeholders et choisit automatiquement les chests ; il ne valide pas l'équilibrage.
- [x] Une instance d'équipement permanente par run Survival, y compris défaite ; slot parmi les six validés, lignes sans statistique répétée, rarité selon la table Normal **[PROPOSÉE]**. Smoke victoire/défaite et unicité par `run_id`.
- [x] Inventaire Survival consultable : affiche rareté, slot, percentiles et état des rolls proposés ; l’ouverture suspend la simulation et la fermeture la reprend seulement si elle tournait déjà. Test headless et revue du rendu fenêtré.
- [x] Équipement persistant : équiper, déséquiper et remplacer une pièce du même slot ; migration des profils précédents. Le prototype P6 applique maintenant les lignes portées à Survival ; leurs plages restent proposées et non calibrées.
- [x] Progression v5 : migration des profils précédents vers quatre tiers de Powder, conversion 10:1, amélioration de ligne +0..+10, coût de rareté/niveau et pity au dixième essai ; probabilités et coûts restent les valeurs **[PROPOSÉES]** du GDD.
- [x] UI Enhancement : sélection du tier Powder, affichage du niveau de ligne et ressources, consommation, retour de résultat et inventaire persistant vérifiés dans `survival_inventory_smoke` et revue fenêtrée.
- [x] Équipement : choix d'un effet unique éligible et démontage persistés. Rendement provisoire. Lightning burst, overflow shield, evolution shockwave et elite haste ont des prototypes ; reroll gratuit et knockback de résurrection sont sans comportement faute de contrats requis.
- [x] Skill tree prototype : nodes Vitality (+5 % HP, 50 Essence) et Focused Training (+3 % dégâts, prérequis Vitality, 80 Essence), valeurs **[PROPOSÉES]** ; respec gratuit vérifié.
- [x] Achievement prototype : kills cumulés et quatre paliers Exterminator **[PROPOSÉS]** crédités une seule fois par run ; bonus dégâts cumulés de l'exemple vérifiés.
- [ ] Rareté ajustée par difficulté/vague et mort précoce, calibrage des rolls, arbitrage vente/démantèlement et validation des bonus. Le rayon de ramassage ne doit jamais affecter la collecte de coffres selon GDD v1.6.
- [x] Revue de code v1.6 : collecte de coffres utilise uniquement `chest_collection_radius`; `pickup_radius_pct` ne l’élargit pas.
- [x] Smoke de régression sous Godot 4.7.2 Linux (`survival_chest_smoke`) : avec `pickup_radius_pct` à 900 %, l’XP distante est collectée et le coffre hors de `chest_collection_radius` reste au sol ; les coffres dans le rayon ouvrent le choix en pause.
- [x] Magnet Heart sous Godot 4.7.2 Linux : disponible sans évolution, bonus XP aux niveaux 1 et 5, plafond de niveau respecté et aucun effet sur le coffre à distance.
- [x] Achievement tiers débloqués une seule fois et bonus cumulés vérifiés pour la famille prototype Exterminator ; le catalogue et les seuils complets restent à définir.
- [ ] Armorless : 3 équipements proposés après chaque vague, 1 choisi ; Flux temporaire.
- [x] `SaveService` : slot JSON versionné, checksum SHA-256, remplacement via temporaire, backup relu après altération/corruption et migration de la fixture v0 dictionnaire brut ; vérifié par `save_service_smoke`. Cette fixture ne définit pas un ancien schéma de production. Le service n’est pas chargé par le Sandbox.
- [x] Progression Survival : gains d’Essence/Powder selon la formule **[PROPOSÉE]** Normal, cumul sur plusieurs runs, défaite récompensée et `run_id` idempotent ; injection du service uniquement par l’entrée Survival et smoke avec slot temporaire isolé.
- [ ] Le mode Endless standard reste à finaliser avant ses tests de validation.

## Runner headless (CLI P1 implémentée)

```bash
dopamine-sim --scenario benchmark_500_enemies --duration 60 --output results.json
```

Le runner est fourni par `game/scripts/scenario_runner.gd` et consomme un fichier JSON de commandes. Le nom `dopamine-sim` et les options de durée illustrés ci-dessus restent une proposition distincte.

## Audit du 2026-10-15

- `git diff --check` exécuté ; résultat attendu consigné dans la revue du changement.
- Le binaire officiel Godot 4.7.2 a été lancé depuis `/tmp` (il reste absent du PATH). Import headless réussi ; smokes `combat_catalog`, `survival_loadout`, `survival_starting_weapon`, `survival_weapon_catalog`, `survival_inventory` et `survival_chest` réussis.
- Cet import a révélé trois erreurs d’inférence GDScript qui empêchaient Survival/Skill Tree de se charger ; les types de `evolved`, `vitality_cost` et `focus_cost` ont été explicités avant la réussite des smokes.
- Cibles natives non reconstruites dans cet audit ; les résultats historiques ci-dessus restent datés de leurs exécutions précédentes.
- P5 v1.6 (dix armes, onze reliques, familles d’ennemis) n’est pas livré ; dix paires ont un prototype Survival, dont Frost Nova/Absolute Zero. Le smoke `survival_weapon_catalog_smoke` vérifie les impacts prioritaires et les effets de statut/évolution. La progression permanente existante est un prototype anticipé P6.

## UI refonte — ui-foundation (2026-10-15)

- [x] Godot 4.7.2 Linux : import headless du projet avec le Theme UI partagé.
- [x] Smoke `ui_foundation_smoke.gd` : palette et styles, contrôles requis, focus initial, Tab, limites géométriques à 1280×800, 960×600 et 1600×900, mapping Entrée/Espace/A et Échap/B.
- [x] Lancement fenêtré de la scène de prévisualisation sous Xvfb aux trois tailles ci-dessus; aucune erreur de script ou de parsing. Le smoke confirme les limites du panneau; la revue fenêtrée complète reste limitée par l’absence d’entrée souris interactive dans l’environnement.
- [ ] Essai avec une manette physique non exécuté : aucun périphérique de jeu n’est présent. Les mappings A/B sont vérifiés dans `InputMap`, ce qui ne prouve pas l’activation sur matériel.
- [ ] Build natif et CTest non exécutés : `cmake` et `ctest` sont absents de l’environnement. Les artefacts de build préexistants ne sont pas considérés comme une validation de ce changement.
