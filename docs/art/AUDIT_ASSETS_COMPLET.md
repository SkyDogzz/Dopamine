# Audit complet des assets avant remplacement

Date de l'audit initial : 2026-10-18  
Statut : inventaire initial; aucune migration ni suppression effectuée.

## Portée et règle de remplacement

Cette initiative remplace les assets visuels et audio actuellement employés par le jeu et refait son interface. Consigne utilisateur supplémentaire : **aucun asset existant ne doit être réutilisé**. Cette règle couvre les exports actifs et les dépendances importées dans le produit (sprites, fonds, icônes, polices, musique et SFX). Les sources d'édition et références historiques sont inventorées séparément; leur conservation dans le dépôt ne signifie pas qu'elles seront embarquées ou réutilisées. Aucun fichier ne sera supprimé avant migration et contrôle de références.

L'inventaire recense les fichiers sous `game/assets/`, les références Godot dans scènes/scripts/données/thèmes, et les lecteurs audio. Le statut de provenance n'est pas une licence : les droits d'usage sont notés selon la documentation existante et doivent rester traçables pour chaque nouvel asset.

## Comptage initial

Comptage obtenu par `rg --files game/assets` au 2026-10-18; les fichiers `.import` Godot sont exclus des nombres de contenus.

| Groupe | Quantité constatée | Sources / provenance connues | Décision pour cette initiative |
|---|---:|---|---|
| Exports visuels PNG/SVG sous `game/assets` | 165 fichiers | Le registre [`PROVENANCE_ASSETS.csv`](PROVENANCE_ASSETS.csv) suit les hash et la provenance de 165 PNG/SVG livrables; les correspondances source/export ne sont pas toutes des preuves. | Remplacer tous les visuels actifs; examiner les visuels inactifs et les références avant exclusion/suppression. Aucun export actuel ne sera réutilisé. |
| Audio runtime | 39 fichiers : 1 OGG, 38 WAV | Musique Space City CC0; SFX générés depuis recettes versionnées via Bfxr2 CLI MIT. Notices dans `THIRD_PARTY_NOTICES.md`, `game/assets/audio/sfx/README.md`, `recipes.json` et `manifest.json`. | Remplacer tous les fichiers audio actifs et ne pas réutiliser les recettes comme source de composition finale. Garder les outils historiques hors du runtime selon décision. |
| Sources et références sous `game/assets/source/` | 212 fichiers non `.import` (dont Aseprite et planches/références PNG) | Plusieurs sources éditables Aseprite; certaines dérivent de références générées, d'autres sont procédurales. Registre détaillé des exports visuels dans `PROVENANCE_ASSETS.csv`; le lien par nom seul n'est pas une preuve. | Ne pas utiliser les sources existantes pour fabriquer les remplacements. Conserver en archives d'audit ou retirer après confirmation de leur statut et vérification qu'aucun outil/document actif ne les requiert. |
| Polices runtime | 2 polices : Press Start 2P, DejaVu Sans | Licences OFL 1.1 et Bitstream Vera/DejaVu détaillées dans `THIRD_PARTY_NOTICES.md`. | Remplacer si la consigne « tous les assets » inclut les polices; choisir des remplaçantes avec licences documentées. |
| Fichiers annexes audio | README, manifest, recettes JSON, galerie HTML et générateurs Python/JS | Sources de synthèse et notice MIT de Bfxr2 CLI déjà documentées. | Laisser hors runtime; archiver ou remplacer leur statut documentaire après migration. Ne pas les compter comme assets joués. |

Les 165 visuels comprennent exports utilisés et fichiers historiques/inactifs. Le PCK audité précédemment excluait certains doublons/références inactifs, mais les presets utilisent `all_resources`; tout export restant dans un dossier inclus peut donc être empaqueté. Un contrôle PCK doit être refait après migration.

## Références runtime explicites relevées

| Famille | Références connues | Consommateurs / rôle |
|---|---|---|
| Joueur | `sprites/player_idle.png`, `sprites/player_walk.png`; `player_cyan.png` est une référence supplémentaire | `player.tscn`, `player_controller.gd`; feuilles dans le rendu Survival/Sandbox. |
| Ennemis et boss | `sprites/roster/*.png`; quelques anciens `sprites/enemy_*.png`/`.svg` et placeholders | `sprite_batch_renderer.gd`, aperçu du hub, Sandbox et données de combat. Boss canoniques et premier biome restent ouverts; garder les prototypes de rôle jusqu'à décision. |
| Armes, reliques, évolutions | `sprites/catalog/weapon_*.png`, `relic_*.png`, `evolution_*.png` | `survival_session.gd`, `survival_loadout.gd`, `run_stat_hub.gd`, coffre, inventaire et résultats. Le catalogue actif est `game/data/combat_catalog.json`. |
| Projectiles, impacts, VFX | `sprites/projectiles/*.png`, `sprites/vfx/*.png`, `weapon_impacts_pixel.png`; anciennes variantes PNG/SVG | `sprite_batch_renderer.gd`, `survival_session.gd`, familles d'armes et événements de combat. |
| Terrain et récompenses | `environment/survival_ground_tile.png`, `survival_ruins_pixel.png`, `rewards/chest_closed.png`, `rewards/xp_orb.png` | Rendu Survival et parcours de récompense. Identité officielle de biome ouverte. |
| Accueil | `backgrounds/title_skyline.png`, `icons/ui/signal_prism.png` | `launch_menu.tscn`; ambiance validée, emblème exact proposé. |
| Icônes UI/catalogue | `icons/catalog/equipment_*.png`, `rarity_*.png`, ressources, skill node, médaille, records | Hub, skill tree, équipement, statistiques, résultats. Certains sont seulement des pictogrammes sur des entrées inactives. |
| Polices et thème | `fonts/PressStart2P-Regular.ttf`, `fonts/DejaVuSans.ttf`; `themes/dopamine_ui.tres` | Thème UI, titres et affichage de dégâts. Fonte exacte pixel encore ouverte dans l'Art Bible. |
| Musique | `audio/music/space_city_bpm115.ogg` | `adaptive_survival_music.gd`; boucle active. |
| SFX | 38 WAV sous `audio/sfx/` : tirs, zaps, balayages, impacts légers/lourds, morts, XP, relique, coffres, niveau, boss, interface | `sfx_service.gd`; inventaire exact des identifiants et mesures dans `manifest.json`. |

## État de provenance et licences

- Les exports PNG/SVG ont une provenance technique consignée dans `PROVENANCE_ASSETS.csv`; l'inventaire précédent indiquait 43 actifs dérivés de références C2PA Trusted et 59 générés par le dépôt. Cette initiative les remplace tous selon la consigne utilisateur, y compris les assets procéduraux internes.
- La musique actuelle est identifiée comme Space City de MintoDog sous CC0. Ce statut documente l'existant mais ne l'autorise pas à être réutilisé dans les nouveaux livrables.
- Les SFX actuels ont des recettes de paramètres éditables et reproductibles; l'outil auteur externe est MIT. Les SFX ne contiennent pas d'échantillons tiers identifiés selon la documentation. Leur rendu et leurs recettes ne seront pas utilisés comme éléments de composition des nouveaux sons.
- Les polices sont sous OFL et Bitstream Vera/DejaVu. À remplacer si incluses dans la portée intégrale demandée.
- Les fichiers Aseprite et références non listés comme livrables dans le registre de provenance nécessitent encore un inventaire individuel de liens, hashes, créateur et statut actif/inactif avant toute suppression définitive.

## Méthode pour compléter les références

1. Les références statiques sont recherchées dans `game/scenes/`, `game/scripts/`, `game/data/`, `game/themes/`, `game/project.godot` et les fichiers `.import`.
2. Les références construites dynamiquement doivent être suivies depuis leurs fonctions de chargement (notamment `sprite_batch_renderer.gd`, `sfx_service.gd`, `run_result_panel.gd` et les catalogues JSON).
3. Les usages de production dans les scripts d'export/génération sont distincts des références runtime et doivent être maintenus jusqu'à ce que leurs nouveaux remplaçants soient disponibles.
4. Avant retrait d'un fichier : recherche plein dépôt du chemin/ID, import Godot, smoke ciblé du parcours consommateur, export PCK/scan, puis mise à jour du registre et de l'inventaire.

## Dépendances de design à préserver

- Le contenu des 100 nœuds et leurs effets/coûts sont **[PROPOSÉS]** dans `progression_service.gd`; seule la cible de 100 nœuds au lancement est **[VALIDÉE]**. L'arbre peut être affiché à partir des données implémentées sans inventer leur sens. Si une nouvelle définition de contenu est nécessaire, demander une validation précise.
- L'identité canonique des boss et du premier biome reste **[OUVERTE]**. Remplacer les assets à rôle égal sans fabriquer une identité de lore ou de mécanique.
- La police exacte reste **[OUVERTE]**. La spécification audio laisse ouverts le format source/runtime, l'outil et la méthode d'arrangement adaptatif; la licence et l'inventaire des assets existants, eux, sont maintenant relevés ci-dessus.
- Garder les parcours validés et le Sandbox isolé de toute progression/sauvegarde normale pendant chaque tranche.

## Étape suivante

La capacité `asset-pipeline` commence ici. Avant production de remplacement audio et choix de police, arbitrer le mode de production/licence voulu. Une tranche ultérieure devra migrer les assets visuels à partir d'une direction compatible avec la Bible, vérifier chaque famille en scène, puis remplacer les fichiers audio et écouter les transitions dans une run réelle. Aucun asset n'est déclaré remplacé par ce document seul.
