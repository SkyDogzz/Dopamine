# Registre des décisions restantes

Ce registre aide à conduire l’interview avant les changements qui dépendent d’un arbitrage. Il ne modifie aucun statut du GDD : les choix ci-dessous sont des **options de discussion [PROPOSÉES]**, pas des règles adoptées. Les décisions déjà confirmées restent dans le GDD et les ADR.

## À trancher avant les fonctions concernées

| Ordre | Sujet | Options de discussion | Quand c’est nécessaire | Référence |
|---|---|---|---|---|
| 1 | Overcharge et statut Shock | **Décidé [VALIDÉ, 2026-10-17]** : tous les coups directs électriques appliquent Shock pendant 1 s; un nouveau coup électrique pendant cette durée déclenche une décharge de zone sans chaîne. Les paramètres de prototype (50 % des dégâts déclencheurs, rayon 60 px, cooldown local 1 s) restent **[PROPOSÉS]**. Implémenté dans P5.2.3. | Décision fermée; calibration des paramètres proposée à faire en run représentative. | GDD §5, annexe C; roadmap P5.2.3. |
| 2 | Coexistence des DoT hors Burn + Poison | **Décidé [VALIDÉ, 2026-10-17]** : chaque type distinct de DoT coexiste; réappliquer un type remplace uniquement celui-là. Implémenté et couvert par le test natif Burn + Poison + Bleed. | Décision fermée. | GDD §5; roadmap P5.2.1. |
| 3 | Mutations supplémentaires de Chaos | **Décidé [VALIDÉ, 2026-10-17]** : soutiens existants plus fréquents dans les vagues; deux affixes distincts par élite Chaos; patterns télégraphiés des boss différents d’une attaque à la suivante. Les coefficients de fréquence et de combinaison restent **[PROPOSÉS]**. | Décision de périmètre fermée; équilibrage et runs représentatives restent requis. | GDD §4; roadmap P5.4.6. |
| 4 | Lifesteal général, indépendant de Blood Chalice | **Décidé [VALIDÉ, 2026-10-17] — réponse B** : un taux de base global s’applique, Blood Chalice y ajoute son bonus. Le taux de base du prototype est de 5 % **[PROPOSÉ]** et reste à calibrer. | Contrat fermé; calibration du taux, du soft cap et du soin sur la durée encore ouverte. | GDD §3 et §5; roadmap P5.2.2. |
| 5 | Synergies Magnet Heart | **Décidé [VALIDÉ, 2026-10-17] — réponse « les 3 »** : inclure les trois synergies proposées avec Magnetic Coil, Singularity et Celestial Eye. | Périmètre fermé; condition niveau 5 et valeurs d’activation restent **[PROPOSÉES]**. | GDD annexe Magnet Heart; roadmap P5.1.13. |
| 6 | Endless standard — entrées et déblocage | **Prototype choisi [PROPOSÉ, 2026-10-17]** : option B, déblocage après victoire Survival et lancement depuis le hub uniquement. Pas de continuation immédiate après le boss dans cette tranche. | Le hub et le lancement sont implémentés; la continuation reste une extension ouverte. | GDD §11–12; roadmap P7B. |
| 7 | Endless standard — état à la transition | **Prototype choisi [PROPOSÉ, 2026-10-17]** : depuis le hub, utiliser la progression/équipement permanent actif et commencer la run avec les armes et reliques au niveau 1. | Appliqué au lancement depuis le hub; un transfert du build du Survival reste ouvert avec la continuation. | GDD §12; roadmap P7B. |
| 8 | Endless standard — cycles et difficulté | **Prototype choisi [PROPOSÉ, 2026-10-17]** : réutiliser Easy–Chaos et le scaling existant; mid-boss toutes les 12 vagues, y compris aux vagues 24, 36, etc. Implémenté dans le directeur et vérifié par `survival_wave_director_smoke.gd`; valeurs d’équilibrage toujours ouvertes. | Cadence prototype implémentée; calibration représentative encore requise. | GDD §12; roadmap P7B. |
| 9 | Endless standard — fin, records et récompenses | **Prototype choisi [PROPOSÉ, 2026-10-17]** : défaite ou abandon; records locaux par difficulté, triés par vague puis temps et kills; récompenses avec la formule Survival sans bonus de boss final ni équipement garanti. Attribution idempotente. | Flux implémenté; montants proposés à calibrer en run représentative. | GDD §12; roadmap P7B. |

## À arbitrer pendant la calibration ou avant extension

| Sujet | Options de discussion | État / référence |
|---|---|---|
| Économie Enhancement | A. Garder les tableaux proposés et calibrer par essais. B. Revoir coûts, chances et rendements avant de calibrer. C. Garder les chances mais refaire l’économie de Powder. | Les règles de base sont validées; poudre par niveau/rareté, prix exact du reroll, économie de démantèlement et protections de conversion restent ouverts. GDD §8; roadmap P6.4. |
| Probabilités de coffre | A. Garder les valeurs GDD proposées pour les prochaines runs représentatives, puis décider après les mesures. B. Revoir les chances ordinaires/élites avant ces runs. C. Garder les chances mais revoir l’intervalle et la règle du filet anti-malchance. | Les valeurs GDD restent **[PROPOSÉES]** : 0,5 % par famille et ennemi ordinaire, 15 % par famille et élite, boss garantissant chaque famille, filet de 60 s par famille. Le prototype tire séparément les deux familles et déclenche le filet au prochain événement de mort ennemi après l’intervalle. Avant filet, la probabilité d’obtenir une famille donnée est 9,5 % après 20 morts ordinaires, 22,2 % après 50 et 39,4 % après 100; contre 5/10/20 élites, elle est 55,6/80,3/96,1 %. GDD §6; roadmap P5.3.4. |
| Armorless sans fin | A. Garder les formules proposées et mesurer des runs longues. B. Ajuster séparément les récompenses et la rareté. C. Remplacer la progression de scaling/récompense. | Les catégories de récompenses sont validées; montants, multiplicateurs et scaling restent proposés. GDD §13; roadmap P7A.5. |
| Skill tree | A. Garder 100 nœuds et calibrer le budget actuel. B. Étendre vers la cible éditoriale proposée d’environ 120. C. Revoir la répartition avant extension. | 100–150 nœuds validés; environ 120 et la répartition précise sont proposés. GDD §9; roadmap P6.6. |
| Achievements | A. Garder les 100 familles actuelles. B. Étendre vers 120. C. Réviser d’abord les catégories et récompenses. | 100–150 familles validées; 120 est la cible éditoriale proposée. GDD §10; roadmap P6.7. |
| Puissance cumulée | A. Garder les budgets proposés et mesurer débutant/moyen/complet. B. Réduire les bonus si les mesures dépassent les cibles. C. Revoir l’allocation entre arbre, achievements, équipement et run. | Cibles globales validées, répartition et valeurs proposées; mesures complètes requises. GDD §9–10; roadmap P6.9. |
| Nouveaux pickups pour Magnet Heart | A. Ne pas ajouter de catégories avant de définir chacune. B. Définir d’abord soin, ressource, monnaie et bonus temporaire, puis les ajouter au fur et à mesure. | L’attraction est validée quand ces objets existent, mais leurs effets, valeurs et apparitions sont ouverts. Vérification du code le 2026-10-17 : les pickups de run sont les orbes XP; les coffres sont des objets séparés. Aucun pickup soin/ressource/monnaie/bonus temporaire n’est implémenté; ne pas en déduire depuis Magnet Heart. GDD annexe Magnet Heart; roadmap P5.1.13. |
| Direction visuelle fine | A. Garder la direction ART_BIBLE et reporter les détails encore ouverts. B. Valider successivement biome, police, mapping couleur et rythme de clignotement. | Choix de production, non-bloquants pour le combat; les propositions et limites QA figurent dans `docs/qa/TESTS.md` et `docs/ART_BIBLE.txt`. |

## Validations à faire, sans arbitrage de design

- Profilage CPU/GPU représentatif sur l’iGPU cible; l’environnement courant n’expose pas le GPU hôte.
- Run Armorless complète à durée de production, avec drafts, boss et pauses, sans invulnérabilité ni éliminations scriptées.
- Runs Survival représentatives et équilibrage des armes, boss, Thermal Shock, probabilités et progression; les chiffres proposés ne deviennent pas validés par les tests synthétiques.
- Validation Windows quand le travail Windows reprendra; les instructions antérieures de suspendre ce travail restent applicables.

## Conduite de l’interview

Poser une question à la fois, dans l’ordre de priorité, et proposer les options de ce registre. Une réponse règle seulement le sujet demandé; elle ne valide pas automatiquement les chiffres ou décisions associées. Après chaque réponse, consigner explicitement son statut dans le GDD/roadmap avant d’implémenter le comportement dépendant.
