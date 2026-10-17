# Registre des courbes de progression

État relevé le 2026-10-17. Ce document rassemble les courbes numériques et règles de croissance qui influencent la progression en run, les récompenses permanentes et les modes sans fin. Les statuts désignent le niveau de décision, pas le degré d’implémentation : une courbe codée peut rester proposée.

## Légende

- **[VALIDÉ]** règle ou direction explicitement acceptée. Les valeurs exactes ne sont validées que si elles sont précisées comme telles.
- **[PROPOSÉ]** valeurs/formule de prototype, même si elles sont implémentées ou couvertes par un smoke.
- **[OUVERT]** courbe absente, arbitrage en attente ou calibration représentative nécessaire.
- **[PROPOSÉ — implémenté]** aide à repérer un prototype fonctionnel, sans en faire une décision définitive.

Les références au GDD et à la roadmap prévalent. Les tests synthétiques prouvent une propriété du code, pas l’équilibrage ni l’acceptation des chiffres.

## Progression pendant une run

| Courbe | Règle / valeurs actuelles | Statut et état | Sources |
|---|---|---|---|
| Pression du HP decay | Dégâts passifs `D(t)=1,5 + 0,004t` PV/s; perte cumulée sur un intervalle `[t,t+Δt] = 1,5Δt + 0,002((t+Δt)²−t²)`, où `t` est le temps actif. Le compteur ne progresse pas pendant les pauses. | Base et croissance **[PROPOSÉES]** dans le GDD; implémentées, mais leur équilibre reste **[OUVERT]** à confirmer en run représentative. | [GDD §3](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd) |
| Soin par élimination | `H(T)=2+3√T` PV; menace `T` bornée entre 0,5 et 25; ennemi ordinaire `T=1` donne 5 PV. | **[PROPOSÉE]**; valeur de soin réellement utilisée et balance par archétype/difficulté à vérifier. | [GDD §3](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd) |
| Vol de vie | Jusqu’à 10 PV/s, rendement nominal; au-delà, 25 % du rendement supplémentaire. Les dégâts sur la durée ne donnent que 25 % du vol de vie théorique. | **[PROPOSÉ]**; caps et rendement doivent être évalués en jeu. | [GDD §3](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd) |
| Durée et cadence des vagues Survival | 24 vagues, 30 secondes actives par vague; mid-boss après la vague 12, boss final après la 24. | **[VALIDÉ]** structure/cadence de référence; la composition et la difficulté réelle des vagues restent **[OUVERTES]** à calibrer. Implémenté. | [GDD §2, §4, §11](../gdd/GDD_v1.6.md), [`survival_wave_director.gd`](../../game/scripts/survival_wave_director.gd) |
| Besoin d’XP par niveau | Niveau 1 demande 10 XP; le seuil du prochain niveau augmente de 5 par niveau : après chaque montée, `XP_suivant = base + croissance × (niveau − 1)` (10, 15, 20, 25…). | **[PROPOSÉ — implémenté]** valeurs configurables; le GDD valide le gain d’XP et le bonus par niveau, mais ne valide pas cette courbe de seuil. | [`survival_session.gd`](../../game/scripts/survival_session.gd), propriétés `xp_base_to_next_level` et `xp_growth_per_level` |
| Bonus automatique de niveau XP | À chaque niveau gagné après le niveau 1, rotation de 12 stats; chaque stat en % gagne +1 point de pourcentage. `max_hp` multiplie PV max et PV actuels par 1,01 en conservant le ratio. Rotation répétée sans plafond; bonus réinitialisé à chaque run. | **[VALIDÉ]** règle et valeurs; implémenté et couvert par `survival_xp_run_bonuses_smoke.gd`. | [GDD §2](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd), [`ROADMAP.md`](ROADMAP.md) P5 |
| Niveaux des armes | 5 niveaux, améliorations fixes par niveau, puis une évolution qui conserve le niveau 5. Les valeurs de progression chiffrées de toutes les armes sont dans le tableau de l’annexe du [GDD §5](../gdd/GDD_v1.6.md) (par ex. plusieurs armes gagnent +20 % au niveau 2 et un bonus spécialisé aux niveaux 3–5). | Nombre de niveaux, caractère fixe et évolution **[VALIDÉS]**; les valeurs chiffrées par arme sont **[PROPOSÉES]**. Les effets actuellement exécutés peuvent différer du tableau historique; consulter les définitions/configurations de progression avant d’équilibrer. | [GDD §5 et annexe A](../gdd/GDD_v1.6.md), [`weapon_progression.json`](../../game/data/weapon_progression.json) |
| PV ennemis selon la vague | Vagues 1–24 : `min(1,12^(vague−1), 12) × difficulté`. En Endless standard après 24 : `12 × 1,055^(vague−24) × difficulté`. | Courbe de base **[PROPOSÉE — implémentée]** et à valider sur une run; le facteur 1,055 après la vague 24 est une option de prototype documentée, non définitive. | [`survival_session.gd`](../../game/scripts/survival_session.gd), [`DECISIONS_RESTANTES.md`](DECISIONS_RESTANTES.md) sujet Endless standard |
| Population de vague | Nombre cible avant facteurs : `arrondi(10 + 390 × ((vague−1)/23)^1,5)`; multiplicateurs de densité Easy–Chaos; cadence de spawn divisée par densité. | **[PROPOSÉ — implémenté]**; calibration de composition/densité **[OUVERTE]**. La politique de spawn ne doit pas plafonner le nombre de mobs déjà présents. | [`survival_session.gd`](../../game/scripts/survival_session.gd), [`survival_difficulty.gd`](../../game/scripts/survival_difficulty.gd) |
| Budget de menace des élites | `arrondi(10 + 390 × ((vague−1)/23)^1,5)`, environ 10 à 400 sur les vagues 1–24. Ce budget contrôle les élites; il ne limite pas les ennemis ordinaires vivants. | **[PROPOSÉ]**; seuils, fréquence et composition restent à mesurer. | [GDD §4](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd) |
| Stats globales des reliques | La progression statistique par niveau est linéaire. Valeurs du prototype par niveau : Storm Core +5 % dégâts; Infernal Heart +5 % cadence; Blood Chalice +5 % lifesteal et +10 % soin par élimination; Singularity +5 % réduction cooldown; Frozen Crown +5 % zone; Overdrive Engine +4 % cadence; Celestial Eye +3 % zone; Magnetic Coil +4 % vitesse projectile; Plague Mask +5 % dégâts; Prism Crystal +3 % dégâts critiques; Magnet Heart +25 % rayon XP. | Linéarité **[VALIDÉE]**; bonus Magnet Heart +25 % par niveau **[VALIDÉ]**; autres montants **[PROPOSÉS]** et à équilibrer. | [GDD §5](../gdd/GDD_v1.6.md), données de loadout et reliques |
| Magnet Heart | Rayon XP par niveau : +25 %, +50 %, +75 %, +100 %, +125 %. Au niveau 5, Magnetic Pulse toutes les 20 s, durée 1,5 s, rayon 300 % du rayon de base; accélération 600, vitesse max 240. Synergies niveau 5 actives pendant le pulse : Coil ×1,5 vitesse max, Singularity attire l’XP vers Void Orb/Event Horizon, Celestial Eye ×1,5 rayon. | Comportement et valeurs actuels **[VALIDÉS, 2026-10-17]**. Attraction des soins/ressources/monnaies/bonus futurs **[OUVERTE]**, faute de pickups définis; coffres toujours exclus. | [GDD §5, annexe Magnet Heart](../gdd/GDD_v1.6.md) |
| Récompenses des coffres | 3 choix; poids finaux : amélioration possédée ×1,25; relique assortie ×1,5; arme assortie ×1,25; évolution prête/proche ×1,125; poids combiné plafonné ×2. Transformation utilisateur : `1 + (x−1)/2` appliquée aux multiplicateurs initiaux et au plafond. Chaque candidat éligible garde un poids positif; tirage pondéré sans remise. | Trois choix/préférence et ces valeurs pondérées **[VALIDÉS]**; condition d’« évolution proche » reste **[PROPOSÉE]**. La récompense de substitution quand tout est au maximum et le nombre de rerolls restent **[OUVERTS]**. | [GDD §6](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd), [`survival_loadout.gd`](../../game/scripts/survival_loadout.gd) |
| Fréquence des coffres | Par famille et par mort : ennemi ordinaire 0,75 %; élite 30 %; boss garantissant chaque famille; filet 60 s/famille au prochain événement de mort. | 0,75 % ordinaire, 30 % élite, garantie boss et filet 60 s **[VALIDÉS, 2026-10-17]** et implémentés. Les métriques exploratoires ne calibrent pas encore les taux. | [GDD §6](../gdd/GDD_v1.6.md), [`DECISIONS_RESTANTES.md`](DECISIONS_RESTANTES.md), [`survival_chest_director.gd`](../../game/scripts/survival_chest_director.gd) |
| Thermal Shock | Coup direct Burn↔Chill : impact supplémentaire immédiat égal à 50 % des dégâts directs déclencheurs; cooldown local d’une seconde par cible; DoT et impact réaction exclus. | Règle et coefficients **[VALIDÉS, 2026-10-17]**; test de ressenti en run réel demeure utile mais ne bloque pas la décision. | [GDD §5](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd) |
| Overcharge | Un coup électrique direct qui réapplique Shock pendant la seconde active déclenche une décharge sans chaîne; prototype : 25 % du coup déclencheur, rayon 60 px, cible centrale comptée une fois, cooldown local 1 s. | Déclencheur/durée **[VALIDÉS, 2026-10-17]**; coefficients **[PROPOSÉS — implémentés]**. Le multiplicateur a été ramené de 50 % à 25 % après une comparaison exploratoire cluster 4 seeds (plus pilote approche); run représentative encore requise. | [GDD §5](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd), [QA P9.1](../qa/TESTS.md) |

## Courbes de combat et de drop par difficulté

Ces courbes modifient le rythme de danger et de récompenses. Leur existence ou leur ordre peut être décidé sans que leurs coefficients le soient.

| Courbe | Règle / valeurs actuelles | Statut et état | Sources |
|---|---|---|---|
| Dégâts ennemis et densité par difficulté | Facteurs Easy → Chaos : dégâts `0,70 / 1 / 1,30 / 1,70 / 2,30`; densité `0,80 / 1 / 1,20 / 1,50 / 1,80`. Les facteurs de densité modulent la cadence, sans plafond sur la population vivante. | Progression croissante **[VALIDÉE]**; coefficients **[PROPOSÉS — implémentés]**, à équilibrer. | [GDD §4](../gdd/GDD_v1.6.md), [`survival_difficulty.gd`](../../game/scripts/survival_difficulty.gd) |
| Fréquence des ennemis de soutien en Chaos | Multiplicateur prototype ×1,5 sur les chances individuelles de spawn des soutiens existants, avec plafonnement à 100 %. | Mutation Chaos **[VALIDÉE]**; facteur ×1,5 **[PROPOSÉ — implémenté]**. | [GDD §4](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd) |
| Drop de coffre par difficulté | Les multiplicateurs d’Essence/Powder influent aussi la progression permanente (table ci-dessous); aucune hausse de taux de coffre par difficulté n’est spécifiée. | **[OUVERT]** si un scaling spécifique du taux de coffre est souhaité; ne pas le déduire des multiplicateurs de ressources. | [GDD §4, §6](../gdd/GDD_v1.6.md), [`survival_chest_director.gd`](../../game/scripts/survival_chest_director.gd) |

### Progression chiffrée proposée des armes

Ces gains de niveau sont la grille de balancing du GDD; **[PROPOSÉ]**, pas des valeurs définitives. Le runtime/config peut contenir des valeurs ou effets plus récents : ce tableau sert de référence d’intention, et le code doit être comparé avant un changement d’équilibrage.

| Arme | Niv. 2 | Niv. 3 | Niv. 4 | Niv. 5 |
|---|---|---|---|---|
| Lightning Conductor | +20 % dégâts | +1 rebond | −15 % cooldown | +25 % dégâts |
| Inferno Sprayer | +20 % dégâts | +15 % portée | +20 % largeur | +25 % Burn |
| Crimson Daggers | +20 % dégâts | +1 dague | +20 % vitesse orbitale | +25 % dégâts |
| Void Orb | +20 % dégâts | +20 % rayon d’attraction | +15 % durée | +25 % force d’attraction |
| Frost Nova | +20 % dégâts | +20 % rayon | +20 % durée Chill | −20 % cooldown |
| Minigun | +20 % dégâts | +25 % cadence | +15 % précision | +25 % cadence |
| Meteor Staff | +20 % dégâts | +20 % rayon | −15 % délai d’impact | +30 % dégâts |
| Sawblades | +20 % dégâts | +1 rebond | +20 % vitesse | +25 % dégâts |
| Toxic Cloud | +20 % DoT | +20 % rayon | +20 % durée | +25 % DoT |
| Prism Laser | +20 % dégâts | +20 % portée | +15 % suivi | +25 % dégâts |

### Plages de roll proposées pour l’équipement

Roll uniforme sur la plage min–max; l’amélioration multiplie le roll par `(1 + 0,08 × niveau)`.

| Stat | Min–max proposé |
|---|---:|
| Dégâts | 1–5 % |
| Vitesse d’attaque | 1–4 % |
| Chance critique | 0,5–2 points de % |
| Dégâts critiques | 5–20 points de % |
| PV max | 2–8 PV |
| Vitesse de déplacement | 1–4 % |
| Soin par élimination | 1–3 points de % |
| Zone | 1–4 % |
| Réduction de cooldown | 0,5–2 points de % |
| Gain d’XP | 1–4 % |
| Rayon de collecte | 2–8 % |
| Vitesse projectile | 2–8 % |

Ces plages sont **[PROPOSÉES]** dans [`PROPOSITION_P5.md`](PROPOSITION_P5.md); les caps finaux des statistiques restent **[OUVERTS]**.

## Progression permanente

| Courbe | Règle / valeurs actuelles | Statut et état | Sources |
|---|---|---|---|
| Déblocage des difficultés | Easy initiale; victoire du boss final débloque la suivante dans l’ordre Easy → Normal → Hard → Nightmare → Chaos. | **[VALIDÉ]** règle de déblocage; multiplicateurs précis ci-dessous restent **[PROPOSÉS]**. | [GDD §4, §11](../gdd/GDD_v1.6.md), [`survival_difficulty.gd`](../../game/scripts/survival_difficulty.gd) |
| Multiplicateurs de difficulté | Easy: HP ennemis 0,75; dégâts 0,70; densité 0,80; Essence/Powder 0,70. Normal: 1/1/1/1. Hard: 1,50/1,30/1,20/1,60/1,50. Nightmare: 2,20/1,70/1,50/2,50/2,30. Chaos: 3,20/2,30/1,80/4,00/3,50. Ordre des colonnes : HP, dégâts, densité, Essence, Powder. | **[PROPOSÉ — implémenté]**; valeurs de départ GDD explicitement proposées, runs représentatives requises. | [GDD §4](../gdd/GDD_v1.6.md), [`survival_difficulty.gd`](../../game/scripts/survival_difficulty.gd) |
| Récompense d’une run Survival | `Essence = arrondi((15 + 2 × vague_max + 25 × boss_final_vaincu) × facteur_Essence)`; `Powder Basic = arrondi((20 + 3 × vague_max + 30 × boss_final_vaincu) × facteur_Powder)`. Équipement garanti par run classique, même après défaite. | **[PROPOSÉ — implémenté]**; la forme de la courbe et les facteurs ne sont pas confirmés par une calibration représentative. Équipement garanti **[VALIDÉ]**. | [GDD §7, §9](../gdd/GDD_v1.6.md), [`progression_service.gd`](../../game/scripts/progression_service.gd) |
| Rareté de l’équipement Survival | Poids Normal/Magic/Mystic/Legendary/Mythic (%) : Easy `60/30/9/0,9/0,1`; Normal `35/40/20/4,5/0,5`; Hard `15/30/40/13/2`; Nightmare `5/15/45/28/7`; Chaos `0/5/35/40/20`. +1 point déplacé de Normal vers les autres raretés proportionnellement à leurs poids par tranche de 6 vagues (jusqu’à vague 24). En cas de défaite avant vague 6, réduction progressive jusqu’à −50 % des raretés Mystic+ en vague 1; nulle à vague 6. | **[PROPOSÉ — implémenté]**; valeurs, bonus de vague et aide de défaite restent à calibrer. | [GDD §7](../gdd/GDD_v1.6.md), [`equipment_generator.gd`](../../game/scripts/equipment_generator.gd) |
| Lignes de stats et roll | Une ligne par équipement Normal, 2 Magic, 3 Mystic/Legendary, 4 Mythic; stats distinctes. Chaque stat est tirée uniformément dans la plage proposée du [GDD §7](../gdd/GDD_v1.6.md). Enhancement multiplie la valeur par `(1 + 0,08 × niveau)`, niveaux 0–10. | Nombre de lignes et formule d’amélioration **[VALIDÉS]**; plages précises **[PROPOSÉES]**. | [GDD §7–8](../gdd/GDD_v1.6.md), [`PROPOSITION_P5.md`](PROPOSITION_P5.md), [`equipment_generator.gd`](../../game/scripts/equipment_generator.gd) |
| Coût et chances Enhancement permanent | Coûts de base des niveaux +1 à +10 : `10, 15, 22, 32, 46, 65, 90, 125, 175, 250`, multipliés par rareté `1 / 1,5 / 2 / 3 / 4`. Succès Basic/Refined/Pure/Prismatic : `50/70/85/95 − 3 × niveau courant` %. Échec critique conditionnel : `10/5/2/0,5` %. Succès forcé à la 10e tentative consécutive. | Règles générales et garantie **[VALIDÉES]**; coûts et chances **[PROPOSÉS — implémentés]**; économie Powder/démantèlement et calibration **[OUVERTES]**. | [GDD §8](../gdd/GDD_v1.6.md), [`progression_service.gd`](../../game/scripts/progression_service.gd), [`DECISIONS_RESTANTES.md`](DECISIONS_RESTANTES.md) |
| Démantèlement et vente | Démantèlement proposé : Normal 1 Basic; Magic 3 Basic; Mystic 1 Refined; Legendary 3 Refined; Mythic 1 Pure. Vente proposée : Essence `5/10/20/40/80` selon la même progression de rareté. Conversion de Powder vers tier supérieur : 10:1. | Conversion **[VALIDÉE]**; rendements et vente **[PROPOSÉS]**; économie d’ensemble **[OUVERTE]**. | [GDD §8](../gdd/GDD_v1.6.md), [`PROPOSITION_P5.md`](PROPOSITION_P5.md), [`progression_service.gd`](../../game/scripts/progression_service.gd) |
| Coût des nœuds d’arbre | Prototype : coût Essence `40 + 10 × index` pour les lignes de stats générées; nœuds de déblocage ont également des coûts codés. Proposition de règle générale : `20 + 10 × profondeur + 80` pour un déblocage d’arme/relique. | **[PROPOSÉ — implémenté partiellement]**; graphe et coûts définitifs **[OUVERTS]**. Cible de puissance globale de l’arbre ~+30 % **[VALIDÉE comme cible]**, répartition à calibrer. | [GDD §9](../gdd/GDD_v1.6.md), [`PROPOSITION_P5.md`](PROPOSITION_P5.md), [`progression_service.gd`](../../game/scripts/progression_service.gd) |
| Bonus des achievements | Exemple validé comme exemple éditorial : Exterminator aux seuils 100/1 000/10 000/100 000 éliminations, bonus cumulés +0,05/+0,10/+0,15/+0,20 point de pourcentage dégâts (total +0,50 %). Prototype étendu ajoute d’autres seuils/bonus par arme et affixe. | Plage 100–150 familles **[VALIDÉE]**; seuils/bonus catalogue majoritairement **[PROPOSÉS]**. Cible globale de puissance +12 % **[PROPOSÉE]** dans le budget validé +10–15 %. | [GDD §10](../gdd/GDD_v1.6.md), [`PROPOSITION_P5.md`](PROPOSITION_P5.md), [`achievement_catalog.json`](../../game/data/achievement_catalog.json) |

## Progressions Endless

| Courbe | Règle / valeurs actuelles | Statut et état | Sources |
|---|---|---|---|
| Endless standard | Après la vague 24, HP ennemis +5,5 % par vague; mid-boss toutes les 12 vagues. | **[PROPOSÉ]** choix de prototype; valeurs à calibrer. Entrées, continuité de build et récompenses sont des comportements implémentés, mais ne rendent pas cette courbe définitive. | [`DECISIONS_RESTANTES.md`](DECISIONS_RESTANTES.md), [`survival_session.gd`](../../game/scripts/survival_session.gd), [`survival_wave_director.gd`](../../game/scripts/survival_wave_director.gd) |
| Armorless — gain de Flux | Après la vague `w`, `Flux = 5 + 2 × w` (7, 9, 11…); les objets restent temporaires et disparaissent à la fin de run. | Catégories de récompenses et temporaire **[VALIDÉS]**; quantité **[PROPOSÉE — implémentée]**. | [GDD §13](../gdd/GDD_v1.6.md), [`armorless_run_state.gd`](../../game/scripts/armorless_run_state.gd) |
| Armorless — rareté | Poids Normal/Magic/Mystic/Legendary/Mythic selon vague : vague 1 `55/35/9/1/0`; 6 `25/40/27/7/1`; 16 `5/20/45/25/5`; 31 `0/5/25/50/20`; 51 `0/0/10/55/35`. Entre paliers, le palier précédent est conservé. Modificateur de difficulté appliqué comme puissance de l’indice de rareté puis renormalisé : Easy 0,80; Normal 1; Hard 1,15; Nightmare 1,35; Chaos 1,60. | **[PROPOSÉ — implémenté]**; paramètres non validés, test de run longue requis. | [GDD §13](../gdd/GDD_v1.6.md), [`equipment_generator.gd`](../../game/scripts/equipment_generator.gd) |
| Armorless — choix de slot | Chaque choix de draft tire indépendamment et uniformément un des six slots; aucun filet de sécurité. Un slot donné apparaît au moins une fois parmi les trois options avec probabilité `1−(5/6)^3 ≈ 42,13 %`. | Règle **[VALIDÉE]** et implémentée; la sélection indépendante implique qu’un même slot peut être proposé plusieurs fois. | [GDD §13](../gdd/GDD_v1.6.md), [`equipment_generator.gd`](../../game/scripts/equipment_generator.gd) |
| Armorless — coût/amélioration d’équipement | Coût `ceil(5 × 1,5^niveau_courant × multiplicateur_rareté)`; multiplicateurs Normal/Magic/Mystic/Legendary/Mythic `1/1,25/1,5/2/2,5`. Chances de succès `max(0, 50 − 3 × niveau)` %; échec critique 10 % conditionnel à un échec; garantie après 10 échecs consécutifs. | **[PROPOSÉ — implémenté]**; taux et coût restent à mesurer. | [GDD §13](../gdd/GDD_v1.6.md), [`armorless_run_state.gd`](../../game/scripts/armorless_run_state.gd) |
| Armorless — PV ennemis | `HP0 × facteur_difficulté × 1,10^(w−1)` jusqu’à la vague 24; ensuite `HP0 × facteur_difficulté × 1,10^23 × 1,055^(w−24)`. | Courbe toujours **[PROPOSÉE]**, implémentée dans Armorless et vérifiée aux vagues 24, 25 et 60. Les coefficients de difficulté communs restent proposés. | [GDD §13](../gdd/GDD_v1.6.md), [`survival_session.gd`](../../game/scripts/survival_session.gd), [`armorless_wave_director_smoke.gd`](../../game/tests/armorless_wave_director_smoke.gd) |
| Armorless — récompenses permanentes de fin | Pas de bonus de boss final : `Essence = arrondi((15 + 2 × vague_atteinte) × facteur_Essence)`; `Basic Powder = arrondi((20 + 3 × vague_atteinte) × facteur_Powder)`. Achievements progressent; aucun équipement permanent n’est attribué. | Catégories sans équipement **[VALIDÉES]**; formule **[PROPOSÉE — implémentée via le calcul commun des runs]** et à calibrer. | [GDD §13](../gdd/GDD_v1.6.md), [`progression_service.gd`](../../game/scripts/progression_service.gd) |

## Courbes encore absentes ou à formaliser

- **[OUVERT] Courbe d’XP éditoriale :** les valeurs 10 + 5 par niveau sont des paramètres de prototype; le GDD n’a pas arrêté de progression d’XP jusqu’aux niveaux tardifs.
- **[OUVERT] Tables de scaling détaillées des ennemis et boss :** multiplicateurs de HP codés et population cible existent, mais composition, dégâts, densité et durées utiles par vague requièrent des runs représentatives. Les paramètres précis de Chaos restent à équilibrer.
- **[OUVERT] Récompense de substitution des coffres** quand tous les choix possibles sont au niveau maximum, ainsi que nombre exact de rerolls.
- **[OUVERT] Courbe économique globale :** rythme de gain/dépense Essence et Powder, nombre de runs par déblocage, coût de reroll, rendements et cibles d’équipement complet.
- **[OUVERT] Armorless :** quantité de récompenses permanentes selon vague/difficulté; validation de longues runs sans assistance.
- **[OUVERT] Équilibrage représentatif :** les surveys et smokes confirment l’exécution des calculs mais pas que les courbes produisent la difficulté, durée de progression ou fréquence de loot voulues.

## Références de conception

- [GDD v1.6](../gdd/GDD_v1.6.md) — source des règles et des statuts.
- [Roadmap](ROADMAP.md) — état d’implémentation et jalons P5–P7.
- [Décisions restantes](DECISIONS_RESTANTES.md) — sujets à arbitrer et validations non décisionnelles.
- [Propositions de progression P5/P6](PROPOSITION_P5.md) — détail des paramètres de prototype.
- [Effets uniques P6](EFFETS_UNIQUES_P6.md) — paramètres proposés des effets.
- [QA progression](../qa/data/) — mesures observées; elles ne changent pas les statuts de design.
