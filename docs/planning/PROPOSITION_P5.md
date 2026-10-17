# Proposition de réglages de progression permanente (prototype P6 v1.6)

**Statut : [PROPOSÉ] — document de revue, non accepté.** Cette proposition fournit des valeurs de départ pour calibrer les prototypes de progression (jalon P6 dans la roadmap v1.6). Elle ne ferme aucun point `[OUVERT]` du GDD v1.6 et ne change aucun contrat de gameplay. Les valeurs ci-dessous sont des hypothèses de prototype, à mesurer en jeu avant toute validation.

## 1. Équipement : plages de statistiques

Proposition : chaque ligne tire uniformément un percentile `r ∈ [0,1]`, bornes incluses, puis calcule `base = min + r × (max − min)`. Les rolls sauvegardés acceptent cette même plage; le calcul rejette les entrées hors plage ou non finies au lieu de les borner silencieusement. Les bonus exprimés en `%` sont des points de pourcentage ajoutés à la statistique correspondante ; `max_hp` est un nombre de PV. L'amélioration conserve la formule GDD `valeur = base × (1 + 0,08 × niveau)`.

| ID | Plage de base proposée | Unité |
|---|---:|---|
| `damage_pct` | 1–5 | points de % dégâts |
| `attack_speed_pct` | 1–4 | points de % vitesse d'attaque |
| `critical_chance_pct` | 0,5–2 | points de % critique |
| `critical_damage_pct` | 5–20 | points de % dégâts critiques |
| `max_hp` | 2–8 | PV |
| `move_speed_pct` | 1–4 | points de % vitesse de déplacement |
| `kill_healing_pct` | 1–3 | points de % soin par élimination |
| `area_pct` | 1–4 | points de % zone |
| `cooldown_reduction_pct` | 0,5–2 | points de % réduction de recharge |
| `xp_pct` | 1–4 | points de % XP |
| `pickup_radius_pct` | 2–8 | points de % rayon de ramassage |
| `projectile_speed_pct` | 2–8 | points de % vitesse de projectile |

Proposition complémentaire : garder les mêmes plages pour toutes les raretés ; la rareté augmente le nombre de lignes selon le contrat existant. Cela facilite la comparaison et évite de cumuler une plage supérieure avec plus de lignes. Limiter les statistiques finales par des caps globaux documentés avant d'activer des bonus de compétence/achievement qui peuvent les amplifier.

Pour rendre les statistiques critiques jouables, ajouter comme hypothèse de prototype un multiplicateur de critique de base de 150% auquel s'ajoute la ligne `critical_damage_pct`. Ce socle est une proposition de combat supplémentaire, pas une valeur validée par le GDD.

## 2. Poudre, démantèlement et vente

Le coût de tentative d'amélioration déjà proposé au GDD reste inchangé. Pour tester l'économie sans introduire plusieurs monnaies, proposition de rendement du démantèlement selon la rareté :

| Rareté | Poudre proposée |
|---|---:|
| Normal | 1 Basic |
| Magic | 3 Basic |
| Mystic | 1 Refined |
| Legendary | 3 Refined |
| Mythic | 1 Pure |

La conversion ascendante 10:1 est **[VALIDÉE]** vers le tier supérieur uniquement; aucun retour ni restitution de Powder ne sont permis, et aucune limite/traçage de provenance supplémentaire n’est retenu (décision utilisateur du 2026-10-17). Aucun rendement direct en Prismatic : ce tier reste rare et provient de conversions. La recommandation initiale de ne pas ajouter de vente n'est pas retenue dans le prototype courant : le GDD prévoit vente et démantèlement comme actions distinctes. La vente crédite uniquement de l'Essence et affiche une confirmation; ses montants par rareté (5/10/20/40/80) restent **[PROPOSÉS]** et non calibrés. Le démantèlement reste la sortie Powder. Le prix du reroll d’effet est **[VALIDÉ]** : 1 Powder Pure pour Legendary, 1 Powder Prismatic pour Mythic (décision utilisateur du 2026-10-17). Tant que le reroll n’est pas implémenté, aucune ressource ne doit être débitée pour cette action indisponible.

## 3. Effets uniques — comportements de prototype

Pour les six exemples du GDD, proposition d'un comportement borné, soumis à instrumentation. Les nombres sont des valeurs initiales de test, pas des décisions finales.

| Effet | Comportement proposé | Garde-fou proposé |
|---|---|---|
| Éclair supplémentaire occasionnel | À chaque attaque, 10% de chance de frapper un ennemi proche pour 50% des dégâts de l'arme principale. | Une seule chaîne, sans rebond récursif ; temps de recharge interne de 2 s. |
| Bouclier issu du soin excédentaire | Le soin excédant les PV manquants devient bouclier à 50% de sa valeur. | Bouclier plafonné à 10% des PV max ; expire après 5 s. |
| Onde de choc à la première évolution | La première évolution de la run inflige 100% des dégâts de base aux ennemis dans un rayon de test de 120 px. | Une activation par run et par objet. |
| Vitesse après élimination d'élite | +15% vitesse de déplacement pendant 3 s après une élimination d'élite. | Durée non cumulable ; une nouvelle élimination rafraîchit le délai. |
| Premier chest relançable | Le premier choix de chest de la run peut être relancé une fois gratuitement. | Le reroll ne peut pas reproduire les options déjà proposées dans ce chest. |
| Onde de recul à la résurrection | À la résurrection, repousse les ennemis proches de 120 px. | Une fois par run ; n'accorde ni soin, ni invulnérabilité, ni résurrection supplémentaire. |

État : l'overflow shield a un état temporaire visible dans le HUD et absorbe les dégâts de la run ; il n'est pas sauvegardé, car la run ne peut pas encore être reprise après fermeture. Le reroll gratuit du premier chest est implémenté comme prototype : une seule relance, options précédentes exclues, seulement si assez d'alternatives sont disponibles; l'effet et ses limites restent **[PROPOSÉS]**. L'onde de recul nécessite une résurrection de gameplay définie; elle reste lisible dans les sauvegardes existantes, mais ne peut plus être choisie pour un nouvel équipement.

## 4. Skill tree

Proposition : conserver la répartition éditoriale de 120 nœuds déjà marquée `[PROPOSÉ]` dans le GDD : 30 stats centrales, 8 déblocages d'armes, 8 déblocages de reliques, 20 maîtrises d'armes, 20 maîtrises de reliques, 14 utilitaires et 20 passerelles.

Pour éviter que le coût dépende de l'ordre d'achat, proposer une profondeur fixe dans le graphe et la formule suivante : `coût Essence = 20 + 10 × profondeur + supplément de déblocage`. Suppléments : 0 pour bonus simples ; +80 pour un déblocage d'arme ou relique. Les prérequis restent déterministes et le respec reste gratuit. La formule est branchée sur les deux nœuds actuels, dont les profondeurs 3 et 6 donnent 50 et 80 Essence.

Garde-fou de puissance proposé : attribuer un budget de puissance à chaque nœud et vérifier que l'ensemble atteignable reste dans la cible GDD d'environ +30% sur un build de référence. Aucun nœud ne doit réduire le HP decay à zéro ni accorder de revive infini.

## 5. Achievements

Proposition : conserver les quatre seuils Exterminator et les bonus par palier déjà donnés en exemple dans le GDD ; ils servent de modèle, pas de catalogue accepté. Pour les autres familles, utiliser des métriques cumulées monotones (`sum`), des records (`max`) ou des compteurs d'événements idempotents selon la définition de l'objectif. Les récompenses de palier sont reconstruites à partir des paliers atteints, sans stocker les mêmes bonus deux fois.

Répartition de 120 familles proposée par le GDD à garder comme squelette éditorial : Combat 25, Survival 15, Weapons 20, Relics & Evolutions 15, Equipment 15, Difficulty & Bosses 15, Progression 10, Secrets 5. Les bonus permanents doivent rester dans le budget GDD proposé de +12% global, mesuré sur plusieurs builds ; les récompenses utilitaires/effets spéciaux sont incluses dans ce budget après mesure.

Proposition de priorité pour le catalogue de progression : compléter d'abord un petit ensemble traversant toutes les catégories et tous les types de métriques, valider l'idempotence/migration/persistance, puis remplir le catalogue complet par lots. La cible éditoriale de 120 n'est pas un prérequis technique au fonctionnement du système, mais le contenu complet reste à satisfaire avant de déclarer le prototype de progression terminé.

## Revue et critères de validation

Avant d'accepter ces réglages, tester au minimum plusieurs builds de référence sur des runs Survival, comparer la progression par rareté et vérifier qu'aucune statistique n'atteint un cap trop tôt. Ajuster ensuite les plages, gains de poudre, coûts d'Essence et budgets de bonus ensemble. Consigner les valeurs acceptées au GDD avec leur nouveau statut ; maintenir `[OUVERT]` pour tout point non arbitré.

## État d'implémentation

Les plages percentiles et leur affichage sont branchés ; les douze statistiques équipées modifient actuellement Survival (dégâts, vitesse d'attaque, critiques, PV, mobilité, soin par élimination, zone, cooldown, XP, collecte et vitesse projectile). Les rendements de démantèlement suivent le tableau proposé. Lightning burst, overflow shield, evolution shockwave, elite haste et le reroll gratuit du premier chest ont des comportements de prototype; elite haste se déclenche à la mort d’un élite et accorde +15 % de mobilité pendant 3 secondes simulées, chiffres **[PROPOSÉS]** couverts par `survival_elite_smoke.gd`. Le reroll gratuit du premier chest est couvert par `free_chest_reroll_smoke.gd`. Seul `revive_knockback` reste stockable pour les anciennes sauvegardes sans nouveau choix ni comportement, et le générateur de catalogue de 120 nœuds/achievements n'est pas encore un contenu jouable. Ces limites sont reflétées dans la roadmap : cette tranche ne clôt pas P6.
