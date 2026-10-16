# Tests d'acceptation et validation

> Les cases cochées sont des exécutions documentées. Le binaire Godot local est `tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`; il peut être invoqué directement même s’il n’est pas présent dans le `PATH`.

## Correction du viewport UI — 2026-10-16

- [x] Les interfaces conservent leur viewport logique 1280×800 et la fenêtre initiale 1280×800. Le viewport cible 640×360 de l’Art Bible attend l’adaptation responsive de chaque écran.
- [x] Le thème partagé reprend les couleurs sémantiques de la palette maître, les panneaux opaques et les boutons rectangulaires; Press Start 2P est réservée aux titres, DejaVu Sans au texte courant. Le feedback souris agrandit au survol et décale de 2 px à l’appui. Licences livrées dans `game/assets/fonts/`.
- [x] Import Godot 4.7.2 et 10 smokes ciblés UI passent après le rétablissement du viewport 1280×800, avec un `XDG_DATA_HOME` isolé par script : fondation, hub/layouts 1280×800/1600×900/1920×1080, pause, inventaire, coffre, résultat, navigation et Sandbox.
- [ ] Le smoke fenêtré et la suite complète ne sont pas relancés après cette correction.

## Hub Survival — état visuel des destinations inactives — 2026-10-16

- [x] `survival_hub_smoke.gd` vérifie que Succès et Bestiaire utilisent le style atténué, restent activables au focus et gardent le cadre de focus partagé; ils ne sont pas désactivés.
- [x] `survival_hub_layout_smoke.gd` confirme les bornes du hub à 640×360, 1280×720 et 1920×1080.
- [x] `survival_hub_smoke.gd` vérifie la médaille de Succès et le sprite de chaser du Bestiaire, leur taille compacte nearest, leurs teintes atténuées/dorées selon le focus et leur absence de signal d’action.
- [x] Capture fenêtrée avec viewport logique 640×360 relue; Succès et Bestiaire sont visuellement secondaires. Le focus est vérifié par le smoke, l’interaction avec une manette physique n’a pas été vérifiée ici.

## Inventaire d’équipement — hiérarchie des cartes — 2026-10-16

- [x] `equipment_panel_visual_smoke.gd` contrôle la largeur réservée aux contrôles, la bordure de rareté et le maintien dans les 640 px logiques.
- [x] `ui_viewport_layout_smoke.gd` passe pour toutes les interfaces aux viewports 640×360, 1280×720 et 1920×1080.
- [x] Capture fenêtrée de l’inventaire vérifiée à 640×360 logique et fenêtre 1280×720; les lignes, options, états et actions restent dans le panneau.
- [ ] `survival_inventory_smoke.gd` n’a pas terminé dans le délai de 30 s lors de cette vérification; le processus a été arrêté. Parcours de progression non revalidé dans cette tranche.
- [x] `equipment_panel_visual_smoke.gd` vérifie maintenant les états vide/erreur exclusifs, le contraste, le centrage et la taille 10 px; captures des deux états revues à 640×360 logique.
- [x] `equipment_panel_visual_smoke.gd` vérifie que le nom de l’effet unique est rendu en texte lisible sans séparateurs d’identifiant. Le smoke visuel et `survival_inventory_smoke.gd` passent.

## Arbre de compétences — hiérarchie des nœuds — 2026-10-16

- [x] `skill_tree_panel_visual_smoke.gd` vérifie largeur des choix, bornes logiques, état de prérequis et focus de la fondation.
- [x] `ui_viewport_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080.
- [x] Capture fenêtrée avec viewport logique 640×360 relue; les effets, coûts et relation de prérequis tiennent dans le cadre.
- [x] `skill_tree_panel_visual_smoke.gd` vérifie que les deux choix emploient l’icône skill-node nearest limitée à 12 px; parcours du hub et capture 640×360 revus, puis `ui_viewport_layout_smoke.gd` et `survival_inventory_smoke.gd` passent.

## Pause — hiérarchie visuelle — 2026-10-16

- [x] `pause_panel_visual_smoke.gd` contrôle la largeur des cartes, les libellés d’état/vitesse et le focus des six actions.
- [x] `pause_panel_visual_smoke.gd` vérifie l’accent cyan de reprise et l’accent rouge d’abandon/confirmation; `survival_pause_smoke.gd` passe sans changement du parcours.
- [x] `survival_pause_smoke.gd` passe, y compris Options au-dessus de Pause et invariance des horloges/positions.
- [x] `ui_viewport_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080; captures de Pause et de confirmation revues à 640×360 logique.

## HUD Survival — visibilité de la rangée d’armes — 2026-10-16

- [x] `survival_hud_smoke.gd` vérifie que le texte du loadout a une hauteur visible; ce contrôle détectait une hauteur maximale de zéro.
- [x] Capture 640×360 logique revue avec plusieurs armes; les noms ne sont plus coupés verticalement et les deux cartes restent dans leurs zones.
- [x] `ui_viewport_layout_smoke.gd` passe à 640×360, 1280×720 et 1920×1080.

## HUD Survival — séparation santé et XP — 2026-10-16

- [x] `survival_hud_smoke.gd` vérifie que santé et XP disposent de lignes distinctes, que leurs valeurs/barres suivent le bon état et que les deux lignes restent dans le panneau aux viewports testés.
- [x] `survival_hud_smoke.gd` et `survival_weapon_smoke.gd` passent après le déplacement des contrôles dans leurs lignes dédiées.
- [x] Capture fenêtrée revue à 640×360 logique : barres HP et XP longues, valeurs et rangée d’arme restent visibles et dans la carte.

## Coffres — accent de famille — 2026-10-16

- [x] `survival_chest_choice_smoke.gd` vérifie le titre cyan du coffre d’arme, le titre magenta du coffre de relique, les icônes/descriptions, le focus et l’émission de sélection inchangée.
- [x] `survival_chest_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080 avec descriptions longues et bonus de prochain niveau.

## Accueil — emblème pixel art — 2026-10-16

- [x] `signal_prism_asset_smoke.gd` vérifie le PNG 32×32 transparent, sa palette maîtresse de 16 couleurs maximum, l’en-tête Aseprite et son intégration nearest dans le menu.
- [x] `process_signal_prism.gd` reproduit l’export depuis la référence générée vers le PNG utilisé et la source Aseprite éditable.
- [x] Import Godot 4.7.2, `ui_foundation_smoke.gd` et `ui_viewport_layout_smoke.gd` passent; capture de l’accueil relue à 640×360 logique dans une fenêtre 1280×720.
- [x] `launch_navigation_smoke.gd` passe en headless après ajout de l’emblème; retour du Sandbox vers l’accueil fonctionne toujours.

## Inventaire de run — densité au viewport logique — 2026-10-16

- [x] `survival_pause_inventory_smoke.gd` vérifie le cadre élargi, le focus visible, la navigation clavier, le défilement jusqu’au dernier item et l’absence de mutation du loadout.
- [x] Le panneau reste dans les viewports 640×360, 960×600, 1280×800 et 1600×900; `ui_viewport_layout_smoke.gd` passe aussi aux tailles 640×360, 1280×720 et 1920×1080.
- [x] Capture 640×360 logique relue avec quatre armes et quatre reliques : deux cartes complètes restent visibles avant défilement.

## Résultat de run — poids des récompenses — 2026-10-16

- [x] `run_result_panel_smoke.gd` vérifie carte 360 px, icône 24×24, focus initial, ordre des actions, victoire/défaite, doublon et échec de sauvegarde.
- [x] Le même smoke vérifie que l’échec de sauvegarde prend l’accent rouge et que l’accent cyan des récompenses est rétabli au prochain résultat.
- [x] `survival_run_result_smoke.gd` confirme que le parcours victoire/défaite et la navigation restent inchangés.
- [x] Capture fenêtrée de l’état d’échec de sauvegarde relue à 640×360 logique; le message est distinguable des récompenses et actions.
- [x] `ui_viewport_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080; capture de victoire avec équipement long relue à 640×360 logique.

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
- [ ] P3 placement des drops : le smoke `survival_chest_smoke.gd` vérifie que les orbes XP ne chevauchent pas les coffres, qu’un coffre reste partiellement visible face à un autre et que le spawn d’un coffre évite aussi un orbe déjà au sol; exécution Godot à relancer.
- [x] P3 armes/reliques prototype : tests de collision/tuerie Inferno et Crimson, bonus de dégâts Storm Core/Infernal Heart, bonus de soin Blood Chalice, Bloodstorm niveau 5/relique avec saignement/lifesteal, Infinite Circuit niveau 5/Storm Core avec éclairs ramifiés, et Wildfire niveau 5/relique avec explosion et brûlure de zone. Les cibles initiales, branchements et dégâts/rayon d’explosion restent **[PROPOSÉS]**.
- [x] P3 flux de run : entrée Sandbox→Survival, choix parmi deux armes **[PROPOSÉES]**, résultat de défaite/victoire et vague finale enregistrée comme 24.
- [ ] Résultat de run : smoke ajouté pour vérifier `QUIT TO MENU` juste sous `RUN AGAIN`, son signal de navigation et l’ajustement responsive; exécution Godot à relancer.
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
- [x] Smoke `ui_foundation_smoke.gd` : palette et styles, contrôles requis, focus initial, Tab, limites géométriques à 1280×800, 1600×900 et 1920×1080, mapping Entrée/Espace/A et Échap/B.
- [x] Lancement fenêtré de la scène de prévisualisation sous Xvfb aux trois tailles ci-dessus; aucune erreur de script ou de parsing. Le smoke confirme les limites du panneau; la revue fenêtrée complète reste limitée par l’absence d’entrée souris interactive dans l’environnement.
- [ ] Essai avec une manette physique non exécuté : aucun périphérique de jeu n’est présent. Les mappings A/B sont vérifiés dans `InputMap`, ce qui ne prouve pas l’activation sur matériel.
- [ ] Build natif et CTest non exécutés : `cmake` et `ctest` sont absents de l’environnement. Les artefacts de build préexistants ne sont pas considérés comme une validation de ce changement.

## UI refonte — ui-settings (2026-10-15)

- [x] Godot 4.7.2 Linux : import headless du projet et smokes `settings_service_smoke.gd`, `ui_settings_smoke.gd` passés avec `XDG_DATA_HOME` temporaire.
- [x] Service : valeurs par défaut, clamp `[0,100]`, valeur non finie, persistance/relecture, fichier invalide, retour sûr et bus Master fini à −80 dB pour 0 % vérifiés.
- [x] Panneau : Theme, deux réglages, focus initial, synchro/affichage du volume, demande de fermeture par bouton et `ui_cancel`, présence des actions A/B et limites géométriques à 1280×800, 960×600, 1600×900 vérifiés.
- [x] Slider et CheckButton du Theme utilisent les couleurs de la palette néon; la poignée de volume est un rond pixel 12×12 filtré nearest. `ui_settings_smoke.gd` vérifie aussi que le focus du slider reprend le cadre doré partagé. Smokes `ui_foundation_smoke.gd`, `ui_settings_smoke.gd` et `settings_service_smoke.gd` passent; la capture Options à 640×360 logique en fenêtre 1280×720 a été inspectée.
- [x] Régression : `sandbox_smoke.gd`, `sandbox_ui_smoke.gd` et `survival_entry_smoke.gd` passés avec des profils `XDG_DATA_HOME` isolés. Le service ne dépend pas de `SaveService` et écrit seulement ses préférences dans `user://settings.cfg`.
- [x] Prévisualisation fenêtrée sous Xvfb aux trois tailles sans erreur de script; rendu examiné à 1280×800.
- [ ] Interaction physique souris/clavier/manette non parcourue de bout en bout; aucun contrôleur n’est présent et aucun outil de souris interactive n’est disponible dans cet environnement. Le smoke headless vérifie le focus initial, le contrat de fermeture et les mappings A/B, pas leur activation matérielle.
- [ ] Plein écran sur écran réel et sortie audio sur haut-parleurs/casque non vérifiés; seules les API DisplayServer/AudioServer et leurs valeurs sous headless ont été exercées.
- [x] Test d’intégration de l’écran Options depuis la pause couvert par `survival_pause_smoke.gd` : Retour et Échap ramènent à Pause, restaurent le focus et ne font avancer ni temps Simulation, ni temps actif, ni position joueur.
- [ ] Build natif et CTest non exécutés : `cmake` et `ctest` sont absents de l’environnement.

## UI refonte — survival-pause (2026-10-16)

- [x] Godot 4.7.2 Linux : import headless réussi; `survival_pause_smoke.gd` vérifie ouverture/reprise, focus, temps Simulation/actif/vague et positions joueur/ennemi figés, retour d’Options par bouton/Échap et bornes Pause aux viewports 960×600, 1280×800 et 1600×900.
- [x] `survival_pause_inventory_smoke.gd` vérifie la projection en lecture seule de deux armes/deux reliques, noms, niveaux, descriptions, icônes et évolution active; l’ouverture place le focus sur le premier objet, les flèches déplacent le focus et le défilement, le contour doré est visible et les icônes 24×24 utilisent le filtrage nearest.
- [x] `survival_pause_inventory_smoke.gd` et `ui_viewport_layout_smoke.gd` passent; bounds de l’inventaire testés à 640×360, 1280×720 et 1920×1080.
- [x] `survival_abandon_smoke.gd` vérifie focus sûr, annulation souris/Échap, bounds de la confirmation, retour à l’accueil, suppression de session et absence de changement aux ressources, objets ou runs récompensées du profil.
- [x] Régressions passées : `survival_starting_weapon_smoke`, `survival_chest_choice_smoke`, `survival_chest_smoke`, `survival_hud_smoke`, `run_result_panel_smoke`, `survival_run_result_smoke`, `survival_loadout_smoke`, `survival_inventory_smoke`, `survival_wave_director_smoke`, `survival_wave_duration_smoke`, `survival_entry_smoke`, `survival_hub_smoke`, `survival_hub_layout_smoke`, `launch_navigation_smoke`, `ui_settings_smoke`, `settings_service_smoke`, `sandbox_smoke` et `sandbox_ui_smoke`.
- [ ] `combat_catalog_smoke.gd` garde une assertion historique « Dagues en orbite autour du joueur, non lancées » qui échoue avec le catalogue actuel, lequel décrit Crimson Daggers comme deux dagues tirées en éventail. Le smoke d’inventaire pause consomme les données courantes et passe; aucune donnée ou règle de combat n’a été modifiée ici.
- [ ] Parcours matériel complet souris/clavier/manette non réalisé; le focus, les actions A/B et les contrats bouton/Échap sont testés sous headless, mais aucun périphérique ni entrée fenêtrée interactive n’était disponible.
- [ ] CTest/build natif non exécutés : `ctest` et `cmake` sont absents du PATH. `git diff --check` passe.

## Vitesse de run Survival (2026-10-16)

- [x] `survival_speed_control_smoke.gd` : choisir ×4 dans le menu Pause applique la vitesse au moteur de combat et à `Engine.time_scale`, puis quitter Survival restaure ×1.
- [x] `survival_pause_smoke.gd` et `survival_wave_duration_smoke.gd` passent avec le nouveau contrôle; la vague simulée de 30 secondes avance correctement à ×4.


## UI refonte — sandbox-ui (2026-10-16)

- [x] `render_visual_smoke.gd` sous Xvfb/Mesa : scène Sandbox vérifiée à 640×360 logiques dans la fenêtre par défaut 1280×720; les entités restent découpées dans la zone de simulation, sans recouvrir l’accueil. llvmpipe passe le smoke; audio et V-Sync indisponibles dans le conteneur.
- [x] `sandbox_ui_smoke.gd` : Theme partagé, grille métriques, focus initial, spawn/inspection/DoT, pause/reprise, step/vitesse, tuning/reset et sauvegarde sentinelle inchangée. Godot 4.7.2 headless passe avec `XDG_DATA_HOME` temporaire isolé.
- [x] `sandbox_ui_smoke.gd` vérifie aussi la barre d’outils cyan (pause/reprise), jaune (step) et rouge (reset). Capture à 640×360 logique relue; les accentuations ne changent pas l’isolation de la sauvegarde sentinelle.
- [x] `ui_foundation_smoke.gd` vérifie les états normal/survol/appui/focus des barres de défilement horizontales/verticales du Theme; `sandbox_ui_smoke.gd` vérifie que le préfixe compact `WGT` tient dans le réglage d’espacement tout en gardant le tooltip explicatif. Capture Sandbox 1280×720 inspectée : poignée bleu ardoise bordée cyan, champ `WGT 0.5` entier.
- [x] `sandbox_smoke.gd` : vérification de base Sandbox.
- [x] Vérification statique : `main.gd` et la scène Sandbox ne référencent pas `SaveService` ni les services de progression. Le Sandbox conserve son chemin isolé vers le prototype Survival.
- [x] Import éditeur Godot 4.7.2 headless et `git diff --check`.
- [ ] Interaction physique souris/clavier/manette non parcourue; focus initial et styles natifs de focus vérifiés dans le smoke, matériel absent.
- [ ] Build natif/CTest non exécutés : `cmake` et `ctest` absents du PATH.


## Clôture UI intégrée (2026-10-16)

- [x] Suite ciblée de 21 smokes UI/intégration passés sous Godot 4.7.2 Linux avec profils `XDG_DATA_HOME` temporaires isolés : foundation, settings, navigation, hub/layout, HUD, départ, coffres, résultats, pause/inventaire/abandon, loadout, durée de vague, entrée et Sandbox. La liste exacte est dans [`INTEGRATION-ui-refonte.md`](../../tasks/ui-refonte/INTEGRATION-ui-refonte.md).
- [x] Import éditeur headless et rendu `render_visual_smoke.gd` sous Xvfb/Mesa passés; inspection du Sandbox à 640×360 logiques confirme le clipping du playfield.
- [x] Clôture documentaire des sept modules dans `tasks/ui-refonte/` et mise à jour de la carte de capacités.
- [ ] Interaction physique manette/souris, plein écran sur écran réel et sortie audio matérielle non vérifiés.
- [ ] Build natif et CTest non exécutés : `cmake` et `ctest` ne sont pas dans le PATH.
- [ ] `combat_catalog_smoke.gd` conserve une assertion historique dague-orbite contredite par le catalogue actuel; sans rapport avec les changements UI.

## Art UI et catalogue — icônes dédiées (2026-10-16)

- [x] Import Godot 4.7.2 headless réussi après ajout des icônes générées du catalogue.
- [x] `catalog_icon_assets_smoke.gd` passe : les 10 icônes d’armes, 10 icônes d’évolution et 11 icônes de reliques font 32×32, restent sous la limite de 16 couleurs, et possèdent un PNG et une source Aseprite valide.
- [x] `survival_chest_choice_smoke.gd`, `survival_pause_inventory_smoke.gd`, `ui_foundation_smoke.gd` et `survival_hud_smoke.gd` passent avec les nouvelles icônes et le Theme arcade à angles droits.
- [ ] `survival_weapon_catalog_smoke.gd` échoue sur sa vérification de branche Infinite Circuit après l’ajout visuel. Aucun comportement de combat n’a été modifié dans le lot; le scénario attend que des projectiles atteignent six cibles avant un délai de deux secondes. À isoler avant la clôture de la refonte.
- [ ] Aucun parcours physique souris/manette, export depuis l’application Aseprite, build natif ou test matériel n’a été réalisé dans ce lot.

## Art UI — icônes de progression (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` passe pour les 16 icônes UI supplémentaires : 32×32, limite de 16 couleurs, PNG et source Aseprite.
- [x] `survival_inventory_smoke.gd`, `run_result_panel_smoke.gd`, `ui_foundation_smoke.gd`, `survival_hub_layout_smoke.gd` et `launch_navigation_smoke.gd` passent.
- [x] `sandbox_ui_smoke.gd` passe avec un `XDG_DATA_HOME` neuf et isolé; son premier lancement avait réutilisé les données de smokes précédents et invalidé sa sentinelle de sauvegarde.

## Art combat — roster statique (2026-10-16)

- [x] Import Godot 4.7.2, `catalog_icon_assets_smoke.gd` (9 ennemis, élite, 2 boss; dimensions 24×24/96×96, impacts 64×64, palette et sources), `render_batching_smoke.gd`, `sandbox_ui_smoke.gd` avec profil isolé et `survival_entry_smoke.gd` passent.
- [x] `pilot_scene_visual_smoke.gd` sous Xvfb/Mesa : joueur et chasers de la nouvelle planche visibles; HUD deux coins inspecté à 1280×800.
- [x] Après déplacement timer/vague/état vers le panneau de droite : `survival_hud_smoke.gd`, `survival_weapon_smoke.gd`, `survival_wave_director_smoke.gd` et `survival_pause_smoke.gd` passent.
- [x] Le HUD a été recomposé en deux cartes de coin pour le viewport logique 640×360. Les bounds et l’écartement passent de 640×360 à 1920×1080; les smokes HUD/armes/vagues/pause passent, et la fenêtre 1280×720 a été rendue et inspectée sous Xvfb/Mesa.
- [ ] Le HUD a depuis été resserré pour le viewport logique 640×360 en deux cartes de coin; les smokes vérifient les bounds et l’écartement, mais leur version actuelle n’a pas été exécutée dans cet environnement, où `godot` est absent.
- [ ] `survival_weapon_catalog_smoke.gd` conserve l’échec Infinite Circuit décrit ci-dessus; les règles de combat n’ont pas été touchées dans le lot de sprites.
- [ ] Les boss sont des prototypes abstraits et restent non canoniques; aucun test ne valide une animation ou une identité de boss.

Note de clôture : le blocage historique du smoke `sandbox_ui_smoke.gd` décrit dans le compte rendu initial de `launch-navigation` est résolu; les deux smokes Sandbox passent désormais avec des profils temporaires isolés.

## Récupération CMake `godot-cpp` (2026-10-16)

- [x] Cause : `CMakeLists.txt` associait `GIT_SHALLOW TRUE` à un `GIT_TAG` en SHA, combinaison non prise en charge par CMake. L’épingle de commit reste identique; le clone superficiel a été retiré.
- [x] Configuration propre depuis le dépôt avec CMake 3.31.6 et GCC 14.2 : `godot-cpp` récupéré, 2 135 fichiers générés, configuration terminée.
- [x] Build complet Debug : `dopamine_simulation`, tests natifs, `godot-cpp` et `libdopamine.linux.template_debug.x86_64.so` compilés.
- [x] CTest : 2/2 tests natifs passés (`simulation_core`, `simulation_worker`). Smoke `sandbox_smoke.gd` sous Godot 4.7.2 : pont et GDExtension chargés.

## Pilote visuel — scène de combat (2026-10-16)

- [x] Premier lot : joueur cyan 32×32, chaser 24×24 et projectile Lightning Conductor 16×16, dans la palette validée avec au plus 16 couleurs chacun. Chaque PNG dispose d’une source `.aseprite` éditable à un calque; les animations joueur restent à produire.
- [x] `pilot_asset_batch_smoke.gd` vérifie la présence, les dimensions, le plafond de couleurs et la concordance en-tête/dimensions PNG↔Aseprite.
- [x] `survival_entry_smoke.gd`, `survival_hud_smoke.gd` et `survival_weapon_smoke.gd` passent sous Godot 4.7.2 headless. Import éditeur headless réussi.
- [x] `pilot_scene_visual_smoke.gd` sous Xvfb/Mesa rend et sauvegarde la scène Survival à 1280×800; inspection confirme la lecture des sprites au centre de l’arène. Aucun service Sandbox/progression ni règle de combat n’a changé.
- [x] Le tile de sol généré a été écarté de la scène après inspection, sa répétition créant un bruit visuel trop dense; le sol actuel reste actif.
- [ ] Ce pilote attend la revue artistique avant la production en série. Audio et V-Sync ne sont pas disponibles dans le conteneur de rendu.

## Art combat — projectiles pixel (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` : les 24 projectiles exportés mesurent 16×16, ont une source Aseprite valide et respectent le plafond de 16 couleurs.
- [x] `render_batching_smoke.gd` : base et évolutions utilisent les textures dédiées dans les batches de projectile actifs.
- [ ] `survival_weapon_catalog_smoke.gd` garde l’échec historique Infinite Circuit déjà consigné; ce lot change le rendu des projectiles, pas leurs règles ni leur simulation.
- [ ] Les traînées, projectiles beam continus et animations de projectile ne sont pas couverts par cette planche statique; conventions d’animation encore **[OUVERTES]**.

## Art environnement — sol Survival provisoire (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` vérifie les dimensions et sources Aseprite du sol candidat et de l’overlay pixel art; le sol candidat respecte les 32 couleurs de la palette maître.
- [x] À ce stade historique, `pilot_scene_visual_smoke.gd` confirme l’overlay pixel art à 1280×800; le sol candidat reste hors du jeu car son motif répétitif est trop perceptible, donc `survival_ground.svg` est conservé. Ce sol a depuis été remplacé par `survival_ground_pixel.png` (section « Sol Survival pixel art »). Le biome canonique reste **[OUVERT]**.

## Art pickups Survival (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` vérifie le coffre 32×32 et l’orbe XP 16×16, leurs PNG/Aseprite, et leur plafond de 16 couleurs.
- [x] Les deux textures sont branchées aux appels de rendu déjà existants; aucune règle de collecte ou récompense n’a changé.

## Art accueil — skyline (2026-10-16)

- [x] `process_title_skyline.gd` régénère le PNG 640×360 et sa source Aseprite mono-calque depuis la référence aplatie, avec 30 couleurs de la palette maître.
- [x] `catalog_icon_assets_smoke.gd` contrôle dimensions, palette et en-tête/dimensions Aseprite.

## Responsive Sandbox — panneau latéral (2026-10-16)

- [x] `sandbox_ui_smoke.gd` vérifie les limites des boutons Spawn/Despawn/Kill et l’absence de défilement horizontal à 640×360, 1280×720 et 1920×1080.
- [x] Le formulaire de création place le type, le nombre, les PV et les vitesses sur des rangées étroites pour respecter la largeur de la colonne; les actions Sandbox et l’isolation de sauvegarde sont conservées.
- [x] Smoke Sandbox UI sous Godot 4.7.2 avec `XDG_DATA_HOME` temporaire isolé.

## Sol Survival pixel art (2026-10-16)

- [x] `process_survival_ground.gd` produit une texture répétable 256×256, limitée à six couleurs de la palette maître, et sa source Aseprite mono-calque depuis le visuel généré.
- [x] `catalog_icon_assets_smoke.gd` vérifie les dimensions, la palette, l’égalité des bords opposés, la source Aseprite et son branchement dans la scène Survival.
- [x] La texture SVG et l’ancien candidat moss/stone restent hors du rendu actif; aucune collision ni logique de combat ne change.

## Animations du héros pixel art (2026-10-16)

- [x] Les feuilles idle/marche 4×4 utilisent des frames natives 32×32, une palette limitée à 16 couleurs et des sources Aseprite éditables; ligne des directions Bas/Gauche/Droite/Haut **[PROPOSÉE]**.
- [x] Le contrôleur choisit les frames selon la direction déjà lue par les contrôles et reprend l’image idle quand le joueur s’arrête; contrôles, vitesse et collisions inchangés.
- [x] `catalog_icon_assets_smoke.gd`, `player_controller_smoke.gd`, `survival_entry_smoke.gd` et `pilot_scene_visual_smoke.gd` passent; rendu du personnage inspecté en jeu à 640×360 logique.

## Explosion de pixels à la mort d’un ennemi (2026-10-16)

- [x] L’événement de mort d’un ennemi dessine huit fragments carrés de la palette maître; le burst suit le temps de simulation, se fige en pause et ne crée aucune entité de combat.
- [x] `survival_weapon_smoke.gd` vérifie huit fragments par burst et l’absence de burst pour les projectiles ennemis; la capture en jeu confirme le rendu du burst.
- [x] Durée 0,32 s et nombre de pixels sont **[PROPOSÉS]**; dégâts, cibles, collisions et récompenses inchangés.

## Traînées visuelles des projectiles (2026-10-16)

- [x] `render_batching_smoke.gd` vérifie que les trajectoires orientent les traits derrière les projectiles, que leur plafond visuel tient sous forte charge et qu’ils sont effacés avec les entités.
- [x] Le renderer Survival et le Sandbox dessinent ces traits sous les sprites; inspection d’une capture Survival logique 640×360.
- [x] Longueur, cyan neutre et budget maximal de 256 sont **[PROPOSÉS]**; le mapping couleur par élément reste **[OUVERT]**.
- [x] `render_visual_smoke.gd` passe après alignement de ses positions de stress sur la zone Sandbox visible et sur le viewport logique 640×360; rendu dense revu visuellement.

## Enseignes animées de l’accueil (2026-10-16)

- [x] `launch_navigation_smoke.gd` vérifie la couche de skyline et l’avancement de son horloge de clignotement, en plus des parcours/focus existants.
- [x] Capture de l’accueil inspectée à 640×360; les trois enseignes restent dans les marges visibles du décor et derrière la carte de menu.
- [x] Les périodes de 1,4 à 2,2 s et la phase sombre sont **[PROPOSÉES]**; le rythme exact de clignotement reste **[OUVERT]**.

## Hiérarchie des titres UI (2026-10-16)

- [x] Les titres d’écran et de sections dans l’accueil, Options, hub, choix de coffre, inventaires, pause, résultats et Sandbox utilisent la variation de thème `PixelHeading`; les textes de description conservent la fonte sans moderne.
- [x] `ui_foundation_smoke.gd` vérifie la police et la couverture des titres; `survival_pause_inventory_smoke.gd` couvre aussi les en-têtes créés dynamiquement.
- [x] `run_result_panel_smoke.gd`, `survival_hud_smoke.gd` et `ui_viewport_layout_smoke.gd` passent; les vues principales sont inspectées à 640×360 logiques.
- [x] `run_result_panel_smoke.gd` vérifie les états sans sauvegarde, victoire, doublon et échec de sauvegarde avec une récompense longue; le panneau et chacun de ses contrôles restent contenus de 640×360 à 1920×1080.
- [x] Press Start 2P est l’association **[PROPOSÉE]** pour `PixelHeading`; le choix exact de police reste **[OUVERT]**.
