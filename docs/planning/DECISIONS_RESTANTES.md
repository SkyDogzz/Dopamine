# Registre des décisions restantes

Ce registre aide à conduire l’interview avant les changements qui dépendent d’un arbitrage. Il ne modifie aucun statut du GDD : les choix ci-dessous sont des **options de discussion [PROPOSÉES]**, pas des règles adoptées. Les décisions déjà confirmées restent dans le GDD et les ADR.

## À trancher avant les fonctions concernées

| Ordre | Sujet | Options de discussion | Quand c’est nécessaire | Référence |
|---|---|---|---|---|
| 1 | Réaction Overcharge : statut conducteur et effet | A. Reporter Overcharge et ne pas l’implémenter. B. Choisir un statut conducteur et recevoir une proposition d’effet à valider. C. Définir ensemble déclencheur et effet. | Avant d’implémenter Overcharge. | GDD §5, annexe C; roadmap P5.2.3. |
| 2 | Coexistence des DoT hors Burn + Poison | A. Chaque type distinct coexiste; réappliquer le même type le remplace. B. Seules les paires explicitement validées coexistent; un autre DoT remplace celui déjà présent. C. Définir chaque paire au moment où une arme en a besoin. | Avant toute nouvelle réaction ou arme dépendant de plusieurs DoT. | GDD §5 et décision Toxic Ignition; roadmap P5.2.1. |
| 3 | Autres mutations de Chaos | A. Garder seulement l’enchaînement de boss déjà validé. B. Recevoir une courte liste de mutations candidates à valider une par une. C. Définir les mutations ensemble. | Avant d’ajouter des mutations Chaos au-delà de la séquence de boss validée. | GDD §4; roadmap P5.4.6. |
| 4 | Lifesteal général, indépendant de Blood Chalice | A. Aucun lifesteal sans la relique. B. Fixer un taux global de base, avec Blood Chalice en bonus. C. Revoir le contrat de lifesteal complet. | Avant d’activer un soin par dégâts dans les builds sans Blood Chalice. | GDD §3 et §5. |
| 5 | Endless standard — entrées et déblocage | A. Débloquer uniquement après une victoire Survival et proposer continuation après le boss. B. Débloquer après une victoire, mais lancer seulement depuis le menu. C. Choisir une autre condition/entrée. | Avant le flux de menu et la transition Survival→Endless. | GDD §11–12; roadmap P7B.1. |
| 6 | Endless standard — état à la transition | A. Après victoire, conserver build et HP; au lancement menu, recommencer armes/reliques au niveau 1. B. Conserver aussi le build depuis le menu. C. Toujours recommencer un build neuf. | Avant la transition et la création de run. | Proposition GDD §12; roadmap P7B.1. |
| 7 | Endless standard — cycles et difficulté | A. Réutiliser Easy–Chaos, boss toutes les 12 vagues et scaling proposé. B. Choisir séparément difficulté, cadence des boss et scaling. C. Définir un cycle alternatif. | Avant le directeur endless et son équilibrage. | GDD §12; roadmap P7B.1. |
| 8 | Endless standard — fin, records et récompenses | A. Défaite ou abandon; record local de vague/temps; récompenses Survival sans pièce garantie répétable. B. Ajouter une sortie volontaire avec récompense calculée. C. Définir ensemble les règles de sortie, record et récompenses. | Avant l’écran de résultat et l’attribution persistante. | GDD §12; roadmap P7B.1. |

## À arbitrer pendant la calibration ou avant extension

| Sujet | Options de discussion | État / référence |
|---|---|---|
| Économie Enhancement | A. Garder les tableaux proposés et calibrer par essais. B. Revoir coûts, chances et rendements avant de calibrer. C. Garder les chances mais refaire l’économie de Powder. | Les règles de base sont validées; poudre par niveau/rareté, prix exact du reroll, économie de démantèlement et protections de conversion restent ouverts. GDD §8; roadmap P6.4. |
| Armorless sans fin | A. Garder les formules proposées et mesurer des runs longues. B. Ajuster séparément les récompenses et la rareté. C. Remplacer la progression de scaling/récompense. | Les catégories de récompenses sont validées; montants, multiplicateurs et scaling restent proposés. GDD §13; roadmap P7A.5. |
| Skill tree | A. Garder 100 nœuds et calibrer le budget actuel. B. Étendre vers la cible éditoriale proposée d’environ 120. C. Revoir la répartition avant extension. | 100–150 nœuds validés; environ 120 et la répartition précise sont proposés. GDD §9; roadmap P6.6. |
| Achievements | A. Garder les 100 familles actuelles. B. Étendre vers 120. C. Réviser d’abord les catégories et récompenses. | 100–150 familles validées; 120 est la cible éditoriale proposée. GDD §10; roadmap P6.7. |
| Puissance cumulée | A. Garder les budgets proposés et mesurer débutant/moyen/complet. B. Réduire les bonus si les mesures dépassent les cibles. C. Revoir l’allocation entre arbre, achievements, équipement et run. | Cibles globales validées, répartition et valeurs proposées; mesures complètes requises. GDD §9–10; roadmap P6.9. |
| Nouveaux pickups pour Magnet Heart | A. Ne pas ajouter de catégories avant de définir chacune. B. Définir d’abord soin, ressource, monnaie et bonus temporaire, puis les ajouter au fur et à mesure. | L’attraction est validée quand ces objets existent, mais leurs effets, valeurs et apparitions sont ouverts. GDD annexe Magnet Heart. |
| Direction visuelle fine | A. Garder la direction ART_BIBLE et reporter les détails encore ouverts. B. Valider successivement biome, police, mapping couleur et rythme de clignotement. | Choix de production, non-bloquants pour le combat; les propositions et limites QA figurent dans `docs/qa/TESTS.md` et `docs/ART_BIBLE.txt`. |

## Validations à faire, sans arbitrage de design

- Profilage CPU/GPU représentatif sur l’iGPU cible; l’environnement courant n’expose pas le GPU hôte.
- Run Armorless complète à durée de production, avec drafts, boss et pauses, sans invulnérabilité ni éliminations scriptées.
- Runs Survival représentatives et équilibrage des armes, boss, Thermal Shock, probabilités et progression; les chiffres proposés ne deviennent pas validés par les tests synthétiques.
- Validation Windows quand le travail Windows reprendra; les instructions antérieures de suspendre ce travail restent applicables.

## Conduite de l’interview

Poser une question à la fois, dans l’ordre de priorité, et proposer les options de ce registre. Une réponse règle seulement le sujet demandé; elle ne valide pas automatiquement les chiffres ou décisions associées. Après chaque réponse, consigner explicitement son statut dans le GDD/roadmap avant d’implémenter le comportement dépendant.
