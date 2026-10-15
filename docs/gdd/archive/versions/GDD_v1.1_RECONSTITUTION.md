# Dopamine Survivor — GDD v1.1 (reconstitution historique)

> **RECONSTITUTION, PAS DOCUMENT ORIGINAL.** Cette version est reconstruite à partir des décisions chronologiques retrouvées dans les échanges et des sections du GDD v1.5 consolidé. Les formulations et paramètres détaillés des sections extraites peuvent avoir été affinés après la version concernée ; ils ne constituent pas une transcription mot pour mot de v1.1.

## Objet de cette version

Précisions sur HP decay, soins, scaling, loot, enhancement, économie, données et tests.

Ce document représente les **ajouts identifiés à la version 1.1**, à appliquer cumulativement aux versions antérieures. Il ne prétend pas restituer leur texte historique exact.


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


## 06 — Chests et progression pendant une run

[VALIDÉ] Deux familles de chests : armes et reliques, obtenues sur les ennemis. Trois choix par ouverture. Le tirage favorise les synergies et les améliorations des objets équipés. Un directeur dynamique de loot garantit une progression minimale sans imposer un build.

[PROPOSÉ] Probabilité de drop par ennemi ordinaire : 0,5 % pour chaque famille ; élite : 15 % par famille ; boss : un chest de chaque famille garanti. Filet de sécurité : au moins un chest éligible de chaque famille toutes les 60 secondes. Poids de proposition : ×1,5 upgrade équipé ; ×2 relique correspondant à une arme ; ×1,5 arme correspondant à une relique ; ×1,25 évolution proche ; multiplicateur combiné plafonné à ×3.

[À TESTER] Éviter les tirages impossibles lorsque les slots sont pleins ; définir les alternatives quand tout est niveau 5 ; ne pas compter plusieurs fois les drops garantis ; prévenir les biais extrêmes ; empêcher l'ouverture en double après chargement.

<a id="7"></a>


## 08 — Enhancement et Powder

[VALIDÉ] Chaque ligne de statistique s'améliore indépendamment de +0 à +10. Formule : valeur_effective = roll_de_base × (1 + 0,08 × niveau). Les probabilités de réussite baissent avec le niveau. Échec ordinaire : aucun changement ; échec critique : perte d'un niveau, minimum 0 ; dixième tentative consécutive sans succès : réussite garantie. Seule la Powder est consommée, sans Essence ni gold.

[VALIDÉ] Quatre tiers de Powder : Basic, Refined, Pure, Prismatic. Conversion ascendante 10:1. Le démantèlement d'équipement produit de la Powder. Reroll d'effet unique possible mais coûteux.

[PROPOSÉ] Succès selon poudre et niveau courant E : Basic 50−3E %, Refined 70−3E %, Pure 85−3E %, Prismatic 95−3E %. Échec critique conditionné à l'échec : 10/5/2/0,5 % respectivement ; le reste est un échec normal. Garantie sur la dixième tentative de la même ligne. Coût de base pour cibles +1 à +10 : 10,15,22,32,46,65,90,125,175,250 ; multiplicateurs de rareté 1 / 1,5 / 2 / 3 / 4.

[OUVERT] Poudres consommables selon niveau et rareté, prix exact du reroll, économie de démantèlement, prévention des exploits de conversion.

<a id="9"></a>


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
