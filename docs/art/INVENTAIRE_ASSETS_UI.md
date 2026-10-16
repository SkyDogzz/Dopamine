# Inventaire des assets visuels et de l’UI

**Statut :** inventaire de travail fondé sur le contenu présent dans le dépôt, établi le 2026-10-16. L’intention de recréer tout le catalogue visuel et de refaire toutes les interfaces selon [`ART_BIBLE.txt`](../ART_BIBLE.txt) a été confirmée par l’utilisateur. Ce document recense le travail; il ne constitue pas une validation des propositions visuelles encore ouvertes.

## Portée et règles

- Recréer les assets visuels actuellement utilisés, même lorsqu’ils semblent déjà proches de la direction retenue, et combler les manques du contenu effectivement présent dans le jeu.
- Couvrir tout le catalogue des 10 armes et 11 reliques, indépendamment de leur disponibilité actuelle en Survival.
- Refaire visuellement toutes les interfaces existantes et les rendre conformes à l’Art Bible sans modifier leurs comportements validés.
- Garder le rôle du héros cyan, mais redessiner sa silhouette en personnage top-down chibi.
- Garder l’isolation stricte du Sandbox et ne pas inventer d’écrans fonctionnels pour Succès ou Bestiaire, qui restent inactifs selon l’interview UI précédente.
- Pour les sprites, livrer PNG et source Aseprite. Le lot pilote produit une source éditable pour le héros, le chaser et Lightning Conductor. Le lot catalogue ajoute 10 icônes d’armes, 10 variantes d’évolution et 11 icônes de reliques avec leurs sources.
- Distinguer **[VALIDÉ]**, **[PROPOSÉ]** et **[OUVERT]** comme dans la Bible et le GDD. Une case vide ou une convention habituelle ne vaut pas décision.

## Référence technique importante

La résolution logique **640×360 est [VALIDÉE]** dans l’Art Bible et le projet l’utilise maintenant avec une fenêtre par défaut de 1280×720, étirée en viewport à échelle entière. Les principaux contrôles des interfaces d’accueil, préparation et Survival sont couverts par `game/tests/ui_viewport_layout_smoke.gd` aux tailles 640×360, 1280×720 et 1920×1080. Cette vérification de géométrie ne remplace pas la revue visuelle finale de chaque écran ni un parcours matériel souris/clavier/manette.

## État présent du dépôt

Les nouveaux exports comprennent `sprites/catalog/` (10 armes, 10 évolutions, 11 reliques), `icons/catalog/` (16 icônes UI), `sprites/roster/` (9 ennemis, élite prototype, 2 boss abstraits), `sprites/vfx/` (10 impacts), `sprites/projectiles/` (24 projectiles), `sprites/rewards/` (coffre et orbe XP), un candidat de sol 256×256 limité à la palette maître et un overlay de ruines pixel art 1536×1536. Les icônes font 32×32, les projectiles et l’orbe XP 16×16, les ennemis 24×24, le coffre 32×32, les boss 96×96 et les impacts 64×64; les PNG possèdent chacun une source Aseprite. Les sprites de jeu respectent leur plafond de palette; le sol utilise les 32 couleurs maître. Le script `game/tools/build_catalog_icon_assets.gd` exporte ces lots depuis les planches source. Le catalogue est branché aux coffres, HUD, inventaires, résultats de run, équipement permanent, aperçus ennemis et rendu Survival.

La plupart des PNG historiques découpés ont 64×64 px. Le héros pilote est maintenant 32×32, le chaser 24×24 et le projectile Lightning Conductor 16×16; aucune animation n’est incluse. Les autres images restent un mélange de sprites issus d’atlas, d’illustrations SVG et d’icônes.

### Sprites de jeu existants

| Groupe | Fichiers actuels | Ce qui manque ou doit être repris |
|---|---|---|
| Héros | `player_idle.png` et `player_walk.png` (128×128 chacun, quatre frames 32×32 par direction), sources dans `source/pilot/` | Les deux feuilles sont intégrées au contrôleur visuel du joueur. L’ordre des lignes Haut/Bas/Gauche/Droite est encore **[OUVERT]** dans la Bible; cette implémentation utilise Bas/Gauche/Droite/Haut **[PROPOSÉ]**. Les cadences idle 3 fps et marche 8 fps sont également **[PROPOSÉES]**. `player_cyan.png` reste une image de référence statique. Les détails de tenue additionnels restent **[OUVERTS]**. |
| Ennemis communs et supports | `sprites/roster/enemy_*.png` (9 designs, 24×24) et sources dans `source/roster/` | Silhouettes statiques pixel art intégrées au rendu Survival et Sandbox. Les animations restent **[OUVERTES]** (nombre de frames non défini par la Bible). |
| Élites | `sprites/roster/elite_sprinter.png` (24×24 prototype); sources dans `source/roster/` | Un prototype dédié présente la silhouette sprinter avec symbole et aura tracés. Le renderer Survival conserve son feedback d’élite existant séparé, sans changement de statut ou règle de combat. |
| Boss | `sprites/roster/boss_mid_placeholder.png`, `boss_final_placeholder.png` (96×96) et sources dans `source/roster/` | Deux prototypes abstraits remplacent les sprites placeholder actifs. Ils ne fixent ni identité canonique ni pattern de combat, encore **[OUVERTS]**. |
| Projectiles | `sprites/projectiles/` (24 sprites 16×16, sources Aseprite dans `source/projectiles/`) | Silhouettes pixel art distinctes pour les projectiles de base, formes évoluées, projectile ennemi et effets de projectile déjà présents. Le renderer route les évolutions vers leur sprite dédié et dessine sous les sprites une courte traînée cyan/bleu nuit pour les projectiles mobiles. Sa longueur de 12 px et le plafond de 256 traînées simultanées sont **[PROPOSÉS]**. Les projectiles beam continus, explosions et chronologies restent à vérifier/produire selon les comportements existants; aucun nouvel effet de combat n’est introduit. |
| Récompenses en run | `sprites/rewards/xp_orb.png` (16×16), `chest_closed.png` (32×32), sources Aseprite dans `source/rewards/` | Orbe XP et coffre pixel art dédiés intégrés au renderer existant. Les frames d’ouverture et animations de récompense restent à produire si elles sont déjà requises par le comportement validé; les autres catégories de pickups ne sont pas implémentées et ne sont pas à inventer. |
| Icônes catalogue | `sprites/catalog/weapon_*.png`, `evolution_*.png`, `relic_*.png` (10 armes, 10 évolutions, 11 reliques; sources dans `source/catalog_weapons/` et `source/catalog_relics/`) | Première série homogène livrée et branchée à la présentation. Les dessins restent des prototypes raster issus d’une référence générée; la finition artistique et les animations complètes restent à produire. |
| Terrain de l’arène actuelle | `sprites/environment/survival_ground_pixel.png` (256×256) actif, source `source/environment/survival_ground_pixel.aseprite`; overlay actif `sprites/environment/survival_ruins_pixel.png` (1536×1536), source Aseprite dans `source/environment/` | Le nouveau sol répétable utilise six couleurs de la palette maître et reste volontairement discret. Le candidat moss/stone plus chargé et `survival_ground.svg` sont désormais des références inactives. Les ruines pixel art restent un décor sans collision. Le premier biome officiel et sa palette secondaire restent **[OUVERTS]**. |
| Impacts et combat VFX | `weapon_impacts_pixel.png` (atlas horizontal de 10 cellules 64×64; sources individuelles dans `source/vfx/`) et pixels de mort dessinés dynamiquement | Dix silhouettes d’impact sont intégrées à la scène pour les événements d’arme existants. Les morts d’ennemis émettent maintenant huit petits pixels de la palette maître; leur cadence de disparition (0,32 s) et ce nombre sont **[PROPOSÉS]**. L’ancien SVG reste comme référence. Les traînées supplémentaires et feedbacks animés de récompense/évolution restent à reprendre. Répartition élément/couleur, plafonds VFX et autres timings détaillés restent **[OUVERTS]**. |
| Atlases actuels | `dopamine_atlas_source.png` (sprites), `progression_atlas_source.png` (icônes) | Sources aplaties de découpe 4×4, sans couches ni fichiers Aseprite. À remplacer par sources éditables rangées par famille/animation; le script actuel `game/tools/slice_sprite_atlas.gd` n’établit pas une convention d’animation validée. |

### Catalogue à illustrer

Le catalogue actif est défini dans `game/data/combat_catalog.json` :

| Arme | Relique associée | Évolution |
|---|---|---|
| Lightning Conductor | Storm Core | Infinite Circuit |
| Inferno Sprayer | Infernal Heart | Wildfire |
| Crimson Daggers | Blood Chalice | Bloodstorm |
| Void Orb | Singularity | Event Horizon |
| Frost Nova | Frozen Crown | Absolute Zero |
| Minigun | Overdrive Engine | Redline |
| Meteor Staff | Celestial Eye | Starfall |
| Sawblades | Magnetic Coil | Razorstorm |
| Toxic Cloud | Plague Mask | Pandemic |
| Prism Laser | Prism Crystal | Spectrum Collapse |

**Assets de catalogue livrés :** 10 icônes dédiées d’armes, 10 icônes transformées pour leurs évolutions, 11 icônes de reliques et 24 sprites de projectiles. Les autres effets associés aux projectiles restent à reprendre. Magnet Heart n’a pas d’arme associée ni d’évolution. Les chiffres de puissance/couleur ou tout effet proposé ne doivent pas guider les dessins comme s’ils étaient validés.

### Icônes UI et polices existantes

| Fichiers actuels | Cible de l’inventaire |
|---|---|
| `icons/catalog/equipment_*.png` (6), sources dans `source/catalog_ui/` | Set homogène des 6 emplacements d’équipement livré et utilisé dans l’inventaire permanent. |
| `icons/catalog/rarity_*.png` (5), sources dans `source/catalog_ui/` | Marqueurs distincts des 5 raretés livrés et utilisés dans les écrans équipement/récompense. |
| `icons/catalog/resource_*.png`, `skill_node.png`, `achievement_medal.png`, `run_record.png` (5) | Icônes livrées. Les deux ressources sont utilisées; les marqueurs de compétence, médaille et record n’ajoutent aucun comportement/fonctionnalité. |
| `icons/ui/signal_prism.png` (32×32), source Aseprite `source/ui/signal_prism.aseprite`, référence générée `docs/art/source/signal_prism_generated.png` | Emblème de menu compact, transparent, 16 couleurs de la palette maître et filtrage nearest. Le symbole Signal Prism est **[PROPOSÉ]**; il accompagne le titre textuel sans le remplacer. `tools/process_signal_prism.gd` reproduit l’export. |
| `PressStart2P-Regular.ttf`, `DejaVuSans.ttf` et licences associées | Les titres d’écran, sections et sections de l’inventaire de run utilisent maintenant la variation `PixelHeading`; les descriptions restent dans la fonte moderne. L’association actuelle de `PixelHeading` à Press Start 2P est **[PROPOSÉE]**; la fonte exacte reste **[OUVERTE]** dans l’Art Bible. |
| `game/assets/backgrounds/title_skyline.png` (640×360), source Aseprite éditable dans `game/assets/source/backgrounds/` et source générée `docs/art/source/title_skyline_generated.png` | Le fond conserve sa composition et ses 30 couleurs de la palette maître; le script de traitement exporte une source Aseprite mono-calque. La composition d’accueil a été revue à 640×360 avec trois enseignes animées par `title_skyline_lights.gd`; leurs rythmes sont **[PROPOSÉS]**. |

Manques visibles : pas d’écran ou de jeu d’icônes Succès/Bestiaire (leurs entrées restent volontairement inactives). L’accueil conserve le titre textuel avec un emblème Signal Prism **[PROPOSÉ]**. Le fond skyline possède sa source Aseprite éditable dans `game/assets/source/backgrounds/title_skyline.aseprite`; trois enseignes clignotent maintenant par-dessus le décor via `game/scripts/title_skyline_lights.gd`. Leurs périodes de 1,4 à 2,2 s sont **[PROPOSÉES]**; le rythme exact demeure **[OUVERT]**. Les réglages, le volume, le plein écran, le focus et les états interactifs relèvent principalement de l’UI vectorielle/nodale et du Theme, pas d’une série de sprites à générer.

## Interfaces à refaire

L’UI actuelle se partage entre le Theme `game/themes/dopamine_ui.tres`, des scènes `.tscn` et des contrôles construits dans les scripts. La liste couvre les scènes réellement utilisées; `ui_foundation_preview.tscn` est un outil de prévisualisation/test et non un écran de jeu.

| Écran / scène | État visuel actuel | Travail UI à inventorier et refaire |
|---|---|---|
| Accueil — `launch_menu.tscn` | Carte opaque, titre pixel et emblème Signal Prism, boutons; skyline intégrée récemment | Poursuivre l’affinage de l’identité et des états hover/press/focus au viewport 640×360. La présence et la forme de l’emblème restent **[PROPOSÉES]**. |
| Options — `options_panel.tscn` | Carte compacte; toggle plein écran et slider volume thème néon, curseur rond 12×12 pixel-grid; focus clavier/manette du slider avec le cadre doré partagé | Poursuivre la vérification des états interactifs et des layouts; réglages plein écran/volume et parcours restent inchangés. La couleur cyan d’activation, la teinte désactivée et la couleur dorée de focus sont **[PROPOSÉES]**. |
| Hub Survival — `survival_hub.tscn` | Difficultés et actions permanentes dans deux colonnes; Succès/Bestiaire ont un style atténué dédié, conservent un focus visible et restent sans action | Affiner le layout compact responsive, boutons de difficulté, équipements/skills et CTA de run. |
| Équipement — `equipment_inventory_panel.tscn` | Panneau 460×300 adapté à 640×360; cartes opaques à bordure teintée par rareté; états vide/erreur centrés et texte 10 px; effets uniques affichés comme noms lisibles plutôt que comme identifiants techniques | Poursuivre la finition des lignes, états et navigation sans changer le service. Bordure de rareté et texte d’état 10 px **[PROPOSÉS]**. |
| Arbre de compétences — `skill_tree_panel.tscn` | Cadre 420×210 adapté à 640×360; les deux nœuds prototypes sont distingués comme fondation et suivi, avec coûts/effets visibles | Affiner le cadre et les éléments qui existent. Les étiquettes Foundation/Follow-up sont **[PROPOSÉES]**. Ne pas créer le graphe complet ni ses règles à partir du seul objectif futur de 120 nœuds du GDD. |
| HUD Survival — `survival_session.tscn` + `survival_session.gd` | Deux cartes de coin : HP/XP/armes à gauche, temps/vague/difficulté/état à droite; HP et XP ont chacun une ligne et une barre dédiée; barre de boss centrée et conditionnelle; les noms d’armes restent sur la rangée de loadout | Poursuivre l’affinage visuel des données compactes sans changer les règles. Le découpage en coins suit la direction **[VALIDÉE]** du HUD minimal; dimensions et répartition des métadonnées sont **[PROPOSÉES]**. Capture inspectée à 640×360 logique; bounds automatisés jusqu’à 1920×1080. |
| Choix de coffre — `chest_choice.tscn` | Modal compact de trois cartes, icônes à leur taille native, descriptions et focus visible; titre cyan pour les armes, magenta pour les reliques | Affiner le modal, descriptions, rareté et focus; simulation gelée conservée. Le code couleur par famille est **[PROPOSÉ]**. Le smoke `survival_chest_layout_smoke.gd` contrôle les bornes 640×360, 1280×720 et 1920×1080 avec une description de prochain niveau longue. |
| Pause — `pause_menu.tscn` | Carte 250 px, statut « simulation gelée », vitesse séparée des actions; confirmation d’abandon 280 px au premier plan | Poursuivre la finition des états et transitions. Les libellés de statut/vitesse sont **[PROPOSÉS]**; pause stricte et parcours restent inchangés. |
| Inventaire de run — `run_inventory_panel.tscn` | Cadre 420×300 avec zone défilante de 200 px; liste en lecture seule, totaux visibles, icônes catalogue nearest; focus doré et défilement vers l’item sélectionné | Poursuivre l’affinage des lignes d’arme/relique sans ajouter de commandes de mutation. Équipement permanent reste non modifiable pendant la run. Dimensions du cadre et de la liste **[PROPOSÉES]**; smoke passé sur focus clavier et défilement automatique. |
| Résultat — `run_result_panel.tscn` | Carte 360×240; victoire/défaite, résumé, ressources et icônes 24×24, équipement, puis relancer/quitter | Poursuivre l’affinage des raretés et récompenses sans créer de système de succès. Dimensions de carte et d’icônes **[PROPOSÉES]**; parcours de reprise et de retour conservé. |
| Sandbox développeur — `main.tscn` + `main.gd` | Poste de test dense : simulation, métriques, spawn, tuning, inspecteur, événements | Refaire panneaux et contrôles pour lisibilité; conserver spawn, pause/step/vitesse, sélection, tuning et métriques. Aucune référence à SaveService/progression. |

Composants globaux : fond, cartes opaques à bordure, boutons rectangulaires, champs/toggles/sliders, barres HP/XP/boss et de défilement, badges d’état, focus visible et transitions pixel rapides. Les scrollbars du Theme partagé reprennent la piste bleu nuit, la poignée bleu ardoise bordée cyan, le survol cyan, l’appui et le focus jaunes; ces états précis restent **[PROPOSÉS]**. Le glow doit rester rendu dynamiquement dans les VFX/états UI, jamais précuit dans les sprites.

## Cible de production ordonnée

1. **Filière visuelle et audit de conformité** — couleur, contour, nearest, sources Aseprite, métadonnées, contrôles palette/dimensions; décider explicitement les inconnues bloquant la production.
2. **Scène complète représentative** — joueur, terrain courant, XP/coffre, ennemis et projectiles, impacts/télégraphes, HUD/coffre/pause; vérifier la lisibilité en combat chargé.
3. **Roster complet** — 9 ennemis communs/supports, élites, 2 boss, ennemis projectiles et leurs besoins d’animation.
4. **Catalogue complet** — 10 armes et leurs évolutions visuelles, projectiles, 11 reliques, 10 icônes dédiées, impacts associés.
5. **Environnement, pickups et récompenses** — tiles 16×16, ruines/props de faible contraste, objets existants et animation de récompense.
6. **Icônes UI** — 6 slots, 5 raretés, 2 ressources, skill/achievement/record, identité des armes et reliques.
7. **Refonte complète UI** — foundation et Theme, puis accueil/options/hub, overlays Survival, Sandbox; toutes les vues et parcours au viewport cible avant activation globale.

La séquence est une proposition d’exécution (**[PROPOSÉ]**), pas une modification de priorité acceptée du roadmap. Les fonctionnalités Succès, Bestiaire et Sandbox Lab joueur ne font pas partie de la production d’assets de cette passe tant qu’elles ne sont pas implémentées.

## Points ouverts à garder visibles

- **[OUVERT]** Ordre des directions sur les sheets, pivots/ancrages et padding; durées et frames des animations hors joueur.
- **[OUVERT]** Tenue/détails du héros cyan au-delà du rôle et de la couleur confirmés.
- **[OUVERT]** Identités et patterns complets des boss; conserver les prototypes et ne pas transformer les paramètres de combat **[PROPOSÉS]** en brief visuel définitif.
- **[OUVERT]** Premier biome canonique et palettes secondaires; l’arène moss/ruins actuelle est seulement une référence de prototype.
- **[OUVERT]** Correspondance éléments/couleurs, plafonds/paramètres VFX, rareté des animations et exigences de réduction des flashes.
- **[OUVERT]** Choix final des fontes, tailles de texte/boutons et wireframes détaillés au-delà de la priorité de lisibilité.
- **[OUVERT]** Structure de sources Aseprite (.ase ou .aseprite) et métadonnées d’export. Le livrable PNG + source Aseprite, lui, est **[VALIDÉ]**.
- **[OUVERT]** Comportement du viewport 640×360 sur formats différents et politique d’upscale; le format logique 16:9 reste **[VALIDÉ]**.

## Vérification attendue lors de la production

- Chaque sprite a sa source éditable et son PNG exporté; vérifier dimensions, transparence, nombre et appartenance des couleurs, contour net et absence de glow précuit.
- Les sprites 32×32 restent à 16 couleurs distinctes maximum. Les exceptions de palette sont documentées.
- Les tiles respectent 16×16; le joueur respecte 32×32; les boss suivent le standard 96×96.
- Chaque scène UI est parcourue à la souris, au clavier et à la manette avec focus visible; bounds et lisibilité vérifiés à 640×360 et à l’upscale cible. Le smoke actuel contrôle les bornes, pas tous les états visuels ni le matériel physique.
- Revoir les assets en situation de combat dense et confirmer que dangers, projectiles, ennemis et objets restent séparables.
- Les smokes visuels ne valident ni une manette physique ni la direction artistique; conserver une revue visuelle explicite.
