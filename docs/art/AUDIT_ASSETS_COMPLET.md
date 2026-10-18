# Audit complet des assets avant remplacement

Date de l'audit de base : 2026-10-18
Statut : le registre initial de 425 fichiers reste le snapshot historique avant purge. **État courant au 2026-10-18 :** 356 assets créatifs sont régénérés par les cinq skills locaux et intégrés provisoirement; la revue perceptuelle reste ouverte. Le checkpoint QA courant est [`AUDIT_REMPLACEMENTS_ASSETS.md`](AUDIT_REMPLACEMENTS_ASSETS.md). Voir aussi `ASSET_MANIFEST.json`, `ASSET_GENERATION_REPORT.json` et `INVENTAIRE_ASSETS_UI.md`.

## Portée et règle de remplacement

Cette initiative remplace les assets visuels et audio actuellement employés par le jeu et refait son interface. Consigne utilisateur supplémentaire : **aucun asset existant ne doit être réutilisé**. Cette règle couvre les exports actifs et les dépendances importées dans le produit (sprites, fonds, icônes, polices, musique et SFX). L'utilisateur a aussi confirmé la suppression des anciennes sources Aseprite, recettes et références après migration. Aucun de ces fichiers ne sera supprimé avant migration et contrôle de références.

L'inventaire recense les fichiers sous `game/assets/`, les références Godot dans scènes/scripts/données/thèmes, et les lecteurs audio. Le statut de provenance n'est pas une licence : les droits d'usage sont notés selon la documentation existante et doivent rester traçables pour chaque nouvel asset.

## Comptage initial

Comptage de base vérifié au 2026-10-18. Le snapshot initial immuable est [`ASSET_FILE_REGISTER.csv`](ASSET_FILE_REGISTER.csv) (425 fichiers hors `.import`). Le relevé de 258 fichiers décrit un checkpoint historique antérieur à la reconstruction finale. Le registre courant [`ASSET_FILE_REGISTER_CURRENT.csv`](ASSET_FILE_REGISTER_CURRENT.csv) recense 1 424 fichiers sous `game/assets`, dont 356 exports créatifs (221 PNG, deux TTF et 133 WAV) avec hashes/références; les sources et sidecars figurent aussi au registre. `PROVENANCE_ASSETS.csv` contient 356 entrées créatives courantes. Le contrôle `game/tools/validate_no_legacy_asset_hash_reuse.py` compare les contenus courants au snapshot immuable; migrations et retraits sont consignés dans les CSV dédiés.

Au checkpoint historique `4e9e822`, le registre séparait **64 chemins statiques** et **73 chargements dynamiques** observés dans le runtime; les 137 chemins avaient été retrouvés dans le PCK de contrôle. Après reconstruction, 356 IDs du manifeste sont intégrés et les contrôles de hashes, sources et couverture passent; l’import Godot 4.7.2 et CTest 121/121 ont été réexécutés pour ce checkpoint. Les chemins et états actuels sont dans les registres courants et le rapport de génération; les sources éditables restent exclues du PCK runtime.

| Groupe | Quantité constatée | Sources / provenance connues | Décision pour cette initiative |
|---|---:|---|---|
| Exports créatifs courants | 221 PNG + 2 TTF + 133 WAV | `PROVENANCE_ASSETS.csv` et `ASSET_FILE_REGISTER_CURRENT.csv` consignent les hashes, sources et références; `validate_asset_provenance_registry.py` vérifie les hashes, sources et manifests. La lisibilité du hub/équipement est confirmée à 640×360; le choix global des fontes reste ouvert. | Aucun hash courant ne correspond au snapshot initial. Audio reste à écouter; revue matérielle reste ouverte. |
| Audio sous `game/assets/audio/` **[SNAPSHOT INITIAL — 2026-10-18]** | 43 fichiers : 1 OGG, 38 WAV et 4 annexes SFX. | Le morceau Space City était CC0; les SFX venaient de recettes Bfxr. | Snapshot historique immuable; voir l’état courant ci-dessous et `ASSET_MIGRATIONS.csv` / `ASSET_RETIREMENTS.csv`. |
| Sources et références sous `game/assets/source/` | 105 fichiers courants : 102 Aseprite, 2 SFD, 1 README; snapshot initial : 212 | Les sources courantes sont liées par hash aux 102 PNG et aux deux fontes; `validate_asset_provenance_registry.py` vérifie leur présence et hashes. | Les 417 entrées créatives initiales ont une migration ou un retrait enregistré; aucun ancien source pixel n’est conservé dans le tree courant.
| Polices sous `game/assets/fonts/` | Snapshot initial : 2 polices + 2 notices; état courant : 2 fontes TTF originales. | Glyphes dessinés en grilles dans `generate_original_fonts.py`; sources FontForge `.sfd` conservées sous `source/original_procedural/fonts/`. | Anciennes fontes/notices supprimées après migration et recherche de références; nouvelles fontes **[PROPOSÉES]**, lisibilité à revoir. |
| Fichiers annexes audio **[SNAPSHOT INITIAL]** | README, manifest, recettes JSON et galerie HTML; générateurs Bfxr dans `game/tools/`. | Sources de synthèse et notice MIT conservées dans le snapshot d’audit. | Retirées après remplacement indépendant; voir les hashes de retrait.

## État audio après migration SFX et musique — 2026-10-18

- Les 38 SFX runtime ont été remplacés par les WAV originaux générés par `game/tools/generate_original_audio.py`; l’autoload `Sfx` pointe désormais vers `game/assets/audio/original_procedural/sfx/`. Les usages d’événements et familles restent inchangés.
- Les 38 WAV antérieurs, leurs fichiers `.import`, les recettes/manifestes/galeries/README et les scripts de production Bfxr ont été retirés après scan des références. Hashes, sources et remplacements figurent dans les CSV de migration et retrait.
- Les cinq stems originaux rythme/basse/pad/arpège/boss sont chargés par `adaptive_survival_music.gd` depuis `audio/original_procedural/music/` dans un flux synchronisé. L’arpège évolue avec les vagues et le stem boss fait un fondu sans redémarrage. Le smoke dédié valide les boucles et le changement de contexte.
- L’ancien OGG Space City et son `.import` sont retirés après scan des références. Hash de l’ancien morceau, référence adaptative avant migration et correspondance vers les stems consignés dans `ASSET_MIGRATIONS.csv`; retrait dans `ASSET_RETIREMENTS.csv`.
- **[PROPOSÉ / À ÉCOUTER]** Effets, composition et gains restent candidats : le mix n’a pas été validé à l’écoute ni en combat sur matériel. Aucun périphérique ALSA/PulseAudio n’est disponible dans cet environnement.

Le registre initial de 425 fichiers sous `game/assets` hors `.import` est un snapshot historique. Le registre courant recense 1 424 fichiers, dont 356 exports créatifs; les migrations/retraits restent consignés séparément. Tous les exports PNG, fontes et WAV courants ont une ligne de provenance; les chemins disparus restent historiques. Le dernier PCK de contrôle archivé après retrait des placeholders boss fait 1 594 288 octets, SHA-256 `91ecb2346c3abfd16cf8d86f9d255b762fda4d5a1b2e08a59cf755e1ab92ad05`; il exclut les sources d’auteur et les placeholders. Ce PCK est une preuve historique, pas une revalidation de l’environnement courant.

## Références runtime explicites relevées

| Famille | Références connues | Consommateurs / rôle |
|---|---|---|
| Joueur | `sprites/player_idle.png`, `sprites/player_walk.png` — feuilles originales 4×4 de 32×32 remplaçant les exports antérieurs | `player.tscn`, `player_controller.gd`; feuilles dans le rendu Survival/Sandbox. `player_cyan.png`, références et recettes antérieures retirés après vérification des consommateurs; provenance/hash avant-après dans `ASSET_MIGRATIONS.csv`. Le design de la tenue reste **[OUVERT]**; le contrat de rangées actuel est **[PROPOSÉ]**. |
| Ennemis et boss | `sprites/roster/*.png`; quelques anciens `sprites/enemy_*.png`/`.svg` et placeholders | `sprite_batch_renderer.gd`, aperçu du hub, Sandbox et données de combat. Boss canoniques et premier biome restent ouverts; garder les prototypes de rôle jusqu'à décision. |
| Armes, reliques, évolutions | `sprites/catalog/weapon_*.png`, `relic_*.png`, `evolution_*.png` | `survival_session.gd`, `survival_loadout.gd`, `run_stat_hub.gd`, coffre, inventaire et résultats. Le catalogue actif est `game/data/combat_catalog.json`. |
| Projectiles, impacts, VFX | `sprites/projectiles/*.png`, `sprites/vfx/*.png`, `weapon_impacts_pixel.png`; anciennes variantes PNG/SVG | `sprite_batch_renderer.gd`, `survival_session.gd`, familles d'armes et événements de combat. |
| Terrain et récompenses | `environment/survival_ground_tile.png`, `survival_ruins_pixel.png`, `rewards/chest_closed.png`, `rewards/xp_orb.png` | Rendu Survival et parcours de récompense. Identité officielle de biome ouverte. |
| Accueil | `backgrounds/title_skyline.png`, `icons/ui/signal_prism.png` | `launch_menu.tscn`; ambiance validée, emblème exact proposé. |
| Icônes UI/catalogue | `icons/catalog/equipment_*.png`, `rarity_*.png`, ressources, skill node, médaille, records | Hub, skill tree, équipement, statistiques, résultats. Certains sont seulement des pictogrammes sur des entrées inactives. |
| Polices et thème — état courant | `fonts/NeonArcadePixel.ttf`, `fonts/NeonArcadeUI.ttf`; `themes/dopamine_ui.tres` | Thème UI, titres et affichage de dégâts. Les deux fontes originales sont **[PROPOSÉES]**; la lisibilité du hub et de l’équipement à 640×360 est confirmée par l’utilisateur; choix typographique global et autres états restent ouverts. |
| Musique — état courant | Cinq WAV sous `audio/original_procedural/music/` : rythme, basse, pad, arpège, boss | `adaptive_survival_music.gd`; flux synchronisé avec évolution proposée par vague et fondu boss. Ancien OGG retiré après migration; hashes dans les CSV. |
| SFX — état courant après reconstruction 2026-10-18 | 125 WAV sous `audio/original_procedural/sfx/`: 65 cues de base et 60 variations d’armes sur 20 événements | `sfx_service.gd` garde les noms et règles des familles. `generate_original_audio.py`, `ASSET_MANIFEST.json`, les sidecars et `sfx_service_assets_smoke.gd` documentent, mesurent et vérifient les assets originaux; anciens fichiers et recettes retirés, hashes conservés aux registres. |

## État de provenance et licences

- Les exports initiaux PNG/SVG avaient 43 actifs liés à des références C2PA Trusted et 59 générés par le dépôt **[HISTORIQUE — paquet du 2026-10-17]**. Ces nombres ont été supersédés par le remplacement intégral; `PROVENANCE_ASSETS.csv` et `validate_asset_provenance_registry.py` décrivent et vérifient les assets courants.
- **[HISTORIQUE]** L’ancien morceau était Space City de MintoDog sous CC0; l’OGG a été retiré après remplacement et n’est pas réutilisé. Hash et provenance restent au registre de migration.
- **[HISTORIQUE]** Les anciens SFX Bfxr venaient de recettes versionnées et d’un renderer MIT; fichiers, recettes et renderer ont été retirés après la migration. **[PROPOSÉ]** Les nouveaux SFX sont synthétisés depuis des rôles et des seeds déterministes, sans lire l’ancien contenu; ils doivent encore être écoutés et approuvés en contexte.
- **[HISTORIQUE]** Les polices retirées étaient sous OFL et Bitstream Vera/DejaVu; notices, fichiers et références runtime sont supprimés et leurs hash figurent au registre de retrait.
- Toutes les sources éditables courantes ont une ligne dans `ASSET_FILE_REGISTER_CURRENT.csv`; les références retirées conservent leur hash et motif dans `ASSET_RETIREMENTS.csv`. Aucun retrait supplémentaire ne doit précéder une recherche de consommateur.

## Couverture statique et chemins dynamiques

Le snapshot initial contenait 140 assets dont une référence de chemin littérale avait été trouvée. Dans l’état courant, les statuts du registre explicitent 64 chemins statiques et 73 chemins chargés dynamiquement. Les deux chargeurs dynamiques principaux sont `sfx_service.gd` (19 familles/38 identifiants WAV sous un répertoire) et `sprite_batch_renderer.gd` (37 IDs visuels via `SPRITE_FILES`, avec extensions ajoutées à l'exécution); catalogues et écrans chargent aussi des chemins calculés. Au PCK de contrôle `4e9e822`, les 137 chemins runtime actifs du registre sont présents. Les smokes catalogue, renderer et audio valident ces tables de chargement; le PCK seul ne constitue pas une preuve de lancement autonome sans sa GDExtension.

## Méthode pour compléter les références

1. Les références statiques sont recherchées dans `game/scenes/`, `game/scripts/`, `game/data/`, `game/themes/`, `game/project.godot` et les fichiers `.import`.
2. Les références construites dynamiquement doivent être suivies depuis leurs fonctions de chargement (notamment `sprite_batch_renderer.gd`, `sfx_service.gd`, `run_result_panel.gd` et les catalogues JSON).
3. Les usages de production dans les scripts d'export/génération sont distincts des références runtime et doivent être maintenus jusqu'à ce que leurs nouveaux remplaçants soient disponibles.
4. Avant retrait d'un fichier : recherche plein dépôt du chemin/ID, import Godot, smoke ciblé du parcours consommateur, export PCK/scan, puis mise à jour du registre et de l'inventaire. Les sources et recettes originales ne sont supprimées qu'après conservation des hashes/provenances nécessaires à l'audit de l'ancien état et preuve que les nouveaux actifs ne les utilisent pas.

## Dépendances de design à préserver

- Le contenu des 100 nœuds et leurs effets/coûts sont **[PROPOSÉS]** dans `progression_service.gd`; seule la cible de 100 nœuds au lancement est **[VALIDÉE]**. L'arbre peut être affiché à partir des données implémentées sans inventer leur sens. Si une nouvelle définition de contenu est nécessaire, demander une validation précise.
- L'identité canonique des boss et du premier biome reste **[OUVERTE]**. Remplacer les assets à rôle égal sans fabriquer une identité de lore ou de mécanique.
- Les fontes actuelles sont **[PROPOSÉES]**; le choix final, tailles et lisibilité restent **[OUVERTS]**. La spécification audio laisse ouverts les gains finaux et l'approbation de la composition; le format runtime PCM16 mono WAV 44,1 kHz est **[PROPOSÉ]**. Les assets historiques, provenances et migrations sont relevés ci-dessus et dans les registres.
- Garder les parcours validés et le Sandbox isolé de toute progression/sauvegarde normale pendant chaque tranche.

## Étape suivante

**Visuel :** les familles de remplacement prévues sont produites; le PCK de contrôle couvre les chemins statiques/dynamiques, mais le paquet de livraison et la revue lisibilité/GPU restent ouverts. **Interface :** revoir chaque écran/état et le focus, ainsi que les contrôles matériels. **Audio :** fournir une écoute humaine du mix et des transitions; couvrir run, boss, pause et cues de danger.

**[VALIDÉ]** La production audio emploie une synthèse procédurale originale; les fichiers antérieurs ont été supprimés après migration et vérification des références. Les 125 SFX, cinq stems et trois cues musique sont intégrés au runtime. La validation numérique reproductible de la bibliothèque intégrée passe avec `game/tools/validate_original_audio.py`; le contenu reste **[PROPOSÉ]** jusqu’à la revue auditive. L’écoute humaine et l’écoute en run restent **[OUVERTES]**, car aucun périphérique de sortie audio n’est disponible dans cet environnement. Format source et gains finaux restent **[OUVERTS]**.

**[PROPOSÉ]** La skyline de titre active a été remplacée par une création 640×360 produite depuis `docs/art/palette_master.gpl`, source des 32 couleurs **[VALIDÉES]** de l'Art Bible. Le nouveau PNG et la source Aseprite sont aux chemins runtime existants; l'ancienne planche de référence et sa recette de traitement ont été retirées après recherche de références. `docs/art/title_skyline_migration.json` garde hashes et provenance avant/après. Dans une copie temporaire, après réimport Godot, la capture du menu à 640×360 a été examinée et le smoke de navigation d'accueil a passé. Cette preuve montre encore des éléments UI existants; elle ne valide pas l'interface finale.

Les migrations par familles sont intégrées; la clôture de l'initiative dépend encore des preuves de revue indiquées ci-dessus. Pour tout asset conditionné par une identité **[OUVERTE]** (notamment les boss et le biome), demander un arbitrage avant production canonique; les prototypes de rôle ne deviennent pas des décisions de lore.
