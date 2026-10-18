# Intention — refonte de toutes les interfaces

**Statut : intention confirmée par interview, 2026-10-15.** Ce document conserve les réponses validées avant la rédaction des specs. Il ne transforme pas les propositions du GDD en décisions acceptées.

## Objectif

Remplacer le parcours de lancement actuel centré sur le Sandbox par une expérience cohérente de jeu : accueil, hub, préparation et lancement d’une run, HUD et pause, tout en refondant aussi l’interface du Sandbox existant. La direction reste pixel art néon; la priorité est une hiérarchie plus claire et une meilleure lisibilité.

## Parcours confirmé

1. L’accueil propose **Jouer**, **Options**, **Quitter** et un accès **Sandbox** discret.
2. **Jouer** ouvre un hub avec Survival comme seul mode actuellement jouable, le choix de difficulté, les équipements, l’arbre de compétences, Succès, Bestiaire et un bouton explicite de lancement de run.
3. Les cinq difficultés sont Easy, Normal, Hard, Nightmare et Chaos. Easy est disponible d’emblée; chaque difficulté suivante se débloque après une victoire dans la difficulté précédente. Les multiplicateurs numériques du GDD restent **[PROPOSÉS]**.
4. Équipements et arbre de compétences se consultent/se modifient dans le hub avant la run. Succès et Bestiaire restent visibles mais sans action tant que leurs fonctions ne sont pas implémentées.
5. Pendant une run, Échap ouvre la pause; Échap ou **Reprendre** reprend la run. Le menu de pause contient **Reprendre**, **Options**, un inventaire en lecture seule des armes et reliques équipées, et **Abandonner**.
6. L’inventaire de run présente l’icône, le nom, le niveau, l’état d’évolution et la description de chaque arme/relique équipée. L’équipement permanent et l’arbre de compétences ne sont jamais modifiables pendant une run.
7. L’abandon demande confirmation; confirmer ramène à l’accueil et annule la run, annuler permet de reprendre.
8. Options reste volontairement minimal pour cette tranche : plein écran et volume général. Depuis la pause, ouvrir ou fermer Options ne reprend pas la simulation.
9. La refonte du Sandbox améliore son interface existante sans créer de pont vers la progression normale ni les sauvegardes.
10. Les choix de coffre indiquent clairement s’ils proposent une arme ou une relique et décrivent l’effet de chaque option.

## Entrées et accessibilité

Toutes les interfaces et actions de menu doivent être utilisables à la souris, au clavier et à la manette. Le focus clavier/manette doit rester visible et suivre les changements d’écran.

## Statuts de référence

- **[VALIDÉ]** par le GDD ou un ADR : direction pixel art néon, lisibilité HUD à forte densité, prise en charge manette, choix/déblocage séquentiel des difficultés et Sandbox-first avec isolation de progression.
- **[VALIDÉ]** par l’interview utilisateur : parcours décrit ci-dessus, menus d’options minimaux, inventaire de pause en lecture seule et confirmation d’abandon. **Extension utilisateur 2026-10-18 :** Succès ouvre la progression et les bonus d’achievements; Bestiaire ouvre le Codex.
- **[PROPOSÉ]** : multiplicateurs de difficulté, paramètres d’équilibrage et recommandations visuelles non explicitement retenues.
- **[OUVERT]** dans le GDD : wireframes détaillés, options VFX et détails audio. Ils ne sont pas implicitement arbitrés par cette intention.

## Hors périmètre de cette intention

- Implémenter Succès ou Bestiaire; seuls leurs boutons doivent apparaître.
- Ajouter des modes non implémentés ou prétendre qu’ils sont jouables.
- Construire le Sandbox Lab joueur complet de P8; la refonte porte sur le Sandbox développeur déjà présent.
- Modifier les décisions acceptées des ADR, l’équilibrage proposé ou la séparation des sauvegardes.

## Extension confirmée — refonte visuelle complète, 2026-10-16

L’utilisateur confirme maintenant la recréation de **tous les assets visuels existants**, y compris ceux déjà proches du style, et la production des assets manquants pour le catalogue complet des 10 armes et 11 reliques. La silhouette actuelle du héros peut être refaite, mais son identité et sa dominante cyan sont conservées.

Toutes les interfaces existantes doivent également être refaites pour appliquer `docs/ART_BIBLE.txt`, en conservant les comportements du parcours ci-dessus et l’isolation Sandbox/progression. Le premier livrable est un inventaire complet des assets et écrans; la production se fera ensuite par lots cohérents.

Les contraintes validées de la Bible gouvernent la production. Les décisions encore **[OUVERTES]** — par exemple l’ordre des directions sur les feuilles, les frames d’animation des ennemis, le biome canonique et les paramètres VFX — restent visibles et ne deviennent pas des faits implicites. Le PNG et sa source Aseprite sont le format de livraison validé pour les sprites.

Le viewport logique 1280×720 est **[VALIDÉ — EXTENSION CRÉATEUR 2026-10-18]** et remplace l’ancienne résolution logique 640×360. Chaque interface doit être adaptée et vérifiée à la taille native ainsi qu’aux résolutions d’affichage prises en charge. Les comportements de jeu, les fonctionnalités Succès/Bestiaire non implémentées et le Sandbox Lab joueur P8 restent hors de cette extension.

L’inventaire de référence est [`docs/art/INVENTAIRE_ASSETS_UI.md`](../art/INVENTAIRE_ASSETS_UI.md).

## Carte des capacités

Les responsabilités, dépendances et l’ordre proposé sont dans [`UI_CAPABILITY_MAP.md`](../../UI_CAPABILITY_MAP.md), carte validée avant la rédaction de specs séparées par module.
