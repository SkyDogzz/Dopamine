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
| `asset-pipeline` | **EN COURS** | Snapshot initial conservé; registre courant 258 fichiers hors `.import`, dont 148 assets créatifs tracés. 107 exports graphiques hash-identiques ont été remplacés; zéro hash initial ne demeure, 417 entrées créatives sont migrées/retirées. Les 137 chemins actifs sont présents au PCK de contrôle. Le staging Release propre courant `714d35c` s’extrait et démarre avec sa GDExtension adjacente; il reste non distribuable. Restent la revue physique/UI exhaustive, l’écoute et le paquet distribuable après acceptation. |
| `visual-assets` | **EN COURS** | Skyline, joueur, neuf rôles communs/supports, 24 projectiles, coffre/orbe XP, icônes UI/catalogue, sol/ruines, élite, prototypes boss génériques, VFX et deux fontes originales ont des sources éditables. Exports racine hérités et recettes par référence retirés après vérification des consommateurs. Les références actives sont présentes dans le PCK de contrôle; le staging Release `714d35c` se lance. Identités boss/biome restent ouvertes, revue complète écran par écran et GPU réelle restent à faire. |
| `interface-overhaul` | **EN COURS** | Fondations, accueil, options, hub, vues Survival/Sandbox et parcours existants ont des smokes ciblés; captures des écrans principaux et états secondaires consignées. Le Sandbox Lab a un fond Neon uniforme, une page défilante à 640×360 et sa session cachée n’expose ni HUD, caméra ni service de progression au viewport global. L’utilisateur confirme la lisibilité hub/équipement à 640×360. La revue exhaustive des états/focus, les contrôles matériels et le choix final des fontes restent ouverts; l’isolation Sandbox est couverte avec profil temporaire isolé. |
| `skill-tree` | **TRANCHE LIVRÉE — CAPACITÉ EN COURS** | Graphe navigable montrant 100 définitions runtime et leurs vrais prérequis; contenu, coûts et effets proposés ne sont pas validés. Commit `15a9071`. |
| `equipment-screen` | **TRANCHE LIVRÉE — CAPACITÉ EN COURS** | Six slots, filtre, bonus avant/après et actions existantes conservées; états sans pièce compatible et échec réel d’action capturés. Overlay du personnage et formules proposées restent ouverts. Commit initial `5eadb12`; couverture d’état ajoutée dans la tranche courante. |
| `adaptive-audio` | **EN COURS** | 38 SFX branchés sur 19 familles; cinq stems originaux synchronisés suivent les vagues et ajoutent le stem boss par fondu sans redémarrage. Capture numérique du bus Master en runtime ajoutée, sans écrêtage mesuré; extrait de transition aussi prêt pour écoute locale. Mix/gains **[PROPOSÉS]**; revue auditive humaine et en jeu **[OUVERTE]** faute de sortie locale. |

### Mise à jour des preuves UI (2026-10-18)

- **[VALIDÉ — ÉQUIPEMENT]** La confirmation de vente système grise est remplacée par un overlay Neon; l’annulation et l’absence de mutation avant confirmation sont testées. Capture indexée dans `docs/art/evidence/2026-10-18/README.md`, commit `cfe4e51`.
- **[VALIDÉ — SKILL TREE]** Libellés de nœuds agrandis à 9 px et boutons à 82 px; capture 640×360 actualisée. Les 100 nœuds restent dérivés des données existantes; la lisibilité universelle n’est pas encore validée, commit `64d5c91`.
- **[VALIDÉ — TESTS]** CTest complet après les deux tranches : 118/118, résultat détaillé dans `docs/qa/TESTS.md`.
- **[OUVERT]** Revue matérielle exhaustive, contrôles physiques et écoute audio en jeu; ces preuves virtualisées ne les remplacent pas.

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
