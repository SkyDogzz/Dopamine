# DOPAMINE SURVIVOR — GDD COMPLET v1.6

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

DOPAMINE SURVIVOR — GAME DESIGN DOCUMENT v1.6
Statut : spécification consolidée de conception, 15 octobre 2026.

La version 1.6 intègre les décisions et propositions du delta v1.6. Les règles inchangées de v1.5 sont conservées. Les statuts [VALIDÉ], [PROPOSÉ] et [OUVERT] restent distincts. En cas de contradiction, les règles validées du delta prévalent, sous réserve des ADR acceptés et de l’architecture technique. Les sources historiques et leur fiabilité sont indexées dans [`archive/VERSIONS.md`](archive/VERSIONS.md).

Dopamine Survivor est un roguelite top-down à combat automatique inspiré du genre bullet heaven. Son identité repose sur une pression de survie permanente : les points de vie diminuent continuellement et les éliminations permettent de les restaurer. Le joueur optimise armes, reliques, évolutions, équipement, arbre de compétences et achievements afin de vaincre des vagues toujours plus dangereuses.

Direction : pixel art néon, ambiance électronique synthwave/EDM dont les couches s'intensifient avec les vagues ; nombres de dégâts agrégés ; lisibilité prioritaire malgré des centaines d'ennemis.

Plateforme initiale : Windows PC. Modèle économique : achat premium unique. Moteur : Godot 4.x. Cible : 60 FPS sur GPU intégré dans les configurations représentatives. Contrôles : clavier WASD, flèches directionnelles et manette. Arène infinie, caméra orthographique, ennemis générés autour du joueur.

Quatre expériences : Survival (24 vagues), Endless standard, Endless Armorless et Sandbox Lab. Sandbox est un laboratoire hors progression et accessible sans sauvegarde.

Légende de statut : [VALIDÉ] décision explicitement retenue ; [PROPOSÉ] paramètre de départ à équilibrer ; [OUVERT] décision restant à prendre. Les valeurs numériques proposées ne doivent pas être considérées comme figées.

Le registre transversal des formules de progression et de leur statut est maintenu dans [`docs/planning/COURBES_PROGRESSION.md`](../planning/COURBES_PROGRESSION.md). En cas de différence, les statuts et règles du présent GDD prévalent.

<a id="2"></a>

## 02 — Boucle de jeu et commandes

[VALIDÉ] Combat automatique ; le joueur dirige le déplacement et choisit ses objets lors de l'ouverture des chests. Les armes attaquent automatiquement suivant leurs propres règles de ciblage. Les chests d'armes et de reliques proviennent des ennemis. Chaque chest propose trois options, avec une préférence pour les améliorations équipées et les synergies. Les orbes d'XP font monter le niveau sans écran traditionnel de trois upgrades.

Boucle Survival : choisir difficulté et arme initiale → survivre à une vague de 30 secondes → tuer pour se soigner et gagner XP → ramasser chests → améliorer armes/reliques → vaincre le mid-boss vague 12 → vaincre le boss final vague 24 → récompenses permanentes → recommencer.

[VALIDÉ] La durée de base est de 24 × 30 secondes = 12 minutes de combat actif, plus les pauses de boss et les choix. Objectif d'une run : 10–15 minutes. Le timer de vague s’arrête durant les boss ; le HP decay continue pendant le gameplay et se suspend durant les vraies pauses, notamment les choix de coffre. **[VALIDÉ — EXTENSION DU 2026-10-17]** Une victoire débloque l’entrée Endless standard depuis le hub et autorise une proposition de continuation optionnelle après le boss final; en cas de continuation, HP, build et niveaux sont conservés. Le profil de départ depuis le hub est aussi **[VALIDÉ]**; les autres règles Endless restent **[PROPOSÉES]** ou **[OUVERTES]**, voir §12.

[VALIDÉ — EXTENSION DU 2026-10-16] Chaque montée de niveau d'XP accorde automatiquement un bonus, à partir du passage du niveau 1 au niveau 2. Une rotation fixe, commune aux runs, suit cet ordre puis recommence : dégâts %, vitesse d'attaque %, chance critique %, dégâts critiques %, PV maximum, vitesse de déplacement %, soin par élimination %, zone %, réduction de cooldown %, gain d'XP %, rayon de collecte XP % et vitesse projectile %. Chaque stat en pourcentage gagne 1 point de pourcentage à son tour ; le PV maximum est multiplié par 1,01 à son tour et les PV actuels sont ajustés pour conserver leur ratio. Ces bonus ne persistent pas entre les runs. Aucun choix ni retour ponctuel n'accompagne le gain ; les contributions sont consultables dans les statistiques de run.

**[VALIDÉ — DIRECTION ET RÈGLES OVERSTIMULATION, 2026-10-19]** La direction Survival doit être hyperactive et généreuse en variations et payoffs. Sont retenus comme capacités de design : combo d’éliminations à paliers; alternance de pression et de brèves accalmies; objectifs courts pendant une vague; événements surprises annoncés et chevauchement possible de modificateurs; esquive parfaite avec ralenti et contre-attaque; zone de risque/récompense; bonus rare mobile à intercepter; jauge de style alimentée par les actions; mutations temporaires de build; objets maudits; surchauffe d’arme; synergies spectaculaires arme/relique; compositions d’ennemis complémentaires; patterns de boss combinés; finishers sur ennemis affaiblis; explosion de boss en chaîne; mode optionnel « encore plus intense ». Les règles et valeurs de départ de ces 18 capacités sont **[VALIDÉES par l’utilisateur, 2026-10-19]** dans [la spec Overstimulation](../specs/SPEC-overstimulation-gameplay.md); une modification ultérieure issue de la calibration devra être documentée comme une nouvelle décision. Les autres idées non sélectionnées restent dans la [carte Overstimulation](../specs/CAPABILITY_MAP_OVERSTIMULATION.md) au statut **[PROPOSÉ]**.

**État d’intégration Overstimulation :** les tranches 1 à 5 sont intégrées à Survival et Endless standard. Les vagues gardent 30 secondes; les vagues 1–4 utilisent 5/20/5 secondes, les vagues 5–12 5/22/3 secondes et les vagues 13+ 5/23/2 secondes. La montée fait évoluer la cadence de 50 % à 100 %, l’accalmie la réduit à 50 %; les ennemis et attaques persistants restent actifs. Le HUD indique la phase et son compte à rebours, avec signaux visuels et sonores. La tranche 2 (compositions d’ennemis complémentaires) est aussi intégrée : la composition alterne de façon déterministe parmi les archétypes débloqués, s’affiche au HUD et favorise les rôles complémentaires; leur part **[PROPOSÉE]** est de 30 % multipliée par la densité de difficulté, bornée entre 20 % et 55 %. Le motif Pursuit augmente de 50 % la chance de base d’apparition d’un élite, sous le budget et plafond existants **[PROPOSÉ]**. La tranche 3 ajoute un objectif tiré au sort sur les vagues paires non-boss, pendant 15 secondes : quota d’éliminations, cible marquée ou zone mobile à tenir 8 secondes cumulées dans un rayon de 72 px. La réussite donne 15 % de progression XP et +10 % de vitesse d’attaque pendant 6 secondes. La formule de quota (`3 + ⌊vague/6⌋`, plafonnée à 8) est **[PROPOSÉE]**. Les valeurs de départ restent **[OUVERTES à calibration]**. Les cinq tranches sont actives en Survival/Endless standard seulement; Armorless et Sandbox sont exclus. Les 13 capacités restantes restent à implémenter.

La tranche 4 ajoute une alerte générique cinq secondes avant un événement, puis une anomalie durant 15 secondes. Les événements sont planifiés toutes les trois vagues non-boss; ceux dus aux vagues 12/24 attendent la fin du boss. Feral Surge multiplie la cadence de spawn par 1,5 et la vitesse ennemie par 1,15; Overclock donne +20 % de vitesse d’attaque et +15 % de vitesse ennemie; Magnetic Storm double le rayon de collecte XP et attire les orbes vers le joueur; Prism Break provoque une explosion de rayon **96 px [PROPOSÉ]** à chaque huitième élimination, pour les dégâts de base de l’arme principale. Survivre jusqu’au terme donne 15 % de progression XP. Le tirage est uniforme et interdit de répéter l’anomalie précédente dans la même run. Le multiplicateur de vitesse s’applique également aux ennemis déjà présents et fait partie du checkpoint natif format 18.

La tranche 5 ajoute une seconde anomalie dans 20 % des événements. Le tirage reste limité à deux effets, exclut les anomalies de l’événement précédent et vérifie une table de compatibilité des six paires disponibles; Feral Surge + Overclock conserve une seule hausse ennemie de 15 %. Les deux noms et effets sont affichés ensemble. Ces tranches sont implémentées et couvertes par des tests ciblés; l’intégration GDExtension complète reste à vérifier dans un environnement avec les dépendances natives installées. Équilibrage et rayon d’explosion restent **[OUVERTS à calibration]**; la valeur de rayon est **[PROPOSÉE]**.

[VALIDÉ — EXTENSION DU 2026-10-17, réponse A] Conserver pendant les mesures les caps actuels : chance critique limitée à 100 % et réduction de cooldown limitée à 90 % (durée minimale 10 %). Leur équilibre final reste **[OUVERT]** et doit être mesuré avec les profils P6.9.

<a id="3"></a>

## 03 — Combat, HP decay et guérison

[VALIDÉ] Mouvement précis et instantané, sans inertie significative ; pas de dash de base, certains équipements peuvent en accorder un. HP initial = 100. Perte passive de HP initiale = 1,5 HP/s, croissante linéairement avec le temps de combat actif. Les kills soignent selon le niveau de menace des ennemis. Lifesteal sur dégâts avec soft cap. Le délai entre deux dégâts de contact corps à corps est suivi séparément pour chaque ennemi ; il ne bloque pas les projectiles ni les autres attaques. Revives rares.

[VALIDÉ — EXTENSION DU 2026-10-17, réponses C, B, B, B, A puis B] L’effet unique `revive_once` accorde un revive, au maximum une fois par run en Survival et Endless standard. Au coup fatal, un dialogue demande si le joueur veut consommer ce revive; s’il confirme, le joueur revient avec 50 % de ses PV maximum et 3 secondes d’invulnérabilité. `revive_knockback` reste lisible pour les sauvegardes existantes, sans comportement de revive.

[VALIDÉ] Le revive ne s’applique pas à Endless Armorless, qui ne comporte pas d’équipement, ni au Sandbox Lab, dont les simulations restent isolées de la progression normale.

[PROPOSÉ] Le HP decay s’applique pendant tout le gameplay, y compris hors combat et pendant les boss, mais est suspendu par une vraie pause, dont la sélection d’un chest. D(t) = 1,5 + 0,004 t HP/s (t en secondes actives). Perte exacte sur [t,t+Δt] = 1,5 Δt + 0,002((t+Δt)^2 - t²). Après 60 secondes sans soin : 97,2 HP perdus. Après 720 secondes : 2 116,8 HP perdus. Le timer ne progresse pas pendant les menus en pause, mais progresse pendant les combats de boss.

[PROPOSÉ] Soin par kill H(T)=2+3√T, menace T bornée dans [0,5 ; 25] ; ennemi ordinaire T=1 → +5 HP. Menace calculée depuis archétype et multiplicateurs HP/dégâts/vitesse. Lifesteal : rendement normal jusqu'à 10 HP/s puis efficacité de 25 % au-delà ; dégâts sur la durée donnent 25 % de leur lifesteal théorique. Délai de contact corps à corps par ennemi : 0,35 s.

[À TESTER] Taux de kills nécessaire pour compenser le decay, situations sans ennemis, builds à faible DPS, boucles de guérison infinie, survie à 1 HP et comportement pendant les transitions.

<a id="4"></a>

## 04 — Ennemis, vagues et difficultés

[VALIDÉ] Le jeu comporte 8 à 12 familles au lancement : mêlée, rapides, tanks, distance, soutien et explosifs, interactions de groupe, élites à affixes et projectiles télégraphiés esquivables.

[VALIDÉ] Cinq difficultés progressives : Easy, Normal, Hard, Nightmare, Chaos. Chaque difficulté se débloque en battant la précédente. Les statistiques et la densité des ennemis augmentent avec la difficulté ; Chaos ajoute des comportements particuliers. Élites aléatoires pilotées par un budget de menace et cooldown. Mid-boss à la vague 12, boss final à la vague 24. Pas de limite de temps pour battre un boss.

[VALIDÉ — 2026-10-16] En Chaos, après deux attaques normales télégraphiées, chaque boss enchaîne une attaque supplémentaire télégraphiée choisie parmi ses patterns existants. Easy à Nightmare gardent leur cadence actuelle; dégâts, vitesse et plafond global d'invocations ne sont pas modifiés par cette règle.

[VALIDÉ — 2026-10-17] Trois mutations Chaos supplémentaires sont retenues : les ennemis de soutien existants apparaissent plus souvent dans les vagues; les élites portent deux affixes existants distincts; chaque attaque télégraphiée d’un boss Chaos utilise un pattern différent de son attaque précédente. La cadence d’un follow-up après deux attaques normales et les limites validées de dégâts, vitesse et invocations restent en vigueur. Les affixes s’appliquent ensemble; lorsqu’ils modifient une même statistique, les multiplicateurs se composent, et Hasted conserve sa vitesse propre. La fréquence initiale des ennemis de soutien est multipliée par 1,5 **[PROPOSÉ]**; les valeurs d’équilibrage des combinaisons d’affixes et le ressenti restent à mesurer.

[VALIDÉ] Pendant une vague, les ennemis ordinaires continuent d’apparaître à la cadence de spawn sans plafond sur leur nombre vivant. Une élimination trop lente peut ainsi accumuler les ennemis et submerger le joueur. La densité de difficulté agit sur cette cadence ; ses multiplicateurs numériques restent **[PROPOSÉS]**.

[PROPOSÉ] Archétypes initiaux : Chaser (20 HP, 75 px/s), Sprinter (12 HP, 125 px/s), Tank (80 HP, 45 px/s), Shooter (25 HP, 65 px/s). Multiplicateur HP de vague en Survival : min(1,12^(vague−1), 12). Budget de menace élite : round(10+390*((vague−1)/23)^1,5), de ~10 à ~400; il ne limite pas le nombre d’ennemis ordinaires vivants.

[PROPOSÉ] Multiplicateurs par difficulté (HP / dégâts / densité / Essence / Powder) : Easy 0,75 / 0,70 / 0,80 / 0,70 / 0,70 ; Normal 1 / 1 / 1 / 1 / 1 ; Hard 1,5 / 1,3 / 1,2 / 1,6 / 1,5 ; Nightmare 2,2 / 1,7 / 1,5 / 2,5 / 2,3 ; Chaos 3,2 / 2,3 / 1,8 / 4 / 3,5.

[VALIDÉ — EXTENSION DU 2026-10-17, réponse A] Garder les rosters et patterns prototypes comme base, compléter les lacunes requises par le GDD, puis calibrer les compositions de vagues, seuils d’élites et budget de simulation sur des runs représentatives. Aucun chiffre sans mesure ne devient définitif. Les détails non spécifiés des patterns et les paramètres/ressentis restent **[PROPOSÉS]** ou **[OUVERTS]** jusqu’à leur vérification QA. Les mutations Chaos validées gardent leurs règles; leurs coefficients et leur ressenti restent à équilibrer en runs représentatives.

<a id="5"></a>

## 05 — Armes, reliques et évolutions

[VALIDÉ] Les interactions entre armes peuvent émerger des dégâts et statuts. Aucune limite artificielle aux synergies n’est ajoutée pour le seul équilibrage, sous réserve des protections techniques.

[PROPOSÉ] Réactions élémentaires entre statuts ; Shatter, Electroplague et Gravity Collapse sont validées comme indiqué en annexe. Les autres combinaisons restent proposées ou ouvertes.

**Electroplague [VALIDÉE, 2026-10-17] :** un coup direct de Shock sur une cible empoisonnée propage son Poison à toutes les autres cibles ennemies vivantes dans un rayon de 60 px, sans plafond de cibles. La propagation copie les dégâts par tick, l’intervalle et la durée restante du Poison; elle n’inflige aucun dégât direct. Une cible déjà empoisonnée conserve son effet existant. Les ticks de DoT et les effets propagés ne déclenchent pas de propagation en chaîne sans nouveau coup direct de Shock.

**Gravity Collapse [VALIDÉE, 2026-10-17] :** un coup direct d’Impact sur un ennemi vivant dans le champ gravitationnel actif de Void Orb/Event Horizon déclenche immédiatement une explosion centrée sur cet ennemi. L’explosion inflige 50 % des dégâts déclencheurs aux ennemis vivants à portée de 60 px, cible centrale comprise une seule fois; aucun coup direct supplémentaire n’est ajouté et la réaction ne chaîne pas. L’éligibilité du prototype à tous les impacts directs hors Void Orb/Event Horizon et projectiles de réaction reste **[PROPOSÉE]**, à calibrer en run.

**Thermal Shock [VALIDÉ, 2026-10-17] :** un coup direct de Burn sur une cible déjà Chill, ou de Chill sur une cible qui porte Burn, ajoute immédiatement un impact égal à 50 % des dégâts directs déclencheurs. Un cooldown local d’une seconde par cible borne la répétition. Les dégâts sur la durée et les impacts de Thermal Shock ne déclenchent pas la réaction. Ces valeurs sont celles du prototype validé; leur ressenti en run reste à observer.

[VALIDÉ] Dix armes distinctes, chacune à ciblage automatique intelligent propre, dont l’efficacité dépend fortement du positionnement et du déplacement. Le choix de départ se fait parmi deux armes débloquées. Aucun doublon d’arme en run normale (doublons autorisés dans le Sandbox). Chaque arme et relique a cinq niveaux ; les niveaux d’arme ont des améliorations fixes, principalement statistiques, et une évolution majeure conserve le niveau 5. Chaque relique accorde aussi un bonus à une statistique globale en run normale. Le combo associé ne renforce que son arme : il devient disponible comme choix d’évolution lorsque l’arme et la relique atteignent toutes deux le niveau 5, puis ne s’active qu’après collecte de ce choix. La relique n’est pas consommée. Une seule évolution par arme ; une arme niveau 5 non évoluée ne peut plus apparaître comme amélioration ordinaire de chest. Chaque niveau d’arme reçoit un retour visuel, même pour une hausse uniquement statistique. Les bonus de relique progressent linéairement.

Paires de contenu validées :
1. Lightning Conductor + Storm Core → Infinite Circuit : éclairs ramifiés et Shock.
2. Inferno Sprayer + Infernal Heart → Wildfire : brûlures qui explosent et se propagent.
3. Crimson Daggers + Blood Chalice → Bloodstorm : tempête orbitale de dagues, Bleed et lifesteal.
4. Void Orb + Singularity → Event Horizon : trous noirs et attraction.
5. Frost Nova + Frozen Crown → Absolute Zero : gel et fragmentation.
6. Minigun + Overdrive Engine → Redline : cadence accélérante.
7. Meteor Staff + Celestial Eye → Starfall : météores fragmentés.
8. Sawblades + Magnetic Coil → Razorstorm : ricochets.
9. Toxic Cloud + Plague Mask → Pandemic : poison contagieux.
10. Prism Laser + Prism Crystal → Spectrum Collapse : faisceaux secondaires.

[PROPOSÉ] Valeurs actuellement utilisées par le prototype pour les bonus globaux par niveau : Storm Core +5 % dégâts, Infernal Heart +5 % cadence, Blood Chalice +5 % lifesteal et +10 % de soin par élimination, Singularity +5 % réduction de cooldown, Frozen Crown +5 % zone, Overdrive Engine +4 % cadence, Celestial Eye +3 % zone, Magnetic Coil +4 % vitesse de projectile, Plague Mask +5 % dégâts, Prism Crystal +3 % dégâts critiques et Magnet Heart +25 % rayon de ramassage XP. Ces valeurs restent à équilibrer. Le lifesteal reste soumis au soft cap décrit en section 03.
[VALIDÉ — décision utilisateur B, 2026-10-17] Le lifesteal sur les dégâts s’applique avec un taux global de base, même sans Blood Chalice; les niveaux de Blood Chalice ajoutent leur bonus de stat globale.
[PROPOSÉ] Taux global de base du lifesteal : 5 %, configurable dans Survival. Les dégâts directs utilisent le taux complet; les dégâts sur la durée utilisent 25 % du taux théorique. Le soft cap proposé de 10 HP/s puis 25 % d’efficacité au-delà s’applique au soin total. La valeur du taux de base et la calibration du soin restent à mesurer.

[PROPOSÉ] Les valeurs chiffrées de progression des dix armes (niveaux 2–5) figurent dans l’annexe v1.6 ci-dessous et restent des hypothèses de balancing. Les nombres précis des reliques et le calibrage des armes restent à confirmer.

[PROPOSÉ] Réglages initiaux du prototype Crimson Daggers/Bloodstorm : rayon orbital de 30 unités et vitesse angulaire de 5 rad/s ; durée de base 0,8 s, portée à 2,4 s pour Bloodstorm. Ils rendent le comportement testable et restent à équilibrer ; seule l’orbitation des dagues est [VALIDÉE].

[VALIDÉ] Chaque arme a le comportement distinct décrit dans le tableau récapitulatif de l’annexe A.

[VALIDÉ] Les armes/reliques débloquées deviennent disponibles pour les tirages et ne sont pas automatiquement équipées dans chaque run. Le total cible est de 10 armes et 11 reliques (10 reliques associées et Magnet Heart), avec cinq slots normaux de relique ; les exceptions de capacité Legendary/Mythic de la règle v1.5 restent applicables si leurs effets sont retenus.

<a id="6"></a>

## 06 — Chests et progression pendant une run

[VALIDÉ] Chests d’armes et de reliques obtenus sur les ennemis, trois choix par ouverture, préférence pour les améliorations et synergies, et protection anti-malchance. Les slots pleins limitent les propositions aux améliorations encore disponibles. Les rerolls sont limités et obtenus via la progression. Le gameplay est en pause pendant le choix. Toute acquisition/amélioration peut rendre un choix d’évolution disponible ; le combo ne s’active qu’à sa collecte.

[VALIDÉ — 2026-10-18] En Survival et Endless standard, si une famille de coffre n’a plus aucune acquisition, amélioration ou évolution disponible, ses coffres continuent de tomber et proposent une cache d’Essence à la place. L’Essence est ajoutée à la récompense de fin de run. La valeur de 5 Essence par coffre est **[PROPOSÉE]**. Sandbox et Armorless n’accordent pas cette ressource permanente.

[VALIDÉ — EXTENSION DU 2026-10-17] Probabilité de drop par ennemi ordinaire : 0,75 % par famille, tirée indépendamment pour les chests d’armes et de reliques. Poids d’offre : formule `poids_final = 1 + (poids_proposé − 1) / 2`, appliquée à chaque multiplicateur et au plafond combiné. Les poids résultants sont ×1,25 pour une amélioration possédée, ×1,5 pour une relique liée à une arme possédée, ×1,25 pour une arme liée à une relique possédée, ×1,125 pour une évolution prête/proche, plafond combiné ×2. Le tirage reste sans remise parmi les options éligibles et garde à chacune un poids positif.

[VALIDÉ — 2026-10-17] Élite : 30 % par famille, tirées indépendamment. Chaque boss garantit un chest de chaque famille éligible. Filet anti-poisse : au moins un chest éligible de chaque famille toutes les 60 secondes de temps actif, attribué au prochain événement de mort ennemi après le seuil. Ces règles s’appliquent seulement aux familles encore éligibles.

[À TESTER] Ne pas compter plusieurs fois les drops garantis ; prévenir les biais extrêmes ; empêcher l'ouverture en double après chargement.

<a id="7"></a>

## 07 — Équipement permanent

[VALIDÉ] Les effets d’équipement ont un impact significatif sans trivialiser les runs ; les effets Legendary/Mythic peuvent transformer les mécaniques. Les stats couvrent offense, défense et utilitaire, et les synergies peuvent dépendre d’une arme ou d’un statut. Le changement d’équipement se fait hors run.

[VALIDÉ] Six slots : helmet, armor, gloves, boots, amulet, ring. Une seule pièce d'équipement garantie par run classique, y compris en cas de mort. Slot tiré aléatoirement. Inventaire permanent illimité ; équiper, vendre ou démanteler. Pas de bonus de set. Pas de type de statistique répété sur un même objet.

Raretés : Normal (1 ligne aléatoire), Magic (2), Mystic (3), Legendary (3 aléatoires + 1 effet unique choisi librement), Mythic (4 aléatoires + 1 effet unique choisi librement). Les rolls de statistiques sont continus dans des plages dépendantes de la rareté. Rareté dépend de la difficulté, de la vague atteinte et de la RNG.

[PROPOSÉ] Prototype de vente : vendre un équipement crédite uniquement de l'Essence, sans Powder ni remboursement des enhancements : Normal 5, Magic 10, Mystic 20, Legendary 40, Mythic 80. Le panneau demande confirmation avant la suppression définitive. Ces montants servent de départ et restent à calibrer avec l'économie de progression.

Douze statistiques candidates : dégâts %, vitesse d'attaque %, chance critique %, dégâts critiques %, HP max, vitesse déplacement %, soin par kill %, zone %, réduction de cooldown %, XP %, rayon de collecte %, vitesse projectile %.

[PROPOSÉ] Chances de rareté Normal/Magic/Mystic/Legendary/Mythic : Easy 60/30/9/0,9/0,1 ; Normal 35/40/20/4,5/0,5 ; Hard 15/30/40/13/2 ; Nightmare 5/15/45/28/7 ; Chaos 0/5/35/40/20 (%). Le prototype déplace aussi 1 point de pourcentage depuis Normal vers les raretés non-Normal proportionnellement à leurs poids initiaux par tranche de six vagues atteintes (plafond de la vague 24), sans dépasser la probabilité Normal disponible. **Prototype de mort précoce [PROPOSÉ] :** une défaite avant la vague 6 réduit les poids Mystic/Legendary/Mythic jusqu'à 50 % en vague 1, avec une atténuation linéaire jusqu'à zéro en vague 6; les poids sont ensuite renormalisés à 100 %. Les victoires ne subissent aucune pénalité. Les deux règles restent à calibrer avec les plages de rolls et des parcours représentatifs.

[VALIDÉ] Effets uniques peuvent augmenter la capacité d'armes ou reliques à six ; un même effet unique actif ne se cumule pas automatiquement plusieurs fois. [PROPOSÉ] En cas de perte du slot bonus, l'objet supplémentaire devient inactif plutôt que détruit.

[PROPOSÉ] Le prototype `expanded_loadout` ajoute un slot d'arme et un slot de relique (plafond de six chacun) lorsqu'une pièce porteuse de l'effet est équipée. Plusieurs pièces avec cet effet ne cumulent pas le bonus. La répartition du bonus entre les deux familles et son calibrage restent à valider.

<a id="8"></a>

## 08 — Enhancement et Powder

[VALIDÉ] Chaque ligne de statistique s'améliore indépendamment de +0 à +10. Formule : valeur_effective = roll_de_base × (1 + 0,08 × niveau). Les probabilités de réussite baissent avec le niveau. Échec ordinaire : aucun changement ; échec critique : perte d'un niveau, minimum 0 ; dixième tentative consécutive sans succès : réussite garantie. Seule la Powder est consommée, sans Essence ni gold.

[VALIDÉ] Quatre tiers de Powder : Basic, Refined, Pure, Prismatic. Conversion ascendante 10:1. Le démantèlement d'équipement produit de la Powder. Reroll d'effet unique possible mais coûteux.

[PROPOSÉ] Succès selon poudre et niveau courant E : Basic 50−3E %, Refined 70−3E %, Pure 85−3E %, Prismatic 95−3E %. Échec critique conditionné à l'échec : 10/5/2/0,5 % respectivement ; le reste est un échec normal. Garantie sur la dixième tentative de la même ligne. Coût de base pour cibles +1 à +10 : 10,15,22,32,46,65,90,125,175,250 ; multiplicateurs de rareté 1 / 1,5 / 2 / 3 / 4.

[VALIDÉ — EXTENSION DU 2026-10-17, réponse A] Conserver les tables proposées de coûts, chances et rendements de poudre comme base de calibration par essais; aucun chiffre n’est ainsi validé. Les paramètres et l’économie de démantèlement restent **[PROPOSÉS]** jusqu’à des mesures représentatives.

[VALIDÉ — EXTENSION DU 2026-10-17, réponse A] Un reroll d’effet unique coûte 1 Powder Pure pour un équipement Legendary et 1 Powder Prismatic pour un équipement Mythic.

**[VALIDÉ — EXTENSION DU 2026-10-17, réponse A]** Après paiement, le joueur choisit un effet différent parmi les effets uniques sélectionnables. L’effet actuel n’est pas proposé.

[VALIDÉ — EXTENSION DU 2026-10-17, réponse A] La conversion Powder conserve le ratio 10:1 uniquement vers le tier supérieur; aucune conversion inverse ni restitution de Powder n’est permise. Aucune limite supplémentaire ni traçage de provenance n’est ajouté.

[VALIDÉ — EXTENSION DU 2026-10-17] Pour P6.4, conserver les tableaux de coûts, probabilités et rendements proposés comme base de calibration par essais. Cette décision ne valide aucun chiffre : ces paramètres restent **[PROPOSÉS]** jusqu’à ce que des mesures de jeu représentatives justifient leur promotion ou leur ajustement. Le prix du reroll d’effet unique et les règles de conversion sont fixés par les décisions utilisateur du 2026-10-17; coûts/chances d’Enhancement et économie de démantèlement restent à calibrer.

<a id="9"></a>

## 09 — Progression permanente et économie

[VALIDÉ] Arbre de compétences interconnecté de 100–150 nodes. Branches de déblocage d'armes/reliques et bonus avancés avec prérequis. Respec complet gratuit. Tous les nodes peuvent finir par être acquis. **[VALIDÉ — EXTENSION DU 2026-10-17, réponse A]** Le lancement conserve le périmètre actuel de 100 nœuds et calibre son budget; l’extension vers la cible éditoriale proposée d’environ 120 est différée. **[VALIDÉ — EXTENSION DU 2026-10-17, réponse A]** Garder les budgets de puissance du prototype comme **[PROPOSÉS]**, mesurer les profils débutant/intermédiaire/complet et n’ajuster l’allocation que si les résultats établissent un écart. Budget cible du prototype : ~+30 % de puissance de combat équivalente. Environ un déblocage utile toutes les 2–3 runs. Essence plus abondante en difficulté élevée. Coûts et bonus détaillés restent **[PROPOSÉS]**.

[PROPOSÉ] Répartition 120 nodes : 30 stats centrales ; 8 déblocages armes ; 8 déblocages reliques ; 20 maîtrises armes ; 20 maîtrises reliques ; 14 utilitaires ; 20 passerelles. Graphe précis et coûts à définir.

[PROPOSÉ] Récompenses Survival : Essence = arrondi((15 + 2×vague_max + 25×boss_final_vaincu) × multiplicateur_difficulté). Powder = arrondi((20 + 3×vague_max + 30×boss_final_vaincu) × multiplicateur_difficulté). Victoire Normal vague 24 : 88 Essence, 122 Powder Basic.

[VALIDÉ] Endgame : optimiser les équipements Mythic, terminer toutes les difficultés, développer les achievements et battre ses records Endless.

<a id="10"></a>

## 10 — Achievement Mastery (officiel v1.2)

[VALIDÉ] 100–150 familles d'achievements. Quatre paliers Bronze, Silver, Gold, Diamond. Bonus permanents cumulables, statistiques et effets spéciaux. Défis secrets récompensés. Progression conservée entre toutes les runs. Indépendance totale vis-à-vis du respec du skill tree. **[VALIDÉ — EXTENSION DU 2026-10-17, réponse A]** Le lancement conserve les 100 familles actuelles et calibre conditions/récompenses; l’extension vers la cible éditoriale proposée de 120 est différée. Budget de puissance totale : +10–15 % équivalent global ; cible proposée +12 %. Les métriques, seuils et récompenses restent **[PROPOSÉS]**.

**[VALIDÉ — EXTENSION UTILISATEUR, 2026-10-18]** Le hub expose un onglet Succès. Chaque palier obtenu confère un petit bonus permanent de statistique et correspond à un achievement Steam. Le catalogue courant prépare un identifiant API Steam stable par palier; le pont Steamworks et l’App ID restent à intégrer/configurer. Les familles et paliers du catalogue (conditions, statistiques récompensées et montants) restent **[PROPOSÉS]** tant qu’ils ne sont pas calibrés.

[PROPOSÉ] Répartition des 120 familles : Combat 25 ; Survival 15 ; Weapons 20 ; Relics & Evolutions 15 ; Equipment 15 ; Difficulty & Bosses 15 ; Progression 10 ; Secrets 5. Jusqu'à 480 récompenses de palier.

[PROPOSÉ — prototype étendu] Le catalogue actuel contient 100 familles, au plancher de la plage [VALIDÉE] de 100–150; la cible éditoriale de 120 ci-dessus reste [PROPOSÉE]. L’extension ajoute dix records de niveau maximal d’arme (niveaux 2–5; +0,0025 point de pourcentage de dégâts par palier), six suivis d’éliminations par affixe élite (1/5/15/50; +0,0025 point de pourcentage de dégâts par palier) et une maîtrise de variété des affixes (1/3/5/6 types; +0,0025 point de pourcentage de dégâts par palier). Ces seuils et bonus sont des hypothèses de départ, pas un arbitrage du budget de puissance.

Exemple Exterminator : 100 / 1 000 / 10 000 / 100 000 kills cumulés ; bonus par palier +0,5 / +1 / +1,5 / +2 points de pourcentage de dégâts ; total +5 % au Diamond, après multiplication par dix des bonus du catalogue le 2026-10-18 [VALIDÉ — EXTENSION UTILISATEUR]. Autres exemples : coups critiques, élites tuées, dégâts par arme, guérison cumulée, boss vaincus, équipement démantelé, enhancements réussis, runs Chaos, évolutions déclenchées.

Effets uniques proposés : Lightning supplémentaire occasionnel ; bouclier temporaire issu du soin excédentaire ; onde de choc à la première évolution ; vitesse temporaire après élimination d’élite ; reroll gratuit du premier chest. Le revive `revive_once` suit le contrat **[VALIDÉ]** du §3; l’ancien `revive_knockback` ne produit aucun effet. Les autres comportements de prototype détaillés dans `docs/planning/PROPOSITION_P5.md` ne deviennent pas des décisions du GDD sans validation. Aucun achievement ne désactive le HP decay ni ne procure de revive infini.

Données : AchievementDefinition {id, category, secret, metric, aggregation, tiers[threshold,rewards]}; métriques de vie cumulées (sum), records (max), et état des tiers. Les récompenses sont reconstruites à partir des tiers acquis au chargement ; jamais dupliquées dans le save. Events idempotents ; secrets suivis avant révélation.

[À TESTER] Les bonus spécialisés et utilitaires ne s'additionnent pas naïvement au budget de puissance ; mesurer des builds de référence complets.

<a id="11"></a>

## 11 — Mode Survival

[VALIDÉ] Mode principal : 24 vagues de 30 secondes, mid-boss 12, boss final 24 ; fin victorieuse ou mort. Équipement permanent actif, bonus de skill tree et achievements actifs. Armes et reliques reconstruits à chaque run via chests. Une pièce d'équipement permanente garantie par run, y compris défaite. Difficulté choisie parmi celles débloquées.

[VALIDÉ — EXTENSION DU 2026-10-17] Une victoire Survival débloque Endless standard dans le hub et permet de proposer une continuation immédiate après le boss final.

<a id="12"></a>

## 12 — Endless standard (conception provisoire)

[VALIDÉ — EXTENSION DU 2026-10-17, réponse A] Depuis le hub, progression permanente et équipement actifs; armes/reliques de run commencent au niveau 1. **[VALIDÉ — EXTENSION DU 2026-10-17]** En continuation, conserver les HP, le build et les niveaux de la run Survival; créditer sa victoire avant de démarrer un nouvel ID de run Endless. Difficultés Easy à Chaos. Les deux parcours n’ont donc pas le même état initial.

[PROPOSÉ] Cycles après vague 24 : ennemis plus puissants, élites et mutations, boss récurrents. Le prototype réutilise le scaling actuel jusqu'à la vague 24 puis augmente les PV ennemis de 5,5 % par vague; il déclenche un mid-boss toutes les 12 vagues, dont 24, 36, etc. Records locaux séparés par difficulté, classés par vague, temps puis kills. **[VALIDÉ — EXTENSION DU 2026-10-17, réponse A]** Reporter la maîtrise répétable après la livraison; elle n’est pas requise au lancement.

[PROPOSÉ] Le mode se termine à la mort ou à l’abandon. Récompenses basées sur la formule Survival sans bonus du boss final et sans équipement permanent garanti; les montants restent à calibrer.

[VALIDÉ] Accès depuis le hub après une victoire Survival et proposition de continuation optionnelle après le boss final. La continuation conserve les HP, le build et les niveaux; crédit de la victoire avant le nouvel ID Endless.

Prototype d’accès depuis le hub, de cadence et de fin **[PROPOSÉ, 2026-10-17]** retenu pour l’implémentation : progression permanente et équipement actifs, armes/reliques niveau 1, défaite ou abandon, records par difficulté et récompenses sans bonus de boss final ni équipement garanti. Réutiliser Easy–Chaos, augmenter les PV ennemis de 5,5 % par vague après la vague 24 et déclencher un mid-boss toutes les 12 vagues, y compris aux vagues 24, 36, 48, etc. Ces règles restent **[PROPOSÉES]**, sauf le profil hub désormais **[VALIDÉ]** ci-dessus.

[VALIDÉ — EXTENSION DU 2026-10-17, réponse A] La maîtrise répétable est reportée après la livraison et n’est pas requise au lancement. Valeurs finales de scaling, récompenses et équilibrage restent **[OUVERTES]** ou **[PROPOSÉES]**. Le profil depuis le hub, l’accès/déblocage et l’état conservé en continuation sont **[VALIDÉS]**; cadence, fin et records restent **[PROPOSÉS]**.

<a id="13"></a>

## 13 — Endless Armorless (officiel v1.3)

[VALIDÉ] Mode Endless autonome : aucun équipement permanent actif. Skill tree et Achievement Mastery restent actifs. Les armes et reliques sont reconstruits normalement pendant la run. Après CHAQUE vague terminée : un Equipment Draft de trois propositions, dont une seule est choisie. Slots entièrement aléatoires et indépendants : chaque proposition a 1/6 de chances pour chacun des six slots ; aucun filet de sécurité pour slots vides. Probabilité qu'un slot précis apparaisse dans un draft : 1−(5/6)^3 ≈ 42,13 %.

[VALIDÉ] Les objets sélectionnés sont temporaires et disparaissent à la fin de la run. Amélioration possible grâce au Flux, ressource temporaire spécifique à Armorless. Legendary/Mythic : libre choix de l'effet unique parmi les effets éligibles. Difficultés Easy à Chaos. Classement : vague la plus haute, puis temps de survie le plus long, puis nombre de kills ; classements séparés par difficulté.

[PROPOSÉ] Raretés selon vague, en % Normal/Magic/Mystic/Legendary/Mythic : vagues 1–5 : 55/35/9/1/0 ; 6–15 : 25/40/27/7/1 ; 16–30 : 5/20/45/25/5 ; 31–50 : 0/5/25/50/20 ; 51+ : 0/0/10/55/35. Multiplicateur de poids selon difficulté : Easy 0,80 ; Normal 1 ; Hard 1,15 ; Nightmare 1,35 ; Chaos 1,60, appliqué sous forme poids_r × multiplicateur^indice_r, puis normalisé.

[PROPOSÉ] Flux gagné à la fin de la vague w : 5+2w ; coût d'amélioration au niveau E : ceil(5×1,5^E×multiplicateur_rareté), multiplicateurs 1 / 1,25 / 1,5 / 2 / 2,5. Bonus de ligne +8 % par niveau ; max +10 ; échecs et pity analogues à l'enhancement normal. Flux jamais convertible en Powder.

[PROPOSÉ] HP ennemis Armorless : HP0 × multiplicateur_difficulté × (1,10^(w−1) si w≤24, sinon 1,10^23 × 1,055^(w−24)). HP decay identique au système de base, sans reset. Boss toutes les 12 vagues ; timers suspendus pendant boss, decay maintenu. Densité bornée par budget de performance.

[VALIDÉ — extension du 2026-10-16] À la fin d'une run Armorless, accorder de l'Essence, de la Basic Powder et le progrès des achievements ; ne pas accorder d'équipement permanent. Les records locaux restent séparés par difficulté.

[PROPOSÉ] Réutiliser la formule de récompenses Survival sans bonus de boss final : Essence = arrondi((15 + 2 × vague atteinte) × multiplicateur de difficulté), Basic Powder = arrondi((20 + 3 × vague atteinte) × multiplicateur de difficulté). Comme Armorless est sans fin, la formule continue après la vague 24 ; montants et multiplicateurs restent à calibrer.

[VALIDÉ — EXTENSION DU 2026-10-17] Pour P7A.5, conserver les formules de scaling, rareté et récompenses Armorless **[PROPOSÉES]** comme base de mesure en runs longues. Cette décision n’en valide aucun coefficient ni montant : les règles restent **[PROPOSÉES]** jusqu’à la calibration sur une session complète représentative, sans assistance.

[À TESTER] Draft à trois slots identiques, objets multiples d'un slot, gestion de l'inventaire temporaire, remplacement d'un équipement qui fournit un slot d'arme, destruction de Flux à la mort, sauvegarde/reprise et anti-double-attribution.

<a id="14"></a>

## 14 — Sandbox Lab (officiel v1.4)

[VALIDÉ] Sandbox Lab est accessible depuis le menu principal avant toute création/lecture de sauvegarde. Ce n'est pas un mode de progression. Presque tous les paramètres peuvent être modifiés, y compris des valeurs extrêmes. Édition en direct pendant la run. Build initial totalement libre : armes, reliques, équipement, statistiques et niveaux. Presets indépendants, export/import JSON et code de partage. Import d'une sauvegarde normale autorisé uniquement en copie isolée modifiable. Outils obligatoires : spawn, kill all, DPS meter, god mode, contrôle de vitesse, logs. Valeurs dangereuses : avertissement et limite technique de sécurité.

[VALIDÉ] Aucun gain d'Essence/Powder permanent, aucun achievement officiel, aucun score classé. Aucune modification de sauvegarde normale. Copie dans un contexte mémoire séparé ; import à sens unique Normal → Sandbox, jamais l'inverse.

Familles d'overrides : Player (HP, decay, dégâts, mobilité, crit, soins, revives) ; Weapons/Relics (capacité, niveaux, duplications, évolutions, cooldowns, projectiles) ; Loot (drops, chests, choix, poids, garanties) ; XP ; Enemies/Waves (stats, densité, spawn, bosses, scaling, durée) ; Equipment (stats, rareté, effets, enhancements) ; Progression simulée (skill tree, achievements) ; Simulation (seed, vitesse, invincibilité, métriques).

Architecture : BaseBalanceConfig → SandboxOverrideLayer → RuntimeConfigResolver → systèmes de jeu existants. Les changements sont typés LIVE (immédiat), REBUILD (reconstruire le composant), RESTART (redémarrer la simulation). Les modifications multiples s'appliquent transactionnellement ; rollback si erreur. Tous les systèmes lisent la configuration effective plutôt que des constantes codées en dur.

[PROPOSÉ] Presets : schema_version, preset_id, name, description, base_mode, seed, overrides, flags, initial_build. Codes : préfixe DSLAB1:, JSON canonique compressé, Base64URL, somme de contrôle ; validation de taille et décompression bornée ; jamais de script, commande, chemin système ou données privées. Sauvegardes locales distinctes : user://saves/ et user://sandbox/{presets,snapshots,logs}.

[PROPOSÉ] DPS : fenêtre 1 s, 10 s et run ; dégâts par arme/évolution/effet, critiques, coups, cibles, overkill. Logs événements et RNG. Commandes : spawn, kill all avec ou sans loot, reset cooldowns, restore HP, freeze AI, clear projectiles, jump wave, give item.

[PROPOSÉ — prototype actuel] Le panneau Sandbox Lab affiche les fenêtres DPS 1 s, 10 s et run par type de source arme/évolution/effet. Les échantillons récents couvrent au plus 10 s et sont bornés à 4 096 entrées. Le seed du preset initialise un RNG local aux tirages de `survival_session.gd`; chaque tirage journalise son motif, son temps et sa valeur dans un tampon de 256 entrées, dont les six dernières sont visibles. Ces données sont volatiles, ne sont pas exportées, et ne couvrent pas les générateurs de loot désactivés du Lab.

[PROPOSÉ] Seuils indicatifs normal / avertissement / hard cap : armes 5–6 / 15+ / 64 ; reliques 5–6 / 20+ / 128 ; ennemis 200–500 / 750+ / 2 000 ; projectiles variable / 5 000+ / 20 000 ; vitesse ×1 / ×4+ / ×16 ; XP ×1 / ×100+ / ×10 000. Hard caps à profiler, pas des garanties de performance.

<a id="15"></a>

## 15 — Interface et expérience utilisateur

[VALIDÉ] Les retours de dégâts sont agrégés et les critiques mis en évidence. Les impacts combinent flash, particules et audio avec hitstop sélectif ; les dangers et télégraphes ennemis restent prioritaires visuellement. Des options réduisent les VFX ; la musique EDM/synthwave s’adapte aux vagues et boss.

[PROPOSÉ — prototype P9.3] L’option `Réduire les effets visuels`, désactivée par défaut, masque les trails de projectiles, impacts décoratifs, pixels de mort, arcs Lightning et flashs de propagation Pandemic. Elle conserve les projectiles, champs persistants, statuts, auras et télégraphes de danger. Ce découpage doit encore être vérifié en jeu et confirmé; il n’altère ni les règles de combat ni le flux RNG.

[VALIDÉ] Direction pixel art néon ; HUD lisible à très forte densité ; support manette. Menus : écran d'accueil avec Play et Sandbox Lab accessibles indépendamment ; choix de sauvegarde seulement pour Play ; choix de mode et difficulté ; préparation de run ; HUD ; chests ; écran de mort/victoire ; inventaire ; enhancement ; skill tree ; achievements ; records ; Sandbox configuration et panneau live.

**[VALIDÉ — EXTENSION DU 2026-10-17, réponse A]** Conserver la direction artistique de l’ART_BIBLE et reporter les arbitrages fins non bloquants à la QA P9. Les couleurs, la police, le clignotement et l’identité canonique des placeholders restent à vérifier ou arbitrer avant la validation visuelle finale.

[PROPOSÉ] HUD : HP et decay actuel, vague/timer, difficulté, XP/niveau, armes/reliques, évolutions, boss HP, dégâts agrégés. Armorless : comparer trois équipements à chaque vague, stats positives/négatives et comparaison avec l'objet équipé, choix d'effet unique sur Legendary/Mythic, solde de Flux, enhancements accessibles pendant pause. Sandbox : onglets de paramètres, éditeur de build, contrôles de simulation, panneau DPS/logs, recherche de paramètres, export/import.

[À DÉFINIR] Wireframes de chaque écran, navigation manette, accessibilité, réglages VFX et affichage du nombre d'ennemis, détails audio.

[VALIDÉ — EXTENSION DU 2026-10-16] Pendant une run, un hub compact à gauche affiche les statistiques courantes de la run. Tab ouvre un panneau détaillé en lecture seule qui présente les totaux et leur contribution par source : progression acquise pendant la run (dont bonus automatiques d'XP), équipement, achievements et skill tree. L'ouverture de ce panneau ne met pas la run en pause. Aucun retour visuel ponctuel n'accompagne le gain de niveau XP.

[PARTIELLEMENT DÉFINI] Le panneau Tab empile le libellé de chaque statistique au-dessus de son icône et de sa valeur totale. Les contributions de sources sont affichées en paires icône + valeur, sans libellés textuels; des info-bulles donnent le nom de la statistique et des sources. Le détail reste aligné à gauche. La sélection exacte des statistiques du hub compact et la navigation de fermeture restent à définir. Le hub reflète les valeurs effectives en run; le panneau Tab explique leurs contributions sans interrompre le gameplay.

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

Combat : decay exact sur intervalle et pause, guérison par menace, soft cap lifesteal, cooldown de collision corps à corps par ennemi, revives rares, arrêt de wave timer pendant boss, pas d'arrêt du decay.

Loot : deux types de chest, trois choix, évolution disponible après niveau 5 de l'arme et de la relique associée puis activée à la collecte, slots max 5/6, absence de doublons en mode normal, garanties de directeur, RNG reproductible.

Equipment : 1 objet garanti par run classique même en cas de mort, slots et raretés, nombre exact de lignes, unicité des types de stats, choix effet unique, inventaire illimité, démontage et vente.

Enhancement : +0..+10 par ligne, +8 % par niveau, réussite/échec normal/critique, protection à 0, dixième tentative garantie, conversion Powder 10:1, absence de coût Essence.

Progression : prérequis du skill tree, respec gratuit, achievements persistants, tiers cumulables, secrets, pas de double attribution, migrations.

Armorless : départ sans équipement permanent ; skill tree/achievements actifs ; trois objets après chaque vague, un seul conservé ; trois slots identiques autorisés ; choix effet Legendary/Mythic ; Flux uniquement temporaire ; disparition des équipements/Flux à la fin ; classement vague/temps/kills ; boss et draft déclenchés une fois.

Sandbox : fonctionne sans save ; import en copie isolée ; original bit-à-bit inchangé ; live override et rollback ; éditeur d'objets hors limites normales ; JSON invalide refusé sans crash ; code de partage borné ; aucune Essence/Powder/achievement/leaderboard officiel ; hard caps respectés ; mesures DPS cohérentes.

Performance : tests sur iGPU, worst-case densité, 10+ armes, effets chaînés, run Endless longue, allocations stables, sauvegarde/reprise, UI manette.

<a id="20"></a>

## 20 — MVP, roadmap et questions ouvertes

La roadmap de livraison de référence est P0–P9 dans `docs/planning/ROADMAP.md`. Elle respecte le Sandbox dès P1 et décrit les critères de sortie, l’état réel, les dépendances et les points ouverts.

[VALIDÉ] Premier playable : trois armes et trois reliques, une run complète de 24 vagues, core loop jouable. Contenu final visé : dix paires d'armes/reliques, 120 nodes de skill tree, environ 120 familles d'achievements, cinq difficultés et les quatre expériences.

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

La base éditoriale v1.5 est conservée dans ce document avec les règles non modifiées ; les changements v1.6 intégrés et leur annexe prévalent en cas de contradiction. Les propositions de balancing restent explicitement non validées.


---

# Annexe — Détails du delta v1.6 intégrés

Les tableaux ci-dessous précisent les comportements et hypothèses numériques du delta. Les contenus explicitement proposés restent [PROPOSÉ].

## A. Armes

### Règles validées

- 10 armes, chacune avec un gameplay distinct.
- Ciblage automatique intelligent et spécifique à chaque arme.
- Le positionnement et les déplacements du joueur influencent fortement leur efficacité.
- Choix de l'arme de départ parmi 2 armes débloquées.
- Aucun doublon d'arme, sauf dans le Sandbox.
- 5 niveaux par arme, avec améliorations fixes, principalement statistiques.
- Évolution majeure, visuellement spectaculaire, conservant le niveau 5.
- Chaque relique donne un bonus de statistique globale en run normale.
- Le combo d'évolution renforce uniquement l'arme associée et ne s'active qu'après le niveau 5 des deux objets et la collecte de l'offre d'évolution.
- Une seule évolution par arme.
- Une arme niveau 5 non évoluée n'apparaît plus comme amélioration ordinaire dans les coffres.
- Évolution visuelle de l'arme à chaque niveau, même lorsque l'amélioration est purement statistique.

### Comportements des armes

| Arme                | Comportement validé                            | Évolution existante |
| ------------------- | ---------------------------------------------- | ------------------- |
| Lightning Conductor | Chaînes électriques entre ennemis              | Infinite Circuit    |
| Inferno Sprayer     | Jet de feu directionnel automatique            | Wildfire            |
| Crimson Daggers     | Dagues en orbite autour du joueur, non lancées | Bloodstorm          |
| Void Orb            | Orbe lente traversante attirant les ennemis | Event Horizon       |
| Frost Nova          | Onde de gel autour du joueur                | Absolute Zero       |
| Minigun             | Tir automatique très rapide sur une cible   | Redline             |
| Meteor Staff        | Météores ciblant des groupes d'ennemis      | Starfall            |
| Sawblades           | Lames rebondissant entre ennemis            | Razorstorm          |
| Toxic Cloud         | Nuages persistants empoisonnant les ennemis | Pandemic            |
| Prism Laser         | Rayon continu suivant la cible prioritaire     | Spectrum Collapse   |

### Progression numérique proposée (non validée)

| Arme      | Niveau 2    | Niveau 3                | Niveau 4              | Niveau 5                |
| --------- | ----------- | ----------------------- | --------------------- | ----------------------- |
| Lightning | +20% dégâts | +1 rebond               | -15% cooldown         | +25% dégâts             |
| Inferno   | +20% dégâts | +15% portée             | +20% largeur          | +25% Burn               |
| Daggers   | +20% dégâts | +1 dague                | +20% vitesse orbitale | +25% dégâts             |
| Void      | +20% dégâts | +20% rayon d'attraction | +15% durée            | +25% force d'attraction |
| Frost     | +20% dégâts | +20% rayon              | +20% durée de Chill   | -20% cooldown           |
| Minigun   | +20% dégâts | +25% cadence            | +15% précision        | +25% cadence            |
| Meteor    | +20% dégâts | +20% rayon              | -15% délai d'impact   | +30% dégâts             |
| Sawblades | +20% dégâts | +1 rebond               | +20% vitesse          | +25% dégâts             |
| Toxic     | +20% DOT    | +20% rayon              | +20% durée            | +25% DOT                |
| Prism     | +20% dégâts | +20% portée             | +15% suivi            | +25% dégâts             |

Ces valeurs sont des hypothèses de balancing, pas des valeurs définitives.

## B. Reliques

### Règles validées

- Les reliques offrent des bonus passifs et une mécanique spéciale à haut niveau.
- Leurs bonus s'appliquent globalement lorsque cela est pertinent.
- Chaque relique doit être utile indépendamment de son arme associée.
- Progression statistique linéaire du niveau 1 au niveau 5.
- Certaines combinaisons de reliques déclenchent des interactions particulières.

### Effets proposés pour les 10 reliques existantes

| Relique          | Bonus niv. 5 proposé    | Mécanique spéciale proposée                |
| ---------------- | ----------------------- | ------------------------------------------ |
| Storm Core       | +20% chance Shock       | Décharge à proximité                       |
| Infernal Heart   | +25% Burn               | Explosion des cibles brûlées               |
| Blood Chalice    | +5% lifesteal           | Soins excédentaires convertis en bouclier  |
| Singularity      | +25% contrôle           | Dégâts bonus sur ennemis regroupés         |
| Frozen Crown     | +25% Chill              | Vulnérabilité des cibles gelées            |
| Overdrive Engine | +20% cadence            | Accélération après attaques consécutives   |
| Celestial Eye    | +15% zone               | Chance de double impact                    |
| Magnetic Coil    | +20% vitesse projectile | Homing léger                               |
| Plague Mask      | +25% DOT                | Transmission de statut à la mort           |
| Prism Crystal    | +15% dégâts critiques   | Projectile secondaire sur critique        |

Ces effets et chiffres restent à valider.

Le prototype applique le « Homing léger » de Magnetic Coil au projectile Sawblades/Razorstorm seulement lorsque la relique atteint le niveau 5. Le projectile corrige sa trajectoire à 1 radian/s vers une cible vivante non encore touchée, située dans un rayon de ciblage visible (valeur initiale `SURVIVAL_TARGETING.SAWBLADES_RANGE`, limitée par le plafond de portée à l’écran). La vitesse est conservée. Ces paramètres sont **[PROPOSÉS]**, configurables et à calibrer; l’effet n’est pas déclaré équilibré.

### Nouvelle relique : Magnet Heart

**Statut : ajout validé au GDD v1.6.**

- Type : utilitaire.
- Aucune arme associée.
- Aucune évolution d'arme associée.
- Occupe un slot de relique normal.
- Augmente la distance de ramassage des orbes d'XP **[VALIDÉ — 2026-10-17]**.
- Attire les orbes d’XP. **[VALIDÉ — EXTENSION DU 2026-10-17, réponse A]** Décider séparément l’interaction de Magnet Heart lors de la définition de chaque nouveau pickup (soin, ressource, monnaie ou bonus temporaire). Aucun de ces effets n’est présumé avant ce contrat.
- **N'attire jamais les coffres.**
- Les coffres restent au sol et exigent proximité ou interaction du joueur.
- Cette exclusion s'applique aussi aux effets de ramassage provenant des équipements, du skill tree et des autres reliques.

Les soins, ressources, monnaies et bonus temporaires n’ont pas de contrat de pickup; ils ne sont pas inclus ni créés par déduction de Magnet Heart. Toute nouvelle famille reste **[OUVERTE]** quant à son effet, sa valeur et son apparition; décider aussi de son interaction avec Magnet Heart dans son propre contrat avant implémentation.

Progression **[VALIDÉE — 2026-10-17]** :

| Niveau | Bonus de rayon |
| ------ | -------------- |
| 1      | +25%           |
| 2      | +50%           |
| 3      | +75%           |
| 4      | +100%          |
| 5      | +125%          |

**Effet niv. 5 [VALIDÉ — 2026-10-17] — Magnetic Pulse :** toutes les 20 secondes, attire progressivement les orbes d’XP pendant 1,5 seconde dans un rayon de 300 % du rayon de base, sans les téléporter ni attirer les coffres. L’accélération est de 600 et la vitesse maximale de 240; la collecte reste limitée au rayon XP normal. Le pulse et son déplacement se figent en pause.

Synergies **[VALIDÉES par l’utilisateur, 2026-10-17 — réponse « les 3 »]** :

- Magnet Heart + Magnetic Coil : vitesse d’attraction accrue.
- Magnet Heart + Singularity : attraction de l’XP par gravité.
- Magnet Heart + Celestial Eye : rayon des impulsions augmenté.

**Règles des synergies [VALIDÉES — 2026-10-17] :** les deux reliques concernées doivent être au niveau 5 et l’effet s’active pendant Magnetic Pulse. Magnetic Coil multiplie la vitesse maximale d’attraction par 1,5; Singularity attire les orbes XP vers le champ actif de Void Orb/Event Horizon; Celestial Eye multiplie le rayon du pulse par 1,5. Ces valeurs et conditions correspondent au prototype implémenté.

**Nouveau total : 10 armes, 11 reliques, toujours 5 slots de reliques.**

## C. Évolutions et synergies

### Décisions validées

- Évolutions automatiques, une par arme.
- Interactions émergentes entre armes via dégâts et statuts.
- Pas de limitation artificielle des synergies pour des raisons d'équilibrage ; seules les protections techniques nécessaires sont autorisées.

### Réactions élémentaires

Les statuts de décision sont indiqués par réaction dans le tableau ci-dessous. Shock est appliqué une seconde sur toute cible touchée directement par une source électrique **[VALIDÉ, 2026-10-17]**.

### Évolutions proposées

- Infinite Circuit : ramifications électriques supplémentaires et Shock.
- Wildfire : Burn contagieux et explosion à la mort.
- Bloodstorm : tempête orbitale de dagues, Bleed et lifesteal.
- Event Horizon : trou noir persistant et effondrement.
- Absolute Zero : bris des ennemis gelés et dégâts de zone.
- Redline : cadence croissante en tir continu.
- Starfall : fragments de météores.
- Razorstorm : ricochets et pénétration.
- Pandemic : Poison contagieux et nouveaux nuages.
- Spectrum Collapse : faisceaux secondaires.

### Réactions élémentaires

| Réaction         | Combinaison           | Résultat                              |
| ---------------- | --------------------- | ------------------------------------- |
| Thermal Shock    | Burn + Chill          | Impact direct supplémentaire à 50 %, cooldown local d’une seconde **[VALIDÉ, 2026-10-17]** |
| Toxic Ignition   | Poison + Burn         | Explosion chimique **[VALIDÉ]**        |
| Shatter          | Freeze + Impact/Shred | Dégâts bonus et fragments **[VALIDÉ]** |
| Electroplague    | Poison + Shock        | Propagation de Poison **[VALIDÉ]**     |
| Gravity Collapse | Gravity + Impact      | Dégâts de zone **[VALIDÉ]**            |
| Hemorrhage       | Bleed + Crit          | Un coup critique direct sur une cible qui saigne provoque immédiatement un tick supplémentaire de Bleed, sans changer sa durée et sans chaîne **[VALIDÉ, 2026-10-17]** |
| Overcharge       | Shock + Shock         | Une attaque directe appliquant Shock à une cible déjà affectée par Shock déclenche une décharge de zone, sans chaîne **[VALIDÉ, 2026-10-17]** |

Les combinaisons marquées **[PROPOSÉ]** n’ont pas encore été validées.

**Décision utilisateur [VALIDÉE, 2026-10-17] — Overcharge :** Shock est le statut requis. Une attaque directe qui applique Shock à une cible déjà affectée par Shock déclenche une décharge de zone, sans chaîne. Shock est appliqué pendant une seconde après tout coup direct électrique **[VALIDÉ, 2026-10-17]**. Les paramètres du prototype — dégâts égaux à 25 % du coup déclencheur, rayon de 60 px, cible affectée incluse une fois, cooldown local d’une seconde — restent **[PROPOSÉS]** et configurables. Le multiplicateur de dégâts a été recalibré à 25 % après un survey exploratoire multiseed (P9.1); ce résultat ne valide pas la valeur.

**Décisions utilisateur [VALIDÉES, 2026-10-16 et 2026-10-17] — Toxic Ignition et coexistence des DoT :** déclencher une explosion immédiate quand un coup direct applique Burn à une cible déjà empoisonnée ou Poison à une cible déjà brûlée. Tous les types distincts de DoT peuvent coexister sur une même cible et tickent selon leurs horloges indépendantes; réappliquer un type remplace uniquement ce type, sans effacer ni rafraîchir les autres. L’explosion inflige 50 % des dégâts du coup direct déclencheur, dans un rayon de 60 px. Les deux statuts restent actifs après l’explosion. Une cible ne peut déclencher cette réaction qu’une fois par seconde. L’explosion n’applique pas de statut, donc ses dégâts ne déclenchent pas récursivement Toxic Ignition.

**Décision utilisateur [VALIDÉE, 2026-10-17] — Shatter :** un coup direct de Crimson Daggers, Minigun, Sawblades, Meteor Staff ou Void Orb sur une cible encore gelée déclenche des dégâts bonus sur cette cible et des fragments vers les ennemis proches. Les évolutions de ces armes gardent la même éligibilité. Les ticks de statut et les sources feu, foudre, poison et glace ne déclenchent pas Shatter; les fragments terminent la chaîne de réaction et ne peuvent pas la relancer. Le prototype ajoute 25 % des dégâts du coup déclencheur sur la cible gelée puis choisit jusqu’à trois cibles vivantes distinctes les plus proches dans un rayon de 96 px et lance un fragment vers chacune. Multiplicateur de dégâts (25 % du coup déclencheur par fragment), nombre (3), rayon (96 px), vitesse (700 px/s), durée de vie (0,75 s) et rayon de collision (3 px) restent **[PROPOSÉS]**, configurables et à calibrer.

Synergies proposées entre reliques :

- Storm Core + Frozen Crown.
- Infernal Heart + Plague Mask.
- Blood Chalice + Overdrive Engine.
- Singularity + Celestial Eye.
- Magnetic Coil + Prism Crystal.

## D. Coffres et progression pendant une run

### Décisions validées

- Coffres proposant 3 choix : armes, reliques ou améliorations selon le type de coffre.
- Drops aléatoires avec protection anti-malchance.
- Lorsque les slots sont pleins, seules les améliorations encore disponibles sont proposées.
- Rerolls limités, obtenus via la progression.
- Pause du gameplay pendant la sélection d'une récompense.
- Évolution automatique vérifiée après chaque acquisition ou amélioration.

À définir : récompense de substitution lorsque plus aucune amélioration n'est disponible, pondérations exactes, pity et nombre de rerolls.

## E. Ennemis

### Décisions validées

- 8 à 12 familles au lancement.
- Comportements variés : mêlée, rapides, tanks, ranged, supports, explosifs.
- Certaines interactions entre ennemis : buffs, protections, invocations.
- Élites avec affixes.
- Projectiles ennemis esquivables et télégraphiés.

### Dix familles proposées

1. Swarmers : ennemis nombreux.
2. Rushers : charges rapides.
3. Bruisers : tanks.
4. Spitters : projectiles à distance.
5. Snipers : tirs puissants télégraphiés.
6. Exploders : explosions de proximité.
7. Shielders : protection des alliés.
8. Buffers : renforcement des groupes.
9. Summoners : invocations limitées.
10. Phasers : déplacements intermittents.

Affixes proposés : Armored, Hasted, Volatile, Regenerating, Shielded, Split-on-Death. Prototypes Survival **[PROPOSÉS]** : Hasted (vitesse 100 px/s), Armored (75 px/s, 65 % des dégâts reçus), Regenerating (1 % des PV max/s), Volatile (explosion de 18 dégâts, rayon 82, sans chaîne), Shielded (anneau visible, 50 % des dégâts reçus) et Split-on-Death (deux adds si la limite globale le permet). En difficulté normale, le directeur choisit un affixe; en Chaos, il en choisit deux distincts qui s’appliquent ensemble. Les effets superposés sont combinés selon la règle validée au §4; les valeurs de ces combinaisons restent **[PROPOSÉES]** à calibrer.

Proposition : Threat Director distribuant un budget de menace entre les familles d'ennemis, avec règles de compatibilité des affixes et prévention des combinaisons impossibles à esquiver.

## F. Boss

### Décisions validées

- Bullet hell lisible, avec phases et patterns.
- 2 à 3 phases selon les HP.
- Difficultés supérieures ajoutant des patterns et des mécaniques, pas seulement des multiplicateurs.
- Invocations limitées par budget.
- Coffres garantis et ressources de run comme récompenses.
- Conservation des boss aux vagues 12 et 24.

### Boss proposés

**Wave 12 — The Pulse Warden**

- Phase 1 : projectiles radiaux.
- Phase 2 : charges et invocations.
- Phase 3 : combinaisons de patterns.

**Wave 24 — The Dopamine Core**

- Phase 1 : rayons et zones dangereuses.
- Phase 2 : spirales, déplacements et invocations.
- Phase 3 : patterns combinés plus exigeants.

Les noms et patterns restent des propositions.

## G. Mouvement et survie

### Décisions validées

- Mouvement instantané, précis, sans inertie significative.
- Aucun dash de base.
- Dash possible via certains équipements.
- Contact corps à corps ennemi : dégâts avec cooldown séparé pour chaque ennemi. Les projectiles et autres attaques ne partagent pas ce délai.
- HP decay toujours actif pendant le gameplay, y compris hors combat et pendant les boss.
- Guérison via kills, lifesteal et effets rares.

### Précision proposée

Suspendre le HP decay pendant les véritables pauses du gameplay, notamment la sélection des coffres.

Conserver provisoirement la formule existante :

`HP_decay_per_second = 1.5 + 0.004 * elapsed_gameplay_seconds`

Séparer horloge de gameplay, horloge de vague et temps réel.

## H. Équipement et progression permanente

### Décisions validées

- Équipement avec impact majeur sur les builds, sans rendre les runs triviales.
- Effets uniques Legendary/Mythic transformant des mécaniques.
- Stats offensives, défensives et utilitaires.
- Synergies d'équipement spécialisées par type d'arme ou statut.
- Skill tree avec respec gratuit.
- Équipement interchangeable hors run.

### Ajout proposé

Introduire `pickup_radius` comme statistique globale, utilisable par :

- Magnet Heart.
- Certains équipements.
- Certains nœuds du skill tree.
- Éventuels effets temporaires.

La statistique doit respecter une règle globale d'exclusion des coffres : aucun effet de ramassage ne les attire ou ne les collecte ; ils restent au sol jusqu’à ce que le joueur s’en approche ou interagisse avec eux.

Conserver les autres règles d'équipement, enhancement, achievements et raretés de la base v1.5 intégrée à ce document.

## I. Feedback audiovisuel

### Décisions validées

- Damage numbers agrégés intelligemment, critiques mis en avant.
- Feedback d'impact : flash, particules, son et hitstop sélectif.
- Évolution visuelle à chaque niveau d'arme.
- Transformation visuelle majeure lors des évolutions.
- Priorité visuelle aux dangers et télégraphes ennemis.
- Options de réduction des VFX.
- Musique EDM/synthwave adaptative aux vagues et boss.

[PROPOSÉ — prototype P9.3] Une base synthwave/EDM en boucle monte progressivement de niveau selon la vague, avec un accent pendant les combats de boss; elle s’atténue en pause, pendant les choix et après la fin de run. Les fichiers et recettes audio antérieurs ont été retirés conformément à la consigne de remplacement; les créations procédurales internes et leur manifeste sont documentés dans `docs/specs/SPEC-adaptive-audio.md` et `docs/art/PROVENANCE_ASSETS.csv`. Gains et vitesse de fondu restent à régler par écoute en jeu.

## J. Équilibrage et rejouabilité

### Décisions validées

- Toutes les armes doivent être viables, avec des rôles différents.
- RNG contrôlé et protection anti-malchance.
- Rééquilibrage des builds dominants pour préserver plusieurs stratégies.
- Synergies cachées, achievements et effets spéciaux secrets.
- Rejouabilité fondée sur les builds, la progression, les difficultés et Endless.

## K. ADR à modifier

- **ADR-007** : intégrer les réactions élémentaires et la gestion de causalité.
- **ADR-014** : compléter la stratégie Sandbox-first avec les tests d'armes, de DPS, de statuts et de synergies.
- **ADR-015 — Weapon & Relic Framework** : nouvel ADR proposé.
- **ADR-016 — Status & Reaction System** : nouvel ADR proposé.
- **ADR-017 — Loot & Run Progression** : nouvel ADR proposé.
- **ADR-018 — Enemy & Boss Director** : nouvel ADR proposé.

Ne pas renuméroter les ADR existants si les identifiants sont déjà utilisés.

## Phases de roadmap v1.6

| Phase | Contenu                                                   |
| ----- | --------------------------------------------------------- |
| P0    | Fondations techniques                                     |
| P1    | Sandbox minimal                                           |
| P2    | Combat core et statuts                                    |
| P3    | Prototype de 3 armes, 3 reliques, évolutions et DPS meter |
| P4    | Vertical slice Survival                                   |
| P5    | 10 armes, 11 reliques, évolutions, ennemis                |
| P6    | Progression permanente                                    |
| P7    | Endless et Armorless                                      |
| P8    | Sandbox Lab complet                                       |
| P9    | Équilibrage, polish, livraison                            |

Le Sandbox doit être utilisable dès P1 et enrichi progressivement, pas développé uniquement en P8.

