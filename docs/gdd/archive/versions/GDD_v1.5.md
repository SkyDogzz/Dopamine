# DOPAMINE SURVIVOR — GDD COMPLET v1.5

> Document de référence consolidé · 15 octobre 2026 · Français

## Sommaire

- [01 — Vision et périmètre](#1)
- [02 — Boucle de jeu et commandes](#2)
- [03 — Combat, HP decay et guérison](#3)
- [04 — Ennemis, vagues et difficultés](#4)
- [05 — Armes, reliques et évolutions](#5)
- [06 — Chests et progression pendant une run](#6)
- [07 — Équipement permanent](#7)
- [08 — Enhancement et Powder](#8)
- [09 — Progression permanente et économie](#9)
- [10 — Achievement Mastery (officiel v1.2)](#10)
- [11 — Mode Survival](#11)
- [12 — Endless standard (conception provisoire)](#12)
- [13 — Endless Armorless (officiel v1.3)](#13)
- [14 — Sandbox Lab (officiel v1.4)](#14)
- [15 — Interface et expérience utilisateur](#15)
- [16 — Architecture technique Godot](#16)
- [17 — Modèle de données et conventions](#17)
- [18 — Performances, stabilité et sécurité](#18)
- [19 — Tests d’acceptation et QA](#19)
- [20 — MVP, roadmap et questions ouvertes](#20)


<a id="1"></a>

## 01 — Vision et périmètre

DOPAMINE SURVIVOR — GAME DESIGN DOCUMENT v1.5
Statut : spécification consolidée de conception, 15 octobre 2026.

Dopamine Survivor est un roguelite top-down à combat automatique inspiré du genre bullet heaven. Son identité repose sur une pression de survie permanente : les points de vie diminuent continuellement et les éliminations permettent de les restaurer. Le joueur optimise armes, reliques, évolutions, équipement, arbre de compétences et achievements afin de vaincre des vagues toujours plus dangereuses.

Direction : pixel art néon, ambiance électronique synthwave/EDM dont les couches s'intensifient avec les vagues ; nombres de dégâts agrégés ; lisibilité prioritaire malgré des centaines d'ennemis.

Plateforme initiale : Windows PC. Modèle économique : achat premium unique. Moteur : Godot 4.x. Cible : 60 FPS sur GPU intégré dans les configurations représentatives. Contrôles : clavier WASD et manette. Arène infinie, caméra orthographique, ennemis générés autour du joueur.

Quatre expériences : Survival (24 vagues), Endless standard, Endless Armorless et Sandbox Lab. Sandbox est un laboratoire hors progression et accessible sans sauvegarde.

Légende de statut : [VALIDÉ] décision explicitement retenue ; [PROPOSÉ] paramètre de départ à équilibrer ; [OUVERT] décision restant à prendre. Les valeurs numériques proposées ne doivent pas être considérées comme figées.

<a id="2"></a>

## 02 — Boucle de jeu et commandes

[VALIDÉ] Combat automatique ; le joueur dirige le déplacement et choisit ses objets lors de l'ouverture des chests. Les armes attaquent automatiquement suivant leurs propres règles de ciblage. Les chests d'armes et de reliques proviennent des ennemis. Chaque chest propose trois options, avec une préférence pour les améliorations équipées et les synergies. Les orbes d'XP font monter le niveau sans écran traditionnel de trois upgrades.

Boucle Survival : choisir difficulté et arme initiale → survivre à une vague de 30 secondes → tuer pour se soigner et gagner XP → ramasser chests → améliorer armes/reliques → vaincre le mid-boss vague 12 → vaincre le boss final vague 24 → récompenses permanentes → recommencer.

[VALIDÉ] La durée de base est de 24 × 30 secondes = 12 minutes de combat actif, plus les pauses de boss et les choix. Objectif d'une run : 10–15 minutes. Le timer de vague s'arrête durant les boss ; le HP decay continue. Les joueurs peuvent poursuivre en Endless après la victoire finale selon le design proposé, mais les règles d'accès exactes d'Endless standard restent [OUVERTES].

[PROPOSÉ] Chaque niveau d'XP donne un petit bonus automatique de stats, sans écran de sélection. La courbe d'XP, les bonus par niveau et le comportement des pauses d'interface restent à spécifier.

<a id="3"></a>

## 03 — Combat, HP decay et guérison

[VALIDÉ] HP initial = 100. Perte passive de HP initiale = 1,5 HP/s, croissante linéairement avec le temps de combat actif. Les kills soignent selon le niveau de menace des ennemis. Lifesteal sur dégâts avec soft cap. Dégâts de contact accordent une courte invulnérabilité. Revives rares.

[PROPOSÉ] D(t) = 1,5 + 0,004 t HP/s (t en secondes actives). Perte exacte sur [t,t+Δt] = 1,5 Δt + 0,002((t+Δt)^2 - t²). Après 60 secondes sans soin : 97,2 HP perdus. Après 720 secondes : 2 116,8 HP perdus. Le timer ne progresse pas pendant les menus en pause, mais progresse pendant les combats de boss.

[PROPOSÉ] Soin par kill H(T)=2+3√T, menace T bornée dans [0,5 ; 25] ; ennemi ordinaire T=1 → +5 HP. Menace calculée depuis archétype et multiplicateurs HP/dégâts/vitesse. Lifesteal : rendement normal jusqu'à 10 HP/s puis efficacité de 25 % au-delà ; dégâts sur la durée donnent 25 % de leur lifesteal théorique. Invulnérabilité après impact : 0,35 s.

[À TESTER] Taux de kills nécessaire pour compenser le decay, situations sans ennemis, builds à faible DPS, boucles de guérison infinie, survie à 1 HP et comportement pendant les transitions.

<a id="4"></a>

## 04 — Ennemis, vagues et difficultés

[VALIDÉ] Cinq difficultés progressives : Easy, Normal, Hard, Nightmare, Chaos. Chaque difficulté se débloque en battant la précédente. Les statistiques et la densité des ennemis augmentent avec la difficulté ; Chaos ajoute des comportements particuliers. Élites aléatoires pilotées par un budget de menace et cooldown. Mid-boss à la vague 12, boss final à la vague 24. Pas de limite de temps pour battre un boss.

[PROPOSÉ] Archétypes initiaux : Chaser (20 HP, 75 px/s), Sprinter (12 HP, 125 px/s), Tank (80 HP, 45 px/s), Shooter (25 HP, 65 px/s). Multiplicateur HP de vague en Survival : min(1,12^(vague−1), 12). Population cible : round(10+390*((vague−1)/23)^1,5), de ~10 à ~400.

[PROPOSÉ] Multiplicateurs par difficulté (HP / dégâts / densité / Essence / Powder) : Easy 0,75 / 0,70 / 0,80 / 0,70 / 0,70 ; Normal 1 / 1 / 1 / 1 / 1 ; Hard 1,5 / 1,3 / 1,2 / 1,6 / 1,5 ; Nightmare 2,2 / 1,7 / 1,5 / 2,5 / 2,3 ; Chaos 3,2 / 2,3 / 1,8 / 4 / 3,5.

[OUVERT] Catalogue détaillé des patterns des boss, compositions de vagues, mutations Chaos, seuils d'élites et budget de simulation.

<a id="5"></a>

## 05 — Armes, reliques et évolutions

[VALIDÉ] Deux armes et deux reliques initialement débloquées ; les autres se débloquent dans l'arbre de compétences. Le choix d'arme de départ propose deux armes initialement, puis trois après le troisième déblocage. Maximum normal : cinq armes et cinq reliques ; certains effets uniques Legendary/Mythic peuvent étendre chacun à six. Pas de doublons d'armes dans une run normale. Niveau maximum : 5 pour chaque arme/relique. Les améliorations des armes sont spécifiques à leur identité ; les bonus des reliques sont linéaires. Une évolution se déclenche lorsque l'arme atteint le niveau 5 et que la relique associée est possédée, quel que soit le niveau de cette relique.

Paires de contenu :
1. Lightning Conductor + Storm Core → Infinite Circuit : éclairs ramifiés.
2. Inferno Sprayer + Infernal Heart → Wildfire : brûlures qui explosent et se propagent.
3. Crimson Daggers + Blood Chalice → Bloodstorm : entailles et lifesteal.
4. Void Orb + Singularity → Event Horizon : trous noirs et attraction.
5. Frost Nova + Frozen Crown → Absolute Zero : gel et fragmentation.
6. Minigun + Overdrive Engine → Redline : cadence accélérante.
7. Meteor Staff + Celestial Eye → Starfall : météores fragmentés.
8. Sawblades + Magnetic Coil → Razorstorm : ricochets.
9. Toxic Cloud + Plague Mask → Pandemic : poison contagieux.
10. Prism Laser + Prism Crystal → Spectrum Collapse : faisceaux divisés.

[PROPOSÉ] Lightning Conductor niveaux 1–5 : 2 chaînes → 3 chaînes → +25 % dégâts → 5 chaînes → 2 cibles initiales. Les 9 autres tables de niveaux, cooldowns, dégâts, portée, ciblage et bonus précis des reliques restent [À RÉDIGER].

[VALIDÉ] Les armes/reliques débloquées deviennent disponibles pour les tirages et ne sont pas automatiquement équipées dans chaque run.

<a id="6"></a>

## 06 — Chests et progression pendant une run

[VALIDÉ] Deux familles de chests : armes et reliques, obtenues sur les ennemis. Trois choix par ouverture. Le tirage favorise les synergies et les améliorations des objets équipés. Un directeur dynamique de loot garantit une progression minimale sans imposer un build.

[PROPOSÉ] Probabilité de drop par ennemi ordinaire : 0,5 % pour chaque famille ; élite : 15 % par famille ; boss : un chest de chaque famille garanti. Filet de sécurité : au moins un chest éligible de chaque famille toutes les 60 secondes. Poids de proposition : ×1,5 upgrade équipé ; ×2 relique correspondant à une arme ; ×1,5 arme correspondant à une relique ; ×1,25 évolution proche ; multiplicateur combiné plafonné à ×3.

[À TESTER] Éviter les tirages impossibles lorsque les slots sont pleins ; définir les alternatives quand tout est niveau 5 ; ne pas compter plusieurs fois les drops garantis ; prévenir les biais extrêmes ; empêcher l'ouverture en double après chargement.

<a id="7"></a>

## 07 — Équipement permanent

[VALIDÉ] Six slots : helmet, armor, gloves, boots, amulet, ring. Une seule pièce d'équipement garantie par run classique, y compris en cas de mort. Slot tiré aléatoirement. Inventaire permanent illimité ; équiper, vendre ou démanteler. Pas de bonus de set. Pas de type de statistique répété sur un même objet.

Raretés : Normal (1 ligne aléatoire), Magic (2), Mystic (3), Legendary (3 aléatoires + 1 effet unique choisi librement), Mythic (4 aléatoires + 1 effet unique choisi librement). Les rolls de statistiques sont continus dans des plages dépendantes de la rareté. Rareté dépend de la difficulté, de la vague atteinte et de la RNG.

Douze statistiques candidates : dégâts %, vitesse d'attaque %, chance critique %, dégâts critiques %, HP max, vitesse déplacement %, soin par kill %, zone %, réduction de cooldown %, XP %, rayon de collecte %, vitesse projectile %.

[PROPOSÉ] Chances de rareté Normal/Magic/Mystic/Legendary/Mythic : Easy 60/30/9/0,9/0,1 ; Normal 35/40/20/4,5/0,5 ; Hard 15/30/40/13/2 ; Nightmare 5/15/45/28/7 ; Chaos 0/5/35/40/20 (%). Une mort précoce diminue les chances des raretés supérieures. Plages exactes de rolls à calibrer.

[VALIDÉ] Effets uniques peuvent augmenter la capacité d'armes ou reliques à six ; un même effet unique actif ne se cumule pas automatiquement plusieurs fois. [PROPOSÉ] En cas de perte du slot bonus, l'objet supplémentaire devient inactif plutôt que détruit.

<a id="8"></a>

## 08 — Enhancement et Powder

[VALIDÉ] Chaque ligne de statistique s'améliore indépendamment de +0 à +10. Formule : valeur_effective = roll_de_base × (1 + 0,08 × niveau). Les probabilités de réussite baissent avec le niveau. Échec ordinaire : aucun changement ; échec critique : perte d'un niveau, minimum 0 ; dixième tentative consécutive sans succès : réussite garantie. Seule la Powder est consommée, sans Essence ni gold.

[VALIDÉ] Quatre tiers de Powder : Basic, Refined, Pure, Prismatic. Conversion ascendante 10:1. Le démantèlement d'équipement produit de la Powder. Reroll d'effet unique possible mais coûteux.

[PROPOSÉ] Succès selon poudre et niveau courant E : Basic 50−3E %, Refined 70−3E %, Pure 85−3E %, Prismatic 95−3E %. Échec critique conditionné à l'échec : 10/5/2/0,5 % respectivement ; le reste est un échec normal. Garantie sur la dixième tentative de la même ligne. Coût de base pour cibles +1 à +10 : 10,15,22,32,46,65,90,125,175,250 ; multiplicateurs de rareté 1 / 1,5 / 2 / 3 / 4.

[OUVERT] Poudres consommables selon niveau et rareté, prix exact du reroll, économie de démantèlement, prévention des exploits de conversion.

<a id="9"></a>

## 09 — Progression permanente et économie

[VALIDÉ] Arbre de compétences interconnecté de 100–150 nodes ; environ 120 prévus. Branches de déblocage d'armes/reliques et bonus avancés avec prérequis. Respec complet gratuit. Tous les nodes peuvent finir par être acquis. Budget cible : ~+30 % de puissance de combat équivalente. Environ un déblocage utile toutes les 2–3 runs. Essence plus abondante en difficulté élevée.

[PROPOSÉ] Répartition 120 nodes : 30 stats centrales ; 8 déblocages armes ; 8 déblocages reliques ; 20 maîtrises armes ; 20 maîtrises reliques ; 14 utilitaires ; 20 passerelles. Graphe précis et coûts à définir.

[PROPOSÉ] Récompenses Survival : Essence = arrondi((15 + 2×vague_max + 25×boss_final_vaincu) × multiplicateur_difficulté). Powder = arrondi((20 + 3×vague_max + 30×boss_final_vaincu) × multiplicateur_difficulté). Victoire Normal vague 24 : 88 Essence, 122 Powder Basic.

[VALIDÉ] Endgame : optimiser les équipements Mythic, terminer toutes les difficultés, développer les achievements et battre ses records Endless.

<a id="10"></a>

## 10 — Achievement Mastery (officiel v1.2)

[VALIDÉ] 100–150 familles d'achievements ; cible éditoriale 120 familles. Quatre paliers Bronze, Silver, Gold, Diamond. Bonus permanents cumulables, statistiques et effets spéciaux. Défis secrets récompensés. Progression conservée entre toutes les runs. Indépendance totale vis-à-vis du respec du skill tree. Budget de puissance totale : +10–15 % équivalent global ; cible proposée +12 %.

[PROPOSÉ] Répartition des 120 familles : Combat 25 ; Survival 15 ; Weapons 20 ; Relics & Evolutions 15 ; Equipment 15 ; Difficulty & Bosses 15 ; Progression 10 ; Secrets 5. Jusqu'à 480 récompenses de palier.

Exemple Exterminator : 100 / 1 000 / 10 000 / 100 000 kills cumulés ; bonus par palier +0,05 / +0,10 / +0,15 / +0,20 points de pourcentage de dégâts ; total +0,50 % au Diamond. Autres exemples : coups critiques, élites tuées, dégâts par arme, guérison cumulée, boss vaincus, équipement démantelé, enhancements réussis, runs Chaos, évolutions déclenchées.

Effets uniques proposés : Lightning supplémentaire occasionnel ; bouclier temporaire issu du soin excédentaire ; onde de choc à la première évolution ; vitesse temporaire après élimination d'élite ; reroll gratuit du premier chest ; onde de recul à la résurrection. Aucun achievement ne désactive le HP decay ni ne procure de revive infini.

Données : AchievementDefinition {id, category, secret, metric, aggregation, tiers[threshold,rewards]}; métriques de vie cumulées (sum), records (max), et état des tiers. Les récompenses sont reconstruites à partir des tiers acquis au chargement ; jamais dupliquées dans le save. Events idempotents ; secrets suivis avant révélation.

[À TESTER] Les bonus spécialisés et utilitaires ne s'additionnent pas naïvement au budget de puissance ; mesurer des builds de référence complets.

<a id="11"></a>

## 11 — Mode Survival

[VALIDÉ] Mode principal : 24 vagues de 30 secondes, mid-boss 12, boss final 24 ; fin victorieuse ou mort. Équipement permanent actif, bonus de skill tree et achievements actifs. Armes et reliques reconstruits à chaque run via chests. Une pièce d'équipement permanente garantie par run, y compris défaite. Difficulté choisie parmi celles débloquées.

[PROPOSÉ] Après victoire, proposition de poursuivre en Endless standard sans perdre le build. [OUVERT] Décision finale sur l'accès au Endless depuis le menu et sa condition de déblocage.

<a id="12"></a>

## 12 — Endless standard (conception provisoire)

[PROPOSÉ — NON ENCORE VALIDÉ PAR LE JOUEUR] Deux entrées : (a) lancer Endless depuis le menu après déblocage ; (b) continuer immédiatement après la vague 24. Depuis le menu : progression permanente et équipement actif, mais armes/reliques recommencent au niveau 1 ; après le boss : build et HP actuels conservés. Difficultés Easy à Chaos.

[PROPOSÉ] Cycles après vague 24 : ennemis plus puissants, élites et mutations, boss récurrents ; maîtrise répétable temporaire avec rendements décroissants après max des objets. Records de vague et survie.

[OUVERT] Déblocage, difficulté, cadence des boss, nature de la maîtrise répétable, modalités de sortie, récompenses et classement. Ces options ne sont pas des décisions officiellement arrêtées.

<a id="13"></a>

## 13 — Endless Armorless (officiel v1.3)

[VALIDÉ] Mode Endless autonome : aucun équipement permanent actif. Skill tree et Achievement Mastery restent actifs. Les armes et reliques sont reconstruits normalement pendant la run. Après CHAQUE vague terminée : un Equipment Draft de trois propositions, dont une seule est choisie. Slots entièrement aléatoires et indépendants : chaque proposition a 1/6 de chances pour chacun des six slots ; aucun filet de sécurité pour slots vides. Probabilité qu'un slot précis apparaisse dans un draft : 1−(5/6)^3 ≈ 42,13 %.

[VALIDÉ] Les objets sélectionnés sont temporaires et disparaissent à la fin de la run. Amélioration possible grâce au Flux, ressource temporaire spécifique à Armorless. Legendary/Mythic : libre choix de l'effet unique parmi les effets éligibles. Difficultés Easy à Chaos. Classement : vague la plus haute, puis temps de survie le plus long, puis nombre de kills ; classements séparés par difficulté.

[PROPOSÉ] Raretés selon vague, en % Normal/Magic/Mystic/Legendary/Mythic : vagues 1–5 : 55/35/9/1/0 ; 6–15 : 25/40/27/7/1 ; 16–30 : 5/20/45/25/5 ; 31–50 : 0/5/25/50/20 ; 51+ : 0/0/10/55/35. Multiplicateur de poids selon difficulté : Easy 0,80 ; Normal 1 ; Hard 1,15 ; Nightmare 1,35 ; Chaos 1,60, appliqué sous forme poids_r × multiplicateur^indice_r, puis normalisé.

[PROPOSÉ] Flux gagné à la fin de la vague w : 5+2w ; coût d'amélioration au niveau E : ceil(5×1,5^E×multiplicateur_rareté), multiplicateurs 1 / 1,25 / 1,5 / 2 / 2,5. Bonus de ligne +8 % par niveau ; max +10 ; échecs et pity analogues à l'enhancement normal. Flux jamais convertible en Powder.

[PROPOSÉ] HP ennemis Armorless : HP0 × multiplicateur_difficulté × (1,10^(w−1) si w≤24, sinon 1,10^23 × 1,055^(w−24)). HP decay identique au système de base, sans reset. Boss toutes les 12 vagues ; timers suspendus pendant boss, decay maintenu. Densité bornée par budget de performance.

[PROPOSÉ] Récompenses persistantes possibles : Essence, Powder, achievements et records, mais pas d'équipement permanent garanti. Ce dernier point reste une proposition à confirmer ; la règle d'un équipement garanti s'applique explicitement aux runs classiques.

[À TESTER] Draft à trois slots identiques, objets multiples d'un slot, gestion de l'inventaire temporaire, remplacement d'un équipement qui fournit un slot d'arme, destruction de Flux à la mort, sauvegarde/reprise et anti-double-attribution.

<a id="14"></a>

## 14 — Sandbox Lab (officiel v1.4)

[VALIDÉ] Sandbox Lab est accessible depuis le menu principal avant toute création/lecture de sauvegarde. Ce n'est pas un mode de progression. Presque tous les paramètres peuvent être modifiés, y compris des valeurs extrêmes. Édition en direct pendant la run. Build initial totalement libre : armes, reliques, équipement, statistiques et niveaux. Presets indépendants, export/import JSON et code de partage. Import d'une sauvegarde normale autorisé uniquement en copie isolée modifiable. Outils obligatoires : spawn, kill all, DPS meter, god mode, contrôle de vitesse, logs. Valeurs dangereuses : avertissement et limite technique de sécurité.

[VALIDÉ] Aucun gain d'Essence/Powder permanent, aucun achievement officiel, aucun score classé. Aucune modification de sauvegarde normale. Copie dans un contexte mémoire séparé ; import à sens unique Normal → Sandbox, jamais l'inverse.

Familles d'overrides : Player (HP, decay, dégâts, mobilité, crit, soins, revives) ; Weapons/Relics (capacité, niveaux, duplications, évolutions, cooldowns, projectiles) ; Loot (drops, chests, choix, poids, garanties) ; XP ; Enemies/Waves (stats, densité, spawn, bosses, scaling, durée) ; Equipment (stats, rareté, effets, enhancements) ; Progression simulée (skill tree, achievements) ; Simulation (seed, vitesse, invincibilité, métriques).

Architecture : BaseBalanceConfig → SandboxOverrideLayer → RuntimeConfigResolver → systèmes de jeu existants. Les changements sont typés LIVE (immédiat), REBUILD (reconstruire le composant), RESTART (redémarrer la simulation). Les modifications multiples s'appliquent transactionnellement ; rollback si erreur. Tous les systèmes lisent la configuration effective plutôt que des constantes codées en dur.

[PROPOSÉ] Presets : schema_version, preset_id, name, description, base_mode, seed, overrides, flags, initial_build. Codes : préfixe DSLAB1:, JSON canonique compressé, Base64URL, somme de contrôle ; validation de taille et décompression bornée ; jamais de script, commande, chemin système ou données privées. Sauvegardes locales distinctes : user://saves/ et user://sandbox/{presets,snapshots,logs}.

[PROPOSÉ] DPS : fenêtre 1 s, 10 s et run ; dégâts par arme/évolution/effet, critiques, coups, cibles, overkill. Logs événements et RNG. Commandes : spawn, kill all avec ou sans loot, reset cooldowns, restore HP, freeze AI, clear projectiles, jump wave, give item.

[PROPOSÉ] Seuils indicatifs normal / avertissement / hard cap : armes 5–6 / 15+ / 64 ; reliques 5–6 / 20+ / 128 ; ennemis 200–500 / 750+ / 2 000 ; projectiles variable / 5 000+ / 20 000 ; vitesse ×1 / ×4+ / ×16 ; XP ×1 / ×100+ / ×10 000. Hard caps à profiler, pas des garanties de performance.

<a id="15"></a>

## 15 — Interface et expérience utilisateur

[VALIDÉ] Direction pixel art néon ; HUD lisible à très forte densité ; support manette. Menus : écran d'accueil avec Play et Sandbox Lab accessibles indépendamment ; choix de sauvegarde seulement pour Play ; choix de mode et difficulté ; préparation de run ; HUD ; chests ; écran de mort/victoire ; inventaire ; enhancement ; skill tree ; achievements ; records ; Sandbox configuration et panneau live.

[PROPOSÉ] HUD : HP et decay actuel, vague/timer, difficulté, XP/niveau, armes/reliques, évolutions, boss HP, dégâts agrégés. Armorless : comparer trois équipements à chaque vague, stats positives/négatives et comparaison avec l'objet équipé, choix d'effet unique sur Legendary/Mythic, solde de Flux, enhancements accessibles pendant pause. Sandbox : onglets de paramètres, éditeur de build, contrôles de simulation, panneau DPS/logs, recherche de paramètres, export/import.

[À DÉFINIR] Wireframes de chaque écran, navigation manette, accessibilité, réglages VFX et affichage du nombre d'ennemis, détails audio.

<a id="16"></a>

## 16 — Architecture technique Godot

[VALIDÉ] Godot 4.x, fichiers de balance JSON externes + Godot Resources, sauvegardes locales automatiques, RNG seeded avec flux séparés gameplay/loot/progression/cosmetic. 60 FPS cible sur iGPU. Configurations et données d'objets pilotées par données.

[PROPOSÉ] Modules : GameSessionManager ; ModeRules ; RuntimeConfigResolver ; CombatSystem ; HealthDecaySystem ; EnemySpawnDirector ; WaveManager ; BossManager ; WeaponManager ; RelicManager ; EvolutionResolver ; ChestDirector ; XPSystem ; EquipmentGenerator ; InventoryService ; EnhancementService ; SkillTreeService ; AchievementTracker/Evaluator/RewardRegistry ; EconomyService ; SaveManager ; SandboxManager ; MetricsCollector ; UI.

[PROPOSÉ] Tous les modes implémentent une interface de règles commune : autorisations progression, source d'équipement, événement de fin de vague, règles de récompenses, condition de fin, classement, difficulté et caps. Les événements gameplay portent un event_id unique pour éviter les doublons. La simulation utilise un clock de combat distinct du temps réel et du temps de menu.

Séparation de données : definitions (armes, reliques, équipement, effets, achievements, skill nodes), balance (formules, probabilités, difficultés), saves (progression), sandbox (presets, snapshots), telemetry (logs et mesures). Versions de schéma explicites et migrations. Ne jamais sérialiser de références Godot ou objets arbitraires provenant d'un JSON importé.

[À DÉFINIR] Contrat des événements, schémas JSON exhaustifs, arbre de scènes Godot, ordre exact des modificateurs, traitement des évolutions simultanées et stratégie de pooling.

<a id="17"></a>

## 17 — Modèle de données et conventions

Entités canoniques proposées :
WeaponDefinition {id, target_policy, level_effects[1..5], evolution_id, relic_requirement_id}; RelicDefinition {id, level_effects[1..5]}; EquipmentInstance {instance_id, slot, rarity, stat_lines[{stat_id,base_roll,enhancement_level,fail_streak}], unique_effect_id, source_mode}; SkillNode {id, cost, prerequisites, effects}; AchievementDefinition {id, category, secret, metric, aggregation, tiers[{id,threshold,rewards}]}; ModeDefinition {id, rule_flags, reward_policy, leaderboard_policy}; SandboxPreset {schema_version, base_mode, overrides, initial_build, seed}.

Conventions : les valeurs en points de pourcentage sont explicites (0,20 = +0,20 %, pas +20 %). IDs stables ASCII snake_case ; valeurs RNG reproductibles par seed et sous-flux ; timestamp et version de balance dans les résultats ; validation stricte des enums ; calcul des récompenses idempotent ; progression persistante indépendante de la simulation.

[PROPOSÉ] Ordre des modificateurs : bases + bonus plats, puis somme des bonus % de même catégorie, puis catégories multiplicatives explicites. Les effets spéciaux utilisent des cooldowns et budgets d'activation pour éviter les cascades infinies.

<a id="18"></a>

## 18 — Performances, stabilité et sécurité

[VALIDÉ] Cible 60 FPS sur GPU intégré ; simulation robuste à 200–500 ennemis en fin de Survival et valeurs Sandbox extrêmes avec protections. Pas de transfert de contenu Sandbox vers progression normale.

[PROPOSÉ] Pooling d'ennemis/projectiles/FX ; calculs de proximité spatialisés ; dégâts agrégés ; budgets de projectiles, chaînes, explosions et particules ; cadence de spawn adaptative ; télémétrie frametime CPU/GPU ; seuils de réduction VFX ; tests soak 30–120 minutes Endless.

Sécurité des fichiers : import JSON limité en taille, profondeur et nombre d'éléments ; validation de schéma ; pas de scripts arbitraires ; pas de chemins fournis par preset ; copies de sauvegardes immuables ; écriture atomique fichier temporaire puis remplacement ; sauvegarde de secours ; vérification des migrations ; checksums de partage pour intégrité accidentelle, non comme preuve cryptographique anti-triche.

Classements en ligne [PROPOSÉ] : résultats vérifiés côté serveur ou protocole de validation robuste ; un save local ne suffit pas pour empêcher la triche.

<a id="19"></a>

## 19 — Tests d’acceptation et QA

Combat : decay exact sur intervalle et pause, guérison par menace, soft cap lifesteal, invulnérabilité après contact, revives rares, arrêt de wave timer pendant boss, pas d'arrêt du decay.

Loot : deux types de chest, trois choix, évolution niveau 5 + relique possédée, slots max 5/6, absence de doublons en mode normal, garanties de directeur, RNG reproductible.

Equipment : 1 objet garanti par run classique même en cas de mort, slots et raretés, nombre exact de lignes, unicité des types de stats, choix effet unique, inventaire illimité, démontage et vente.

Enhancement : +0..+10 par ligne, +8 % par niveau, réussite/échec normal/critique, protection à 0, dixième tentative garantie, conversion Powder 10:1, absence de coût Essence.

Progression : prérequis du skill tree, respec gratuit, achievements persistants, tiers cumulables, secrets, pas de double attribution, migrations.

Armorless : départ sans équipement permanent ; skill tree/achievements actifs ; trois objets après chaque vague, un seul conservé ; trois slots identiques autorisés ; choix effet Legendary/Mythic ; Flux uniquement temporaire ; disparition des équipements/Flux à la fin ; classement vague/temps/kills ; boss et draft déclenchés une fois.

Sandbox : fonctionne sans save ; import en copie isolée ; original bit-à-bit inchangé ; live override et rollback ; éditeur d'objets hors limites normales ; JSON invalide refusé sans crash ; code de partage borné ; aucune Essence/Powder/achievement/leaderboard officiel ; hard caps respectés ; mesures DPS cohérentes.

Performance : tests sur iGPU, worst-case densité, 10+ armes, effets chaînés, run Endless longue, allocations stables, sauvegarde/reprise, UI manette.

<a id="20"></a>

## 20 — MVP, roadmap et questions ouvertes

[VALIDÉ] Premier playable : 3 armes et 3 reliques, une run complète de 24 vagues, core loop jouable. Contenu final visé : 10 paires d'armes/reliques, 120 nodes de skill tree, ~120 familles d'achievements, 5 difficultés et les quatre expériences.

[PROPOSÉ] Étape 1 — Vertical slice : mouvement, HP decay, soin par kill, 4 ennemis, 3 armes/reliques, chests, XP, vagues et boss, HUD, sauvegarde minimale.
Étape 2 — Métaprogression : équipement, enhancement, Powder, Essence, skill tree, difficultés.
Étape 3 — Contenu : 10 paires, boss, élites, Chaos, achievements, équilibrage.
Étape 4 — Endless et Armorless : règles, Flux, drafts, records.
Étape 5 — Sandbox Lab : override registry, éditeur live, métriques, presets, codes de partage.
Étape 6 — QA, optimisation, accessibilité, tuning et publication.

QUESTIONS OUVERTES PRIORITAIRES :
1. Accès et déblocage exacts du Endless standard ; récompenses et sortie.
2. Tables chiffrées complètes des 10 armes et 10 reliques.
3. Patterns des boss et élites ; composition des vagues.
4. Courbe d'XP et stats automatiques par niveau.
5. Graph complet des ~120 nodes et leurs coûts.
6. Catalogue exhaustif des ~120 achievements et tous leurs seuils.
7. Plages de rolls d'équipement et effets uniques complets.
8. Économie complète Powder/Flux, gains et coûts, avec simulation.
9. Récompenses permanentes exactes d'Armorless.
10. Maquettes UI et règles de sauvegarde/reprise en plein draft.

Cette version v1.5 est une consolidation fidèle des décisions connues ; elle ne présente pas les propositions de balancing comme des décisions validées.
