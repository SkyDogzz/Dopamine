# Dopamine Survivor — GDD v1.0 (reconstitution historique)

> **RECONSTITUTION, PAS DOCUMENT ORIGINAL.** Cette version est reconstruite à partir des décisions chronologiques retrouvées dans les échanges et des sections du GDD v1.5 consolidé. Les formulations et paramètres détaillés des sections extraites peuvent avoir été affinés après la version concernée ; ils ne constituent pas une transcription mot pour mot de v1.0.

## Objet de cette version

Première définition de la boucle Survival, des équipements, des armes/reliques, de la métaprogression et des modes envisagés.

Les éléments détaillés ci-dessous sont extraits de la consolidation v1.5 et ne garantissent pas que chaque phrase figurait déjà en v1.0.


## 02 — Boucle de jeu et commandes

[VALIDÉ] Combat automatique ; le joueur dirige le déplacement et choisit ses objets lors de l'ouverture des chests. Les armes attaquent automatiquement suivant leurs propres règles de ciblage. Les chests d'armes et de reliques proviennent des ennemis. Chaque chest propose trois options, avec une préférence pour les améliorations équipées et les synergies. Les orbes d'XP font monter le niveau sans écran traditionnel de trois upgrades.

Boucle Survival : choisir difficulté et arme initiale → survivre à une vague de 30 secondes → tuer pour se soigner et gagner XP → ramasser chests → améliorer armes/reliques → vaincre le mid-boss vague 12 → vaincre le boss final vague 24 → récompenses permanentes → recommencer.

[VALIDÉ] La durée de base est de 24 × 30 secondes = 12 minutes de combat actif, plus les pauses de boss et les choix. Objectif d'une run : 10–15 minutes. Le timer de vague s'arrête durant les boss ; le HP decay continue. Les joueurs peuvent poursuivre en Endless après la victoire finale selon le design proposé, mais les règles d'accès exactes d'Endless standard restent [OUVERTES].

[PROPOSÉ] Chaque niveau d'XP donne un petit bonus automatique de stats, sans écran de sélection. La courbe d'XP, les bonus par niveau et le comportement des pauses d'interface restent à spécifier.

<a id="3"></a>


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


## 07 — Équipement permanent

[VALIDÉ] Six slots : helmet, armor, gloves, boots, amulet, ring. Une seule pièce d'équipement garantie par run classique, y compris en cas de mort. Slot tiré aléatoirement. Inventaire permanent illimité ; équiper, vendre ou démanteler. Pas de bonus de set. Pas de type de statistique répété sur un même objet.

Raretés : Normal (1 ligne aléatoire), Magic (2), Mystic (3), Legendary (3 aléatoires + 1 effet unique choisi librement), Mythic (4 aléatoires + 1 effet unique choisi librement). Les rolls de statistiques sont continus dans des plages dépendantes de la rareté. Rareté dépend de la difficulté, de la vague atteinte et de la RNG.

Douze statistiques candidates : dégâts %, vitesse d'attaque %, chance critique %, dégâts critiques %, HP max, vitesse déplacement %, soin par kill %, zone %, réduction de cooldown %, XP %, rayon de collecte %, vitesse projectile %.

[PROPOSÉ] Chances de rareté Normal/Magic/Mystic/Legendary/Mythic : Easy 60/30/9/0,9/0,1 ; Normal 35/40/20/4,5/0,5 ; Hard 15/30/40/13/2 ; Nightmare 5/15/45/28/7 ; Chaos 0/5/35/40/20 (%). Une mort précoce diminue les chances des raretés supérieures. Plages exactes de rolls à calibrer.

[VALIDÉ] Effets uniques peuvent augmenter la capacité d'armes ou reliques à six ; un même effet unique actif ne se cumule pas automatiquement plusieurs fois. [PROPOSÉ] En cas de perte du slot bonus, l'objet supplémentaire devient inactif plutôt que détruit.

<a id="8"></a>


## 09 — Progression permanente et économie

[VALIDÉ] Arbre de compétences interconnecté de 100–150 nodes ; environ 120 prévus. Branches de déblocage d'armes/reliques et bonus avancés avec prérequis. Respec complet gratuit. Tous les nodes peuvent finir par être acquis. Budget cible : ~+30 % de puissance de combat équivalente. Environ un déblocage utile toutes les 2–3 runs. Essence plus abondante en difficulté élevée.

[PROPOSÉ] Répartition 120 nodes : 30 stats centrales ; 8 déblocages armes ; 8 déblocages reliques ; 20 maîtrises armes ; 20 maîtrises reliques ; 14 utilitaires ; 20 passerelles. Graphe précis et coûts à définir.

[PROPOSÉ] Récompenses Survival : Essence = arrondi((15 + 2×vague_max + 25×boss_final_vaincu) × multiplicateur_difficulté). Powder = arrondi((20 + 3×vague_max + 30×boss_final_vaincu) × multiplicateur_difficulté). Victoire Normal vague 24 : 88 Essence, 122 Powder Basic.

[VALIDÉ] Endgame : optimiser les équipements Mythic, terminer toutes les difficultés, développer les achievements et battre ses records Endless.

<a id="10"></a>


## 11 — Mode Survival

[VALIDÉ] Mode principal : 24 vagues de 30 secondes, mid-boss 12, boss final 24 ; fin victorieuse ou mort. Équipement permanent actif, bonus de skill tree et achievements actifs. Armes et reliques reconstruits à chaque run via chests. Une pièce d'équipement permanente garantie par run, y compris défaite. Difficulté choisie parmi celles débloquées.

[PROPOSÉ] Après victoire, proposition de poursuivre en Endless standard sans perdre le build. [OUVERT] Décision finale sur l'accès au Endless depuis le menu et sa condition de déblocage.

<a id="12"></a>


## 12 — Endless standard (conception provisoire)

[PROPOSÉ — NON ENCORE VALIDÉ PAR LE JOUEUR] Deux entrées : (a) lancer Endless depuis le menu après déblocage ; (b) continuer immédiatement après la vague 24. Depuis le menu : progression permanente et équipement actif, mais armes/reliques recommencent au niveau 1 ; après le boss : build et HP actuels conservés. Difficultés Easy à Chaos.

[PROPOSÉ] Cycles après vague 24 : ennemis plus puissants, élites et mutations, boss récurrents ; maîtrise répétable temporaire avec rendements décroissants après max des objets. Records de vague et survie.

[OUVERT] Déblocage, difficulté, cadence des boss, nature de la maîtrise répétable, modalités de sortie, récompenses et classement. Ces options ne sont pas des décisions officiellement arrêtées.

<a id="13"></a>
