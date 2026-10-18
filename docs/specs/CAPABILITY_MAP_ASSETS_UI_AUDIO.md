# Capability Map: Refonte des assets, de l’interface et de l’audio

## Objectif

Remplacer les assets graphiques et audio du jeu et refaire l’interface dans le style Neon Arcade de `docs/ART_BIBLE.txt`. La refonte inclut un véritable arbre de compétences ramifié et un écran d’équipement avec aperçu des changements de statistiques.

## Carte des capacités

| ID | Responsabilité | Dépend de |
|---|---|---|
| `asset-pipeline` | [Spec](SPEC-asset-pipeline.md) — inventorier les assets à remplacer, établir les sources/export PNG et critères de conformité visuelle et sonore, et intégrer les assets sans casser les références du jeu. | — |
| `visual-assets` | [Spec](SPEC-visual-assets.md) — remplacer les assets de gameplay, environnements, récompenses, catalogue, effets et identité visuelle selon l’Art Bible. | `asset-pipeline` |
| `interface-overhaul` | [Spec](SPEC-interface-overhaul.md) — refaire tous les écrans et composants UI existants en conservant les parcours validés, l’accessibilité et l’isolation Sandbox. | `asset-pipeline`, `visual-assets` |
| `skill-tree` | [Spec](SPEC-skill-tree.md) — concevoir et réaliser une page de compétences présentant un arbre ramifié et ses états/actions. Les règles de progression non validées restent à définir avant implémentation. | `interface-overhaul` |
| `equipment-screen` | [Spec](SPEC-equipment-screen.md) — réaliser la page d’équipement avec personnage et six slots à gauche, équipements équipés, liste équipable à droite, actions d’équipement/remplacement et aperçu avant/après des statistiques. | `interface-overhaul` |
| `adaptive-audio` | [Spec](SPEC-adaptive-audio.md) — remplacer musique et effets sonores par une direction arcade synthwave néon, avec une base EDM qui suit la progression de run et évolue par transitions fluides lors des événements, notamment les boss. | `asset-pipeline` |

## Ordre de réalisation proposé

`asset-pipeline` → `visual-assets` → `interface-overhaul` → `skill-tree` et `equipment-screen` ; `adaptive-audio` peut avancer après `asset-pipeline` en parallèle des capacités visuelles.

## État d’initiative (2026-10-18)

Les statuts suivants décrivent le dépôt; ils ne valident aucun choix de contenu marqué proposé.

| Capacité | Statut | Livré / restant |
|---|---|---|
| `asset-pipeline` | **EN COURS** | Instantané initial conservé, registre courant (262 fichiers, 64 usages statiques, 73 chargements dynamiques, sources éditables, prévisualisations et placeholders explicitement classés), migrations/retraits hashés. Remplacement des 107 exports graphiques restés identiques au snapshot initial vérifié à zéro correspondance; PCK Linux/X11 contrôlé. SFX, musique, familles visuelles et fontes runtime ont des remplacements originaux; revue finale audio et PCK de clôture restent requis. |
| `visual-assets` | **EN COURS** | Skyline, joueur, neuf rôles communs/supports, 24 projectiles, coffre/orbe XP, icônes UI/catalogue, sol/ruines, élite, prototypes boss génériques, VFX et deux fontes originales ont des sources éditables. Exports racine hérités et recettes par référence retirés après vérification des consommateurs. Identités boss/biome restent ouvertes; revue lisibilité et GPU réelle restent à faire. |
| `interface-overhaul` | **EN COURS** | Fondations, accueil, options, hub, vues Survival/Sandbox et parcours existants ont déjà des changements et smokes antérieurs; captures et smokes ciblés passent, et lisibilité hub/équipement confirmée à 640×360. Revue finale écran par écran, focus, contrôles matériels et choix final des fontes restent ouverts. L’isolation Sandbox est conservée et couverte par smoke avec profil temporaire propre. |
| `skill-tree` | **TRANCHE LIVRÉE — CAPACITÉ EN COURS** | Graphe navigable montrant 100 définitions runtime et leurs vrais prérequis; contenu, coûts et effets proposés ne sont pas validés. Commit `15a9071`. |
| `equipment-screen` | **TRANCHE LIVRÉE — CAPACITÉ EN COURS** | Six slots, filtre, bonus avant/après et actions existantes conservées; overlay du personnage et formules proposées restent ouverts. Commit `5eadb12`. |
| `adaptive-audio` | **EN COURS** | 38 SFX branchés sur 19 familles; cinq stems originaux synchronisés suivent les vagues et ajoutent le stem boss par fondu sans redémarrage. L’ancien OGG et les recettes SFX ont été retirés après migration. Un extrait de transition est prêt pour écoute locale. Mix/gains **[PROPOSÉS]**; revue auditive humaine et en jeu **[OUVERTE]** faute de sortie locale. |

## Contraintes déjà confirmées

- Style Neon Arcade, pixel art strict pour les sources, VFX modernes et contextuels, lisibilité prioritaire.
- Respecter la palette maître de 32 couleurs, la résolution logique 640×360, les sprites 32×32 limités à 16 couleurs, et le livrable PNG + source Aseprite décrits dans l’Art Bible.
- Refaire tous les assets graphiques et audio ainsi que l’interface, en conservant les fonctionnalités/parcours validés sauf les deux pages explicitement étendues.
- Musique arcade synthwave néon sur une base EDM, intensité liée à la progression du jeu, transitions musicales fluides plutôt qu’un changement brutal au spawn d’un boss.
- Équipement : six emplacements, aperçu des statistiques modifiées avant confirmation de l’équipement.
- Architecture Sandbox-first et séparation stricte du Sandbox et de la progression normale.

## Points ouverts à préserver dans les specs

- L’Art Bible laisse ouverts plusieurs détails du héros, des boss, du biome, des timings d’animation, des pivots et des conventions de métadonnées.
- Le graphe complet et les règles du skill tree ne sont pas définis par le seul objectif GDD de 120 nœuds ; ne pas inventer silencieusement son contenu ni ses effets.
- Vérifier les contrats existants d’équipement et de calcul de statistiques avant de définir les changements requis.
- La méthode de transition audio (couches, stems, snapshots, ou autre) et les seuils de progression restent des choix de conception technique à préciser dans la spec, sans imposer un changement de morceau au spawn d’un boss.
- Le périmètre des assets protégés par des licences tierces et les exigences de livraison des sources audio devront être inventoriés avant suppression/remplacement.
