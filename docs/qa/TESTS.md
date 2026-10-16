# Tests d'acceptation et validation

## Run Survival réelle — validation P5 partielle — 2026-10-16

- [x] Depuis l’accueil et le hub, démarrage manuel d’une run Easy avec Lightning Conductor dans Godot 4.7.2; profil isolé par `XDG_DATA_HOME=/tmp/dopamine-p5-real-profile`.
- [x] Dans le menu Pause, `LOCK HEALTH` et `AUTO PICK FIRST CHEST` étaient OFF; la vitesse ×4 était sélectionnée manuellement. Défaite affichée à la vague 2, temps actif 00:45, 14 éliminations; l’écran a affiché +13 Essence et +18 Basic Powder.
- [ ] Ce parcours établit seulement la branche de défaite. Une victoire réelle, un choix de coffre réel et l’idempotence des récompenses restent à vérifier; les smokes ne ferment pas ces critères P5.V3.

## Progression permanente — équipement classique — 2026-10-16

- [x] `equipment_slots_smoke.gd` couvre les six slots, l’unicité des statistiques dans chaque pièce, et le remplacement d’un objet équipé du même slot sans déséquiper les cinq autres.
- [x] `progression_service_smoke.gd` vérifie qu’une victoire et une défaite distinctes ajoutent chacune une seule pièce et que le retraitement du même `run_id` n’en ajoute pas une seconde.
- [x] Les quatre smokes ciblés passent. La suite séquentielle passe 67/67 sous Godot 4.7.2; `survival_weapon_catalog_smoke` a échoué une première fois de façon intermittente, puis a passé seul et dans le rerun complet.

## P6 — Tirage de rareté équipement — 2026-10-16

- [x] `equipment_rarity_smoke.gd` compare 20 000 tirages seedés à la table attendue pour Easy, Normal, Hard, Nightmare et Chaos, aux vagues 1 et 24; les observations restent dans une tolérance de cinq écarts-types.
- [x] `progression_service_smoke.gd` vérifie les poids, la somme de 100 %, le transfert proposé par paliers de vagues et que le contexte affecte effectivement le résultat généré.
- [ ] Pénalité de mort précoce et calibration des taux restent à définir/mesurer; cette implémentation ne les déclare pas validés.

## P6.3 — Portée de ramassage équipement et XP — 2026-10-16

- [x] `equipment_stats_smoke.gd` charge un seul bonus d’équipement par profil et lance une session Survival séparée par stat; vérifie HP, mobilité, dégâts, cadence, chance et dégâts critiques, soin par élimination, aire, cooldown, XP, portée de collecte et vitesse projectile.
- [x] `survival_chest_smoke.gd` passe sous Godot 4.7.2; le rayon bonus et l’impulsion Magnet Heart collectent les orbes XP, tandis qu’un coffre placé au-delà de `chest_collection_radius` reste intact.

## P6.4 — Enhancement — 2026-10-16

- [x] `equipment_enhancement_smoke.gd` vérifie les niveaux +0..+10 avec chaque tier Powder, réussite garantie au dixième essai, échec normal, échec critique avec protection au niveau 0, coûts proposés par niveau/rareté et conversions 10:1 à sens unique. Coûts et probabilités restent **[PROPOSÉS]** et non calibrés.
- [x] `equipment_economy_smoke.gd` vérifie les ventes uniques des cinq raretés, le crédit Essence sans Powder, et le rejet d'un fail streak hors plage 0..9. `survival_inventory_smoke.gd` vérifie la confirmation avant vente et le rafraîchissement de l'inventaire; les valeurs de vente restent **[PROPOSÉES]** et non calibrées.

## P6.5 — Effet Elite Haste — 2026-10-16

- [x] `survival_elite_smoke.gd` équipe `elite_haste` dans un profil temporaire isolé, tue un élite via le pipeline de dégâts natif, puis vérifie le bonus de mobilité de 15 %, son expiration après trois secondes simulées et le feedback HUD. Ces valeurs restent **[PROPOSÉES]**.

## P6.5 — Scénarios d’effets uniques — 2026-10-16

- [x] `survival_unique_effects_smoke.gd` vérifie l’absence d’effet sans équipement, le ciblage visible et le cooldown de Lightning Burst, puis l’inactivité d’Evolution Shockwave avant évolution et son unique activation à huit projectiles au tir suivant. Les réglages restent **[PROPOSÉS]**.

## P6.5 — Reroll gratuit du premier coffre — 2026-10-16

- [x] `free_chest_reroll_smoke.gd` équipe le reroll gratuit dans un profil temporaire, l’active au clavier, vérifie que les offres remplacées ne reviennent pas et qu’aucun reroll n’est offert au coffre suivant.
- [x] `progression_service_smoke.gd` vérifie que `revive_knockback` ne peut plus être choisi, mais reste lisible dans un profil qui le contient déjà.

## P5 — Chaînes Lightning — 2026-10-16

- [x] Un arc Lightning ignore désormais sa cible source afin que le saut touche l’ennemi suivant, y compris lorsque les cibles sont très proches; sa position de départ est bornée par l’écart au prochain ennemi.
- [x] `simulation_core_test` vérifie que `lightning_arc:*` ne retouche pas sa source et frappe la cible suivante. `survival_weapon_catalog_smoke.gd` passe dix exécutions consécutives après le correctif.

## P5 — Configuration des coffres — 2026-10-16

- [x] `survival_chest_director_smoke.gd` vérifie les chances configurables Ordinary/Elite, le filet anti-malchance configurable et les coffres boss garantis; `survival_loadout_smoke.gd` couvre les poids des offres.
- [ ] Les rerolls d’offres ne sont pas exposés pendant les runs et restent différés jusqu’à l’intégration des effets uniques de progression P6.5.

## Run réelle et redémarrage Survival — 2026-10-16

- [x] Lancé depuis l’accueil en Easy avec un profil `XDG_DATA_HOME` temporaire, choix initial manuel, `LOCK HEALTH` et auto-choix des coffres désactivés, aucun HP forcé ni harness de simulation. À vitesse de jeu ×4 choisie dans la pause, la partie s’est terminée en défaite à la vague 1 après 13 s actives et 10 kills.
- [x] L’écran et le profil montrent +12 Essence, +16 Basic Powder, un Magic Ring, un seul `run_id` récompensé, une pièce d’équipement et 10 kills crédités.
- [ ] Cette partie n’a pas atteint les 60 s nécessaires au filet de coffre ni le boss final; la victoire et le coffre garanti restent à observer pendant P5.V3.
- [x] Le contrôle du bouton RUN AGAIN a révélé une perte de difficulté et du service de progression. `survival_run_restart_smoke.gd` vérifie désormais Easy conservé, un nouvel identifiant et une seconde récompense distincte; test enregistré dans CTest.
- [x] Suite CTest complète : 66/66 sous Godot 4.7.2.

## Population ennemie sans plafond — 2026-10-16

- [x] `survival_wave_spawn_smoke.gd` crée des fixtures actives jusqu’au seuil de l’ancienne première vague et confirme qu’un spawn ordinaire supplémentaire est quand même accepté.
- [x] Le smoke vérifie la courbe de population sans plafond fixe et la cadence configurable : facteur Normal 1×, Chaos 1,8×. Les coefficients de densité restent **[PROPOSÉS]**.
- [x] Les tests de spawn, de difficulté et du directeur de vagues passent; toute la suite CTest passe 65/65 en séquentiel sous Godot 4.7.2. Une run de joueur sans assistance reste à valider en P5.V3.

## Scénarios de validation des dix armes — 2026-10-16

- [x] `sandbox_weapon_scenario_runner.gd` lance chaque attaque de production contre des cibles déterministes avec une loadout temporaire en mémoire; `progression_service` est nul et aucun `SaveService` n’est chargé.
- [x] Les dix scénarios passent dans CTest, ainsi que le smoke de validation des fichiers et des entrées invalides : 12/12 tests ciblés, import Godot inclus, sous Godot 4.7.2.
- [x] Chaque scénario écrit métriques et événements dans un JSON de résultat CTest distinct; les fichiers produits restent dans `build/`.
- [x] La suite complète passe 64/64 sous Godot 4.7.2 en séquentiel. Une première exécution parallèle avait déclenché l’échec intermittent déjà connu de `survival_weapon_catalog_smoke`; son rerun isolé puis la suite séquentielle passent.

## Politiques de ciblage exposées dans le Sandbox — 2026-10-16

- [x] `survival_targeting_smoke.gd` vérifie nearest, farthest, highest threat, highest HP, lowest HP, la priorité PV max de Prism dans une grappe dense, les cibles de grappes, le centroïde Meteor, la réduction commune des portées (−71 %, plafond visible de 180 unités), le plafond après bonus de niveau/zone et l’exclusion des ennemis morts, des projectiles et des orbes XP. Ces règles restent **[PROPOSÉES]**.
- [x] `sandbox_ui_smoke.gd` vérifie le sélecteur à neuf politiques, l’ID ou centroïde affiché, les portées et rayons de grappe par défaut, l’effet du choix de politique et de portée, l’effacement après kill-all et la préservation du fixture de sauvegarde normale. Capture Xvfb relue à 640×360; cible, marqueur et réglages restent dans leurs cadres.
- [x] `survival_weapon_catalog_smoke.gd` vérifie le regroupement Lightning/Sawblades/Meteor/Prism, les choix par menace/PV/distance, le ciblage faible PV des Crimson Daggers, le focus PV max de Prism, le maintien/reciblage du Minigun, et les bonus Inferno des niveaux 2–5.
- [x] La suite complète est à 53/53 sous Godot 4.7.2. `survival_run_result_smoke` attend que le worker ait acquitté la pause après `run_over`; ce test passe dix exécutions consécutives. Les smokes profil, unlock, session de difficulté, pause et rendu des profils communs sont enregistrés dans CTest.
- [x] Les dix armes ont des règles de ciblage distinctes couvertes par les fixtures de comportement et les profils Sandbox.
- [ ] Leur équilibrage comparatif reste **[OUVERT]**; les sélecteurs numériques sont **[PROPOSÉS]** et la couverture ne prouve pas leur qualité finale.

> Les cases cochées sont des exécutions documentées. Le binaire Godot local est `tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`; il peut être invoqué directement même s’il n’est pas présent dans le `PATH`.

## Revalidation intégrée P5 — 2026-10-16

- [x] La suite CTest complète passe à 51/51 sous Godot 4.7.2 et Linux C++23 après intégration des smokes de difficulté, de validation du runner et stabilisation du résultat de run; temps CTest total 40,94 s, qui ne constitue pas une mesure de performance en jeu.
- [x] Au contrôle précédent, Godot 4.7.2 officiel exécuté depuis `/tmp`; la suite CTest passait avec 45/45 tests. Depuis, deux tests ont été ajoutés; résultat courant ci-dessus.
- [x] `survival_inventory_smoke.gd` utilise désormais deux équipements de fixture valides et déterministes au lieu de dépendre de récompenses aléatoires; équipement, enhancement, effet unique, compétences et démantèlement passent dans la suite intégrée.
- [x] `survival_elite_smoke.gd` vérifie le Split-on-Death plafonné sous Godot 4.7.2; les smokes voisins Summoner, boss, vagues et durée passent également.

## Profil natif des impacts — 2026-10-16

- [x] `build/simulation_benchmark` (Debug, GCC 14.2, Linux x86-64, AMD EPYC-Milan) exécute deux fois le même workload de 500 ennemis et 2 000 projectiles sur 300 frames à 60 Hz. Sans impacts : moyenne 1,27–1,30 ms avant et 1,08–1,13 ms après.
- [x] La rafale dense `wildfire_impact_burst` mesurait 141,1–143,1 ms/frame en moyenne et 154,4–158,0 ms p95 avant; après avoir évité les requêtes de zone quand le budget de cibles était épuisé, elle mesure 72,6–74,4 ms moyenne et 77,6–82,4 ms p95 (environ 48 % de baisse sur les médianes des deux exécutions).
- [x] `simulation_core` et `simulation_worker` passent après la modification, puis toute la suite CTest passe 47/47. Le stress test extrême reste au-dessus de 16,7 ms; cette charge concentre toutes les cibles et projectiles au même point et ne constitue pas un profil représentatif de Survival. Aucun budget de performance n’est actuellement défini dans les documents.

## Scénario Sandbox des affixes élite — 2026-10-16

- [x] `enemy_profiles_smoke.json` fait apparaître de façon déterministe Hasted, Armored, Regenerating, Volatile, Shielded et Split-on-Death dans le Sandbox; les attentes vérifient leur identité, leur vitesse et les attributs d’affixe publiés.
- [x] `scenario_runner.gd` valide `affix` uniquement sur un profil elite et autorise les six IDs supportés; `scenario_runner_validation_smoke.gd` couvre les cas acceptés/refusés. Le snapshot valide les attributs; le scénario passe avec Godot 4.7.2 sans accéder à la sauvegarde normale.

## Profils communs de P5 — 2026-10-16

- [x] `enemy_profiles_smoke.json` vérifie le spawn Sandbox et les PV/vitesses de Chaser, Sprinter et Tank; `simulation_core_test` vérifie pour les trois le steering conservant la vitesse propre et l’événement de mort typé.
- [x] `survival_combat_visual_smoke.gd` vérifie leurs routes de sprites distinctes et produit une capture Xvfb du combat; test ajouté à CTest sur Linux quand `xvfb-run` est disponible.
- [ ] Profil rapide, HP, menace et contre-jeu final restent **[PROPOSÉS]** jusqu’à validation d’équilibrage; le test confirme leur implémentation, pas leur qualité de tuning.

## Pression de combat sans amélioration — 2026-10-16

- [x] `survival_idle_combat_smoke.gd` vérifie 20 secondes simulées de la première vague en Normal, joueur immobile, arme de départ active et rayon XP/coffre à zéro : 23 ennemis éliminés, 83,3/100 PV restants, aucun XP ni choix collecté. Le défaut historique « aucun dégât jusqu’aux vagues 8–9 » ne se reproduit pas sur ce parcours ciblé; ce n’est pas une validation d’équilibrage complet.

## Boss final — loot et résultat — 2026-10-16

- [x] `survival_final_boss_loot_smoke.gd` vérifie que le boss final déclenche les deux familles de coffres garanties et configurables, que chaque choix laisse la simulation en pause, puis que l’écran de victoire apparaît après le dernier coffre.
- [x] `survival_boss_attack_smoke.gd` et `survival_wave_director_smoke.gd` passent avec le smoke de loot; cela valide transitions, attaques, victoire et séquence de coffres sous harness, pas une run sans assistance (P5.V3).
- [x] (2026-10-16) `survival_wave_director_smoke.gd` observe désormais les deux familles de boss dans le parcours accéléré de 24 vagues et exige que toutes deux aient été traitées avant la victoire. Ce run garde HP élevés, dégâts de boss par DoT de test et choix de coffre automatiques; il ne remplace pas le parcours P5.V3 manuel.

## Ciblage du Minigun — 2026-10-16

- [x] `survival_weapon_catalog_smoke.gd` vérifie le contrat catalogue **[PROPOSÉ]** : acquisition de la cible vivante la plus proche plutôt que d’une cible plus menaçante, conservation de la cible verrouillée quand une autre s’approche, puis reciblage après mort ou sortie de portée. Le changement remet à zéro la montée de cadence de Redline.

## Correction du viewport UI — 2026-10-16

- [x] Les interfaces conservent leur viewport logique 1280×800 et la fenêtre initiale 1280×800. Le viewport cible 640×360 de l’Art Bible attend l’adaptation responsive de chaque écran.
- [x] Le thème partagé reprend les couleurs sémantiques de la palette maître, les panneaux opaques et les boutons rectangulaires; Press Start 2P est réservée aux titres, DejaVu Sans au texte courant. Le feedback souris agrandit au survol et décale de 2 px à l’appui. Licences livrées dans `game/assets/fonts/`.
- [x] Import Godot 4.7.2 et 10 smokes ciblés UI passent après le rétablissement du viewport 1280×800, avec un `XDG_DATA_HOME` isolé par script : fondation, hub/layouts 1280×800/1600×900/1920×1080, pause, inventaire, coffre, résultat, navigation et Sandbox.
- [ ] À la date de cette correction, le smoke fenêtré et la suite complète n’avaient pas encore été relancés. La revalidation intégrée ci-dessus couvre depuis l’import et 45 tests CTest; le smoke fenêtré reste à faire.

## Feedback des niveaux d’objets en run — 2026-10-16

- [x] `survival_level_feedback_smoke.gd` vérifie les notifications d’acquisition et de niveaux 1–5 pour armes et reliques; le toast reste visible à temps de simulation figé, disparaît après expiration simulée et reste dans les viewports 640×360, 1280×800 et 1920×1080. Il vérifie aussi les impacts des dix armes pour les cinq niveaux : chaque impact conserve le niveau de sa source et son échelle augmente avec ce niveau (**[PROPOSÉ]**).

## Bonus globaux et évolutions des reliques — 2026-10-16

- [x] `survival_weapon_catalog_smoke.gd` vérifie les bonus globaux des onze reliques aux cinq niveaux; les chiffres sont exercés comme valeurs **[PROPOSÉES]**, sans valider leur équilibre.
- [x] Le même smoke vérifie les dix paires d’évolution : l’offre reste verrouillée jusqu’au niveau 5 de l’arme et de la relique, quel que soit leur ordre d’acquisition; le niveau 5 et la relique sont conservés, l’offre est unique, et seul le dégât de l’arme évoluée gagne le multiplicateur proposé de 25 % après collecte.
- [x] Avec les cinq slots d’armes saturés, il vérifie l’absence d’évolution au niveau 1 lors de l’acquisition d’une arme dont la relique est déjà niveau 5, puis l’apparition au niveau 5; dans l’autre ordre, le coffre réel présente et collecte l’évolution lorsque la relique atteint le niveau 5 après l’arme.
- [x] Vérifie aussi que les armes/évolutions déjà maximisées ne réapparaissent pas dans les offres.
- [x] `survival_contact_damage_smoke.gd` couvre séparément le délai de contact corporel par ennemi et confirme que les projectiles ennemis ne partagent pas ce délai.

## Pause du choix de coffre — 2026-10-16

- [x] `survival_chest_smoke.gd` attend que l’interface ait rejoint le dernier snapshot, puis vérifie pendant 120 ms que la simulation, le temps actif affiché et l’état pause restent figés; il vérifie aussi la reprise après sélection.

## Rendu des évolutions — 2026-10-16

- [x] `survival_weapon_catalog_smoke.gd` observe le projectile `redline` réellement tiré après évolution et vérifie que la collision continue de fonctionner.
- [x] `render_batching_smoke.gd` vérifie le lot de rendu propre à Redline, la silhouette Minigun réutilisée et la teinte rouge néon; les neuf autres formes évoluées restent vérifiées dans leurs lots dédiés.

## Hub Survival — état visuel des destinations inactives — 2026-10-16

- [x] `survival_hub_smoke.gd` vérifie que Succès et Bestiaire utilisent le style atténué, restent activables au focus et gardent le cadre de focus partagé; ils ne sont pas désactivés.
- [x] `survival_hub_layout_smoke.gd` confirme les bornes du hub à 640×360, 1280×720 et 1920×1080.
- [x] `survival_hub_smoke.gd` vérifie la médaille de Succès et le sprite de chaser du Bestiaire, leur taille compacte nearest, leurs teintes atténuées/dorées selon le focus et leur absence de signal d’action.
- [x] Capture fenêtrée avec viewport logique 640×360 relue; Succès et Bestiaire sont visuellement secondaires. Le focus est vérifié par le smoke, l’interaction avec une manette physique n’a pas été vérifiée ici.

## Hub Survival — confirmation de difficulté au lancement — 2026-10-16

- [x] Le bouton primaire reprend la difficulté active et suit la sélection Easy → Normal; le smoke confirme que l’action temporaire sans sauvegarde garde son libellé et son parcours distincts.
- [x] `survival_hub_smoke.gd` passe; `survival_hub_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080.
- [x] Capture fenêtrée du hub relue à 640×360 logique : sélection, statut et bouton principal sont visibles avec le focus.

## Sandbox développeur — largeur du panneau de réglages — 2026-10-16

- [x] `sandbox_ui_smoke.gd` vérifie que la sidebar garde au moins 194 px et que les quatre champs AI Steering s’étendent au-delà de leur minimum de 70 px à 640×360, 1280×720 et 1920×1080.
- [x] Le smoke passe sous Godot 4.7.2 avec un `XDG_DATA_HOME` isolé; son fixture sentinelle de sauvegarde normale reste inchangé et aucune autre sauvegarde n’est créée.
- [x] Capture fenêtrée Xvfb relue au viewport logique 640×360 avec deux entités; réglages et sélection restent visibles, sans débordement horizontal. Souris/manette physiques non testées.

## Inventaire d’équipement — hiérarchie des cartes — 2026-10-16

- [x] `equipment_panel_visual_smoke.gd` contrôle la largeur réservée aux contrôles, la bordure de rareté et le maintien dans les 640 px logiques.
- [x] `ui_viewport_layout_smoke.gd` passe pour toutes les interfaces aux viewports 640×360, 1280×720 et 1920×1080.
- [x] Capture fenêtrée de l’inventaire vérifiée à 640×360 logique et fenêtre 1280×720; les lignes, options, états et actions restent dans le panneau.
- [ ] `survival_inventory_smoke.gd` n’a pas terminé dans le délai de 30 s lors de cette vérification; le processus a été arrêté. Parcours de progression non revalidé dans cette tranche.
- [x] Nouvelle vérification : le smoke hub/inventaire/compétences passe après correction de ses recherches d’icône de rareté et d’action de démantèlement dans l’arborescence actuelle.
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
- [x] Entrées synthétiques : `launch_navigation_smoke.gd` parcourt le focus avec la croix, active Options avec Entrée et la ferme avec B; `survival_pause_smoke.gd` vérifie que B ouvre/reprend Pause et ferme Options sans faire avancer la run.

## HUD Survival — visibilité de la rangée d’armes — 2026-10-16

- [x] `survival_hud_smoke.gd` vérifie que le texte du loadout a une hauteur visible; ce contrôle détectait une hauteur maximale de zéro.
- [x] Capture 640×360 logique revue avec plusieurs armes; les noms ne sont plus coupés verticalement et les deux cartes restent dans leurs zones.
- [x] `ui_viewport_layout_smoke.gd` passe à 640×360, 1280×720 et 1920×1080.

## HUD Survival — séparation santé et XP — 2026-10-16

- [x] `survival_hud_smoke.gd` vérifie que santé et XP disposent de lignes distinctes, que leurs valeurs/barres suivent le bon état et que les deux lignes restent dans le panneau aux viewports testés.
- [x] `survival_hud_smoke.gd` et `survival_weapon_smoke.gd` passent après le déplacement des contrôles dans leurs lignes dédiées.
- [x] Capture fenêtrée revue à 640×360 logique : barres HP et XP longues, valeurs et rangée d’arme restent visibles et dans la carte.

## Badge d’état du HUD Survival — 2026-10-16

- [x] `survival_hud_smoke.gd` vérifie que le badge d’état change sa bordure avec les états marche et pause, en plus du libellé; exécuté sous Godot 4.7.2, passe.
- [x] (2026-10-16) `survival_hud_smoke.gd` vérifie que le HUD marque comme EVO chacune des dix évolutions du catalogue; l’indicateur compact reste uniforme, les noms complets figurent dans l’inventaire de run.

## Coffres — accent de famille — 2026-10-16

- [x] `survival_chest_choice_smoke.gd` vérifie le titre cyan du coffre d’arme, le titre magenta du coffre de relique, les icônes/descriptions, le focus et l’émission de sélection inchangée.
- [x] `survival_chest_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080 avec descriptions longues et bonus de prochain niveau.
- [x] Le smoke de choix vérifie les styles distincts du nom et de la description, l’icône 32×32 nearest et le texte complet du bouton; `survival_chest_choice_smoke.gd` exécuté sous Godot 4.7.2, passe.
- [x] Les fixtures d’armes et de reliques utilisent les icônes de catalogue actives, afin que le smoke de présentation vérifie les assets réellement affichés dans les coffres.

## Accueil — emblème pixel art — 2026-10-16

- [x] `signal_prism_asset_smoke.gd` vérifie le PNG 32×32 transparent, sa palette maîtresse de 16 couleurs maximum, l’en-tête Aseprite et son intégration nearest dans le menu.
- [x] `process_signal_prism.gd` reproduit l’export depuis la référence générée vers le PNG utilisé et la source Aseprite éditable.
- [x] Import Godot 4.7.2, `ui_foundation_smoke.gd` et `ui_viewport_layout_smoke.gd` passent; capture de l’accueil relue à 640×360 logique dans une fenêtre 1280×720.

## Accueil — composition menu gauche de l’Art Bible — 2026-10-16

- [x] `launch_navigation_smoke.gd` vérifie que la colonne verticale de commandes reste à gauche de l’identité, avec focus initial sur Jouer; Options, Quitter et l’accès discret Sandbox restent accessibles.
- [x] Le smoke de navigation passe, y compris le trajet accueil → Sandbox → accueil; `ui_foundation_smoke.gd`, `signal_prism_asset_smoke.gd` et `ui_viewport_layout_smoke.gd` passent sous Godot 4.7.2.
- [x] Capture fenêtrée Xvfb relue au viewport logique 640×360; les bornes de layout sont vérifiées à 640×360, 1280×720 et 1920×1080.
- [ ] Essais avec souris et manette physiques non effectués; les contrôles restent natifs, focusables et l’ordre clavier/manette est couvert par les smokes.
- [x] `launch_navigation_smoke.gd` passe en headless après ajout de l’emblème; retour du Sandbox vers l’accueil fonctionne toujours.

## Inventaire de run — densité au viewport logique — 2026-10-16

- [x] `survival_pause_inventory_smoke.gd` vérifie le cadre élargi, le focus visible, la navigation clavier, le défilement jusqu’au dernier item et l’absence de mutation du loadout.
- [x] Le panneau reste dans les viewports 640×360, 960×600, 1280×800 et 1600×900; `ui_viewport_layout_smoke.gd` passe aussi aux tailles 640×360, 1280×720 et 1920×1080.
- [x] Capture 640×360 logique relue avec quatre armes et quatre reliques : deux cartes complètes restent visibles avant défilement.
- [x] Le smoke vérifie la hiérarchie nom/évolution/description; `survival_pause_inventory_smoke.gd` exécuté sous Godot 4.7.2, passe.

## Résultat de run — poids des récompenses — 2026-10-16

- [x] `run_result_panel_smoke.gd` vérifie carte 360 px, icône 24×24, focus initial, ordre des actions, victoire/défaite, doublon et échec de sauvegarde.
- [x] Le smoke vérifie que le résumé de palier reprend la médaille existante, et que l’icône disparaît lors d’un résultat sans nouveau palier; `run_result_panel_smoke.gd` exécuté sous Godot 4.7.2, passe.
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
- [x] P3 placement des drops : `survival_chest_smoke.gd` passe sous Godot 4.7.2 après typage explicite de ses fixtures `Array[Vector2]`; les orbes XP ne chevauchent pas les coffres, les coffres ne se recouvrent pas complètement et un nouveau coffre évite aussi un orbe déjà au sol.
- [x] P3 armes/reliques prototype : tests de collision/tuerie Inferno et Crimson, bonus de dégâts Storm Core/Infernal Heart, bonus de soin Blood Chalice, Bloodstorm niveau 5/relique avec saignement/lifesteal, Infinite Circuit niveau 5/Storm Core avec éclairs ramifiés, et Wildfire niveau 5/relique avec explosion et brûlure de zone. Les cibles initiales, branchements et dégâts/rayon d’explosion restent **[PROPOSÉS]**.
- [x] P3 flux de run : entrée Sandbox→Survival, choix parmi deux armes **[PROPOSÉES]**, résultat de défaite/victoire et vague finale enregistrée comme 24.
- [x] Résultat de run : `run_result_panel_smoke.gd` passe sous Godot 4.7.2; `QUIT TO MENU` reste sous `RUN AGAIN`, émet son signal de navigation et le panneau tient aux viewports testés.
- [x] P3 boss final : une mort réelle génère les chests boss éligibles et la victoire attend la collecte et le choix de chaque chest.
- [x] P3 contact : collision joueur-ennemi, cooldown corps à corps séparé par ennemi, projectiles indépendants, pause/reprise des contrôles et verrouillage après la fin vérifiés sous Godot 4.7.2 headless; 0,35 s **[PROPOSÉ]**.
- [x] P3 contact : projectiles amis et orbes exclus; le rayon de contact enemy correspond au disque affiché (8 unités); les projectiles ennemis ne partagent pas le cooldown des collisions corps à corps.
- [x] (2026-10-16) `survival_contact_damage_smoke.gd` passe sous Godot 4.7.2 : un même ennemi respecte son propre délai corps à corps, un autre peut toucher pendant ce délai, un projectile ennemi reste indépendant, puis le premier ennemi peut retoucher après expiration.
- [x] (2026-10-16) `survival_loadout_smoke.gd` vérifie le bonus global de chacune des 11 reliques, les dix paires arrivées niveau 5 sans évolution automatique, puis l’activation uniquement après collecte de l’offre d’évolution.
- [x] (2026-10-16) `survival_loadout_smoke.gd` vérifie cinq reliques en capacité normale, puis six armes et six reliques avec le bonus de capacité, et refuse le septième item. `survival_unique_effects_smoke.gd` vérifie en session que deux équipements porteurs de `expanded_loadout` dédupliquent l'effet et activent les deux slots supplémentaires. Ce contrat et ses valeurs restent **[PROPOSÉS]**.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie que les sélecteurs partagés, le ciblage Lightning et Frost Nova ignorent une cible morte encore publiée dans le snapshot; le catalogue complet reste vert.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage initial Lightning **[PROPOSÉ]** : choisit le membre le plus proche d’une grappe chainable plus dense qu’une cible isolée, ignore une cible morte dans cette grappe et garde une seconde racine distincte pour Infinite Circuit.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Crimson Daggers **[PROPOSÉ]** : priorité aux PV les plus faibles, départage par proximité et exclusion des cibles mortes ou hors portée.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie la politique Minigun **[PROPOSÉE]** : acquiert la cible de plus haute menace, conserve son ID malgré une menace plus proche, puis retargete et réinitialise Redline quand la cible meurt ou sort de portée.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Inferno **[PROPOSÉ]** : choisit l’ennemi de plus haute menace dans la portée et départage une menace égale par la proximité.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Toxic Cloud **[PROPOSÉ]** : choisit l’ennemi vivant aux PV les plus élevés dans la portée, ignore une cible morte/hors portée et départage des PV égaux par la proximité.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Sawblades **[PROPOSÉ]** : vise une cible accessible de la grappe la plus dense dans son rayon de ricochet, choisit la plus proche à densité égale et retombe sur l’ennemi le plus proche lorsqu’aucune grappe n’existe.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Void Orb **[PROPOSÉ]** : choisit l’ennemi vivant le plus éloigné dans sa portée et ne produit aucune cible quand il n’y en a pas.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Prism Laser **[PROPOSÉ]** : choisit la cible la plus proche dans le groupe le plus dense et centre les faisceaux secondaires autour de la cible principale.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Meteor Staff **[PROPOSÉ]** : préfère une grappe plus dense à une cible isolée plus proche, exclut les cibles mortes du centroïde et renvoie une cible vide quand aucun ennemi vivant n’est présent.
- [x] (2026-10-16) `render_batching_smoke.gd` vérifie le ripple intérieur du champ Pandemic : son rayon varie avec le temps restant du projectile, reste borné dans le champ et devient nul pour un rayon nul ou expiré. Le rendu s’appuie sur le temps de simulation, donc son animation gèle en pause ; période 1,2 s **[PROPOSÉE]**.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` passe sous Godot 4.7.2 avec l’offre d’évolution requise pour les prototypes d’évolution testés; les arcs Lightning ne retouchent plus leur cible d’origine au départ.
- [x] Crimson Daggers/Bloodstorm P5 : `simulation_core` vérifie l’orbite native des dagues de base et l’orbite persistante de Bloodstorm sur deux cibles distinctes, ainsi que la capture/restauration; `survival_weapon_catalog_smoke.gd` vérifie le contact à la portée orbitale puis Bleed. Rayon 30, vitesse 5 rad/s et durées 0,8/2,4 s **[PROPOSÉS]**.
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
- [x] P5.2.1/2 DoT typés et événements de synergie : `simulation_core_test` vérifie Burn/Poison/Bleed, remplacement et conservation en capture/restauration, ainsi que le rejet d’un type inconnu; `simulation_worker_test` vérifie le format 14 et la conservation du statut dans sa file d’événements; les smokes Survival vérifient Poison/Bleed dans les offres de combat, anneaux distincts et lifesteal Burn. `simulation_core_test` vérifie aussi que l’identité Bleed accompagne le tick létal et son événement death. Les durées et dégâts restent **[PROPOSÉS]**; l’empilement reste **[OUVERT]**.
- [x] P5.2.4 causalité dégâts/récompenses : `survival_damage_causality_smoke.gd` vérifie qu’un projectile létal direct et un DoT létal produisent chacun exactement une mort et une orbe XP; `survival_lifesteal_smoke.gd` couvre le lifesteal distinct sur dégâts directs et ticks Burn.
- [x] Catalogue de combat sous Godot 4.7.2 : dix armes, dix reliques associées et Magnet Heart sans paire ; validation des relations et disponibilité des dix paires prototypées plus Magnet Heart.
- [x] P5.3.1 offres pondérées : `survival_loadout_smoke.gd` vérifie les poids proposés d’amélioration, paire liée, évolution proche et plafond combiné; l’offre conserve trois choix éligibles distincts.
- [x] P5.3.2 transitions de coffre : `survival_chest_smoke.gd` vérifie qu’une liste ou sélection invalide ne ferme pas le choix et ne reprend pas le temps; `survival_pause_inventory_smoke.gd` vérifie le retour au menu Pause en conservant la pause et le focus.
- [x] P5.4.6 difficultés : les smokes progression vérifient refus des difficultés verrouillées, victoire/défaite, progression Easy→Chaos et multiplicateurs Easy/Normal/Chaos distincts pour HP, dégâts, densité et récompenses; les facteurs restent **[PROPOSÉS]**.
- [x] (2026-10-15) Minigun/Overdrive/Redline sous Godot 4.7.2 headless : impact d’un projectile Minigun et baisse du délai de tir avec Overdrive au niveau 2 et Minigun au niveau 5 ; réglages marqués **[PROPOSÉS]**.
- [x] (2026-10-15) Toxic Cloud/Plague Mask/Pandemic sous Godot 4.7.2 headless : poison direct et splash via DoT natif, puis transmission à la mort au niveau 5 ; réglages et limite de cibles **[PROPOSÉS]**.
- [x] Natif C++23 : projectile Toxic Cloud inflige son impact de zone puis émet les ticks DoT bornés par le chemin partagé.
- [x] (2026-10-16) Toxic Cloud natif : après impact, le champ persiste jusqu'à la durée restante du projectile, empoisonne une nouvelle cible dans son rayon et survit à capture/restauration ; le smoke `survival_weapon_catalog_smoke.gd` valide aussi la cible entrante sous Godot 4.7.2. Rayon, durée et application unique par cible **[PROPOSÉS]**.
- [x] (2026-10-16) Catalogue de combat : schéma JSON Schema draft 2020-12 validé avec `jsonschema`; le smoke Godot vérifie le chargeur runtime, dont types stricts, absence de champs inconnus, associations et unicité des évolutions. Les entrées Survival sont filtrées par `available_in_survival`.
- [x] (2026-10-16) `survival_wave_director_smoke.gd` génère 256 ennemis sur une vague 20 seedée et vérifie que les huit familles de Survival apparaissent jusque dans la simulation native; ce smoke ne valide pas leurs poids de spawn **[PROPOSÉS]**.
- [x] (2026-10-16) `survival_boss_attack_smoke.gd` valide les trois phases du Dopamine Core : rayon télégraphié esquivé, zone annoncée, spirale en tirs successifs, invocation phase 2, attaque combinée phase 3, pause et HUD de phase. Le smoke sature aussi le plafond partagé à trois adds en phases 2–3, vérifie le refus des suivants et la réutilisation d’une place après une mort. Motifs et réglages **[PROPOSÉS]**.
- [x] (2026-10-15) Sawblades/Magnetic Coil/Razorstorm : test natif vérifie un ricochet après capture/restauration vers une seconde cible unique ; smoke Survival vérifie deux impacts et le rendu charge un asset SVG dédié. Réglages de rebonds/vitesse **[PROPOSÉS]**.
- [x] (2026-10-15) Meteor Staff/Celestial Eye/Starfall : smoke Survival vérifie une explosion limitée au groupe et les fragments sur deux cibles proches ; l'événement natif expose le type de sa source pour déclencher l'évolution. Valeurs **[PROPOSÉES]**.
- [x] (2026-10-15) Prism Laser/Prism Crystal/Spectrum Collapse : smoke Survival valide le tir prioritaire, deux cibles secondaires distinctes à l’évolution et les chemins de projectile natifs. Cadence, dégâts, progression et bonus de critique **[PROPOSÉS]**.
- [x] (2026-10-15) Void Orb/Singularity/Event Horizon : tests natifs vérifient attraction, impacts pénétrants sur cibles distinctes et capture/restauration ; smoke Survival valide le contrat GDExtension et les impacts. Rayon, force et progression **[PROPOSÉS]**.
- [x] Shooter P5 : télégraphe de visée avant le tir, pause du cycle, déplacement du projectile ECS, exclusion des dégâts sur les ennemis et collision/dégâts sur le joueur vérifiés par `simulation_core` et `survival_shooter_smoke` sous Godot 4.7.2 Linux. Dégâts, vitesse, rayon et cadence **[PROPOSÉS]**.
- [x] Buffer P5 : aura de 150 unités, vitesse d’alliés augmentée de 20 %, exclusion des ennemis hors rayon, fin du buff après la mort du soutien et capture/restauration vérifiées par `simulation_core`; snapshot/sprite par `survival_support_enemy_smoke`; profil par `sandbox_enemy_profiles_scenario`. `simulation_worker` vérifie aussi le format de capture 7. Stats et bonus **[PROPOSÉS]**.
- [x] Elite P5 : sélection Hasted/Armored/Regenerating/Volatile/Shielded/Split-on-Death; facteurs défensifs, blast borné sans chaîne et propagation de l’affixe de mort vérifiée en natif; le smoke `survival_elite_smoke.gd` vérifie le split sous plafond et passe sous Godot 4.7.2. Les autres vérifications couvrent l’affixe publié, l’explosion bornée sans chaîne et le rejet des affixes non implémentés et des types non élite, spawn après cooldown, budget de menace lié à la population, maximum actif, mort via le pipeline commun et chest élite garanti dans le smoke. HP, vitesse, facteur Armored, taux de régénération, rayon/dégâts Volatile, facteur Shielded, nombre de splits, menace, intervalle, chance, limite et formule du budget restent **[PROPOSÉS]**.
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

- [x] (2026-10-16) `sandbox_lab_smoke.gd` vérifie la scène Lab, l’absence de services de progression/save, le God Mode local commutable, un spawn de dix ennemis avec tir Lightning, le loadout par défaut, Reset depuis le preset actif et le stockage de preset en répertoire isolé. `launch_navigation_smoke.gd` vérifie l’entrée Lab séparée de `SANDBOX DEV`.
- [x] (2026-10-16) `sandbox_preset_smoke.gd` vérifie le round-trip du share code `DSLAB1:`, le schéma fermé, le rejet des champs de chemin, la détection d’une corruption, la limite JSON de 1 Mio, profondeur 16, collections de 256 éléments, et CRUD du magasin sous un répertoire de test isolé avec rejet d’un chemin `../`.
- [x] (2026-10-16) Le même smoke démarre `SandboxLabContext` sans service de progression/save, refuse transactionnellement un preset invalide et n’applique un preset importé que depuis une simulation en pause; le contexte met la simulation en pause avant chargement/import et garde le reset dans l’état de pause.
- [x] (2026-10-16) `sandbox_preset_smoke.gd` vérifie aussi l’application en combat de niveaux, relique, évolution appariée et stat custom, et le rejet d’une évolution appartenant à une autre arme.
- [x] (2026-10-16) Le smoke vérifie que le build de preset hydrate le modèle Sandbox, accepte une arme catalogue et refuse ID inconnu/niveau au-dessus du cap sans remplacer l’état actif. Les caps 64 armes, 128 reliques et niveau 100 restent **[PROPOSÉS]**.

- [x] Survival : run intégrée aux durées nominales de 24 × 30 s (720 s simulées, accélérées ×4), timer arrêté pendant les deux boss et HP decay actif. Le harness augmente les HP du joueur pour isoler le déroulement, applique les dégâts de test aux placeholders et choisit automatiquement les chests ; il ne valide pas l'équilibrage.
- [x] Une instance d'équipement permanente par run Survival, y compris défaite ; slot parmi les six validés et lignes sans statistique répétée. La rareté suit les tables par difficulté et progression de vague **[PROPOSÉES]**; pénalité de mort précoce non implémentée.
- [x] Inventaire Survival consultable : affiche rareté, slot, percentiles et état des rolls proposés ; l’ouverture suspend la simulation et la fermeture la reprend seulement si elle tournait déjà. Test headless et revue du rendu fenêtré.
- [x] Équipement persistant : équiper, déséquiper et remplacer une pièce du même slot ; migration des profils précédents. Le prototype P6 applique maintenant les lignes portées à Survival ; leurs plages restent proposées et non calibrées.
- [x] Progression v5 : migration des profils précédents vers quatre tiers de Powder, conversion 10:1, amélioration de ligne +0..+10, coût de rareté/niveau et pity au dixième essai ; probabilités et coûts restent les valeurs **[PROPOSÉES]** du GDD.
- [x] `progression_service_smoke.gd` exerce maintenant des profils fixtures v1 à v5; vérifie mise à niveau vers v6, conservation des ressources/récompenses déjà attribuées/équipements et initialisation additive des champs absents. La conversion propre à chaque version reste limitée aux schémas explicitement définis dans le code.
- [x] UI Enhancement : sélection du tier Powder, affichage du niveau de ligne et ressources, consommation, retour de résultat et inventaire persistant vérifiés dans `survival_inventory_smoke` et revue fenêtrée.
- [x] Équipement : choix d'un effet unique éligible et démontage persistés. Rendement provisoire. Lightning burst, overflow shield, evolution shockwave, elite haste et reroll gratuit du premier coffre ont des prototypes; le knockback de résurrection est exclu des nouveaux choix et reste sans gameplay défini.
- [x] Skill tree : Vitality (+5 % HP, 50 Essence), Focused Training (+3 % dégâts, 80 Essence), Fleet Footed (+2 % vitesse, 110 Essence) et Steady Aim (+1 point de critique, 140 Essence), valeurs **[PROPOSÉES]**. Prérequis, dépenses, effets en session Survival/Armorless et respec gratuit vérifiés.
- [x] Achievement prototype : kills cumulés et quatre paliers Exterminator **[PROPOSÉS]** crédités une seule fois par run ; bonus dégâts cumulés de l'exemple vérifiés.
- [x] Catalogue Exterminator data-driven : `progression_service_smoke.gd` valide les métadonnées catégorie/métrique/agrégation/secret, les quatre paliers et les récompenses cumulées depuis `game/data/achievement_catalog.json`; le chargeur rejette les entrées manquantes/dupliquées, seuils non croissants ou récompenses non numériques. Le reste du catalogue 100–150 familles demeure à faire.
- [ ] Rareté ajustée par difficulté/vague et mort précoce, calibrage des rolls, arbitrage vente/démantèlement et validation des bonus. Le rayon de ramassage ne doit jamais affecter la collecte de coffres selon GDD v1.6.
- [x] Revue de code v1.6 : collecte de coffres utilise uniquement `chest_collection_radius`; `pickup_radius_pct` ne l’élargit pas.
- [x] Smoke de régression sous Godot 4.7.2 Linux (`survival_chest_smoke`) : avec `pickup_radius_pct` à 900 %, l’XP distante est collectée et le coffre hors de `chest_collection_radius` reste au sol ; les coffres dans le rayon ouvrent le choix en pause.
- [x] Magnet Heart sous Godot 4.7.2 Linux : disponible sans évolution, bonus XP aux niveaux 1 et 5, plafond de niveau respecté et aucun effet sur le coffre à distance.
- [x] Achievement tiers débloqués une seule fois et bonus cumulés vérifiés pour la famille prototype Exterminator ; le catalogue et les seuils complets restent à définir.
- [ ] Armorless : 3 équipements proposés après chaque vague, 1 choisi ; Flux temporaire.
- [ ] Armorless : amélioration depuis l'inventaire de pause, coût débité du Flux, résultat visible, simulation suspendue et aucun Powder/sauvegarde permanente.
- [x] Armorless : le directeur traverse cinq cycles de boss jusqu'à la vague 60; une session vérifie le temps actif et le HP decay pendant l'état boss alors que l'horloge de vague reste gelée, puis leur continuité après transition. La population proposée continue de croître après la vague 24 tandis que les PV ennemis restent au plafond proposé ×12. La durée de production avec drafts et boss effectivement joués reste à valider.
- [x] `SaveService` : slot JSON versionné, checksum SHA-256, remplacement via temporaire, backup relu après altération/corruption et migration de la fixture v0 dictionnaire brut ; vérifié par `save_service_smoke`. Cette fixture ne définit pas un ancien schéma de production. Le service n’est pas chargé par le Sandbox.
- [x] Progression Survival : gains d’Essence/Powder selon la formule **[PROPOSÉE]** Normal, cumul sur plusieurs runs, défaite récompensée et `run_id` idempotent ; injection du service uniquement par l’entrée Survival et smoke avec slot temporaire isolé.
- [x] Idempotence après redémarrage : `progression_service_smoke.gd` crée un nouveau `ProgressionService`, recharge le même slot, rejoue un `run_id` déjà récompensé et vérifie l’absence de ressources et équipement supplémentaires.
- [x] Récupération de profil après corruption : `progression_service_smoke.gd` corrompt le slot courant, recrée `SaveService` et `ProgressionService`, puis vérifie que le backup précédent est relu et validé sans perdre runs récompensées ni équipement; `save_service_smoke.gd` couvre les contrôles génériques de checksum et JSON.
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
- [x] Panneau : Theme, deux réglages, focus initial, synchro/affichage du volume, demande de fermeture par bouton et entrée B synthétique, présence des actions A/B et limites géométriques à 1280×800, 960×600, 1600×900 vérifiés.
- [x] `ui_settings_smoke.gd` vérifie l’ordre DISPLAY → plein écran → séparateur → volume et le style PixelHeading; exécuté sous Godot 4.7.2, passe.
- [x] Slider et CheckButton du Theme utilisent les couleurs de la palette néon; la poignée de volume est un rond pixel 12×12 filtré nearest. `ui_settings_smoke.gd` vérifie aussi que le focus du slider reprend le cadre doré partagé. Smokes `ui_foundation_smoke.gd`, `ui_settings_smoke.gd` et `settings_service_smoke.gd` passent; la capture Options à 640×360 logique en fenêtre 1280×720 a été inspectée.
- [x] Régression : `sandbox_smoke.gd`, `sandbox_ui_smoke.gd` et `survival_entry_smoke.gd` passés avec des profils `XDG_DATA_HOME` isolés. Le service ne dépend pas de `SaveService` et écrit seulement ses préférences dans `user://settings.cfg`.
- [x] Prévisualisation fenêtrée sous Xvfb aux trois tailles sans erreur de script; rendu examiné à 1280×800.
- [ ] Interaction physique souris/clavier/manette non parcourue de bout en bout; aucun contrôleur n’est présent et aucun outil de souris interactive n’est disponible dans cet environnement. Les smokes ajoutent maintenant des événements synthétiques de croix et B, mais ne remplacent pas le contrôle sur matériel.
- [ ] Plein écran sur écran réel et sortie audio sur haut-parleurs/casque non vérifiés; seules les API DisplayServer/AudioServer et leurs valeurs sous headless ont été exercées.
- [x] Test d’intégration de l’écran Options depuis la pause couvert par `survival_pause_smoke.gd` : Retour, Échap et B ramènent à Pause, restaurent le focus et ne font avancer ni temps Simulation, ni temps actif, ni position joueur.
- [ ] Build natif et CTest non exécutés : `cmake` et `ctest` sont absents de l’environnement.

## UI refonte — survival-pause (2026-10-16)

- [x] `survival_pause_smoke.gd` est enregistré dans CTest et vérifie que `LOCK HEALTH` apparaît sous la vitesse, bloque dégâts PV/bouclier lorsqu'il est actif puis restaure le calcul normal à sa désactivation.
- [x] Validation intégrée : `simulation_core`, scénario Sandbox des profils, smoke Pause, smoke visuel sous Xvfb et `survival_weapon_catalog_smoke` passent; la suite CTest complète passe 53/53. Après un échec isolé précédent sur Infinite Circuit, le catalogue a passé directement, trois répétitions consécutives puis cette suite complète.
- [x] Godot 4.7.2 Linux : import headless réussi; `survival_pause_smoke.gd` vérifie ouverture/reprise, focus, temps Simulation/actif/vague et positions joueur/ennemi figés, retour d’Options par bouton/Échap et bornes Pause aux viewports 960×600, 1280×800 et 1600×900.
- [x] `survival_pause_inventory_smoke.gd` vérifie la projection en lecture seule de deux armes/deux reliques, noms, niveaux, descriptions, icônes et évolution active; l’ouverture place le focus sur le premier objet, les flèches déplacent le focus et le défilement, le contour doré est visible et les icônes 24×24 utilisent le filtrage nearest.
- [x] Le même smoke ferme l’inventaire par B synthétique et vérifie le retour du focus à Pause en maintenant la run gelée.
- [x] `survival_pause_inventory_smoke.gd` et `ui_viewport_layout_smoke.gd` passent; bounds de l’inventaire testés à 640×360, 1280×720 et 1920×1080.
- [x] `survival_abandon_smoke.gd` vérifie focus sûr, annulation souris/Échap/B, bounds de la confirmation, retour à l’accueil, suppression de session et absence de changement aux ressources, objets ou runs récompensées du profil.
- [x] Régressions passées : `survival_starting_weapon_smoke`, `survival_chest_choice_smoke`, `survival_chest_smoke`, `survival_hud_smoke`, `run_result_panel_smoke`, `survival_run_result_smoke`, `survival_loadout_smoke`, `survival_inventory_smoke`, `survival_wave_director_smoke`, `survival_wave_duration_smoke`, `survival_entry_smoke`, `survival_hub_smoke`, `survival_hub_layout_smoke`, `launch_navigation_smoke`, `ui_settings_smoke`, `settings_service_smoke`, `sandbox_smoke` et `sandbox_ui_smoke`.
- [x] L’assertion historique de `combat_catalog_smoke.gd` est à nouveau satisfaite : le catalogue décrit maintenant les dagues orbitantes validées par le GDD.
- [ ] Parcours matériel complet souris/clavier/manette non réalisé; le focus, les actions A/B et les contrats bouton/Échap sont testés sous headless, mais aucun périphérique ni entrée fenêtrée interactive n’était disponible.
- [ ] CTest/build natif non exécutés : `ctest` et `cmake` sont absents du PATH. `git diff --check` passe.

## Vitesse de run Survival (2026-10-16)

- [x] `survival_speed_control_smoke.gd` : choisir ×4 dans le menu Pause applique la vitesse au moteur de combat et à `Engine.time_scale`, puis quitter Survival restaure ×1.
- [x] `survival_pause_smoke.gd` et `survival_wave_duration_smoke.gd` passent avec le nouveau contrôle; la vague simulée de 30 secondes avance correctement à ×4.


## UI refonte — sandbox-ui (2026-10-16)

- [x] `render_visual_smoke.gd` sous Xvfb/Mesa : scène Sandbox vérifiée à 640×360 logiques dans la fenêtre par défaut 1280×720; les entités restent découpées dans la zone de simulation, sans recouvrir l’accueil. llvmpipe passe le smoke; audio et V-Sync indisponibles dans le conteneur.
- [x] `sandbox_ui_smoke.gd` : Theme partagé, grille métriques, focus initial, spawn/inspection/DoT, pause/reprise, step/vitesse, tuning/reset et sauvegarde sentinelle inchangée. Godot 4.7.2 headless passe avec `XDG_DATA_HOME` temporaire isolé.
- [x] `sandbox_ui_smoke.gd` vérifie aussi la barre d’outils cyan (pause/reprise), jaune (step) et rouge (reset). Capture à 640×360 logique relue; les accentuations ne changent pas l’isolation de la sauvegarde sentinelle.
- [x] `sandbox_ui_smoke.gd` couvre le badge de statut dans ses états pause/marche; exécuté sous Godot 4.7.2 avec `XDG_DATA_HOME` isolé, passe.
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

## Navigation manette — retour/annuler (2026-10-16)

- [x] `survival_hub_smoke.gd` injecte B pour fermer les panneaux équipement/compétences en restaurant le focus, puis revenir à l’accueil depuis le hub.
- [x] `run_result_panel_smoke.gd` injecte B depuis l’écran de résultat et vérifie la demande « quitter vers le menu ».
- [x] `sandbox_ui_smoke.gd` injecte B pour revenir à l’accueil et compare la sauvegarde de progression sentinelle avant/après.
- [x] Les trois smokes ci-dessus passent sous Godot 4.7.2 via Xvfb avec `XDG_DATA_HOME` isolé. Les avertissements ALSA indiquent l’absence de sortie audio et le fallback vers le driver dummy; aucun échec de script n’est émis.
- [ ] Interaction avec une manette physique non exécutée; les événements synthétiques vérifient la logique UI et ne remplacent pas le contrôle sur matériel.

## Repère de défilement — inventaire de run (2026-10-16)

- [x] Les totaux d’armes/reliques indiquent maintenant les commandes de défilement clavier et molette, au-dessus de la liste.
- [x] `survival_pause_inventory_smoke.gd` passe sous Godot 4.7.2; la capture logique 640×360 a été inspectée et le repère tient sur une ligne.

## Revalidation de la refonte UI (2026-10-16)

- [x] Import éditeur Godot 4.7.2 réussi, y compris la réimportation de la tuile Survival mise à jour.
- [x] Les 18 smokes ciblés passent sous Xvfb/Mesa, avec un `XDG_DATA_HOME` distinct : `ui_foundation_smoke`, `ui_settings_smoke`, `launch_navigation_smoke`, `survival_hub_smoke`, `survival_hub_layout_smoke`, `ui_viewport_layout_smoke`, `survival_hud_smoke`, `survival_chest_choice_smoke`, `survival_chest_layout_smoke`, `run_result_panel_smoke`, `survival_pause_smoke`, `survival_pause_inventory_smoke`, `survival_abandon_smoke`, `survival_inventory_smoke`, `sandbox_ui_smoke`, `catalog_icon_assets_smoke`, `pilot_scene_visual_smoke` et `render_visual_smoke`.
- [x] Les bounds UI passent de 640×360 à 1920×1080; le smoke HUD contrôle aussi les tailles intermédiaires jusqu’à 1600×900. Les captures Survival et Sandbox ont été générées; la capture récente de l’inventaire est inspectée à 640×360.
- [x] Le smoke Sandbox conserve son profil sentinelle inchangé; le smoke d’assets contrôle dimensions, palettes, sources Aseprite et la densité réduite de la tuile active.
- [ ] Manette physique, plein écran sur écran réel et sortie audio matérielle restent à vérifier; la simulation de manette est synthétique et l’audio utilise le driver dummy en environnement Xvfb.

## Icône catalogue — Lightning Conductor (2026-10-16)

- [x] Référence générée dédiée conservée dans `game/assets/source/catalog_weapons/`; le builder remplace l’ancienne cellule aplatie et régénère le PNG 32×32 ainsi que sa source Aseprite depuis `DEDICATED_ICON_REFERENCES`.
- [x] `catalog_icon_assets_smoke.gd` vérifie la référence de reconstruction et les contraintes existantes de dimensions, palette et source éditable.
- [x] `catalog_icon_assets_smoke.gd`, coffre avec capture, `survival_hud_smoke.gd` et `survival_pause_inventory_smoke.gd` passent sous Godot 4.7.2; l’icône a été inspectée dans la carte du coffre.

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

- [x] Historique : `process_survival_ground.gd` produisait une texture répétable 256×256 depuis une référence générée; cette version est remplacée après revue du rendu répété.
- [x] `process_survival_ground_tile.gd` produit le PNG et la source Aseprite mono-calque de la tuile 16×16 active, avec trois teintes sombres de la palette maître et des bords opposés identiques.
- [x] `catalog_icon_assets_smoke.gd` vérifie dimensions, palette restreinte, densité maximale de six pixels d’accent par tuile, couture sans joint visible, source Aseprite et branchement dans Survival; `pilot_scene_visual_smoke.gd` permet d’inspecter le sol répété en combat.
- [x] Les textures SVG, l’ancien sol 256×256 et le candidat moss/stone restent hors du rendu actif; aucune collision ni logique de combat ne change.

### Réduction du bruit de répétition (2026-10-16)

- [x] La tuile active passe des amas répétés de 2×2/3×3 pixels à cinq accents isolés sur 256 pixels, sans changer la grille 16×16, les trois teintes ou la couture.
- [x] Le PNG et la source Aseprite sont régénérés; contrôle statique de l’en-tête PNG/Aseprite, de la palette, du nombre d’accents et des bords opposés réussi.
- [ ] `catalog_icon_assets_smoke.gd` et le rendu de scène n’ont pas été rejoués après cette modification : aucun exécutable Godot n’est disponible dans cet environnement.

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

## Sources éditables des assets actifs (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` passe sous Godot 4.7.2 pour catalogue, icônes UI, roster, projectiles, impacts, environnement, récompenses et fond skyline; il vérifie les dimensions, palettes et sources Aseprite attendues.
- [x] Le smoke d’assets vérifie aussi le PNG/source Aseprite 96×96 du Dopamine Core, sa transparence, sa palette ≤16 couleurs et son routage depuis l’entité `final_boss`; `survival_boss_attack_smoke.gd` passe avec le nouveau sprite chargé.
- [x] `simulation_core` vérifie le déplacement temporisé prioritaire au steering et sa continuité après capture/restauration; `simulation_worker` vérifie le format de snapshot mis à jour. `survival_boss_attack_smoke.gd` vérifie la télégraphie et le déplacement de charge du Pulse Warden en phase 3, ainsi que sa séquence radiale.
- [x] Le smoke `survival_run_result_smoke.gd` attend que le worker ait confirmé la reprise et la vitesse ×4 avant de déclencher le test de mort; cela évite de mesurer la durée de démarrage asynchrone du worker.
- [x] `survival_weapon_catalog_smoke.gd` attend que la vitesse de simulation soit appliquée et n’active les armes qu’après création des cibles pour stabiliser la baseline de collisions. Le scénario Frost Nova refroidit désormais une cible survivante puis la tue séparément pour vérifier le shatter sur une mort effectivement gelée. Le scénario Crimson vérifie les deux impacts attendus.
- [x] Le smoke Infinite Circuit a mis au jour une origine de tir erronée des branches (créées au-delà de leur cible, vers l’extérieur) ; elles partent maintenant du parent vers la cible suivante. Le test couvre le comportement de chaîne et d’évolution.
- [x] `survival_wave_director_smoke.gd` vérifie que le timer de vague reste suspendu pendant les deux boss, que le decay joueur continue et que les spawns réguliers reprennent après le mid-boss de vague 12. Le smoke garde un intervalle de spawn court en mode accéléré pour tester cette reprise dans la fenêtre de run.
- [x] `survival_wave_duration_smoke.gd` compare la durée de vague au temps de simulation déjà traité par `SurvivalSession`, en tenant compte du temps écoulé avant le début de la mesure; le contrôle a passé trois exécutions de suite.
- [x] `survival_chest_smoke.gd` vérifie que l’offre Magnet Heart niveau 5 déclenche le rayon XP **[PROPOSÉ]** à 300 % pendant 20 secondes de simulation, que son rayon retourne au bonus normal à expiration, que ce délai reste gelé en pause et qu’un chest reste hors attraction.
- [x] Après ces changements, build natif Debug et suite CTest complète sous Godot 4.7.2 avec `XDG_DATA_HOME` isolé : 44/44 passent. Les smokes `survival_weapon_catalog_smoke`, `survival_run_result_smoke` et `survival_wave_director_smoke` ont également passé plusieurs exécutions ciblées.
- [x] `pilot_asset_batch_smoke.gd` passe pour les exports animés du joueur et leurs sources; `signal_prism_asset_smoke.gd` passe pour l’emblème et son intégration à l’accueil.
- [x] L’audit de références runtime ne trouve plus d’asset SVG parmi les visuels chargés par les scènes/scripts; les anciens SVG restants sont des références inactives, sauf une référence historique dans `combat_catalog_smoke.gd`.

## Repères visuels de l’équipement (2026-10-16)

- [x] Les lignes d’équipement affichent séparément l’icône de leur emplacement et celle de leur rareté, en 24×24 et nearest.
- [x] `equipment_panel_visual_smoke.gd` vérifie les ressources, les tailles, le filtrage et les bounds à 640×360, 1280×720 et 1920×1080 sous Godot 4.7.2.
- [x] Capture fenêtrée Xvfb relue à 640×360 logique; les icônes sont distinctes et lisibles près du détail de l’objet.

## Icône de ressource dans l’arbre de compétences (2026-10-16)

- [x] Le solde d’essence reprend l’icône dédiée de la Bible d’assets, en nearest, sans changer son calcul ni les prérequis des nœuds.
- [x] `skill_tree_panel_visual_smoke.gd` vérifie l’icône, le filtrage et la valeur affichée sous Godot 4.7.2.

## Branche visuelle de l’arbre de compétences (2026-10-16)

- [x] `skill_tree_panel_visual_smoke.gd` couvre les deux nœuds existants, le connecteur, la séparation entre action et effet/coût proposé et les statuts de déverrouillage; smoke passé sous Godot 4.7.2.
- [x] Les effets/coûts utilisent 8 px avec retour à la ligne; le smoke échoue si leur taille passe sous ce seuil.
- [x] Capture fenêtrée sous Xvfb relue à 640×360 logique; le cadre et les deux cartes tiennent dans le viewport, le texte est plus lisible, et le focus reste visible.
- [x] `ui_viewport_layout_smoke.gd` vérifie toutes les interfaces à 640×360, 1280×720 et 1920×1080.

## Repère XP du HUD (2026-10-16)

## Déblocages d’armes et de reliques (2026-10-16)

- [x] `progression_service_smoke.gd` vérifie les starters, les prérequis de Crimson Daggers puis Blood Chalice, les coûts **[PROPOSÉS]**, et le remboursement/réinitialisation au respec.
- [x] `progression_service_smoke.gd` achète toutes les branches d’équipement puis confirme que les 10 armes et 11 reliques sont disponibles et que le respec rembourse tous leurs coûts.
- [x] `survival_loadout_smoke.gd` vérifie le filtrage des offres et des choix de départ selon les déblocages, puis le chargement du catalogue complet; `survival_hub_smoke.gd` confirme les deux choix d’arme et les deux reliques de départ d’un profil neuf.
- [x] `survival_entry_smoke.gd` vérifie que le Sandbox n’injecte pas de ProgressionService; il conserve donc son catalogue complet.
- [x] `skill_tree_panel_visual_smoke.gd` couvre le défilement, les cartes générées de tout l’équipement, les coûts proposés, les prérequis et les IDs émis.
- [x] Le smoke vérifie aussi que le focus clavier révèle le dernier déblocage dans le viewport; capture Xvfb relue à 640×360 logique.

## Arbre de compétences 100 nœuds (2026-10-16)

- [x] `progression_service_smoke.gd` achète les 100 nœuds selon leurs prérequis, vérifie le proxy linéaire proposé de 29,7 points, confirme les déblocages et le remboursement total au respec.
- [x] `survival_armorless_mode_smoke.gd` applique le profil complet à de vraies sessions Survival et Armorless : HP +10,7 %, dégâts +9 %, mobilité +6 %, critique +4 points, dix armes et onze reliques.
- [x] `skill_tree_panel_visual_smoke.gd` vérifie le rendu des 94 nœuds générés, le focus clavier jusqu’au dernier rang et la capture à 640×360 logique; les trois viewports passent dans `ui_viewport_layout_smoke.gd`.
- [ ] Le proxy linéaire ne remplace pas la calibration d’équivalence de puissance des profils, qui reste dans P6.9.

## Économie proposée de l’arbre de compétences (2026-10-16)

- [x] `progression_service_smoke.gd` vérifie 15 900 Essence cumulée, 4 160 pour les 17 nœuds d’équipement et une moyenne de 2,78 victoires normales vague 24 par déblocage équipement, calculée sur la récompense GDD **[PROPOSÉE]** de 88 Essence.
- [x] À supposer que chaque run atteigne le boss final et gagne, l’arbre complet équivaut à 257 victoires Easy, 181 Normal, 113 Hard, 73 Nightmare ou 46 Chaos avec les multiplicateurs d’Essence **[PROPOSÉS]**.
- [ ] Cette conversion en victoires équivalentes est seulement analytique; fréquence de runs, récompenses de défaite, ventes et ressenti des coûts restent à observer en P6.9.

- [x] Le HUD reprend l’orbe XP 16×16 à sa taille native et en nearest, sans changer les valeurs ni le calcul de progression.
- [x] `survival_hud_smoke.gd` vérifie l’asset, sa taille, son filtrage et les bounds des lignes; exécuté avec Godot 4.7.2, passe.

## Icônes de préparation du hub (2026-10-16)

- [x] Équipements et arbre de compétences réutilisent chacun leur icône pixel dédiée en taille compacte, nearest.
- [x] `survival_hub_smoke.gd` couvre les ressources d’icône, la taille et le filtrage; exécuté avec Godot 4.7.2, passe avec les parcours, destinations inactives et focus.

## Rappel de reprise dans la pause (2026-10-16)

- [x] Le statut du menu indique que la touche Échap reprend la run; le contrôle et le gel de simulation restent inchangés.
- [x] `pause_panel_visual_smoke.gd` vérifie le rappel et les accents d’action; exécuté avec Godot 4.7.2, passe.

## Actions compactes de l’équipement (2026-10-16)

- [x] Équiper/déséquiper et démanteler partagent maintenant une rangée; cyan et rouge distinguent leurs intentions, sans changer les signaux ni les règles.
- [x] `equipment_panel_visual_smoke.gd` vérifie l’ordre, les couleurs, le rendement complet dans l’infobulle et le libellé visible sans troncature.
- [x] `survival_inventory_smoke.gd` passe sous Godot 4.7.2; équipement, amélioration, effet unique, compétences et démantèlement restent fonctionnels.

## Revalidation intégrée des interfaces (2026-10-16)

- [x] Les 26 smokes UI/flux passent sous Godot 4.7.2 avec un `XDG_DATA_HOME` distinct par smoke : fondation, Options, navigation, hub, HUD, choix de départ/coffre, pause, inventaire, résultat, Sandbox et layouts.
- [x] `sandbox_ui_smoke.gd` passe huit fois d’affilée après que le test a suspendu son polling UI pendant la lecture des événements d’un pas déterministe; le fonctionnement du Sandbox n’a pas changé.
- [x] Le smoke d’entrée contrôle les TextureRect des cartes d’arme; le smoke loadout vérifie le niveau suivant et retrouve l’offre ciblée dans les tirages randomisés sans supposer qu’elle figure dans un tirage particulier.
