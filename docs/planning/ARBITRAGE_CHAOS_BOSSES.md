# Arbitrage proposé — comportement Chaos des boss

**Statut : [PROPOSÉ], en attente de validation.** Le GDD v1.6 valide que Chaos ajoute des comportements particuliers, mais laisse les mutations Chaos et le catalogue détaillé des patterns **[OUVERTS]**. Ce document ne change pas ces statuts et n'autorise pas encore l'implémentation.

## Choix à faire

Le comportement doit différencier Chaos sans remplacer les cinq difficultés, sans modifier l'isolation Sandbox/Survival, et en conservant les télégraphes et le plafond global de trois invocations.

### Option recommandée — séquence de boss Chaos

- En Chaos uniquement, après une attaque normale télégraphiée sur deux, le boss enchaîne une deuxième attaque télégraphiée issue de ses patterns déjà implémentés.
- Le Pulse Warden choisit son prochain pattern de phase parmi radial, tir ciblé et charge; le Dopamine Core parmi rayon, zone et spirale. Le pattern reste annoncé avant son exécution.
- L'enchaînement n'ajoute ni dégâts, ni vitesse de projectile, ni invocation au plafond; les valeurs de dégâts existantes continuent d'utiliser le multiplicateur Chaos.
- Easy à Nightmare gardent leur séquence actuelle. Les boss, le timer de vague et le decay conservent leurs contrats actuels.

Cette option réutilise le contenu de combat existant et introduit une pression de pattern visible sans inventer de famille ou d'affixe. Elle reste **[PROPOSÉE]** et doit être évaluée sur une run réelle avant tout équilibrage définitif.

### Alternatives

1. **Chaos purement numérique** : conserver le code actuel. Cela ne satisfait pas la règle GDD selon laquelle Chaos ajoute des comportements.
2. **Mutation de roster** : ajouter une compatibilité Chaos entre familles et affixes. Non recommandé pour la première tranche, car la compatibilité des affixes avec les familles est elle-même **[OUVERTE]**.
3. **Pattern Chaos inédit** : créer de nouvelles attaques dédiées. Cela augmente le contenu à produire et à télégraphier; à envisager après l'évaluation de la séquence réutilisée.

## Vérification si l'option recommandée est acceptée

- Smoke ciblé : aucun enchaînement supplémentaire en Easy à Nightmare; alternance déterministe et télégraphiée en Chaos pour les deux boss.
- Vérifier pause/reprise, transitions de phase, plafond d'invocations et dégâts avec multiplicateur de difficulté.
- Compléter par une run réelle Chaos avant de calibrer intervalle ou ordre des patterns.
- Tant que le joueur n'a pas validé ce choix, conserver le comportement actuel et le statut **[OUVERT]** du GDD.
