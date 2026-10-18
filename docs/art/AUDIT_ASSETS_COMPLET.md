# Audit complet des assets avant remplacement

Date de l'audit de base : 2026-10-18
Statut : snapshot initial des 425 fichiers; depuis ce snapshot, la skyline de titre a été migrée. Les hash initiaux restent inchangés dans le registre historique.

## Portée et règle de remplacement

Cette initiative remplace les assets visuels et audio actuellement employés par le jeu et refait son interface. Consigne utilisateur supplémentaire : **aucun asset existant ne doit être réutilisé**. Cette règle couvre les exports actifs et les dépendances importées dans le produit (sprites, fonds, icônes, polices, musique et SFX). L'utilisateur a aussi confirmé la suppression des anciennes sources Aseprite, recettes et références après migration. Aucun de ces fichiers ne sera supprimé avant migration et contrôle de références.

L'inventaire recense les fichiers sous `game/assets/`, les références Godot dans scènes/scripts/données/thèmes, et les lecteurs audio. Le statut de provenance n'est pas une licence : les droits d'usage sont notés selon la documentation existante et doivent rester traçables pour chaque nouvel asset.

## Comptage initial

Comptage vérifié par `rg --files game/assets -g '!*.import'` au 2026-10-18 avant la première migration. Le registre fichier par fichier [`ASSET_FILE_REGISTER.csv`](ASSET_FILE_REGISTER.csv) est un snapshot historique immuable contenant hash SHA-256, octets, catégorie, emplacements de références littérales et statut de recherche. Les fichiers `.import` Godot ne sont pas des contenus et ne sont pas comptés; les migrations ultérieures sont suivies dans [`ASSET_MIGRATIONS.csv`](ASSET_MIGRATIONS.csv).

| Groupe | Quantité constatée | Sources / provenance connues | Décision pour cette initiative |
|---|---:|---|---|
| Exports visuels PNG/SVG sous `game/assets` | 165 fichiers | `PROVENANCE_ASSETS.csv` suit les hash/provenance de 165 PNG/SVG; les correspondances source/export ne sont pas toutes des preuves. | Remplacer tous les visuels actifs; examiner les visuels inactifs et les références avant exclusion/suppression. Aucun export actuel ne sera réutilisé. |
| Audio sous `game/assets/audio/` **[SNAPSHOT INITIAL — 2026-10-18]** | 43 fichiers : 1 OGG, 38 WAV et 4 annexes SFX. | Le morceau Space City était CC0; les SFX venaient de recettes Bfxr. | Snapshot historique immuable; voir l’état courant ci-dessous et `ASSET_MIGRATIONS.csv` / `ASSET_RETIREMENTS.csv`. |
| Sources et références sous `game/assets/source/` | 212 fichiers hors `.import` | Plusieurs sources éditables Aseprite; certaines dérivent de références générées, d'autres sont procédurales. Le lien par nom seul n'est pas une preuve. | Ne pas utiliser les sources existantes pour fabriquer les remplacements; supprimer ces sources et références après migration, mise à jour des preuves et vérification qu'aucun outil/document actif ne les requiert. |
| Polices sous `game/assets/fonts/` | 4 fichiers : 2 polices et 2 notices de licence. | Licences OFL 1.1 et Bitstream Vera/DejaVu détaillées dans `THIRD_PARTY_NOTICES.md`. | Remplacer les deux polices runtime; conserver les notices requises jusqu'à ce que les nouvelles licences soient documentées. |
| Fichiers annexes audio **[SNAPSHOT INITIAL]** | README, manifest, recettes JSON et galerie HTML; générateurs Bfxr dans `game/tools/`. | Sources de synthèse et notice MIT conservées dans le snapshot d’audit. | Retirées après remplacement indépendant; voir les hashes de retrait.

## État audio après migration SFX et musique — 2026-10-18

- Les 38 SFX runtime ont été remplacés par les WAV originaux générés par `game/tools/generate_original_audio.py`; l’autoload `Sfx` pointe désormais vers `game/assets/audio/original_procedural/sfx/`. Les usages d’événements et familles restent inchangés.
- Les 38 WAV antérieurs, leurs fichiers `.import`, les recettes/manifestes/galeries/README et les scripts de production Bfxr ont été retirés après scan des références. Hashes, sources et remplacements figurent dans les CSV de migration et retrait.
- Les cinq stems originaux rythme/basse/pad/arpège/boss sont chargés par `adaptive_survival_music.gd` depuis `audio/original_procedural/music/` dans un flux synchronisé. L’arpège évolue avec les vagues et le stem boss fait un fondu sans redémarrage. Le smoke dédié valide les boucles et le changement de contexte.
- L’ancien OGG Space City et son `.import` sont retirés après scan des références. Hash de l’ancien morceau, référence adaptative avant migration et correspondance vers les stems consignés dans `ASSET_MIGRATIONS.csv`; retrait dans `ASSET_RETIREMENTS.csv`.
- **[PROPOSÉ / À ÉCOUTER]** Effets, composition et gains restent candidats : le mix n’a pas été validé à l’écoute ni en combat sur matériel. Aucun périphérique ALSA/PulseAudio n’est disponible dans cet environnement.

Le registre initial détaillait 425 fichiers sous `game/assets` hors `.import`; c’est un snapshot historique. Les migrations/retraits ultérieurs sont consignés dans les CSV correspondants. Le PCK audité précédemment excluait certains doublons/références inactifs, mais les presets utilisent `all_resources`; tout export restant dans un dossier inclus peut donc être empaqueté. Un contrôle PCK final doit être refait après migration visuelle complète.

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
| Polices et thème | `fonts/PressStart2P-Regular.ttf`, `fonts/DejaVuSans.ttf`; `themes/dopamine_ui.tres` | Thème UI, titres et affichage de dégâts. Fonte exacte pixel encore ouverte dans l'Art Bible. |
| Musique — état courant | Cinq WAV sous `audio/original_procedural/music/` : rythme, basse, pad, arpège, boss | `adaptive_survival_music.gd`; flux synchronisé avec évolution proposée par vague et fondu boss. Ancien OGG retiré après migration; hashes dans les CSV. |
| SFX — état après migration 2026-10-18 | 38 WAV sous `audio/original_procedural/sfx/`, 19 familles d’événements | `sfx_service.gd` garde les noms et règles des familles. `generate_original_audio.py`, `sfx/manifest.json` et `sfx_service_assets_smoke.gd` documentent, mesurent et vérifient les candidats originaux; anciens fichiers et recettes retirés, hashes conservés aux registres. |

## État de provenance et licences

- Les exports PNG/SVG ont une provenance technique consignée dans `PROVENANCE_ASSETS.csv`; l'inventaire précédent indiquait 43 actifs dérivés de références C2PA Trusted et 59 générés par le dépôt. Cette initiative les remplace tous selon la consigne utilisateur, y compris les assets procéduraux internes.
- **[HISTORIQUE]** L’ancien morceau était Space City de MintoDog sous CC0; l’OGG a été retiré après remplacement et n’est pas réutilisé. Hash et provenance restent au registre de migration.
- **[HISTORIQUE]** Les anciens SFX Bfxr venaient de recettes versionnées et d’un renderer MIT; fichiers, recettes et renderer ont été retirés après la migration. **[PROPOSÉ]** Les nouveaux SFX sont synthétisés depuis des rôles et des seeds déterministes, sans lire l’ancien contenu; ils doivent encore être écoutés et approuvés en contexte.
- Les polices sont sous OFL et Bitstream Vera/DejaVu. À remplacer si incluses dans la portée intégrale demandée.
- Les fichiers Aseprite et références non listés comme livrables dans le registre de provenance nécessitent encore un inventaire individuel de liens, hashes, créateur et statut actif/inactif avant toute suppression définitive.

## Couverture statique et chemins dynamiques

Le registre contient 140 assets dont une référence de chemin littérale a été trouvée par recherche dans les fichiers Godot. Cela ne prouve pas que les 285 autres sont inutilisés : certains sont atteints par construction de chemins ou sont chargés par outils d'auteur. Les deux chargeurs dynamiques identifiés sont `sfx_service.gd` (19 familles/38 identifiants WAV sous un répertoire) et `sprite_batch_renderer.gd` (37 IDs visuels via `SPRITE_FILES`, avec extensions ajoutées à l'exécution). Les données de catalogue et les écrans chargent également des chemins calculés. Les recherches dans les tests/outils expliquent des références qui ne sont pas des consommateurs runtime. Le champ `reference_status` distingue explicitement une absence de chemin littéral d'une preuve d'inactivité.

## Méthode pour compléter les références

1. Les références statiques sont recherchées dans `game/scenes/`, `game/scripts/`, `game/data/`, `game/themes/`, `game/project.godot` et les fichiers `.import`.
2. Les références construites dynamiquement doivent être suivies depuis leurs fonctions de chargement (notamment `sprite_batch_renderer.gd`, `sfx_service.gd`, `run_result_panel.gd` et les catalogues JSON).
3. Les usages de production dans les scripts d'export/génération sont distincts des références runtime et doivent être maintenus jusqu'à ce que leurs nouveaux remplaçants soient disponibles.
4. Avant retrait d'un fichier : recherche plein dépôt du chemin/ID, import Godot, smoke ciblé du parcours consommateur, export PCK/scan, puis mise à jour du registre et de l'inventaire. Les sources et recettes originales ne sont supprimées qu'après conservation des hashes/provenances nécessaires à l'audit de l'ancien état et preuve que les nouveaux actifs ne les utilisent pas.

## Dépendances de design à préserver

- Le contenu des 100 nœuds et leurs effets/coûts sont **[PROPOSÉS]** dans `progression_service.gd`; seule la cible de 100 nœuds au lancement est **[VALIDÉE]**. L'arbre peut être affiché à partir des données implémentées sans inventer leur sens. Si une nouvelle définition de contenu est nécessaire, demander une validation précise.
- L'identité canonique des boss et du premier biome reste **[OUVERTE]**. Remplacer les assets à rôle égal sans fabriquer une identité de lore ou de mécanique.
- La police exacte reste **[OUVERTE]**. La spécification audio laisse ouverts le format source/runtime, l'outil et la méthode d'arrangement adaptatif; la licence et l'inventaire des assets existants, eux, sont maintenant relevés ci-dessus.
- Garder les parcours validés et le Sandbox isolé de toute progression/sauvegarde normale pendant chaque tranche.

## Étape suivante

**[VALIDÉ]** La production audio emploie une synthèse procédurale originale; les fichiers antérieurs ont été supprimés après migration et vérification des références. Les 38 SFX et les cinq stems sont intégrés au runtime, mais restent **[PROPOSÉS]** comme contenu de production jusqu’à la revue auditive. La validation numérique est reproductible avec `game/tools/validate_original_audio.py`; l’écoute humaine et l’écoute en run restent **[OUVERTES]**, car aucun périphérique de sortie audio n’est disponible dans cet environnement. Format source et gains finaux restent **[OUVERTS]**.

**[PROPOSÉ]** La skyline de titre active a été remplacée par une création 640×360 produite depuis `docs/art/palette_master.gpl`, source des 32 couleurs **[VALIDÉES]** de l'Art Bible. Le nouveau PNG et la source Aseprite sont aux chemins runtime existants; l'ancienne planche de référence et sa recette de traitement ont été retirées après recherche de références. `docs/art/title_skyline_migration.json` garde hashes et provenance avant/après. Dans une copie temporaire, après réimport Godot, la capture du menu à 640×360 a été examinée et le smoke de navigation d'accueil a passé. Cette preuve montre encore des éléments UI existants; elle ne valide pas l'interface finale.

La suite de l'initiative poursuit le remplacement visuel par familles et la refonte des écrans, en gardant les assets actifs jusqu'à migration vérifiée. Pour tout asset conditionné par une identité **[OUVERTE]** (notamment les boss et le biome), poser la question avant production canonique; des prototypes de rôle ne deviennent pas des décisions de lore.
