# Arbitrage — comportement Chaos des boss

**Statut : [VALIDÉ] par le joueur le 2026-10-16; implémentation prototype intégrée.** Le GDD v1.6 valide que Chaos ajoute des comportements particuliers, mais laisse les autres mutations Chaos et le catalogue détaillé des patterns **[OUVERTS]**. Cette décision ne ferme que le comportement décrit ci-dessous.

## Choix à faire

Le comportement doit différencier Chaos sans remplacer les cinq difficultés, sans modifier l'isolation Sandbox/Survival, et en conservant les télégraphes et le plafond global de trois invocations.

### Séquence de boss Chaos retenue

- En Chaos uniquement, après une attaque normale télégraphiée sur deux, le boss enchaîne une deuxième attaque télégraphiée issue de ses patterns déjà implémentés.
- Le Pulse Warden choisit son prochain pattern de phase parmi radial, tir ciblé et charge; le Dopamine Core parmi rayon, zone et spirale. Le pattern reste annoncé avant son exécution.
- L'enchaînement n'ajoute ni dégâts, ni vitesse de projectile, ni invocation au plafond; les valeurs de dégâts existantes continuent d'utiliser le multiplicateur Chaos.
- Easy à Nightmare gardent leur séquence actuelle. Les boss, le timer de vague et le decay conservent leurs contrats actuels.

Cette option réutilise le contenu de combat existant et introduit une pression de pattern visible sans inventer de famille ou d'affixe. La règle est **[VALIDÉE]**; ses valeurs et son ressenti restent à évaluer sur une run réelle avant tout équilibrage définitif.

### Alternatives

1. **Chaos purement numérique** : conserver le code actuel. Cela ne satisfait pas la règle GDD selon laquelle Chaos ajoute des comportements.
2. **Mutation de roster** : ajouter une compatibilité Chaos entre familles et affixes. Non recommandé pour la première tranche, car la compatibilité des affixes avec les familles est elle-même **[OUVERTE]**.
3. **Pattern Chaos inédit** : créer de nouvelles attaques dédiées. Cela augmente le contenu à produire et à télégraphier; à envisager après l'évaluation de la séquence réutilisée.

## Vérification et limites restantes

- Smoke ciblé : aucun enchaînement supplémentaire en Easy à Nightmare; attaque supplémentaire télégraphiée en Chaos pour les deux boss; gel pendant la pause.
- Le code réutilise le chemin d'invocation plafonné existant. Une validation intégrée du plafond pendant l'attaque Chaos et une vérification des dégâts avec multiplicateur de difficulté restent à faire.
- Compléter par une run réelle Chaos avant de calibrer intervalle ou ordre des patterns.
- Le statut **[OUVERT]** du GDD reste applicable aux mutations Chaos autres que cette séquence et au catalogue complet des patterns.
