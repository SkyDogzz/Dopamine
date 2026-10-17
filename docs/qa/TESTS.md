# Tests d'acceptation et validation

## P6.4 — Reroll payant d’effet unique — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : après paiement, le joueur choisit un effet différent; l’effet actuel n’est pas proposé.
- [x] `progression_service_smoke.gd` vérifie les coûts Legendary/Mythic, le choix persistant, le débit d’une poudre, le refus d’un reroll identique, le manque de poudre et l’inéligibilité des objets sous Legendary.
- [x] `survival_inventory_smoke.gd` vérifie le sélecteur dans le hub, l’exclusion de l’effet actuel, le coût affiché, la persistance du choix et la désactivation lorsque la poudre manque.
- [x] Les deux smokes ciblés passent sous Godot 4.7.2; `equipment_panel_visual_smoke.gd` et l’import éditeur passent aussi. Les panneaux signalent des ressources retenues à l’arrêt, sans assertion échouée.

## P5.4 — Contrat de calibration boss/vagues — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : compléter les lacunes du GDD à partir des prototypes existants, puis mesurer compositions, seuils d’élites et budget de simulation en runs représentatives. Les valeurs de départ ne sont pas promues par cet arbitrage.

## P9.8 — Staging Linux Release depuis `8d91079` — 2026-10-17

- [x] `tools/package_linux_staging.sh` reconstruit un `git archive` propre du commit `8d91079560020a140b3a48cb6189fb7da909ec91` avec CMake 3.31.12, GCC 14.2.0, Godot 4.7.2 et `godot-cpp` `b8530af7546a3fcae80cef2477526569fd42ffc2`. Build Release vierge, import, export Linux/X11 filtré, extraction, notices/licences, absence des ressources de développement, `ldd` sans dépendance manquante et lancement headless avec la GDExtension Release adjacente passent.
- [x] Archive non distribuable `DopamineSurvivor-linux-8d91079-staging.tar.gz`, 31 988 718 octets; SHA-256 `d6430957e88c72e3b89f87802ac87836341eb65fdad225a9bbdeaf7123888faa`; manifeste `.sha256` généré à côté dans `build/linux/staging/`.
- [i] Cette reconstruction inclut le correctif des compteurs Endless à la continuation; elle valide le staging Linux sur le même hôte virtualisé, pas une installation machine distincte, le GPU physique, les sauvegardes en usage, les plateformes autres que Linux ni une version distribuable.

## Checkpoint CTest complet après isolation des runs Endless — 2026-10-17

- [x] `XDG_DATA_HOME=/tmp/dopamine-p7-full-checkpoint DOPAMINE_TEST_TIMEOUT=480s /tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1` passe **112/112 tests en 76,56 s**. Le checkpoint comprend import Godot, tests natifs, rendu, Sandbox et ses scénarios d’armes, progression, Armorless, Endless standard, options, parcours clavier/manette et interfaces.
- [i] Vérification Linux sur l’hôte virtualisé courant; elle ne valide pas la run humaine complète, le GPU physique, un contrôleur physique ni l’export Windows Release.

## P7B.1 — Arbitrage de l’état en continuation Endless — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE]** : la continuation après victoire conserve HP, build et niveaux de run; elle crédite Survival avant de créer l’ID Endless.
- [x] `endless_standard_session_smoke.gd` couvre le transfert d’état et l’absence de double crédit; l’entrée depuis le hub suit son profil distinct, encore **[PROPOSÉ]**.
- [i] La validation automatique couvre le contrat implémenté, pas la calibration du mode Endless ni une run représentative.

## P7B.1 — Profil de départ Endless depuis le hub — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : progression et équipement permanents actifs; niveaux des armes/reliques de run à 1 au lancement depuis le hub. La continuation Survival → Endless garde son état de run séparément.
- [x] `survival_hub_smoke.gd` vérifie que le lancement Endless conserve le service de progression, applique les bonus HP permanents de compétences/équipement, et ne reprend aucun niveau d’arme/relique de run.
- [x] `tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/survival_hub_smoke.gd` passe. Godot signale encore des instances ObjectDB et ressources retenues à l’arrêt, sans assertion échouée.
- [i] Cette smoke confirme le contrat de démarrage, pas la calibration des bonus ni une run Endless longue.

## P7B — Maîtrise répétable — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : reporter la maîtrise répétable après la livraison; aucune maîtrise répétable n’est requise au lancement. Le prototype garde ses records et récompenses documentés séparément.

## P6.6 — Périmètre de lancement de l’arbre — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : conserver 100 nœuds au lancement et calibrer le budget actuel; différer l’extension proposée vers environ 120. Les valeurs de coûts et bonus restent **[PROPOSÉES]**.

## P6.7 — Périmètre de lancement des achievements — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : conserver 100 familles au lancement et calibrer conditions/récompenses; différer l’extension proposée vers 120. Métriques, seuils et récompenses restent **[PROPOSÉS]**.

## P6.9 — Méthode de calibration de puissance — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : conserver les budgets de prototype **[PROPOSÉS]**, comparer les profils débutant/intermédiaire/complet, et ne revoir l’allocation que si un écart est mesuré. Les surveys existants sont exploratoires et ne valent pas validation finale.

## P5.2/P6.9 — Caps critique et cooldown — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : conserver les garde-fous actuels pendant les mesures : critique bornée à 100 %, réduction de cooldown à 90 % (plancher de durée 10 %). Le statut validé couvre la méthode de mesure, pas le calibrage définitif.

## P5.1.13 — Pickups futurs de Magnet Heart — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : déterminer l’interaction avec Magnet Heart au moment de spécifier chaque pickup futur. Cela ne définit ni ne crée des pickups; XP reste le seul pickup actuel affecté.

## P9 — Détails visuels — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : garder la direction de l’ART_BIBLE et reporter les choix fins non bloquants à la QA de release. Les couleurs d’éléments/faisceaux, la police, le rythme de clignotement et l’identité du boss placeholder restent à vérifier ou arbitrer.

## P9.8 — Convention de version — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : SemVer, première release distribuable `1.0.0` après validation P9. La version ne sera ajoutée au projet et aux artefacts qu’au jalon de release; les paquets staging restent non versionnés.

## P9.8 — Candidate audio — 2026-10-17

- [x] Décision utilisateur **[VALIDÉE, réponse A]** : garder l’audio livré comme candidate de release.
- [x] Inventaire mécanique du 2026-10-17 : 38 WAV SFX correspondent exactement aux 38 entrées du manifeste; tous sont 44,1 kHz, mono, PCM16 et leurs durées concordent avec le manifeste à 2 ms près. Les recipes de synthèse sont dans `game/assets/audio/sfx/recipes.json`; `Sfx` les charge dans le jeu. Aucun fichier WAV ne manque ni n’est absent du manifeste.
- [x] Provenance recensée dans `THIRD_PARTY_NOTICES.md` : boucle Space City MintoDog CC0, SHA-256 correspondant au fichier; SFX produits depuis les recettes internes par Bfxr2 CLI MIT (commit référencé), outil de génération non inclus dans l’export. La chaîne documentée ne contient pas d’échantillons tiers identifiés. Voir `game/assets/audio/sfx/README.md`.
- [ ] Écouter la galerie et le jeu avec effets simultanés, vérifier les niveaux relatifs et la priorité des cues sur haut-parleurs/casque; l’environnement de développement headless ne permet pas cette validation matérielle.

## P7B.1 — Compteurs du segment de continuation — 2026-10-17

- [x] `endless_standard_session_smoke.gd` vérifie qu’après la continuation HP/build/niveaux persistent, tandis que durée affichée/enregistrée, kills et compteurs additifs d’achievements repartent pour l’ID Endless. L’horloge interne reste monotone pour conserver les expirations et le rythme de simulation.
- [x] `progression_service_smoke`, `endless_standard_progression_smoke` et `endless_standard_session_smoke` passent : **4/4 tests CTest**, y compris `godot_project_import`, en 4,05 s.
- [i] Le smoke affiche à la fermeture des avertissements Godot ObjectDB/ressource encore référencés; ils ne font pas échouer ces tests et restent à diagnostiquer séparément.

## P7B/P8 — Endless standard dans le Sandbox Lab — 2026-10-17

- [x] `sandbox_preset_smoke.gd` démarre successivement Survival, Armorless puis Endless standard dans le même `SandboxLabContext`; le changement de preset reste transactionnel et exige la pause.
- [x] Le smoke confirme que la session Endless Lab active `endless_standard`, garde le verrouillage HP et n’injecte aucun `ProgressionService` ni `SaveService` normal.
- [x] `sandbox_lab_smoke.gd` et la suite CTest complète passent sous Godot 4.7.2 : **95/95 tests en 64,06 s**.
- [i] Cela valide l’exécution isolée du mode et les contrats automatiques, pas la calibration des règles Endless **[PROPOSÉES]** ni une run représentative de jeu.

## Checkpoint complet Linux — 2026-10-17

- CTest séquentiel, build Debug existant, Godot officiel 4.7.2 : **87/87 tests passent en 59,80 s**. Cela couvre simulation core/worker, import Godot, rendu sous Xvfb, armes/catalogue, boss, progression, Armorless, Sandbox Lab/snapshots et scénarios des dix armes.
- Commande : `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`, après configuration avec `DOPAMINE_GODOT_EXECUTABLE` pointant sur `tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`.
- Les résultats de suite ci-dessous sont des instantanés par hôte et par date, pas une assertion que chaque plateforme a le même état. La validation Windows Debug et sa run Easy sont consignées dans [Profil Windows complet — 2026-10-17](#p97-validation-windows-debug-et-run-easy-complète--2026-10-17). Ces preuves ne remplacent ni une run Armorless manuelle complète, ni le profilage sur iGPU cible, ni un export Windows Release vérifié après extraction.

## P6.8 — Revalidation sauvegarde et progression — 2026-10-17

- [x] `save_service_smoke.gd` et `progression_service_smoke.gd` passent sous Godot 4.7.2 avec deux `XDG_DATA_HOME` temporaires isolés (`/tmp/dopamine-p68-*`). Ils couvrent respectivement l’enveloppe/backup/restauration et migrations/idempotence des récompenses.
- [x] La vérification ciblée confirme les preuves historiques de migration v1–v8 et d’absence de double attribution après recréation des services; elle ne remplace pas le CTest complet.

## P6.3 — Réapplication des statistiques d’équipement — 2026-10-17

- [x] Sur le checkout courant, `equipment_stats_smoke.gd` passe sous Godot 4.7.2 avec un `XDG_DATA_HOME` isolé. Il vérifie les douze statistiques d’équipement : PV max, mobilité, dégâts, cadence, chance/dégâts critiques, soin par élimination, aire, cooldown, XP, rayon de collecte XP et vitesse de projectile.
- [x] `survival_chest_smoke.gd` passe également; il confirme que le rayon d’XP, y compris Magnet Heart, ne change pas le rayon dédié aux coffres. Godot signale 6 instances ObjectDB et 3 ressources encore utilisées à l’arrêt, sans échec d’assertion.
- [i] Cette validation ferme l’application fonctionnelle des statistiques P6.3; les plages et l’équilibrage de ces bonus restent **[PROPOSÉS]** et P6.9 demeure ouvert.

## P9.3 — Télégraphe au milieu d’un combat chargé — 2026-10-17

- [x] Le test CTest `survival_combat_visual_smoke` rend maintenant la charge télégraphiée du Pulse Warden en même temps que les neuf familles d’ennemis, 24 projectiles, deux impacts, des pixels de mort, un orbe XP et un coffre. Il vérifie dans la capture 640×360 qu’un pixel jaune du télégraphe reste visible à son emplacement attendu et demeure présent quand les effets décoratifs réduits sont activés.
- [x] Le test échoue quand le télégraphe manque de la fixture, puis passe avec l’attaque télégraphiée réelle; capture inspectée sous Xvfb/Mesa llvmpipe : `/tmp/dopamine-survival-combat-visual.png`.
- [x] CTest ciblé avec son fixture d’import Godot : **2/2 réussis en 3,12 s**.
- [i] Cette vérification valide le rendu superposé, pas la lisibilité sur le GPU cible ni la calibration des couleurs/durées **[PROPOSÉES]**.

## P9.3 — Faisceaux Prism avec effets réduits — 2026-10-17

- [x] `survival_combat_visual_smoke.gd` rend le faisceau primaire et un faisceau secondaire Prism dans la capture de combat dense, puis vérifie leurs pixels centraux avant et après activation des effets visuels réduits.
- [x] Le smoke direct sous Godot 4.7.2/Xvfb/Mesa llvmpipe passe; CTest ciblé importe le projet puis réussit `survival_combat_visual_smoke` (**2/2 tests, 3,23 s**).
- [i] Cela confirme que les faisceaux de gameplay survivent à la réduction des effets décoratifs. Leur couleur reste **[OUVERTE]** selon l’Art Bible; le rendu sur GPU cible reste à vérifier. Le harness signale encore 4 ObjectDB et 2 ressources utilisées à la fermeture.

## P9.3 — Correspondance des PNG avec leurs sources éditables — 2026-10-17

- [x] `catalog_icon_assets_smoke.gd` parcourt récursivement les PNG livrables sous `game/assets/`, exige une source Aseprite de même nom et refuse les nouvelles exceptions non documentées. Il vérifie aussi que les trois exceptions historiques restent présentes et sans source homonyme.
- [x] Godot 4.7.2 headless : **140 PNG inspectés, 3 exceptions documentées**, puis smoke complet des assets réussi.
- [x] Retirer le sprite `boss_final_placeholder` des batches chargés au démarrage, tout en gardant son fichier/source archivé pour audit; le smoke refuse sa présence dans les batches et confirme la route runtime du Dopamine Core. CTest ciblé : `godot_project_import` et `catalog_icon_assets_smoke` passent (2/2) le 2026-10-17.
- [i] La correspondance de nom et l’existence d’une source ne prouvent pas l’origine exacte, les droits d’utilisation ni la licence; cet audit de provenance reste ouvert.

## P9.3 — Retours visuels des critiques et statuts — 2026-10-17

- [x] `survival_visual_effects_smoke.gd` touche une vraie cible avec un projectile natif Minigun marqué critique et confirme que l'événement produit un impact critique rendu par la session; le helper conserve aussi le drapeau et l'échelle supérieure au chemin normal.
- [x] Les dégâts s’affichent en nombres flottants agrégés par cible et catégorie critique : deux coups rapprochés fusionnent, tandis qu’un critique reste séparé et affiche `CRIT`. Les réglages de prototype (fenêtre 0,12 s, durée 0,5 s simulée, plafond 48 nombres) restent **[PROPOSÉS]**. Le smoke vérifie impact natif critique, sommes agrégées, distinction critique et maintien de l’affichage quand la simulation est suspendue.
- [x] Le CTest de capture vérifie le rendu des nombres normaux et critiques sous Xvfb/Mesa llvmpipe; l’image `/tmp/dopamine-aggregated-damage-number.png` montre le texte pixelisé jaune `CRIT 73` avec contour sombre.
- [x] Le CTest `survival_impact_status_visual_smoke` lance le smoke avec capture sous Xvfb/Mesa llvmpipe et compare chaque rendu à une image de fond sans impact : cette exécution compte **384 pixels modifiés** pour l'impact normal et **803** pour le critique; capture `/tmp/dopamine-critical-hit-impact.png`.
- [x] Le même smoke compare les mêmes sprites avec/sans statut : Burn, Poison et Bleed changent chacun **302 pixels**, Chill **258**, et Shock **420** dans leur zone. Les cinq indicateurs restent visibles quand les effets décoratifs sont réduits; capture `/tmp/dopamine-status-rings.png`.
- [x] Le même smoke vérifie que les visuels réduits ne changent pas le flux aléatoire ni l'état de simulation en pause; les parcours headless et rendu Xvfb passent sous Godot 4.7.2.
- [i] L'échelle 1,45× est **[PROPOSÉE]** et n'ajoute pas de couleur dédiée. La vérification est automatisée sous rendu logiciel/headless et ne valide pas encore la lisibilité sur le GPU cible.

## P9.3 — Screen shake sur impacts directs — 2026-10-17

- [x] Prototype caméra **[PROPOSÉ]** : intensité `0,02 px` par dégât direct, plafond `3 px`, retour amorti en `0,12 s` de simulation. Les attaques DoT ne le déclenchent pas; le mouvement utilise l’offset de la Camera2D, sans modifier positions, RNG ou simulation.
- [x] `survival_visual_effects_smoke.gd` vérifie l’intensité, le plafond, le retour à l’offset de base, la suppression immédiate avec effets réduits et l’invariance des entités/séquence de combat. CTest ciblé : **2/2 réussis** (import Godot + smoke); capture Xvfb du smoke visuel existant passe sous Mesa llvmpipe.
- [i] La durée/intensité restent **[PROPOSÉES]** en attendant la revue du ressenti sur matériel réel; l’option effets réduits supprime le shake.

## Checkpoint CTest rendu impacts/statuts — 2026-10-17

- [x] Après reconfiguration CMake, la suite séquentielle passe **98/98 tests en 67,56 s** avec `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`.
- [x] Le checkpoint comprend le `survival_impact_status_visual_smoke` sous Xvfb/Mesa llvmpipe, qui vérifie les pixels des impacts critiques et les anneaux des cinq statuts, le smoke headless correspondant, l’import Godot, les autres tests de rendu, Sandbox, progression, armes, boss, Armorless et Endless.
- [i] Il s'agit d'une validation automatisée sur l'hôte Linux actuel; elle ne clôt pas les runs représentatives, le GPU de référence ni les validations de plateforme ouvertes dans la roadmap.

## Checkpoint CTest complet — 2026-10-17

- [x] Sur le commit `8890e6a` avec un diff local préexistant dans `survival_session.gd` (son Pause/Lightning et correction de portée de contact du rayon combiné du boss final), `ctest --test-dir build --output-on-failure -j1` passe **98/98 tests en 68,44 s**.
- [x] Le checkpoint inclut import Godot, rendus Xvfb, Sandbox et ses snapshots, Survival, armes, ennemis/boss, coffres, progression, Armorless, Endless standard, réglages, UI, parcours clavier/manette synthétique et scénarios Sandbox des dix armes. Les smokes directs du HUD avec contraste et des sources d’assets passent aussi sur le checkout, mais ils ne font pas partie des 98 tests CTest enregistrés.
- [i] La suite est exécutée sur l’hôte Linux actuel; elle ne valide pas une partie humaine représentative, le GPU physique, une manette physique ou les plateformes de livraison encore ouvertes.

## CTest intègre l’audit des assets et le contraste du HUD — 2026-10-17

- [x] `CMakeLists.txt` enregistre `catalog_icon_assets_smoke` et `survival_hud_smoke` dans la suite standard; ce dernier reçoit un `XDG_DATA_HOME` isolé. Le CTest complet passe **100/100 tests en 67,80 s** après reconfiguration CMake avec Godot 4.7.2.
- [x] Les nouveaux gates imposent la correspondance PNG/source avec les seules exceptions documentées et le contraste minimum configuré de 4,5:1 pour les six libellés du HUD Survival.
- [i] Exécuté sur le commit `dd27f55` avec le même diff local préexistant dans `survival_session.gd`; l’hôte Linux logiciel ne valide toujours pas le matériel de rendu, les contrôles physiques ou les runs de calibration.

## CTest intègre les smokes de pause, coffres, UI et assets — 2026-10-17

- [x] `CMakeLists.txt` intègre 12 smokes auparavant absents : scène visuelle joueur, lot asset pilote, Signal Prism, panneau Pause, abandon confirmé/annulé, choix/layout des coffres, méta HUD, contrôle de vitesse, fondations UI, layout multi-viewport et cycle Armorless accéléré.
- [x] Reconfiguration avec Godot 4.7.2 puis suite CTest séquentielle : **112/112 tests en 74,65 s**. Le soak multi-modes de 600 s simulées, dont le timeout va jusqu’à 420 s murales, reste un checkpoint dédié et n’est pas ajouté à chaque suite standard.
- [i] Suite exécutée sur le commit `ee92171` avec le diff local préexistant dans `survival_session.gd`; les tests accélérés et les smokes synthétiques ne remplacent pas les parcours de jeu réels, ni le rendu/contrôles physiques.

## P9.8 — Revalidation staging Linux du Pulse Warden — 2026-10-17

- [x] Depuis le commit `78f37e46d3773307d822dfe89f808cc3575b4e70`, `tools/package_linux_staging.sh` a compilé un checkout `git archive` propre en Release (Linux x86_64, GCC 14.2.0, CMake 3.31.12, Godot 4.7.2, `godot-cpp` `b8530af7546a3fcae80cef2477526569fd42ffc2`) et exporté Linux/X11 avec le sprite du Pulse Warden.
- [x] Le script a filtré les ressources `tests/`, `tools/` et `assets/source/`, assemblé l’exécutable, la GDExtension Release et les notices/licences, extrait l’archive, validé les bibliothèques partagées puis démarré le jeu avec un `XDG_DATA_HOME` vierge. Le chargeur a confirmé la GDExtension Release adjacente et aucun `ERROR:` n’est apparu au démarrage.
- [x] Archive staging non distribuable : `build/linux/staging/DopamineSurvivor-linux-78f37e4-staging.tar.gz`, 31 977 842 octets, SHA-256 `4616c25c2cae69b1e0db9ad118b1c60ed2a0823fe3544f904e630d3e1b792bfc`; le fichier `.sha256` est créé à côté.

## P9.8 — Rebuild staging Linux sur `86351b6` — 2026-10-17

- [x] `tools/package_linux_staging.sh` reconstruit depuis un `git archive` propre du commit `86351b6`, avec Godot 4.7.2, CMake 3.31.12 et GCC 14.2.0; compilation Release vierge, import/export Godot, extraction, vérification des notices et dépendances, puis démarrage headless de l’exécutable extrait avec la GDExtension adjacente passent.
- [x] Archive de staging non distribuable `DopamineSurvivor-linux-86351b6-staging.tar.gz`, 31 977 826 octets, SHA-256 `1ed5f60ae063a42af7da0f0142aee3ede57ccd9b90c8e784b111f388e2057d59`; `sha256sum -c` confirme la somme. L’archive contient seulement l’exécutable, la GDExtension, README de staging, notices et licences requises; aucun contenu de développement.
- [i] Cette preuve couvre Linux x86_64 sur l’hôte virtualisé actuel et reste un staging non versionné, non distribuable; l’installation machine distincte, le GPU physique, Windows et la version du jeu restent ouverts.
- [i] Cette preuve valide l’assemblage et le démarrage headless du commit publié, pas une partie jouée, les sauvegardes en usage, une machine Linux distincte, le GPU réel, les autres plateformes ou une version distribuable.

## P9.8 — Contenu de l’archive Linux staging — 2026-10-17

- [x] `tools/package_linux_staging.sh` contrôle après extraction la présence de l’exécutable, de la GDExtension Release, du README, des notices, des archives de licences Godot et des licences des deux polices; il rejette une archive contenant `tests/`, `tools/` ou `assets/source/`.
- [x] `bash -n tools/package_linux_staging.sh` passe. Reconstruction depuis l’archive Git propre du commit `fa6429887665521b7d1185aeb7ab1a3f97a27272`, build CMake Release vierge, import/export Godot 4.7.2, contrôles sur l’archive extraite, `ldd` sans dépendance manquante, chargement de la GDExtension Release et démarrage headless sans `ERROR:` passent.
- [x] Archive non distribuable : `DopamineSurvivor-linux-fa64298-staging.tar.gz`, 31 977 821 octets; SHA-256 `8bcf9259bd6f987840f76afd6577607d39c97d7ecbd028aaa7382eeb5d21985c`.
- [i] Cela valide le contenu du staging Linux x86_64 sur l’hôte virtualisé actuel; ce n’est ni un artefact versionné ni une validation d’installation, de sauvegarde en jeu, de GPU réel ou d’une autre plateforme.

## P9.3 — Sprite prototype du Pulse Warden — 2026-10-17

- [x] Remplacer l’export visuel du boss intermédiaire par `boss_pulse_warden.png`, avec source Aseprite dans `game/assets/source/roster/` et référence générée archivée dans `docs/art/source/pulse_warden_generated.png`.
- [x] `process_pulse_warden.gd` reconstruit le PNG 96×96 depuis la source, conserve la transparence et limite les pixels à 16 couleurs de la palette maître; le test assets vérifie dimension, palette, source et route `mid_boss` du renderer.
- [x] `catalog_icon_assets_smoke.gd` et `survival_boss_attack_smoke.gd` passent sous Godot 4.7.2. Le second signale des instances/ressources encore référencées à l’arrêt malgré ses assertions réussies.
- [i] Sprite visuel prototype uniquement : il ne canonise ni l’identité du boss, ni ses patterns, et ne modifie aucun gameplay. Les deux exports placeholder historiques restent stockés mais inactifs; revue en mouvement sur GPU cible encore ouverte.

## P5.1.14 — Slots et déduplication des effets uniques — 2026-10-17

- [x] Depuis un `git archive` propre du commit `6647f3f`, l’import Godot 4.7.2 puis `survival_loadout_smoke.gd`, `survival_unique_effects_smoke.gd` et `progression_service_smoke.gd` passent avec des `XDG_DATA_HOME` isolés.
- [x] Les smokes vérifient cinq slots de relique par défaut, l’extension à six armes/reliques par `expanded_loadout`, le refus du septième item et la déduplication d’un même effet unique équipé sur plusieurs pièces. Les chiffres associés restent **[PROPOSÉS]**.

## P5.3.2/P5.3.3 — Pause, coffres et évolution — 2026-10-17

- [x] Depuis un `git archive` propre du commit `efed6e9`, l’import Godot 4.7.2 et les smokes `survival_chest_smoke.gd`, `survival_pause_inventory_smoke.gd`, `survival_pause_smoke.gd` et `survival_weapon_catalog_smoke.gd` passent avec des profils `XDG_DATA_HOME` isolés.
- [x] Les vérifications couvrent les horloges figées pendant un coffre et une pause, le rejet d’un choix invalide sans reprise, la reprise après choix, le retour de l’inventaire en lecture seule vers Pause et la disponibilité/collecte de l’évolution après les deux niveaux 5.
- [x] `survival_chest_smoke.gd` et `survival_pause_smoke.gd` libèrent désormais leur `SurvivalSession` sur succès comme sur échec. Les logs Godot signalent encore des références `AudioStreamWAV` (`chest_open.wav`, `chest_reward.wav`) pendant l’arrêt du smoke Pause; ce reliquat du service SFX ne bloque pas ces assertions et reste à traiter par son propriétaire audio.

## P5.3.1 — Éligibilité et présentation des offres — 2026-10-17

- [x] Depuis un `git archive` propre du commit `e730115`, l’import Godot 4.7.2 puis `survival_loadout_smoke.gd`, `survival_chest_director_smoke.gd` et `survival_chest_choice_smoke.gd` passent avec des profils `XDG_DATA_HOME` isolés.
- [x] Les smokes couvrent choix distincts, niveaux/slots pleins, pondération configurable sans suppression d’offres éligibles, ainsi que présentation et focus clavier des options de coffre.
- [i] Le smoke de présentation a émis un avertissement de ressources au shutdown; les assertions de coffre ont passé. Les poids précis sont maintenant **[VALIDÉS]**; l’interprétation d’« évolution proche » reste **[PROPOSÉE]**.

## P5.3.4 — Fréquence des drops de coffres — 2026-10-17

- [x] `survival_chest_director_smoke.gd` réalise 40 000 tirages reproductibles par famille : les ordinaires donnent 198 armes et 194 reliques (valeur proposée 0,5 %); les élites donnent 6 060 armes, 5 930 reliques et 933 doubles drops (valeur proposée 15 % indépendante par famille). La même fixture vérifie que ces valeurs sont bien les défauts du directeur.
- [x] Le smoke cible passe sous Godot 4.7.2 en 0,12 s. Les graines fixes et tolérances bornées rendent le contrôle déterministe; il vérifie l’implémentation des probabilités, pas leur balance ni leur validation de design.
- [x] `progression_balance_survey.gd` journalise maintenant les drops réellement produits, par famille et source (ordinaire, élite, boss ou filet), sans changer les taux ni les RNG. Trois runs Easy ×1 avec profil neuf donnent 20/22/23 kills et 1 coffre d’arme, 0 coffre de relique; aucun filet ou drop élite/boss n’est atteint. Les lignes brutes sont dans [`data/progression_balance_chest_metrics_20261017.csv`](data/progression_balance_chest_metrics_20261017.csv); reproduction : `XDG_DATA_HOME=/tmp/dopamine-chest-metrics-final DOPAMINE_TEST_TIMEOUT=240s tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/progression_balance_survey.gd -- --tier=fresh --difficulty=easy --movement=loot --replicates=3` (code 0).
- [x] Relevé exploratoire supplémentaire de dix runs Easy ×1 à profil neuf : 14–24 kills/run, 12–24,88 s actives, un seul coffre d’arme ordinaire sur les dix, aucun coffre relique, élite, boss ou filet. La sortie brute est dans [`data/progression_balance_chest_followup_20261017.csv`](data/progression_balance_chest_followup_20261017.csv); commande : `XDG_DATA_HOME=/tmp/dopamine-chest-followup-20261017 tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/progression_balance_survey.gd -- --tier=fresh --difficulty=easy --movement=loot --replicates=10` (code 0). Ces sessions meurent toutes avant 25 s et ne couvrent donc pas le filet de 60 s ni les élites/boss; l’échantillon reste trop petit pour calibrer 0,5 % par kill.
- [x] Cohorte distincte de dix runs Easy ×4 avec mouvement kite : 90 kills, 5 coffres arme (1 ordinaire, 4 filet), 4 coffres relique (tous filet), aucun drop élite/boss. Six runs dépassent 60 s simulées; quatre rencontrent une mort ennemie après le seuil et déclenchent les deux familles du filet. Les autres n’ont pas atteint de mort éligible après le seuil. Données brutes : [`data/progression_balance_chest_kite_20261017.csv`](data/progression_balance_chest_kite_20261017.csv); commande : `XDG_DATA_HOME=/tmp/dopamine-chest-kite-followup-20261017 tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/progression_balance_survey.gd -- --tier=fresh --difficulty=easy --movement=kite --replicates=10` (code 0). Godot affiche à la fermeture 2 instances ObjectDB et une ressource encore référencées, sans échec d’assertion. Le contrôle confirme l’attribution du filet dans ces cas; le bot, les défaites avant vague 4 et 90 kills ne calibrent pas les drops ordinaires.
- [x] Cohorte de dix runs Easy ×4 avec profil arbre complet (`full`) et kite : 454 kills, 14 coffres arme (2 ordinaires, 12 filet), 12 coffres relique (tous filet), aucun drop élite/boss. Deux runs outliers atteignent la vague 12 et ~393–396 s simulées, mais finissent en défaite avant de tuer le boss. Données brutes : [`data/progression_balance_chest_full_kite_20261017.csv`](data/progression_balance_chest_full_kite_20261017.csv); commande : `XDG_DATA_HOME=/tmp/dopamine-chest-full-kite-20261017 tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/progression_balance_survey.gd -- --tier=full --difficulty=easy --movement=kite --replicates=10` (code 0). La grande dispersion montre la sensibilité au pilotage/cadence du bot; 2 drops ordinaires d’arme et zéro de relique sur 454 kills ne permettent pas de valider ni de rejeter les probabilités proposées.
- [x] Après ajout d’une assertion d’attribution (total par famille = somme ordinaire/élite/boss/filet), une session Easy ×1 ciblée passe sous Godot 4.7.2 avec 36 kills et un coffre d’arme attribué au tirage ordinaire; les autres compteurs restent à zéro.
- [i] Les cohortes loot (3 puis 10 runs) et kite (deux groupes de 10 runs) ne calibrent pas les taux ordinaires; elles établissent la mesure des drops observés et du filet en sessions Survival simulées. La paire de runs longues n’est pas représentative et ne ferme pas l’équilibrage.
- [i] Les cohortes n’ont pas calibré les probabilités; leurs mesures antérieures utilisent le taux ordinaire de 0,5 % alors proposé. Le taux ordinaire, les poids transformés, le taux élite de 30 %, la garantie boss et le filet de 60 s sont désormais **[VALIDÉS]**; l’interprétation d’évolution proche reste **[PROPOSÉE]**.

## P5.3.4 — Valeurs de coffre arbitrées par l’utilisateur — 2026-10-17

- [x] **[VALIDÉ]** Taux de drop ordinaire porté à 0,75 % indépendamment pour chaque famille. `survival_chest_director_smoke.gd` passe avec 40 000 tirages seedés par famille : 296 coffres d’arme et 301 reliques; le seuil d’acceptation statistique couvre le taux configuré.
- [x] **[VALIDÉ]** Transformation des poids par `1 + (x−1)/2`, plafond inclus : amélioration ×1,25, relique assortie ×1,5, arme assortie ×1,25, évolution prête/proche ×1,125, plafond combiné ×2. `survival_loadout_smoke.gd` passe; il vérifie aussi qu’une arme nouvelle non assortie garde un poids positif de ×1.
- [x] **[VALIDÉ]** Drop élite 30 % par famille indépendante; chaque boss garantit chaque famille éligible; le filet garantit chaque famille éligible après 60 s de temps actif, au prochain événement de mort. `survival_chest_director_smoke.gd` couvre ces règles et 40 000 tirages seedés à 30 %.
- [i] « Évolution proche » conserve son interprétation proposée niveau 4+. Les taux retenus ne constituent pas encore une calibration en run représentative.

## P5.3.5 — Collecte — 2026-10-17

- [x] Sous Godot 4.7.2, `survival_chest_smoke.gd` passe : rayon de coffre distinct du rayon XP même avec Magnet Heart, attraction XP jusqu’au niveau 5, placement XP/coffres sans chevauchement complet, collecte à proximité et ouverture du choix. Le test détecte également la récompense quand un seul choix reste éligible.
- [x] `survival_chest_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080.
- [i] Le smoke de collecte réussit ses assertions mais Godot signale 8 instances ObjectDB et 4 ressources encore en usage à l’arrêt. La cause de cet avertissement de fermeture reste à diagnostiquer; il ne correspond pas à un échec d’assertion de collecte.

## P5.4.6 — Difficultés et cadence Chaos — 2026-10-17

- [x] Depuis un snapshot propre de `7221c57`, `survival_difficulty_profile_smoke.gd`, `survival_difficulty_unlock_smoke.gd`, `survival_difficulty_session_smoke.gd` et `survival_boss_attack_smoke.gd` passent sous Godot 4.7.2 avec des profils `XDG_DATA_HOME` isolés.
- [x] Les smokes couvrent difficulté transmise à la run, victoire/défaite et déblocage séquentiel, multiplicateurs Easy/Normal/Chaos distincts, cadence du suivi Chaos après deux attaques normales pour les deux boss, télégraphes et pause.
- [i] Les multiplicateurs restent **[PROPOSÉS]** et la run Chaos représentative reste à valider dans P9. Le smoke boss affiche un avertissement ObjectDB/ressource à l’arrêt sans échec d’assertion.

## P5.4.6 — Composition des soutiens Normal/Chaos — 2026-10-17

- [x] `survival_support_spawn_survey.gd` appelle le spawner de production en wave 12, sans arme active ni `ProgressionService`, et vérifie avant/après que les fichiers de sauvegarde normale n’ont pas changé. Commande : `XDG_DATA_HOME=/tmp/dopamine-support-spawn-survey-final DOPAMINE_TEST_TIMEOUT=240s tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/survival_support_spawn_survey.gd -- --seed=20261017 --replicates=10 --output=../docs/qa/data/survival_support_spawn_survey_20261017.csv`.
- [x] Dix seeds appariés (`20261017`–`20261026`), 1 000 spawns chacun par difficulté. Normal : 2 523/10 000 Buffer, Shielder ou Summoner (25,23 %); Chaos : 3 573/10 000 (35,73 %), soit +41,62 %. Les comptes par famille sont Buffer 734→989 (+34,7 %), Shielder 975→1 372 (+40,7 %), Summoner 814→1 212 (+48,9 %).
- [i] Cette sonde utilise la fonction de spawn réelle et quantifie la composition finale après les tirages successifs; elle ne simule pas les vagues, dégâts, élites, boss ni survie, et ne calibre donc pas les règles Chaos **[PROPOSÉES]**. Les variations par famille reflètent l’ordre des tirages et les remplacements entre familles. Une run Chaos représentative et l’équilibrage des combinaisons d’affixes restent ouverts. Aucune valeur n’a été modifiée.

## P5.4.6 — Combinaisons de deux affixes élite — 2026-10-17

- [x] `survival_elite_smoke.gd` instancie l’API native de production et vérifie les 15 paires possibles parmi Hasted, Armored, Regenerating, Volatile, Shielded et Split-on-Death. Chaque paire doit être acceptée et publiée dans le snapshot avec sa vitesse Hasted, ses réductions de dégâts composées, sa régénération et son explosion, selon les affixes présents.
- [x] Le smoke ciblé passe sous Godot 4.7.2 avec un profil `XDG_DATA_HOME` isolé : `XDG_DATA_HOME=/tmp/dopamine-elite-combinations-final tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/survival_elite_smoke.gd`.
- [i] Godot signale encore des références audio SFX/Ogg des autoloads à l’arrêt (14 objets, 6 ressources en exécution verbose); aucun échec d’assertion. Ce contrôle couvre les contrats d’implémentation, pas le réglage du danger ni le ressenti des combinaisons en run Chaos.

## Checkpoint CTest complet — validation des paires d’affixes — 2026-10-17

- [x] CTest séquentiel passe **113/113 en 77,61 s** : `XDG_DATA_HOME=/tmp/dopamine-p54-full-checkpoint-rerun DOPAMINE_TEST_TIMEOUT=480s /tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`.
- [x] Une première exécution à 112/113 a révélé que `survival_visual_effects_smoke.gd` lisait le temps et l’état `paused` avant l’acquittement du worker. La fixture attend maintenant le numéro de séquence de pause; le test visuel ciblé passe 2/2 avec l’import, puis le checkpoint complet passe. Aucun script de jeu ni contrat de pause n’a été modifié.

## P5.4.1–5 — Roster, interactions, élites et boss — 2026-10-17

- [x] Depuis un snapshot propre de `7221c57`, passent sous Godot 4.7.2 : `survival_support_enemy_smoke.gd`, `survival_shielder_smoke.gd`, `survival_summoner_smoke.gd`, `survival_exploder_smoke.gd`, `survival_elite_smoke.gd`, `survival_wave_director_smoke.gd`, `survival_boss_attack_smoke.gd` et `survival_final_boss_loot_smoke.gd`.
- [x] `survival_combat_visual_smoke.gd` passe sous Xvfb/llvmpipe; il capture les neuf familles d’ennemis, les projectiles, impacts, XP et coffre dans le viewport logique.
- [x] Les vérifications couvrent les auras et leur retrait à la mort, les invocations bornées, les six affixes élite, les huit familles générées en Survival, les patterns/télégraphes des deux boss, leur comportement en pause, et les coffres garantis du boss final avant victoire.
- [i] Les paramètres de profils, affixes, patterns, dégâts, rayons, délais, plafonds et probabilités de spawn restent **[PROPOSÉS]**. Plusieurs smokes signalent des instances/ressources encore en usage à l’arrêt; leurs assertions passent. La représentativité et le calibrage restent ouverts pour P9.

## P5.1.15 — Statut de configuration du balancing — 2026-10-17

- [x] Depuis le snapshot propre `7221c57`, `survival_weapon_catalog_smoke.gd` et `survival_loadout_smoke.gd` passent sous Godot 4.7.2 avec des profils `XDG_DATA_HOME` isolés.
- [x] Les vérifications confirment que les valeurs par niveau sont chargées depuis `weapon_progression.json`, qu’une modification de configuration affecte le résultat calculé, et que les dix paires/évolutions ainsi que les choix de loadout restent cohérents.
- [i] Cette vérification atteste le statut documentaire et la configurabilité, pas l’équilibrage : les chiffres restent **[PROPOSÉS]** jusqu’à la calibration représentative.

## Build Linux depuis un répertoire CMake vierge — 2026-10-17

- Inventaire de cet environnement : CMake 3.31.12, GCC 14.2.0, Godot officiel 4.7.2 (`ed1daf0bf`) et `godot-cpp` `b8530af7546a3fcae80cef2477526569fd42ffc2`.
- Configuration neuve dans `/tmp/dopamine-p9-linux-clean`; FetchContent a récupéré le commit `godot-cpp` épinglé et généré les 2 135 bindings.
- `cmake --build /tmp/dopamine-p9-linux-clean --parallel 4` a compilé la simulation, `godot-cpp` et `game/bin/linux/libdopamine.linux.template_debug.x86_64.so` depuis les sources.
- CTest de ce build propre : **87/87 passent en 60,52 s**, incluant l’import Godot et le smoke de rendu.
- C’est un build neuf dans le même hôte et le même checkout, pas un clone propre ni une machine Linux propre. Le dépôt requiert CMake ≥3.21, Git et un compilateur C++23; CMake récupère `godot-cpp`, sans autre dépendance tierce native déclarée. Le projet Godot est nécessaire pour les imports/smokes si son exécutable est détecté par CMake.
- Les sorties locales (`build/`, `.godot/`, `game/bin/linux/`, `game/bin/windows/`) sont ignorées par Git. Le build/import frais n’a modifié aucun fichier généré suivi; les fichiers UID Godot non suivis éventuels restent hors commit.
- Sur Linux, `user://` se trouve dans le répertoire utilisateur Godot `app_userdata/Dopamine Survivor` (sous `$XDG_DATA_HOME/godot/`, ou le répertoire de données Godot par défaut). Le code de sauvegarde du jeu range les slots normaux sous `user://saves/` et les données Sandbox sous `user://sandbox/`.
- Windows et iGPU de référence ne sont pas couverts.

## Preset et PCK Linux — 2026-10-17

- [x] Le preset Godot `Linux/X11` exporte les données du projet en PCK sans warning. Après compilation séparée de `template_release`, le manifeste GDExtension possède les routes Linux debug et release; la route Windows existante reste inchangée.
- [x] Le PCK exporté (32 Mo) démarre avec le binaire Linux Godot 4.7.2 via `--main-pack`, lorsqu’on place à côté du PCK la GDExtension debug sélectionnée par le runtime de développement. Aucun message d’échec de chargement GDExtension n’est émis.
- [x] `godot_project_import`, `sandbox_smoke`, `sandbox_combat_smoke` et `combat_catalog_smoke` passent : 4/4.
- [ ] Les templates Linux 4.7.2 ne sont pas installés. Le test n’est donc pas un export autonome, et ne valide pas le lancement par `linux_release.x86_64` ni la distribution des notices dans un dossier d’installation.

## Export autonome Linux 4.7.2 — 2026-10-17

- [x] Téléchargement des templates officiels 4.7.2 depuis `downloads.godotengine.org`; le SHA-512 de l’archive correspond au manifeste officiel. Seul `linux_release.x86_64` a été installé dans `~/.local/share/godot/export_templates/4.7.2.stable/`.
- [x] `tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --export-release "Linux/X11" build/linux/export/DopamineSurvivor.x86_64` termine avec le code 0. Il produit un exécutable ELF x86_64 d’environ 102 Mo et copie `libdopamine.linux.template_release.x86_64.so` à côté (environ 1,1 Mo); le PCK est intégré à l’exécutable.
- [x] `build/linux/export/DopamineSurvivor.x86_64 --headless --audio-driver Dummy --quit-after 3` démarre le runtime exporté, charge la scène d’accueil et termine avec le code 0 sans erreur de chargement signalée.
- [x] Pendant un runtime exporté, `/proc/<pid>/maps` contient le sidecar `libdopamine.linux.template_release.x86_64.so`, confirmant que le chargeur dynamique l’a chargé. Cela ne prouve pas à lui seul que `CombatSimulation` a été instanciée.
- [x] Sous Xvfb/Mesa llvmpipe, un film de 240 frames à 640×360 a capturé l’accueil pixel art, puis le hub après Entrée, puis une run Survival active après les Entrées suivantes; la dernière image montre le HUD `IN RUN` et l’arme de départ. Le démarrage de la session n’a produit aucune erreur `CombatSimulation` indisponible. Les pressions de touche ont été synthétisées par XTest; aucun contrôleur physique n’a été testé.
- [x] Copie de l’exécutable et de `libdopamine.linux.template_release.x86_64.so` vers un répertoire temporaire hors du checkout; lancement depuis ce répertoire avec un `XDG_DATA_HOME` temporaire neuf et `--headless --audio-driver Dummy --quit-after 3` termine avec code 0. `file` confirme les deux binaires ELF x86_64 et `ldd` ne signale aucune bibliothèque manquante pour l’exécutable. Cela vérifie une relocation locale, pas une installation sur une machine vierge ou une autre distribution.
- [i] Une tentative d’exécuter `res://tests/sandbox_smoke.gd` avec `--script` depuis l’exécutable exporté n’a pas terminé en 30 secondes; le parcours UI ci-dessus fournit le contrôle de runtime à la place. Le film a été coupé pendant la run et Godot a signalé 2 instances ObjectDB et 1 ressource encore référencées à cette fermeture forcée.
- [ ] Ce contrôle porte sur un export local de l’hôte Linux courant, pas sur une installation vierge ni sur une autre distribution. Les notices tierces et le paquet distribuable restent à vérifier.

## P9.6 — Soak Survival et Sandbox — 2026-10-17

- [x] `XDG_DATA_HOME=/tmp/dopamine-p9-stability-soak-verified DOPAMINE_TEST_TIMEOUT=480s tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/stability_soak_smoke.gd` passe.
- [x] Le script agrège **612,4 s de simulation Survival sur 30 sessions** (Easy, arme de départ standard, auto-choix des coffres, aucune invulnérabilité ni ProgressionService; maximum observé : 138 entités), puis **600,1 s de simulation Sandbox** avec 40 lots de dix Chasers. Les snapshots gardent leurs séquences et horloges monotones; le test attend l’acquittement de pause et ferme le contexte Sandbox.
- [x] Le smoke compare les fingerprints des fichiers `user://saves` avant/après; aucun changement n’est détecté. Il ne mesure pas les fuites mémoire à long terme, n’utilise pas de sauvegarde normale réelle et ne remplace pas un soak graphique sur matériel cible.
- [x] Après ajout du smoke, `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1` passe **91/91 en 62,13 s**.

## P9.6 — Soak des modes sans fin — 2026-10-17

- [x] `XDG_DATA_HOME=/tmp/dopamine-p96-all-modes DOPAMINE_TEST_TIMEOUT=480s tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/stability_soak_smoke.gd` passe après extension du smoke.
- [x] En plus des durées existantes, Endless standard agrège **128,1 s sur 10 sessions** et Armorless **128,1 s sur 4 sessions**, à PV normaux, avec auto-choix des coffres/drafts et sans progression persistante. Les séquences/horloges de snapshots progressent, les sessions se libèrent, et le fingerprint de `user://saves` est identique après les quatre modes.
- [i] Les nouveaux segments durent 120 s de simulation chacun pour respecter le plafond total de 420 s du smoke; ils testent la stabilité de session, pas une run représentative ni l’équilibrage. Le script garde le soak Survival/Sandbox existant à 600 s chacun.
- [i] Le passage a été exécuté sur le checkout de travail qui contenait aussi le diff local SFX et rayon du boss dans `game/scripts/survival_session.gd`; les tests n’ont pas atteint le boss. Ce diff n’est pas inclus dans le commit de soak.
- [i] Le checkout de ce CTest contenait un diff local non commité de `game/scripts/survival_session.gd`; ces résultats décrivent cet état de travail, pas le commit seul. Ce diff n’a pas été inclus dans le changement du soak.

## P9.6 — Cible CMake pour le soak multi-modes — 2026-10-17

- [x] Ajouter la cible opt-in `stability_soak`, hors CTest standard, qui lance `stability_soak_smoke.gd` avec `XDG_DATA_HOME` isolé sous `build/stability_soak_data/`.
- [x] Commande : `/tmp/cmake-3.31.12-linux-x86_64/bin/cmake --build build --target stability_soak`. Godot 4.7.2 rapporte **46 sessions Survival / 600,4 s simulées**, **10 sessions Endless / 129,2 s**, **10 Armorless / 130,2 s** et **600,1 s Sandbox / 40 lots d’ennemis**; le smoke passe et confirme l’absence de mutation des sauvegardes normales.
- [i] Exécution sur l’hôte Linux courant avec un diff local non commité dans `survival_session.gd`; l’isolation est vérifiée par empreintes locales, pas sur un profil de joueur réel. Cette cible n’est pas lancée par le CTest rapide.

## P9.6 — Écritures interrompues et fermeture du worker — 2026-10-17

- [x] `save_service_smoke.gd` place un JSON temporaire partiel alors qu’un slot valide existe, puis simule l’intervalle de remplacement où le slot manque et seul le backup valide demeure. Le chargement garde la version courante dans le premier cas, récupère le backup dans le second, et un enregistrement ultérieur enlève le temporaire incomplet.
- [x] `save_service_smoke.gd`, `progression_service_smoke.gd` et `simulation_worker` couvrent respectivement le backup/checksum/migration, le refus du double crédit d’un `run_id` après recréation du service, et l’arrêt répété/join du worker sous charge concurrente.
- [x] Vérifications ciblées après ajout du scénario : import Godot + `save_service_smoke` + `progression_service_smoke` **3/3**; `simulation_worker` **1/1**.
- [x] Suite CTest séquentielle du checkout courant : **91/91 en 62,87 s**. Le checkout contient aussi le diff local non commité de `game/scripts/survival_session.gd`; ce résultat porte sur l’état combiné et ce fichier n’a pas été inclus dans le commit du test.
- [ ] Le test d’interruption construit les états de fichiers représentatifs dans un processus de test; il ne coupe pas réellement le processus ou l’alimentation pendant un write/flush, et ne simule pas les garanties matérielles du système de fichiers.

## P9.8 — Licences du template Linux release — 2026-10-17

- [x] Un projet Godot minimal a été exporté avec le template installé `linux_release.x86_64`, puis lancé en headless. Le runtime du template a produit `Engine.get_copyright_info()` et `Engine.get_license_info()`.
- [x] Les données du runtime du template correspondent exactement aux archives suivies `docs/release/licenses/godot-4.7.2-copyright-info.json` et `godot-4.7.2-license-info.json` : **102 composants** et **19 textes de licence**. Le script/projet de probe était temporaire et n’est pas dans le jeu.
- [ ] Cette vérification ne couvre pas de templates Windows/macOS/Linux supplémentaires ni la présence des notices dans un paquet distribué.

## P9.8 — Paquet Linux de validation — 2026-10-17

- [x] `tools/package_linux_staging.sh` passe depuis le commit `c318888`: `git archive`, CMake Release vierge, GCC 14.2.0/CMake 3.31.12, Godot officiel 4.7.2 et `godot-cpp` `b8530af7546a3fcae80cef2477526569fd42ffc2`; import et export Linux/X11 réussis.
- [x] Le script vérifie les catégories `scenes/`, `scripts/`, `data/`, `assets/sprites/`, `assets/fonts/` et `assets/audio/`, et refuse les chemins exportés sous `tests/`, `tools/` ou `assets/source/`. Exécutable : 76 882 240 octets; GDExtension Release : 1 140 440 octets.
- [x] Archive staging de huit fichiers : exécutable, GDExtension, `README.txt` pré-release, `THIRD_PARTY_NOTICES.md`, deux JSON de licences Godot et deux licences de polices aux chemins référencés. Fichier `build/linux/staging/DopamineSurvivor-linux-c318888-staging.tar.gz`, 31 963 680 octets, SHA-256 `3630dcac930cdd32a8eca545e6f6768e080a03c9299887f672f561dfad64c790`; exécutable `df885b806ff369f985e53903f5a22cf15497ff1b18c3395cdbd31831488de889`; GDExtension `a738d9fda97220a06c39c695f57c97e7b68f37635a6a01ef6b0069e59fb27187`.
- [x] Le script extrait ensuite l’archive dans un nouveau répertoire, vérifie `ldd` et lance le menu avec `XDG_DATA_HOME` neuf; code 0, GDExtension côte à côte confirmée par `LD_DEBUG`, aucune dépendance manquante.
- [i] Ce staging est rattaché au commit source mais n’a pas de version de jeu assignée et n’est pas distribuable. Le parcours ne valide ni les écritures de sauvegarde en jeu, ni une installation sur une machine distincte; ces gates et la clearance de provenance restent ouvertes.

## P9.7/P9.8 — Export Linux depuis un snapshot propre — 2026-10-17

- [x] `git archive` du commit `90a1fdabded9acc03b93ca14d5ab7364c7478d33`, configuration CMake vierge en Release et compilation de la GDExtension `template_release` sous Linux x86_64 (GCC 14.2.0, CMake 3.31.12, Godot 4.7.2, `godot-cpp` verrouillé à `b8530af7546a3fcae80cef2477526569fd42ffc2`). L’export autonome `Linux/X11` a été produit depuis ce snapshot.
- [x] La reconstruction de session autonome lance une `SurvivalSession`, instancie la classe native `CombatSimulation`, lit son snapshot puis ferme la session/worker proprement. Ce probe temporaire a utilisé le même template Linux release et la même GDExtension, mais un main scene distinct du jeu.
- [x] Le paquet staging avec l’exécutable, la GDExtension, les notices Godot/polices et le commit source a été extrait puis lancé avec un `XDG_DATA_HOME` vierge. SHA-256 du paquet : `71435df9388c5047dcec7aa95bedadc8e36f788b1a111391d7cf0b25ac8ef201`; exécutable : `dbc71c3681c0b86ae6c66cf21d010009b1515830973d825b500d8ba4f5f82f61`; GDExtension : `d0efcd2a50be00971745d828838b2fb97bfccbf2a7b72e01b184716f7be52c11`.
- [i] L’import éditeur de ce snapshot a signalé l’absence de la bibliothèque debug parce que la configuration a compilé uniquement `template_release`. L’export release et le probe natif exporté ont réussi; aucun binaire debug n’a été inclus dans le paquet.
- [ ] Source propre et CMake vierge, mais même hôte KVM; ce contrôle ne valide pas une machine Linux distincte, une cible iGPU réelle, Windows, une version produit, ni les autres gates de release.

## P9.7 — Export Linux filtré depuis le commit propre — 2026-10-17

- [x] À partir du snapshot `git archive` du commit `43248d0`, un build CMake vierge `template_release` et un export autonome Godot 4.7.2 Linux/X11 ont été produits. Le probe `sandbox_smoke.gd`, lancé avec cette GDExtension Release, passe et affiche `Sandbox simulation bridge checks passed`.
- [x] Le filtre `tests/**`, `tools/**` et `assets/source/**` a été appliqué au preset Linux de ce snapshot. Le journal d’export ne contient aucun chemin de ces répertoires; l’exécutable filtré démarre avec `--headless --audio-driver Dummy --quit-after 3` et code 0. Le preset Windows n’a pas été modifié.
- [x] La version filtrée mesure 76 882 240 octets contre 106 103 688 octets avant filtre (29 221 448 octets de moins). SHA-256 : exécutable `19cfba86d61e3b8f7d37e191068846cdee4ec3181923d7c21b803ab86372a4ad`; GDExtension `2b6810ad2e66b56fb3202da350e666f4ef3ce3a159a601b92e0fcf663aa6206d`.
- [ ] Vérification sur une machine Linux distincte, iGPU réelle, contrôleur physique et plateformes hors Linux toujours ouvertes; ce résultat est un build staging de validation, pas une release produit.

## P9.8 — Revalidation staging Linux — 2026-10-17

- [x] Depuis le commit `379b9aad23bb9d6284722b485e2f094fd5d7c15d`, `tools/package_linux_staging.sh` reconstruit un checkout `git archive` propre en Release (Linux x86_64, GCC 14.2.0, CMake 3.31.12, Godot 4.7.2, `godot-cpp` `b8530af7546a3fcae80cef2477526569fd42ffc2`), exporte Linux/X11 et filtre les ressources de développement.
- [x] Le script extrait l’archive, vérifie les bibliothèques partagées, démarre l’exécutable headless avec un `XDG_DATA_HOME` vierge et confirme le chargement de la GDExtension Release adjacente; aucune ligne `ERROR:` au démarrage.
- [x] Archive staging non distribuable : `build/linux/staging/DopamineSurvivor-linux-379b9aa-staging.tar.gz`, 31 966 641 octets, SHA-256 `bbfb3f2d20ecd143005c588c7d1419c54e5c48cd3a434a181a7279094e73790c`. `sha256sum -c` passe.
- [i] Cette vérification headless valide l’assemblage et le démarrage, pas une partie jouée, la persistance en usage, l’installation sur une machine distincte, le GPU réel ou les autres plateformes. Le paquet reste un staging sans version de jeu.

## P9.8 — Revalidation staging Linux depuis f806909 — 2026-10-17

- [x] Depuis le commit `f80690965b76b8d58c033b1c36a71af98ecccf88`, `tools/package_linux_staging.sh` reconstruit le snapshot `git archive` en Release, exporte Linux/X11 avec Godot 4.7.2 et filtre les ressources de développement. L’environnement courant ne fournit pas CMake dans `PATH`; le build a utilisé `/tmp/cmake-3.31.12-linux-x86_64/bin`.
- [x] L’archive a été extraite, les bibliothèques vérifiées avec `ldd`, puis l’exécutable lancé headless depuis le dossier extrait avec un répertoire XDG vierge. La GDExtension Release adjacente est chargée et aucune erreur de démarrage n’est signalée.
- [x] Archive staging non distribuable : `build/linux/staging/DopamineSurvivor-linux-f806909-staging.tar.gz`, 31 968 166 octets, SHA-256 `f2da78adb6398e82f4547441d57f19d919935966e21840cfc2f90195ffe6edc9`. `sha256sum -c` passe.
- [i] Cette vérification valide l’assemblage et le démarrage headless; elle ne valide pas une partie jouée, une installation sur une machine distincte, le GPU réel ou les autres plateformes. Le paquet reste un staging sans version de jeu.

## P9.8 — Staging Linux depuis `7b20dd4` — 2026-10-17

- [x] `tools/package_linux_staging.sh` reconstruit un `git archive` propre de `7b20dd485f1078bce51531839554d0e6b9fadfc9` en Release avec GCC 14.2.0, CMake 3.31.12, Godot officiel 4.7.2 et `godot-cpp` épinglé à `b8530af7546a3fcae80cef2477526569fd42ffc2`.
- [x] Import Godot, export Linux/X11 et filtre des ressources de développement réussis. Le script extrait l’archive, vérifie les dépendances partagées, démarre le jeu avec un `XDG_DATA_HOME` vierge et confirme le chargement de la GDExtension Release adjacente sans erreur `ERROR:`.
- [x] Archive staging non distribuable : `build/linux/staging/DopamineSurvivor-linux-7b20dd4-staging.tar.gz`, 31 974 354 octets; SHA-256 `c4530505fe31fbe2bfa9122c3a37aa5f9ff290ede7814c562b35d19563b83393`. Le paquet contient la continuation Endless et le mode Endless du Sandbox Lab présents dans ce commit.
- [i] Même hôte Linux virtualisé et démarrage headless : ce résultat ne valide pas une partie jouée, les sauvegardes en usage, une installation distincte, le GPU réel ou Windows. Le paquet reste un staging sans version de jeu.

## P9.1 — Relevé exploratoire DPS des dix armes — 2026-10-17

- [x] Les 90 cas ont terminé sous Godot 4.7.2 sans erreur avec `--seed=20261017`. Chaque formation a été lancée par `XDG_DATA_HOME=/tmp/dopamine-seeded-<formation> tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/combat_weapon_balance_survey.gd -- --formation=<formation> --seed=20261017`. Chaque cas utilise vitesse ×4 et 18 secondes de simulation active. Les nombres sont le DPS observé en dégâts totaux / temps actif :

  | Arme | Cluster N1 | Cluster N5+R5 | Cluster EVO | Approche N1 | Approche N5+R5 | Approche EVO |
  |---|---:|---:|---:|---:|---:|---:|
  | Lightning Conductor | 40,77 | 115,34 | 182,61 | 35,59 | 100,63 | 163,56 |
  | Inferno Sprayer | 11,10 | 16,49 | 189,69 | 10,63 | 15,98 | 82,41 |
  | Crimson Daggers | 119,72 | 318,51 | 581,88 | 75,30 | 199,20 | 301,29 |
  | Minigun | 19,31 | 43,38 | 54,22 | 18,66 | 41,46 | 52,65 |
  | Toxic Cloud | 16,38 | 24,61 | 32,42 | 8,00 | 10,92 | 12,48 |
  | Sawblades | 8,88 | 19,94 | 33,30 | 8,89 | 19,94 | 33,27 |
  | Meteor Staff | 58,44 | 110,14 | 142,81 | 20,01 | 37,49 | 52,14 |
  | Prism Laser | 18,12 | 27,18 | 78,86 | 17,44 | 26,16 | 73,00 |
  | Void Orb | 13,99 | 43,73 | 109,02 | 9,31 | 20,94 | 32,70 |
  | Frost Nova | 44,44 | 95,24 | 119,36 | 20,88 | 29,77 | 37,26 |

- [x] Même comparaison en formation `single` : une cible statique de 1 000 000 PV à 26 px. Colonnes = niveau 1 / niveau 5 + relique 5 / évolution, en DPS.

  | Arme | Single N1 | Single N5+R5 | Single EVO |
  |---|---:|---:|---:|
  | Lightning Conductor | 22,00 | 51,23 | 64,03 |
  | Inferno Sprayer | 11,09 | 16,52 | 21,29 |
  | Crimson Daggers | 0,78 | 1,75 | 2,18 |
  | Minigun | 19,31 | 43,38 | 54,23 |
  | Toxic Cloud | 2,16 | 2,70 | 3,38 |
  | Sawblades | 4,44 | 6,66 | 8,32 |
  | Meteor Staff | 4,66 | 8,32 | 11,66 |
  | Prism Laser | 17,97 | 27,18 | 33,98 |
  | Void Orb | 3,11 | 5,82 | 5,09 |
  | Frost Nova | 2,67 | 4,27 | 5,33 |

- [i] Cluster utilise 24 cibles statiques de 1 000 000 PV; approche utilise huit ennemis chaser qui avancent depuis 220 px. Les mesures sont propres à ces formations; portée, nombre de cibles effectivement touchées, géométrie, déplacements et synergies rendent le classement brut impropre à décider un équilibrage. Le profil de cadence d’itération observé est proche de 7 ms au P95 par cas, sans constituer un profilage GPU. Le script verrouille la vie du joueur et ne mesure pas sa survie, d’autres archétypes ennemis, les critiques séparément ni une run représentative. Les valeurs de balance restent **[PROPOSÉES]**.
- [i] La formation `single` expose aussi les armes conçues pour des vagues ou cibles mobiles : Crimson Daggers n’a touché la cible que 2/22, 3/22 et 7/22 fois sur ses volleys pour ses trois builds; ce résultat décrit ce placement précis et n’est pas un score général. Des essais d’Inferno N5 seedés différemment donnent les mêmes dégâts bruts (297,60); le DPS diffère légèrement avec la durée active mesurée à la frame.
- [i] La collecte a été exécutée sur le checkout local avec une modification non commitée de `game/scripts/survival_session.gd` appartenant au travail audio en cours; cette scène n’avait ni boss ni lecture audio dans ce scénario. Une répétition sur un commit propre reste souhaitable avant de figer une baseline.
- [x] Investigation d’Inferno Sprayer, formation `single` (une cible immobile à 26 px) : niveau 1 **11,09**, niveau 5 + relique 5 **16,52**, évolution **21,29 DPS**. Le build évolué atteint **189,69 DPS** en grappe et **82,41 DPS** sur huit chasers en approche. Le résultat concorde avec l’explosion de Wildfire ciblée par `_fire_inferno_sprayer` et couverte par `_wildfire_explodes_and_spreads`; il suggère un effet de cibles multiples, pas un multiplicateur équivalent de dégâts monocible. Un essai par configuration ne suffit pas à calibrer cette arme.

## P9.1 — Reproductibilité des surveys d’armes — 2026-10-17

- [x] `combat_weapon_balance_survey.gd` accepte `--seed=<entier>`, configure le RNG de session via l’interface diagnostique Sandbox et imprime la seed dans sa sortie. Valeur par défaut : `20261017`.
- [x] Deux exécutions `--weapon=inferno_sprayer --formation=single --seed=42017` donnent les mêmes dégâts bruts aux trois builds (200,00 / 297,60 / 372,00). La durée active varie légèrement entre frames (18,00–18,03 s), donc le DPS affiché varie de quelques centièmes; le seed ne rend pas le chronométrage frame-driven identique.
- [x] Régénérer les trois formations complètes avec seed `20261017` remplace les tableaux pré-seed; certaines valeurs changent pour les armes à comportements aléatoires. Aucun tuning **[PROPOSÉ]** n’est modifié.
- [i] Cette vérification montre la reproductibilité des dégâts bruts pour certains cas et seeds, pas une calibration statistique de toutes les branches aléatoires.

## P9.1 — Survey Survival par archétype et arme — 2026-10-17

- [x] `survival_archetype_balance_survey.gd` mesure **360 cas** : 12 archétypes (`chaser`, `sprinter`, `tank`, `shooter`, `buffer`, `exploder`, `shielder`, `summoner`, `summoned`, `elite`, `mid_boss`, `final_boss`) × 10 armes × 3 builds (niveau 1, niveau 5 + relique 5, évolution). Seed `20261017`, difficulté Normal, un ennemi initial à 84 px, joueur immobile à PV ordinaires, dégradation passive des PV désactivée, simulation à ×4, plafond de 18 s simulées et multiplicateur de PV ennemi ×1000. XP et coffres sont désactivés; la sonde vérifie que le build reste exactement celui annoncé. Les options `--enemy`, `--weapon`, `--build` et `--movement` filtrent les cas; `stationary`, `kite` et `orbit` sont les profils de déplacement. Le CSV stationnaire est archivé dans [`data/survival_archetype_balance_seed_20261017.csv`](data/survival_archetype_balance_seed_20261017.csv).

  | Archétype | Survie moyenne | Vivant après 18 s |
  |---|---:|---:|
  | Chaser | 5,07 s | 1/30 |
  | Sprinter | 4,58 s | 1/30 |
  | Tank | 5,74 s | 2/30 |
  | Shooter | 5,25 s | 2/30 |
  | Buffer | 5,55 s | 2/30 |
  | Exploder | 18,03 s | 30/30 |
  | Shielder | 5,73 s | 2/30 |
  | Summoner | 4,73 s | 1/30 |
  | Summoned | 4,86 s | 1/30 |
  | Elite | 4,74 s | 1/30 |
  | Mid Boss | 4,68 s | 1/30 |
  | Final Boss | 4,45 s | 1/30 |

- [i] Le multiplicateur de PV élevé évite que les dégâts de l’arme éliminent rapidement la cible; il empêche aussi d’observer les transitions de phase des boss. Les dégâts de l’arme agrègent les ennemis présents dans la rencontre, donc incluent les invocations du Summoner. Une seule unité initiale ne reproduit ni une vague ni le soutien d’un groupe; les PV nets peuvent inclure le soin sur élimination. L’Exploder se détruit après son explosion. Le chronométrage reste frame-driven.
- [i] Exécution sur le checkout de travail contenant le diff local non commité de `game/scripts/survival_session.gd` associé aux SFX et au rayon du boss; ce diff n’a pas été inclus dans ce commit. Une baseline propre est nécessaire avant tout tuning. Le survey filtré pour `exploder/crimson_daggers/evolved` et la matrice complète terminent avec code 0, sans erreur ni avertissement de ressources.
- [ ] Cette collecte n’équilibre pas les valeurs **[PROPOSÉES]** : il reste à comparer des vagues mobiles et représentatives, les profils de joueur, les affixes d’élite et les phases complètes de boss avant toute conclusion de balance.

## P9.1 — Comparaison stationnaire/orbit — 2026-10-17

- [x] Étendre le survey avec `orbit`: le joueur reste à une distance déterminée par la portée effective de son arme, corrige radialement hors de sa zone et change d’angle toutes les 0,25 s. Ce profil tourne à ×1; `kite` reprend le déplacement d’évasion existant et tourne aussi à ×1. Les runs stationnaires restent à ×4. Aucun changement de gameplay ne découle de ces profils de sonde.
- [x] Comparer sur les 12 archétypes un build unique Lightning Conductor niveau 5 + Storm Core niveau 5, à PV ordinaires et sans HP decay, avec un multiplicateur de PV ennemi ×1000. Le résultat orbit est dans [`data/survival_archetype_orbit_pilot_seed_20261017.csv`](data/survival_archetype_orbit_pilot_seed_20261017.csv). Dix rencontres sur douze atteignent 18 s; le Mid Boss tue le joueur à 16,02 s et le Final Boss à 14,56 s. L’Exploder se détruit; le Summoner fait apparaître des invocations.

  | Archétype | Stationnaire: survie / PV restants | Orbit: survie / PV restants |
  |---|---:|---:|
  | Chaser | 4,19 s / 0 | 18,02 s / 90 |
  | Sprinter | 3,88 s / 0 | 18,01 s / 40 |
  | Tank | 4,59 s / 0 | 18,01 s / 80 |
  | Shooter | 4,27 s / 0 | 18,01 s / 32 |
  | Buffer | 4,47 s / 0 | 18,01 s / 80 |
  | Exploder | 18,02 s / 88,2 | 18,01 s / 88,2 |
  | Shielder | 4,59 s / 0 | 18,01 s / 70 |
  | Summoner | 5,14 s / 0 | 18,01 s / 92,4 |
  | Summoned | 4,00 s / 0 | 18,01 s / 100 |
  | Elite | 4,01 s / 0 | 18,01 s / 60 |
  | Mid Boss | 4,01 s / 0 | 16,02 s / 0 |
  | Final Boss | 3,62 s / 0 | 14,56 s / 0 |

- [i] Le mouvement modifie fortement le résultat; le pilote orbit n’est qu’un profil synthétique d’une rencontre à une cible. Les PV nets incluent le soin d’élimination. Les PV élevés empêchent les transitions de phase des boss, le HP decay est désactivé et un build/une arme ne représentent pas une run. Les paramètres de combat restent **[PROPOSÉS]** et aucun équilibrage n’est validé par cette comparaison.
- [i] Le processus Godot termine avec code 0, mais signale 2 instances ObjectDB et 1 ressource encore référencées après le pilote comprenant les boss; la cause n’est pas attribuée à ce script et reste à diagnostiquer.

- [x] Exercer ensuite le profil orbit sur les dix armes contre un Chaser avec un build niveau 5 + relique niveau 5, seed `20261017`; le relevé brut est dans [`data/survival_weapon_orbit_pilot_seed_20261017.csv`](data/survival_weapon_orbit_pilot_seed_20261017.csv). Il termine avec code 0. Dans ce protocole, les dégâts vont de 0 (Crimson Daggers) à 945 (Lightning Conductor), et Frost Nova tue le joueur à 16,65 s.
- [i] Ce pilote confirme que le contrôleur orbit synthétique ne convient pas à une comparaison générale des armes : son rayon, la géométrie d’attaque et les déplacements propres à chaque arme interagissent différemment. Il sert à diagnostiquer la sonde, pas à comparer ou régler le DPS. Le jeu et les valeurs **[PROPOSÉES]** restent inchangés. Les avertissements ObjectDB/ressource sont reproduits à l’arrêt.

## Revalidation de la suite après export Linux — 2026-10-17

- Première exécution CTest séquentielle sur le checkout courant : **86/87**. Le smoke catalogue inspectait le buffer temporaire d’événements alors que `SurvivalSession` acquitte les événements qu’elle consomme; la course pouvait masquer un dégât déjà appliqué.
- Le smoke vérifie désormais les PV persistants des deux cibles, résultat indépendant de l’acquittement du buffer. Après le changement, `survival_weapon_catalog_smoke` passe **10/10** répétitions et CTest complet **87/87 en 61,48 s**.
- Les résultats ont été obtenus sur un checkout contenant aussi un diff local non commité de `survival_session.gd`; ils ne décrivent donc pas uniquement le commit `61e6b8e`.

## P9.1 — Recalibrage exploratoire d’Overcharge — 2026-10-17

- [x] Le survey `combat_weapon_balance_survey.gd` accepte maintenant `--overcharge-multiplier=0..2` pour une instance de session de mesure uniquement; la valeur testée figure dans chaque ligne CSV. Le défaut runtime est passé de 0,50 à 0,25 après comparaison; le chiffre demeure **[PROPOSÉ]**.
- [x] Quatre seeds (`20261017`–`20261020`) couvrent 10 armes × 3 builds sur cluster, à 0,50 et 0,25. Les fichiers bruts sont [`combat_weapon_balance_cluster_multiseed_20261017.csv`](data/combat_weapon_balance_cluster_multiseed_20261017.csv) et [`combat_weapon_balance_cluster_overcharge_025_multiseed_20261017.csv`](data/combat_weapon_balance_cluster_overcharge_025_multiseed_20261017.csv). Au coefficient 0,25, les médianes Lightning Conductor cluster sont 92,64 / 251,38 / 411,14 DPS (niveaux 1 / 5+relique 5 / évolution), contre 119,85 / 298,94 / 586,46 pour Crimson Daggers. À 0,50, les médianes Lightning dépassent Crimson aux trois builds dans cette formation. Sur un pilote approche (seed `20261017`), Lightning 0,25 mesure 56,95 / 164,83 / 287,26 DPS contre 69,58 / 184,05 / 308,71 pour Crimson; à 0,50, Lightning remonte à 82,33 / 220,97 / 367,81.
- [i] La valeur 0,25 réduit la surreprésentation d’Overcharge par rapport au coefficient 0,50 dans ces scénarios sans établir un équilibre global. Les formations sont synthétiques, l’approche n’a qu’une seed, les mesures ne représentent ni vagues réelles ni synergies complètes, et aucune session humaine ou longue n’est incluse. Les dégâts des autres armes, survie, boss et distribution de loot restent à calibrer.
- [x] Le smoke `survival_weapon_catalog_smoke.gd` vérifie le résultat du défaut 0,25 : coup primaire à 5 dégâts et 5 dégâts de zone sur la cible voisine; une cible hors rayon reste inchangée.

## P9.4 — Navigation des entrées inactives du hub — 2026-10-17

- `survival_hub_smoke.gd` parcourt Succès et Bestiaire avec touches fléchées, D-pad et activation A/Entrée; un clic souris synthétique est aussi envoyé. Les contrôles reçoivent un focus visible mais n’ouvrent aucun panneau ni ne déclenchent de données.
- Le smoke ciblé passe sous Godot 4.7.2 : import projet et hub, **2/2**.
- Les interactions sur vraie souris/manette et le parcours physique complet du menu restent à vérifier sur matériel.

## P4.1 / P9.4 — Entrée d’arme et choix de coffre — 2026-10-17

- `survival_starting_weapon_smoke.gd` vérifie le focus initial, la navigation par flèche bas, la validation Entrée, la pause durant le choix, l’arme réellement équipée et son abréviation dans le HUD.
- `survival_chest_choice_smoke.gd` sélectionne la première offre par clic souris synthétique, puis parcourt une offre de relique au D-pad et la valide avec A; les identifiants de sélection et le nombre de callbacks sont vérifiés.
- Les deux CTest ciblés passent avec l’import projet : `survival_starting_weapon_smoke` 2/2 et `chest_choice_smoke` 2/2. `git diff --check` passe.
- Ces événements Godot synthétiques confirment les chemins logiciels; ils ne constituent pas un essai de souris/manette physique. La navigation manette complète de l’arme de départ et celle de tous les menus restent à parcourir sur matériel.

## Revalidation complète de la suite — 2026-10-17

- CTest séquentiel sur le checkout courant : **87/87 tests passent en 60,64 s**, dont import Godot, rendus Xvfb, armes, boss, progression, Armorless, Sandbox Lab et scénarios Sandbox des dix armes.
- Commande : `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`.
- Le checkout contenait aussi un diff local non commité de `game/scripts/survival_session.gd`; le résultat atteste l’état combiné du checkout, mais ne peut pas être attribué exclusivement au commit `26cd944`. Ce test ne couvre toujours pas le GPU cible ni les interactions physiques.

## P9.4 — Événements d’entrée de l’arbre de compétences — 2026-10-17

- `skill_tree_panel_visual_smoke.gd` envoie une flèche droite puis Entrée pour sélectionner un nœud disponible, et D-pad bas puis A pour parcourir et activer le nœud d’arme disponible. Les signaux doivent garder leurs IDs stables; le test observe uniquement les requêtes et ne débloque rien.
- Le script visuel est maintenant enregistré dans CTest afin que cette couverture clavier/manette synthétique soit exécutée avec la suite Godot.
- Le test ne simule ni l’ergonomie sur une vraie manette ni un parcours physique complet du menu.

## P9.4 — Événements d’entrée de l’inventaire d’équipement — 2026-10-17

- `equipment_panel_visual_smoke.gd` envoie Entrée sur l’action équipée, déplace ensuite le focus par D-pad et envoie A. Le signal d’équipement est observé sans connecter de service qui appliquerait la modification; aucune vente, amélioration ou démolition n’est effectuée.
- Le smoke visuel est enregistré dans CTest. La première exécution révélait 5 instances ObjectDB et 2 ressources retenues à la fermeture; libérer explicitement le panneau supprime ces avertissements. L’exécution directe après correction passe sans message de fuite.
- Les entrées sont synthétiques; la navigation sur une manette physique et le parcours complet de l’inventaire restent à vérifier.

## P9.4 — Contrôles clavier/manette des Options — 2026-10-17

- `ui_settings_smoke.gd` vérifie les flèches sur le slider de volume, Espace puis A sur le plein écran et Échap puis B pour fermer. La réouverture relit les valeurs persistées, puis le smoke remet le plein écran et le volume à leurs valeurs initiales.
- Le smoke passe directement sous Godot 4.7.2 headless et reste déjà enregistré dans CTest. Ces événements synthétiques ne valident pas un parcours avec périphérique physique.

## P9.3 — Option de réduction des effets visuels — 2026-10-17

- [x] `SettingsService` persiste `reduced_visual_effects_enabled` dans `user://settings.cfg`, avec `false` par défaut et repli sûr pour les préférences invalides; le service ne référence ni progression ni saves.
- [x] `OptionsPanel` ajoute un `CheckButton` sous ACCESSIBILITY; `ui_settings_smoke.gd` vérifie le focus et l’activation Entrée/A, la persistance/réouverture, et le layout partagé reste dans les bornes 640×360, 1280×720 et 1920×1080.
- [x] `survival_visual_effects_smoke.gd` confirme l’activation par défaut, la suppression immédiate des effets décoratifs visibles, l’absence de changement au snapshot de combat en pause et la conservation du flux RNG pour les impacts/arcs.
- [i] Sont masqués : trails, impacts décoratifs, pixels de mort, arcs Lightning et flashs Pandemic. Télégraphes, projectiles, champs persistants, statuts et auras restent visibles. Ce périmètre/default reste **[PROPOSÉ]** et attend une vérification en jeu; le smoke ne constitue pas une évaluation sensorielle.
- [x] Après ajout du smoke, CTest séquentiel complet : **92/92 passent en 63,46 s**. Le checkout inclut toujours des changements locaux non committés de `survival_session.gd` liés à l’audio et à la collision de zone du boss, qui n’ont pas été inclus dans cette tranche.

## P9.3 — Musique adaptative Survival — 2026-10-17

- [x] Ajout de la boucle synthwave `Space City` de MintoDog, publiée sous CC0 sur OpenGameArt; le fichier et son SHA-256 sont consignés dans `THIRD_PARTY_NOTICES.md`.
- [x] `adaptive_survival_music.gd` boucle la piste et applique un fondu vers la cible : niveau croissant plafonné selon la vague, accent pendant les boss, atténuation en pause, au choix d’arme/coffre, durant les drafts Armorless et à la fin de run. Ces valeurs sont **[PROPOSÉES]**.
- [x] `adaptive_survival_music_smoke.gd` vérifie le chargement, la boucle, les cibles de volume et le plafonnement; CTest ciblé passe avec `survival_entry_smoke`, `armorless_session_cycle_smoke` et `endless_standard_session_smoke` : **5/5 tests**, import inclus, en 4,72 s.
- [ ] Le mix n’a pas été écouté sur haut-parleurs/casque ni validé sur les plateformes de livraison; les niveaux restent à régler.

## P9.4 — Commandes de l’écran de résultat — 2026-10-17

- `run_result_panel_smoke.gd` utilise Entrée sur Recommencer, D-pad pour atteindre Quitter, A pour émettre la demande de navigation, puis B et Échap pour la fermeture. Aucun callback ne redémarre une run ou ne crédite une récompense dans ce test de présentation.
- Le smoke est ajouté à CTest; l’exécution directe passe mais conserve 4 avertissements ObjectDB et 2 ressources encore référencées à la fermeture.
- La preuve est synthétique et headless; le parcours physique complet reste à vérifier.

## P9.4 — Commandes du menu Pause — 2026-10-17

- `survival_pause_smoke.gd` vérifie le parcours flèche bas/Entrée vers Options, Échap/B pour fermer Options, A pour ouvrir Options, B pour pause/reprise, A pour le verrouillage de vie, et Espace pour l’auto-sélection du coffre. Les horloges, la vague et les positions sont toujours comparées pendant les pauses.
- Le smoke ciblé passe sous Godot 4.7.2 headless. Il signale à la fermeture 14 instances ObjectDB et 6 ressources encore référencées; ces avertissements restent visibles.
- Les événements sont synthétiques et ne remplacent pas un essai avec contrôleur physique.

## P9.4 — Navigation de l’inventaire de run — 2026-10-17

- `survival_pause_inventory_smoke.gd` ouvre l’inventaire avec Entrée, parcourt au clavier puis au D-pad, valide avec A un objet purement informatif et ferme avec B. Le loadout exact est comparé ensuite pour confirmer l’absence de mutation.
- Le smoke ciblé passe sous Godot 4.7.2 et est ajouté à CTest. Il signale à la fermeture 4 instances ObjectDB et 2 ressources encore référencées.
- Entrées synthétiques seulement; la manette physique reste à essayer.

## Revalidation complète CTest après extension des parcours UI — 2026-10-17

- CTest séquentiel : **90/90 tests passent en 60,85 s**, comprenant le smoke de résultat désormais enregistré ainsi que les parcours Options, Pause, équipement et arbre de compétences.
- Commande : `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`.
- Le checkout contient toujours le diff local non commité de `game/scripts/survival_session.gd`; le résultat couvre l’état combiné du checkout. Il ne valide ni les contrôleurs physiques ni le GPU cible.

## Revalidation CTest après ajout de l’inventaire en pause — 2026-10-17

- CTest séquentiel : **91/91 tests passent en 63,20 s**; `survival_pause_inventory_smoke` couvre maintenant aussi la navigation D-pad et l’activation A d’un élément read-only.
- Commande : `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`.
- Le checkout contient toujours le diff local non commité de `game/scripts/survival_session.gd`; les contrôleurs physiques et le GPU cible restent hors de cette validation.

## Revalidation CTest après ajout des smokes UI — 2026-10-17

- CTest séquentiel : **89/89 tests passent en 61,02 s**, y compris les nouveaux parcours d’entrée arbre de compétences et inventaire d’équipement.
- Commande : `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`.
- Le checkout contient toujours le diff local non commité de `game/scripts/survival_session.gd`; cette passe ne valide ni les périphériques physiques ni le GPU cible.

## Revalidation CTest après la collecte DPS — 2026-10-17

- [x] CTest séquentiel : **91/91 tests passent en 62,70 s** avec `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`. Cela revalide les smokes natifs, l’import/rendu Godot, les parcours Sandbox, Survival, progression, Armorless et les dix scénarios d’armes.
- [i] Le checkout comprend toujours le diff local non commité de `game/scripts/survival_session.gd` appartenant au travail audio; aucune modification audio n’a été incluse dans cette étape. Les tests automatisés ne couvrent pas les périphériques physiques, le GPU cible ni une partie complète non assistée.

## P7A/P9.2 — Parcours naturels Armorless exploratoires — 2026-10-17

- [x] Deux lancements de `armorless_natural_run_survey.gd` en Easy, mode kite, seed `20261017`, vitesse ×1, PV ordinaires et sans éliminations scriptées. La sonde sélectionne automatiquement le premier coffre et vérifie que les fichiers de sauvegarde normale gardent les mêmes empreintes.

  | Seed | Résultat | Temps simulé | Kills | Niveau | Parcours |
  |---:|---|---:|---:|---:|---:|
  | 20261017 | Défaite vague 2 | 37,94 s | 12 | 2 | 9 144 px |
  | 20261017 | Défaite vague 2 | 39,84 s | 18 | 3 | 9 600 px |

- [x] Deux échantillons supplémentaires sous Godot 4.7.2 headless, vitesse ×1, Easy, déplacement kite et PV ordinaires : seed `20261030`, défaite vague 2 à 52,04 s (10 kills, niveau 3, 12 524 px); seed `20261031`, défaite vague 3 à 60,81 s (17 kills, niveau 3, 14 627,9 px). Chacun termine avec code 0 et confirme l’absence de modification aux sauvegardes normales; les avertissements de fermeture restent à 2 instances ObjectDB et 1 ressource.

- [i] Les deux répétitions du seed `20261017` produisent des résultats différents, car le contrôleur kite dépend du rythme des frames et la sonde laisse la simulation à vitesse réelle. Les quatre échantillons exploratoires ne constituent ni une run complète ni un modèle de joueur humain et ne valident pas les multiplicateurs **[PROPOSÉS]** d’Armorless. Les quatre processus signalent à l’arrêt 2 instances ObjectDB et 1 ressource encore référencées; les contrôles d’empreintes confirment l’absence d’écriture aux sauvegardes normales.

## Build et lancement depuis un clone Git propre — 2026-10-17

- Clone local neuf du commit `09baf7a`, puis configuration CMake 3.31.12, compilation complète avec GCC 14.2.0, import Godot 4.7.2 et lancement headless de la scène principale : réussis. FetchContent a récupéré le SHA `godot-cpp` verrouillé.
- Première suite CTest séquentielle : 86/87, échec isolé de `survival_weapon_catalog_smoke`; ce smoke a ensuite passé seul et la suite complète relancée a passé **87/87 en 59,98 s**. La cause de l’échec initial n’a pas été établie, donc ce passage n’est pas présenté comme une preuve d’absence d’intermittence.
- Le clone provient du dépôt local et utilise le même hôte et les mêmes outils; il valide la reproductibilité depuis un arbre Git propre, pas depuis une machine Linux indépendante.

## Validation d'isolation Sandbox Lab P8.8 — 2026-10-17

- `sandbox_lab_smoke.gd` écrit un slot normal sentinelle dans son `XDG_DATA_HOME` de test, puis démarre le Lab, applique des builds, lance le combat et effectue Reset; le contenu du slot est comparé octet pour octet à la fin.
- `sandbox_snapshot_smoke.gd` utilise un `XDG_DATA_HOME` séparé et vérifie la même sentinelle après capture, restauration, rejet de version, build dépassant les slots et évolution avant niveau 5 sur l’arme et la relique appariée. `sandbox_preset_smoke.gd` couvre le round-trip share code et les payloads hostiles; `sandbox_profile_build_smoke.gd` compare les profils source avant/après import read-only et refuse les anciens profils sans migration.
- Résultats Godot 4.7.2 headless : les quatre smokes passent. `SandboxLabContext` conserve ses références `progression_service` et `normal_save_service` nulles; aucune route de récompense ou leaderboard n’est fournie au Lab.

### Revalidation sur le checkout courant

- [x] `XDG_DATA_HOME=/tmp/dopamine-goal-sandbox-isolation tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/sandbox_lab_smoke.gd` passe : le Lab démarre sans services de progression/sauvegarde, son reset reste isolé et le slot normal sentinelle est préservé. Exécuté pendant la reprise du goal le 2026-10-17.
- [x] `sandbox_preset_smoke.gd`, `sandbox_snapshot_smoke.gd` et `sandbox_profile_build_smoke.gd` repassent sous Godot 4.7.2, chacun avec un `XDG_DATA_HOME` distinct (`/tmp/dopamine-goal-sandbox-preset`, `-snapshot` et `-profile`). Le round-trip preset, les snapshots et l’import read-only n’altèrent pas le slot normal. Le smoke snapshot termine avec code 0 mais signale encore 2 instances ObjectDB et 1 ressource à la fermeture; ces avertissements connus ne sont pas masqués.
- [x] CTest séquentiel complet sur ce checkout : **87/87 passent en 61,67 s** avec `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`. Cela revalide l’import Godot, les rendus sous Xvfb, les smokes Survival et progression, le Sandbox Lab et les dix scénarios d’armes. Ce résultat ne remplace pas le profilage sur le matériel iGPU cible ni les validations manuelles de P9.

## Revue visuelle ciblée Pause et inventaire — 2026-10-17

- [x] À 640×360 sous Xvfb/Mesa llvmpipe, les captures `/tmp/dopamine-pause.png` et `/tmp/dopamine-run-inventory-current.png` ont été inspectées après une hausse typographique proposée : pause titre 15 px et statut/contrôles 9 px dans une carte 270 px; inventaire noms 10 px et détails 9 px dans sa carte 420×300 px. Les cartes, accents cyan/doré/magenta/rouge, états et scroll suivent le thème partagé pixel art néon.
- [x] `pause_panel_visual_smoke.gd`, `survival_pause_smoke.gd`, `survival_pause_inventory_smoke.gd` et `ui_viewport_layout_smoke.gd` passent sous Godot 4.7.2; les bounds sont vérifiés en 640×360, 1280×720 et 1920×1080. Les smokes Pause/inventaire signalent encore des objets/ressources référencés à la fermeture.
- [ ] Le rendu inspecté utilise Mesa llvmpipe; le matériel graphique cible, l’interaction physique à la souris/manette et la revue visuelle aux tailles agrandies ne sont pas couverts par cette passe.

## P8.1/P8.3 — Mode réellement sélectionné par le preset — 2026-10-17

- [x] Régression rouge d’abord : un preset valide `base_mode=armorless` démarrait silencieusement une session Survival standard.
- [x] `SandboxLabContext` transmet désormais `base_mode` à la session Armorless; le smoke confirme le directeur endless Armorless, l’état temporaire actif et l’absence de `ProgressionService`/`SaveService`.
- [x] **État historique, remplacé le 2026-10-17 par P8.1/P8.3 ci-dessous :** à cette date, un preset `base_mode=endless` renvoyait `mode_unavailable`, et le Lab actif était conservé.

## P8.6 — Validation atomique des évolutions en snapshot — 2026-10-17

- [x] Régression rouge d’abord : `sandbox_snapshot_smoke.gd` a révélé qu’un snapshot assortissant un `evolution_id` valide à une arme/relique sous le niveau 5 pouvait restaurer l’état natif avant le rejet du build et laisser le loadout partiellement remplacé.
- [x] `SandboxBuild` rejette désormais atomiquement toute évolution si l’arme ou sa relique appariée n’est pas niveau 5. `SandboxLabContext.restore_snapshot()` valide donc cette condition avant de toucher à la simulation active.
- [x] `sandbox_snapshot_smoke.gd` vérifie le rejet et préserve les quatre entités, l’horloge de run et le niveau de Storm Core; `sandbox_preset_smoke.gd` confirme qu’une évolution valide au niveau 5 reste acceptée. Les deux passent sous Godot 4.7.2.
- [ ] Le smoke snapshot émet toujours des avertissements ObjectDB/ressources à la fermeture; la gestion SFX est suivie séparément.

## Revalidation P5 après reprise — 2026-10-17

- [x] L’arbitrage utilisateur **[VALIDÉ, 2026-10-17]** fixe Electroplague à 60 px, sans plafond de cibles : un coup direct de Shock sur Poison copie les paramètres et la durée restante du statut aux ennemis vivants à portée; aucun dégât direct, remplacement d’un Poison présent ni propagation depuis les ticks DoT. Le smoke `survival_weapon_catalog_smoke.gd` couvre la frontière du rayon, cinq cibles sans cap, les exclusions et l’absence de dégâts/collisions.
- [x] Après ajout du type de statut à la commande de DoT et passage du snapshot worker au format 16, `make -C build -j4` compile la GDExtension; `simulation_core_tests`, `simulation_worker_tests` et `survival_weapon_catalog_smoke.gd` passent sous Godot 4.7.2. Ce smoke réutilise la session Survival normale sans attacher de service de progression.
- [x] Revalidation complète après Electroplague et snapshot format 16 : CTest séquentiel passe 86/86 sous Godot 4.7.2 en 59,61 s, incluant les smokes Survival et Sandbox des dix armes.
- [x] Gravity Collapse **[VALIDÉE, 2026-10-17]** : le smoke catalogue vérifie l’explosion immédiate à 50 % et 60 px dans un champ Void Orb simulé, la cible à la frontière incluse, celle juste hors rayon exclue, les cibles vivantes seules, et l’absence de déclenchement sur DoT, hors gravité ou depuis la réaction elle-même. `simulation_core_tests`, `simulation_worker_tests` et `survival_weapon_catalog_smoke.gd` passent après reconstruction native.
- [x] CTest séquentiel complet après Gravity Collapse : 86/86 tests passent sous Godot 4.7.2 en 60,47 s, avec les dix scénarios Sandbox d’armes.

- [x] Après le correctif de collision des ennemis immobiles et la reconstruction de la GDExtension Linux, `ctest --test-dir build --output-on-failure -j1` passe 86/86 en 60,45 s sous Godot 4.7.2. La suite comprend l’import Godot, les tests natifs, les smokes Survival/progression et les scénarios Sandbox des dix armes.
- [x] Le smoke `survival_weapon_catalog_smoke` passe également dans cette suite : coexistence Burn/Poison et Toxic Ignition restent conformes aux paramètres **[VALIDÉS]**.
- [x] Le benchmark Debug concentré a été comparé avant/après correction de la collision des ennemis immobiles : moyenne passée d’environ 120 ms à 73 ms/frame. `simulation_core` et `simulation_worker` passent (2/2), puis CTest complet passe (86/86). Les mesures répétées et limites du scénario sont dans [`PERFORMANCE.md`](PERFORMANCE.md).
- [x] Recontrôle ciblé du `survival_wave_director_smoke.gd` sous Godot 4.7.2 headless : passe. Godot affiche à la fermeture 12 instances ObjectDB et 5 ressources encore utilisées; les assertions du smoke réussissent. Ce test complète les preuves des transitions de vague/boss, sans remplacer le parcours manuel.
- [x] Recontrôle ciblé du `survival_boss_attack_smoke.gd` sous Godot 4.7.2 headless : passe. Godot affiche à la fermeture 7 instances ObjectDB et 1 ressource encore utilisée; les assertions des attaques/phases réussissent.
- [x] Recontrôle ciblé de `survival_difficulty_profile_smoke.gd` et `survival_difficulty_unlock_smoke.gd` sous Godot 4.7.2 headless : les deux passent.
- [x] Recontrôle ciblé du `survival_weapon_catalog_smoke.gd` sous Godot 4.7.2 headless : passe, y compris les réactions existantes et leurs règles de causalité. Godot affiche à la fermeture 2 instances ObjectDB et 1 ressource encore utilisée; les assertions réussissent.
- [x] Recontrôle ciblé du `survival_chest_smoke.gd` sous Godot 4.7.2 headless : passe pour les coffres, la collecte XP séparée et les choix de run.
- [x] Recontrôle de `survival_pause_inventory_smoke.gd` sous Godot 4.7.2 headless : passe; la pause conserve le focus et laisse la simulation figée au retour de l’inventaire. Godot affiche à la fermeture 2 instances ObjectDB et 1 ressource encore utilisée.
- [x] Recontrôle ciblé de `survival_loadout_smoke.gd` et `survival_damage_causality_smoke.gd` sous Godot 4.7.2 headless : les deux passent pour l’éligibilité du loadout et l’attribution sans double mort/récompense.
- [x] Recontrôle ciblé de `survival_elite_smoke.gd`, `survival_support_enemy_smoke.gd`, `survival_shielder_smoke.gd`, `survival_summoner_smoke.gd` et `survival_exploder_smoke.gd` : les cinq passent sous Godot 4.7.2 headless. Le smoke élite affiche 8 instances ObjectDB et 4 ressources encore utilisées à la fermeture.
- [x] Recontrôle du `survival_wave_spawn_smoke.gd` sous Godot 4.7.2 headless : passe; une tentative au-delà de l’ancien plafond de première vague ajoute bien un ennemi.
- [x] Exécution directe de `build/simulation_core_tests` et `build/simulation_worker_tests` : les deux binaires terminent avec le code 0. `sandbox_weapon_scenario_validation_smoke.gd` passe aussi sous Godot 4.7.2. Ces vérifications ciblées ne remplacent pas CTest complet; `ctest` et `cmake` ne sont pas détectables dans le PATH courant.
- [x] Rejeu des dix `game/scenarios/weapons/*.json` par `sandbox_weapon_scenario_runner.gd` sous Godot 4.7.2 : les dix passent, chaque rapport `/tmp/dopamine-p5-<arme>.json` contient au moins un événement de dégâts et `progression_service_attached=false`. Les cas ont été exécutés séquentiellement, sans écrire dans un profil de progression.
- [x] La suite automatisée ne prouve pas la run réelle; sa confirmation utilisateur est consignée séparément dans la section P5.V3 ci-dessous.

## Préparation du build Windows — 2026-10-16

- [x] Ajouter `tools/build_windows.ps1` pour configurer MSVC x64, compiler les GDExtensions debug/release, importer le projet et exécuter `sandbox_smoke.gd`.
- [x] Ajouter un preset Windows Desktop x86_64 et le workflow `.github/workflows/build-windows.yml`; le runner installe les templates Godot, exporte le jeu autonome et teste son lancement headless avec les tests natifs C++.
- [x] Tolérer les guillemets saisis comme partie de la valeur du chemin Godot au prompt; le workflow transmet maintenant une valeur avec guillemets littéraux pour couvrir ce cas sur Windows. Un chemin introuvable échoue avant CMake avec une erreur indiquant la forme attendue.
- [ ] Le binaire et le chargement Godot n’ont pas encore été exécutés sur Windows; validation réelle attendue du runner CI.

## Run Survival réelle — validation P5 partielle — 2026-10-16

- [x] Depuis l’accueil et le hub, démarrage manuel d’une run Easy avec Lightning Conductor dans Godot 4.7.2; profil isolé par `XDG_DATA_HOME=/tmp/dopamine-p5-real-profile`.
- [x] Dans le menu Pause, `LOCK HEALTH` et `AUTO PICK FIRST CHEST` étaient OFF; la vitesse ×4 était sélectionnée manuellement. Défaite affichée à la vague 2, temps actif 00:45, 14 éliminations; l’écran a affiché +13 Essence et +18 Basic Powder.
- [ ] Ce parcours établit seulement la branche de défaite. Une victoire réelle, un choix de coffre réel et l’idempotence des récompenses restent à vérifier; les smokes ne ferment pas ces critères P5.V3.

## P5.V3 — Confirmation de run complète — 2026-10-17

- [x] Le créateur confirme avoir déjà joué une run complète en interface réelle et que les contrôles demandés sont bons : victoire contre le boss final sans assistance, choix manuel d’un coffre, récompenses visibles et persistées sans doublon après relance.
- [x] Cette validation est un retour utilisateur direct; la session n’a pas été observée indépendamment. La difficulté, l’arme de départ, la plateforme et les valeurs exactes des récompenses ne sont pas consignées.
- [x] Le créateur confirme aussi que cette run complète valide manuellement P5.4. La difficulté et le loadout ne sont pas précisés; cette confirmation ne documente donc pas à elle seule une run Chaos représentative ni son équilibrage.

## P5.4 — Revalidation ciblée des ennemis, boss et difficultés — 2026-10-16

- [x] Sous Godot 4.7.2 avec données utilisateur isolées, `survival_boss_attack_smoke.gd`, `survival_elite_smoke.gd`, `survival_exploder_smoke.gd`, `survival_difficulty_profile_smoke.gd` et `survival_difficulty_unlock_smoke.gd` passent séquentiellement.
- [x] `survival_elite_smoke.gd` affiche des avertissements ObjectDB/ressources encore référencées à la fermeture après réussite; aucun échec de scénario observé.
- [x] Les trois mutations Chaos sont couvertes : multiplicateur de chance de soutien, sélection de deux affixes distincts et composition de leurs effets, et patterns de boss distincts consécutifs; smokes ciblés d’élite, de spawn et de boss.
- [x] Le créateur confirme avoir vérifié manuellement P5.4 pendant sa run complète jusqu’à la victoire du boss final (voir P5.V3 ci-dessus).
- [ ] L’équilibrage spécifique de ces mutations reste à valider en run Chaos représentative; la difficulté, les affixes rencontrés et le loadout de la run confirmée ne sont pas consignés.

## P5 — Séquence télégraphiée des boss en Chaos — 2026-10-16

- [x] Décision utilisateur **[VALIDÉE]** : après deux attaques normales télégraphiées, enchaîner une attaque télégraphiée existante en Chaos uniquement; Easy à Nightmare gardent leur cadence.
- [x] `survival_boss_attack_smoke.gd` vérifie la cadence des cinq difficultés, les patterns distincts des deux boss et le gel du télégraphe en pause.
- [x] L'intégration du Dopamine Core remplit deux places avec des adds de fixture, exécute le follow-up spirale puis vérifie que l'invocation reste plafonnée à trois.
- [ ] Dégâts/multiplicateurs et ressenti nécessitent aussi un parcours Chaos représentatif.

## P5.2.3 — Prototype Thermal Shock — 2026-10-16

- [x] `survival_weapon_catalog_smoke.gd` vérifie l’impact de réaction pour Burn direct sur une cible Chill et Chill direct sur une cible Burn, le cooldown par cible, l’exclusion des ticks DoT et des coups létaux, ainsi que l’absence de chaînage depuis `thermal_shock`.
- [x] Les deux impacts sont appliqués par le worker natif via le projectile de réaction et produisent respectivement 50 % des dégâts déclencheurs (**[PROPOSÉ]**).
- [x] Trois parcours exploratoires de 120 s simulées maximum avec `thermal_shock_run_survey.gd`, Easy, vitesse ×1, PV ordinaires et spawns normaux. Le bot kite pilote les déplacements; Inferno Sprayer Lv1 et Frost Nova Lv1 sont injectées directement dans le loadout pour garantir les deux statuts; les coffres choisissent leur première offre automatiquement. Les résultats bruts sont dans [`data/thermal_shock_run_survey_20261017.csv`](data/thermal_shock_run_survey_20261017.csv).
- [x] Trois répétitions seedées supplémentaires, mêmes règles Easy ×1 et même loadout forcé; une seed initialement interrompue par la limite générique de 120 s a été relancée avec `DOPAMINE_TEST_TIMEOUT=200s` pour achever le scénario.
- [x] Trois parcours exploratoires supplémentaires sous Godot 4.7.2, Normal ×1, même loadout forcé et bot kite, seeds 20261023–20261025; les trois se terminent par défaite vague 3–4 après 60,06–96,21 s simulées. Les données sont dans [`data/thermal_shock_run_survey_normal_20261017.csv`](data/thermal_shock_run_survey_normal_20261017.csv).
- [x] Reproduction depuis l’archive propre `7221c57`, pour chaque seed 20261023, 20261024 et 20261025 : `DOPAMINE_TEST_TIMEOUT=220s XDG_DATA_HOME=/tmp/dopamine-thermal-<seed> tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/thermal_shock_run_survey.gd -- --seed=<seed> --difficulty=normal`.
- [i] Les six runs Easy ont produit 0–5 événements `thermal_shock` chacune; les trois runs Normal en produisent 4–6 et 16,12–24,16 dégâts de réaction chacune. Ces résultats restent cohérents avec le multiplicateur proposé de 50 %, sans valider sa balance. Les runs restent courtes, avec loadout forcé et bot kite; elles ne représentent pas un parcours humain et ne suffisent pas à calibrer.
- [ ] Le prototype, son cooldown de 1 s et le multiplicateur de 50 % restent **[PROPOSÉS]**; il reste à mesurer leur effet pendant des runs représentatives.

## P5.4.6 — Comparaison exploratoire Chaos/Normal — 2026-10-17

- [x] Quatre paires de runs seedées avec `thermal_shock_run_survey.gd`, Godot 4.7.2, vitesse ×1, PV ordinaires et spawns normaux. Le harness impose Inferno Sprayer Lv1 + Frost Nova Lv1, auto-sélectionne le premier coffre et pilote un bot kite. Les résultats bruts sont dans [`data/thermal_shock_chaos_vs_normal_20261017.csv`](data/thermal_shock_chaos_vs_normal_20261017.csv).
- [x] En Chaos, les quatre essais meurent vague 1 en 6,85–20,14 s, avec zéro élimination; Thermal Shock produit 0–5 événements et 0–20 dégâts. En Normal, les essais meurent vague 1–3 en 26,32–74,34 s, avec 11–25 éliminations et 3–7 événements de réaction (12,04–28,16 dégâts).
- [i] Ces échantillons révèlent surtout les limites du bot et la forte pression du Chaos; le build forcé, les choix automatiques et l’échec avant vague 3 ne calibrent pas le multiplicateur Chaos. Thermal Shock a ensuite été validé par le créateur le 2026-10-17; ces runs ne constituent pas une calibration représentative.
- [x] Chaque exécution a quitté avec code 0, mais Godot a signalé 1–3 ressources et 2–6 instances ObjectDB encore référencées à la fermeture; leur origine n’a pas été isolée et reste à analyser séparément des résultats de gameplay.

## P5.2.3 — Toxic Ignition — 2026-10-16

- [x] Décisions utilisateur **[VALIDÉES]** : explosion immédiate à l’application directe de Burn sur Poison ou Poison sur Burn; dégâts égaux à 50 % du coup déclencheur, rayon 60 px, statuts conservés, une explosion par cible et par seconde.
- [x] `simulation_core_tests` vérifie que Poison et Burn coexistent, infligent chacun leurs ticks à leurs propres intervalles et survivent à la capture/restauration de simulation. La réapplication conserve le remplacement du statut de même type.
- [x] `survival_weapon_catalog_smoke.gd` vérifie l’impact direct, les dégâts de zone dans le rayon, l’exclusion d’une cible hors rayon, le cooldown local et l’exclusion des ticks DoT.
- [x] Le snapshot expose `DamageOverTimeEffects` pour tous les statuts actifs et conserve `DamageOverTime` comme alias du premier statut pour les consommateurs historiques; les anneaux Survival affichent les statuts multiples.
- [ ] Équilibrer la réaction au cours de runs réelles; les DoT distincts coexistent **[VALIDÉ, 2026-10-17]**, et cette tâche concerne uniquement leur calibration en run.

## P7A.4 — Cycle Armorless intégré — 2026-10-16

- [x] `armorless_session_cycle_smoke.gd` accélère les vagues mais utilise la vraie session : 12 drafts de trois équipements temporaires, choix/reprise, boss de vague 12, transition vers la vague 13 et nettoyage d'équipement/Flux à la sortie.
- [x] Avec `--production-duration`, le même smoke traverse 60 vagues de 30 secondes simulées, les 60 drafts et les boss des vagues 12/24/36/48/60 à vitesse ×4. Le fixture verrouille les PV, désactive les drops de coffres classiques et tue les boss par script; ce n'est pas une validation de survie ni un parcours joueur.
- [x] Le smoke vérifie que la session n'a pas de `ProgressionService` et qu'aucun fichier de slot normal n'est écrit.
- [x] `armorless_session_cycle_smoke.gd` rapporte à la fermeture 4 objets ObjectDB et 2 ressources encore référencés après réussite; le résultat du scénario est vert.
- [ ] Ce parcours accéléré ne remplace pas une session Armorless complète à durée de production, ni la calibration de la progression à long terme.

## P7A.5 — Contrat de récompense Armorless — 2026-10-17

- [x] L’utilisateur choisit l’option A : conserver scaling, rareté et récompenses **[PROPOSÉS]** comme base de mesure. Aucun coefficient ni montant n’est promu; voir GDD §13 et `docs/planning/DECISIONS_RESTANTES.md`.
- [x] `armorless_records_smoke.gd` vérifie les montants des formules **[PROPOSÉES]** aux vagues 24 et 25 sur Easy, Normal, Hard, Nightmare et Chaos. Les dix cas confirment que la vague 25 continue la formule sans bonus de victoire du boss final; ils ne valident pas le rythme ressenti ni l’économie.
- [x] Montants Essence/Powder de référence aux vagues 24 → 25 : Easy 44/64 → 46/67; Normal 63/92 → 65/95; Hard 101/138 → 104/143; Nightmare 158/212 → 163/218; Chaos 252/322 → 260/333.
- [ ] Les coefficients restent **[PROPOSÉS]**. Leur calibration demande encore une longue run Armorless sans assistance et une comparaison du rythme de progression des ressources.

## P7B.1 — Déblocage et entrées Endless standard — 2026-10-17

- [x] L’utilisateur valide le déblocage après une victoire Survival, l’accès depuis le hub et la proposition d’une continuation optionnelle après le boss final. Les autres règles de transition et valeurs Endless restent à arbitrer/calibrer.
- [x] Les parcours de hub et continuation sont couverts par `survival_hub_smoke.gd` et `endless_standard_session_smoke.gd`; aucune règle d’état du build n’est promue par cette décision.

## P8.4 — Base de lecture de sauvegarde en Sandbox — 2026-10-16

- [x] `save_service_smoke.gd` vérifie que la lecture seule renvoie un ancien payload sans migration/écriture et refuse un slot courant corrompu même si un backup existe, sans restaurer ni modifier la source. Le chargement normal continue ensuite à récupérer le backup.
- [x] `sandbox_profile_build_smoke.gd` vérifie la copie depuis `read_slot_read_only`, les starters et unlocks du skill tree, les bonus permanents et l’équipement équipé; il compare les octets de la sauvegarde avant/après et refuse sans écriture un ancien profil incomplet.
- [x] `sandbox_lab_smoke.gd` continue de vérifier que le contexte et la session Lab ne reçoivent aucun service de progression ou de sauvegarde; l’import du profil est une copie locale du build uniquement.
- [ ] Essayer l’import depuis le Sandbox Lab interactif avec un profil normal v9 et vérifier le texte de refus sur un profil absent/ancien.
- [x] Import UI valide en mémoire les profils courants et copie le build Sandbox sans exposer de capability d’écriture; migration des profils historiques volontairement refusée ici pour préserver la save source.

## Progression permanente — équipement classique — 2026-10-16

- [x] Contrat de roll d’équipement : `progression_service_smoke.gd` sauvegarde et recharge un percentile maximal `1.0`; le calcul accepte `[0,1]` inclus et refuse percentile non fini/hors plage et enhancement hors `0..10`. `equipment_stats_smoke.gd` et `equipment_enhancement_smoke.gd` passent également.

- [x] `equipment_slots_smoke.gd` couvre les six slots, l’unicité des statistiques dans chaque pièce, et le remplacement d’un objet équipé du même slot sans déséquiper les cinq autres.
- [x] `progression_service_smoke.gd` vérifie qu’une victoire et une défaite distinctes ajoutent chacune une seule pièce et que le retraitement du même `run_id` n’en ajoute pas une seconde.
- [x] Les quatre smokes ciblés passent. La suite séquentielle passe 67/67 sous Godot 4.7.2; `survival_weapon_catalog_smoke` a échoué une première fois de façon intermittente, puis a passé seul et dans le rerun complet.

## P6 — Tirage de rareté équipement — 2026-10-16

- [x] `equipment_rarity_smoke.gd` compare 20 000 tirages seedés à la table attendue pour Easy, Normal, Hard, Nightmare et Chaos, aux vagues 1 et 24; les observations restent dans une tolérance de cinq écarts-types.
- [x] `progression_service_smoke.gd` vérifie les poids, la somme de 100 %, le transfert proposé par paliers de vagues et que le contexte affecte effectivement le résultat généré.
- [ ] La pénalité de mort précoce est maintenant un prototype défini mais **[PROPOSÉ]**; son effet en run réelle et la calibration des taux de rareté restent à mesurer.

### Pénalité de mort précoce — prototype proposé

- [x] `equipment_rarity_smoke.gd` couvre les poids de base sur 20 000 tirages/difficulté/vague, la somme 100 % après pénalité, sa réduction monotone entre vagues 1 et 3, son absence à partir de la vague 6, et l’absence de pénalité pour une victoire. Un tirage de 20 000 objets confirme la distribution précoce pondérée dans une tolérance de cinq écarts-types.
- [x] Le même smoke branche deux ProgressionService isolés et compare la rareté réellement récompensée avec les tirages seedés attendus pour une défaite et une victoire avant vague 6. `progression_service_smoke.gd`, `equipment_stats_smoke.gd` et `survival_progression_smoke.gd` passent sous Godot 4.7.2.
- [ ] Les seuils (avant vague 6), le facteur maximal (50 %) et l’application aux raretés Mystic+ sont **[PROPOSÉS]** et ne sont pas équilibrés; ils n’influencent pas les paramètres de base ou les récompenses de progression.

## P6.7 — Évaluateur générique d’achievements — 2026-10-16

- [x] Revalidation sur le checkout courant : `XDG_DATA_HOME=/tmp/dopamine-goal-progression-idempotence tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/progression_service_smoke.gd` passe sous Godot 4.7.2, couvrant les fixtures de migration, récompenses, achievements et refus du double crédit par `run_id`.
- [x] Revalidation de cette extension sous Godot 4.7.2 : `progression_service_smoke.gd`, `survival_progression_smoke.gd` et `survival_elite_smoke.gd` passent. `ctest` n’est pas installé/détectable dans l’environnement courant, donc la suite complète n’a pas été relancée. Le smoke élite affiche à la fermeture des avertissements de ressources encore référencées, sans échec fonctionnel.

- [x] Le profil v8 a introduit les valeurs de métriques, les paliers par ID d’achievement et les records Armorless; v9 ajoute les records Endless et le déblocage de mode. `progression_service_smoke.gd` vérifie la migration des profils v1–v6, dont un profil v6 avec progression Exterminator existante, sans perte des kills/paliers/ressources; les smokes Armorless/Endless couvrent les migrations v7 et v8.
- [x] `award_survival_run` met à jour les métriques de kills cumulés, kills par type ennemi, meilleure vague, runs terminées, victoires au boss final et victoires Chaos. Les répétitions de `run_id` ne progressent aucune métrique deux fois.
- [x] Le catalogue compte maintenant 100 familles; le plancher de la cible **[VALIDÉE]** de 100–150 est atteint. Les 12 familles `enemy_hunter_*` suivent les éliminations par type ennemi; les dix `weapon_mastery_*` agrègent les dégâts attribués par arme, les dix `weapon_killer_*` ses éliminations, les onze `relic_mastery_*` le niveau maximal des reliques, les dix `evolution_mastery_*` les évolutions, et dix suivent runs/victoires de boss par difficulté. Les dix nouvelles `weapon_level_mastery_*` enregistrent le niveau maximal de chaque arme; six `elite_affix_hunter_*` suivent les affixes éliminés et `elite_affix_variety` le nombre de types rencontrés. Les compteurs d’équipement, difficulté et diversité d’affixes sont dérivés/refusés lorsqu’ils sont injectés par `run_metrics`. `progression_service_smoke.gd` vérifie les paliers et la migration additive d’un profil v7 qui contenait 83 familles; `survival_elite_smoke.gd` passe par le bilan de run et vérifie le compteur de l’affixe réellement tué ainsi que le niveau d’arme. Les seuils et bonus de ces familles restent **[PROPOSÉS]**; la cible éditoriale de 120 familles reste **[PROPOSÉE]**.
- [x] Smokes ciblés passés sous Godot 4.7.2 : `progression_service_smoke.gd`, `survival_difficulty_profile_smoke.gd`, `survival_progression_smoke.gd`, `survival_weapon_catalog_smoke.gd` et `run_result_panel_smoke.gd`.
- [x] Le chemin temporaire sans `SaveService` fournit seulement les quatre entrées d’équipement de départ et ne peut pas sauvegarder; `survival_progression_smoke.gd` couvre la run sans sauvegarde.

## P6.9 — Baseline synthétique de balance — 2026-10-16

- [x] Commande : `tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/progression_balance_survey.gd`.
- [x] Le script mesure 3 profils × 5 difficultés × 3 seeds (45 runs), avec les mêmes seeds par difficulté entre profils. Les profils sont construits dans `user://progression_balance_survey/`; les récompenses et sauvegardes normales sont désactivées. Les bonus affichés viennent du `ProgressionService` réel.
- [x] Chaque run est immobile, sans invincibilité, accélérée à 4× moteur et 4× simulation; XP et coffres sont artificiellement à portée et le premier choix est pris automatiquement. La mesure s’arrête à la mort ou après 720 s simulées. Les durées ci-dessous sont les médianes simulées jusqu’à la mort; les éliminations sont aussi les médianes.

| Profil | Easy | Normal | Hard | Nightmare | Chaos |
|---|---:|---:|---:|---:|---:|
| Neuf — survie / éliminations | 12,8 s / 8 | 9,6 s / 4 | 8,3 s / 1 | 7,5 s / 1 | 7,4 s / 0 |
| Intermédiaire — survie / éliminations | 14,6 s / 12 | 9,6 s / 4 | 8,3 s / 1 | 7,5 s / 1 | 7,5 s / 0 |
| Arbre complet — survie / éliminations | 13,7 s / 10 | 9,6 s / 4 | 8,3 s / 1 | 7,9 s / 1 | 7,5 s / 0 |

- [x] Les 45 runs se terminent en vague 1. Les dégâts sortants moyens par seconde sont mesurés et imprimés par le script; ces résultats et la survie évoluent peu entre les builds à partir de Normal.
- [ ] Ce protocole mesure un joueur immobile et une collecte artificiellement facilitée; il ne représente pas un parcours humain et ne permet pas de régler le tuning de difficulté. Aucun paramètre **[PROPOSÉ]** n’a été modifié sur cette seule base. Une calibration représentative et une durée de run complète restent requises pour P6.9.
- [x] Le script s’exécute avec `-- --tier=fresh --difficulty=easy --replicates=1` pour un cas ciblé; `--replicates=N` accepte 1 à 10.
- [x] Godot retourne le code 0, avec un avertissement ObjectDB de ressources encore référencées à la fermeture, également visible sur les parcours du harness; il n’affecte pas les résultats imprimés.

### Parcours carré scripté — 2026-10-16

- [x] Option `--movement=square` pilote le contrôleur réel avec les actions droite, bas, gauche, haut, en changeant de direction toutes les trois secondes simulées; la distance cumulée parcourue est ajoutée au CSV. `--movement=still` conserve le protocole précédent par défaut.
- [x] Smoke exploratoire exécuté avec `--movement=square --replicates=1` : 3 profils × 5 difficultés, même seed initial par difficulté entre profils. Chaque run utilise la session réelle, XP/coffres artificiellement à portée, auto-choix et vitesse ×4. La distance minimale mesurée était >3 200 unités; aucun cas n’a échoué au contrôle de déplacement.

| Profil | Easy (s / vague / kills) | Normal | Hard | Nightmare | Chaos |
|---|---:|---:|---:|---:|---:|
| Neuf | 84,0 / 3 / 15 | 61,7 / 3 / 10 | 38,7 / 2 / 0 | 32,5 / 2 / 0 | 34,5 / 2 / 0 |
| Intermédiaire | 84,5 / 3 / 8 | 96,0 / 4 / 22 | 43,5 / 2 / 0 | 37,3 / 2 / 0 | 12,9 / 1 / 0 |
| Arbre complet | 401,2 / 12 / 292 | 64,9 / 3 / 7 | 29,3 / 1 / 0 | 30,4 / 2 / 0 | 40,9 / 2 / 0 |

- [ ] Ce parcours est scripté et synthétique, sans décision d’évitement, avec un seul seed par combinaison. Des reruns identiques varient (fresh/Easy : 71–85 s et 8–15 kills observés), donc les chiffres du tableau sont un relevé exploratoire et non un résultat statistique. Il ne permet pas de représenter un joueur, comparer statistiquement les builds ou ajuster des paramètres **[PROPOSÉS]**; aucun tuning n’a été modifié. Les parcours humains et plusieurs seeds restent requis pour fermer P6.9.

### Reruns mobiles Easy — profil neuf — 2026-10-16

- [x] Commande : `tools/run_godot_test.sh /tmp/dopamine-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/progression_balance_survey.gd -- --tier=fresh --difficulty=easy --movement=square --replicates=3` avec un `XDG_DATA_HOME` isolé.
- [x] Le CSV indique désormais explicitement `boss_defeated` et distingue `victory`, `defeat` et `timeout` à partir du titre du résultat Survival. Vérification ciblée : fresh/Easy/square, une réplication, 67,48 s simulées, vague 3, défaite et `boss_defeated=false`; aucune récompense persistée.
- [x] Trois sessions Survival réelles du harness, sans invincibilité, XP et coffres accessibles automatiquement : 47,07 / 67,88 / 66,18 secondes simulées; 9 / 12 / 10 kills; vague 2 / 3 / 3; DPS sortant 4,05 / 4,10 / 4,84; distance 11 440 / 16 288 / 15 888 unités. Chaque run finit par défaite, sans récompense persistée.
- [ ] Échantillon limité à un profil, une difficulté et une politique de mouvement carrée sans évitement. Il établit la dispersion de ce protocole seulement; aucun paramètre **[PROPOSÉ]** n’est ajusté et P6.9 reste ouvert.

### Parcours adaptatif kite — profil neuf, Easy — 2026-10-17

- [x] Le survey accepte `--movement=kite`. Toutes les 0,5 s simulées, il choisit une direction combinant recul et tangente à l’ennemi vivant le plus proche, via les actions clavier réelles. Il ne modifie ni les dégâts, ni les PV, ni les drops; les choix de coffre restent automatiques comme dans les autres parcours.
- [x] Reproduction : `tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/progression_balance_survey.gd -- --tier=fresh --difficulty=easy --movement=kite --replicates=3`.
- [x] Trois seeds indépendants sous Godot 4.7.2 headless, sans invincibilité : survie 34,05 / 46,46 / 44,15 s; vagues atteintes 2 / 2 / 2; éliminations 3 / 6 / 11; DPS sortant 4,24 / 4,09 / 7,36; distance 8 304 / 11 168 / 10 608 unités. Les trois runs finissent par défaite, sans récompense persistée.
- [ ] Il s’agit d’un contrôleur déterministe simplifié, pas d’un parcours humain ou d’un évitement complet. Trois runs Easy sur un profil ne suffisent pas au calibrage; aucune valeur **[PROPOSÉE]** n’a été modifiée et P6.9 reste ouvert.

### Recontrôle Easy/kite — profil neuf — 2026-10-17

- [x] Nouvelle exécution sous Godot 4.7.2 headless, `XDG_DATA_HOME` isolé, ×4 simulation/moteur, sans invincibilité ni kills scriptés, mêmes paramètres que le parcours kite ci-dessus.
- [x] Trois répétitions : 73,50 / 43,07 / 52,23 s simulées, vagues 3 / 2 / 2, éliminations 14 / 3 / 12, niveaux XP 5 / 2 / 4, DPS 3,91 / 3,71 / 5,68. Toutes finissent en défaite, `boss_defeated=false`, avec 100 PV de perte cumulée.
- [x] Un lancement séparé du même replicate 1 a donné 39,76 s, vague 2, 6 kills et 3,80 DPS; les valeurs varient malgré le même scénario nominal. Ensemble avec le relevé précédent (34,05 / 46,46 / 44,15 s), cela confirme une forte dispersion du harness/runtime. Cet échantillon ne modifie aucun paramètre **[PROPOSÉ]** et n’est pas une validation de difficulté par un joueur humain.

### Matrice multi-profil kite — 2026-10-17

- [x] Reproduction : `DOPAMINE_TEST_TIMEOUT=1800s tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path game --script res://tests/progression_balance_survey.gd -- --tier=all --difficulty=all --movement=kite --replicates=3`.
- [x] 45 sessions réelles de Survival, à ×4 moteur et simulation, sans invincibilité ni kills scriptés; XP/chests restent accessibles automatiquement. Le contexte de profil est isolé sous `user://progression_balance_survey/`; aucun gain de run n’est persisté. Toutes les sessions terminent en défaite avant le boss final.

| Profil | Difficulté | Survie médiane (s) | Vague médiane | Kills médianes | DPS médian |
|---|---|---:|---:|---:|---:|
| Neuf | Easy | 48,72 | 2 | 5 | 3,03 |
| Neuf | Normal | 22,92 | 1 | 9 | 6,56 |
| Neuf | Hard | 22,67 | 1 | 0 | 5,23 |
| Neuf | Nightmare | 31,36 | 2 | 0 | 2,30 |
| Neuf | Chaos | 16,21 | 1 | 0 | 2,60 |
| Intermédiaire | Easy | 62,23 | 3 | 5 | 2,94 |
| Intermédiaire | Normal | 54,69 | 2 | 6 | 4,48 |
| Intermédiaire | Hard | 17,79 | 1 | 1 | 6,86 |
| Intermédiaire | Nightmare | 26,67 | 1 | 0 | 5,96 |
| Intermédiaire | Chaos | 19,55 | 1 | 0 | 3,74 |
| Arbre complet | Easy | 35,43 | 2 | 7 | 6,48 |
| Arbre complet | Normal | 29,35 | 1 | 5 | 5,50 |
| Arbre complet | Hard | 30,92 | 2 | 1 | 6,37 |
| Arbre complet | Nightmare | 16,77 | 1 | 0 | 3,71 |
| Arbre complet | Chaos | 12,32 | 1 | 0 | 3,55 |

- [ ] La durée médiane n’augmente pas systématiquement avec la progression permanente; la politique kite ne ramasse pas assez d’XP pour atteindre un build de run complet et ne modélise pas un joueur humain. Les écarts et les défaites précoces caractérisent ce protocole, pas une preuve d’équilibre ni une autorisation d’ajuster les valeurs **[PROPOSÉES]**. Parcours humains, progression normale durant une longue run et calibration ressentie restent requis pour fermer P6.9.
- [x] Godot termine avec le code 0; il affiche à l’arrêt des avertissements ObjectDB/ressources encore référencées par le harness, sans échec de session ni récompense enregistrée.

### Pilote collecte d’XP — profils Easy appariés — 2026-10-17

- [x] Le profil `--movement=loot` vise l’orbe XP ou le coffre le plus proche avec les rayons normaux de collecte et s’écarte des ennemis à moins de 100 unités. Le premier choix de coffre est auto-sélectionné. Aucun paramètre de combat ou de pickup n’est modifié.
- [x] Reproduction avec un `XDG_DATA_HOME` temporaire isolé : `XDG_DATA_HOME="$(mktemp -d)" tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/progression_balance_survey.gd -- --tier=all --difficulty=easy --movement=loot --replicates=3`.
- [x] Les neuf runs sont appariées par seed entre profils, utilisent les bonus réels du ProgressionService, conservent les PV ordinaires et n’exécutent aucun kill scripté. Le niveau XP final varie de 4 à 11. Les médianes sont archivées dans [`data/progression_balance_loot_pilot_seed_20261017.csv`](data/progression_balance_loot_pilot_seed_20261017.csv).

  | Profil | Survie médiane | Kills médians | Niveau XP médian | DPS médian | Résultat médian |
  |---|---:|---:|---:|---:|---|
  | Neuf | 20,19 s | 17 | 5 | 13,33 | Défaite, vague 1 |
  | Intermédiaire | 21,54 s | 18 | 5 | 13,79 | Défaite, vague 1 |
  | Arbre complet | 22,64 s | 20 | 6 | 16,46 | Défaite, vague 1 |

- [i] Le profil collecte davantage d’XP que `kite`, mais ne permet pas de représenter un joueur : l’itinéraire est synthétique et l’offre de coffre est choisie automatiquement. Une run full-profile a varié jusqu’à 53,81 s, vague 2 et 71 kills; l’échantillon de trois seeds est donc très dispersé. Tous les cas finissent en défaite avant la vague 3. Aucun chiffre **[PROPOSÉ]** n’est recalibré; P6.9 reste ouvert.
- [x] Godot termine avec code 0; avertissements ObjectDB/ressources référencées à la fermeture, comme sur les autres harness de session.

### Matrice multi-profil collecte d’XP — 2026-10-17

- [x] Reproduction : `XDG_DATA_HOME="$(mktemp -d)" DOPAMINE_TEST_TIMEOUT=1800s tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/progression_balance_survey.gd -- --tier=all --difficulty=all --movement=loot --replicates=3`.
- [x] Le relevé couvre 45 sessions (3 profils × 5 difficultés × 3 seeds), sans invulnérabilité, dégâts ou kills artificiels. XP et coffres gardent leurs rayons de production; le contrôleur choisit l’orbe/coffre le plus proche et écarte les ennemis proches. Toutes les sessions finissent en défaite vague 1; aucun boss n’est vaincu. Données brutes : [`data/progression_balance_loot_survey_seed_20261017.csv`](data/progression_balance_loot_survey_seed_20261017.csv).
- [i] Pour les taux de coffre **[PROPOSÉS]** (0,5 % par famille et mort ordinaire), ces 45 runs ne sont pas une base de calibration : durée active 3,68–24,13 s, 0–19 kills par profil. En supposant deux tirages indépendants par mort et sans filet (aucune run n’atteint 60 s), la chance théorique d’obtenir au moins une famille sur une run médiane est 2,96 % pour les profils neuf/intermédiaire et 3,93 % pour l’arbre complet; les bornes observées sont 0–17,34 % (1,00–17,34 % pour l’arbre complet). Le CSV ne compte pas les drops observés; ce calcul ne mesure donc pas le résultat des runs et ne valide pas les taux. Ce résultat explique pourquoi P5.3.4 reste ouvert.

  | Profil | Difficulté | Survie médiane | Kills médians | Niveau XP médian | DPS médian |
  |---|---|---:|---:|---:|---:|
  | Neuf | Easy | 19,58 s | 16 | 5 | 11,27 |
  | Neuf | Normal | 13,73 s | 10 | 4 | 14,49 |
  | Neuf | Hard | 8,51 s | 3 | 2 | 11,35 |
  | Neuf | Nightmare | 4,95 s | 1 | 1 | 7,98 |
  | Neuf | Chaos | 3,85 s | 0 | 1 | 9,36 |
  | Intermédiaire | Easy | 20,77 s | 17 | 5 | 14,12 |
  | Intermédiaire | Normal | 16,77 s | 13 | 4 | 12,81 |
  | Intermédiaire | Hard | 8,43 s | 3 | 2 | 11,78 |
  | Intermédiaire | Nightmare | 6,28 s | 2 | 2 | 15,24 |
  | Intermédiaire | Chaos | 3,93 s | 0 | 1 | 9,78 |
  | Arbre complet | Easy | 20,61 s | 19 | 5 | 17,45 |
  | Arbre complet | Normal | 14,92 s | 12 | 4 | 12,82 |
  | Arbre complet | Hard | 8,93 s | 4 | 2 | 13,64 |
  | Arbre complet | Nightmare | 6,36 s | 2 | 2 | 13,90 |
  | Arbre complet | Chaos | 4,51 s | 1 | 1 | 11,60 |

- [i] Le profil complet améliore le DPS médian, mais pas la survie de façon uniforme. Les 45 runs perdent avant la deuxième vague; ces contrôles ne représentent toujours pas une navigation humaine ou une run complète. Un deuxième relevé Easy avec les seeds nominaux appariés a donné des résultats différents du pilote précédent, ce qui confirme la sensibilité au cadencement des frames et des choix auto. Aucun réglage **[PROPOSÉ]** n’est modifié; cette matrice ne clôt pas P6.9.
- [x] Godot retourne le code 0; il signale à l’arrêt six instances ObjectDB et trois ressources encore référencées par le harness.

### Vérification des graines à ×1 — 2026-10-17

- [x] Le survey seed maintenant les RNG de la session, du loadout et du directeur de coffres avant de réactiver le traitement de la session; le profil `loot` s’exécute à vitesse réelle ×1 et imprime cette vitesse dans son CSV.
- [x] Reproduction : `XDG_DATA_HOME="$(mktemp -d)" tools/run_godot_test.sh tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path game --script res://tests/progression_balance_survey.gd -- --tier=fresh --difficulty=easy --movement=loot --replicates=1`, exécutée deux fois avec le même seed `20261016` et le même XDG temporaire.
- [x] Les deux runs atteignent le niveau 6 et perdent en vague 1, mais diffèrent : 23,56 s / 24 kills / 13,21 DPS contre 26,41 s / 26 kills / 16,26 DPS. Valeurs brutes : [`data/progression_balance_loot_repeatability_seed_20261017.csv`](data/progression_balance_loot_repeatability_seed_20261017.csv).
- [i] Les seeds sont fixes, mais le replay ne l’est pas encore. Cette comparaison ne permet pas d’attribuer l’écart à l’ordonnancement du worker ou au cadencement des frames; la cause reste à isoler. Les anciennes matrices ×4 demeurent des échantillons exploratoires et aucun paramètre **[PROPOSÉ]** n’est modifié.
- [x] Les deux exécutions retournent le code 0; les avertissements de ressources référencées à la fermeture varient d’un run à l’autre.

## P6.3 — Portée de ramassage équipement et XP — 2026-10-16

- [x] `equipment_stats_smoke.gd` charge un seul bonus d’équipement par profil et lance une session Survival séparée par stat; vérifie HP, mobilité, dégâts, cadence, chance et dégâts critiques, soin par élimination, aire, cooldown, XP, portée de collecte et vitesse projectile.
- [x] `survival_chest_smoke.gd` passe sous Godot 4.7.2; le rayon bonus et Magnetic Pulse Magnet Heart attirent progressivement les orbes XP, tandis qu’un coffre placé au-delà de `chest_collection_radius` reste intact.

## P6 — Bonus automatiques des niveaux XP — 2026-10-16

- [x] `survival_xp_run_bonuses_smoke.gd` vérifie les douze stats dans l’ordre validé, le redémarrage du cycle après douze gains, un point de pourcentage par stat, la hausse de PV max/current de 1 % au tour correspondant en conservant le ratio, les valeurs de contribution du hub, et la remise à zéro à la création d’une nouvelle run.
- [x] Exécuté avec Godot 4.7.2 headless; aucune sauvegarde n’est chargée ou modifiée par ce scénario.
- [ ] Le tuning de combat et l’effet de la rotation sur la durée/équilibre des runs restent à mesurer dans les parcours représentatifs P6.9.

## P6.4 — Enhancement — 2026-10-16

- [x] `equipment_enhancement_smoke.gd` vérifie les niveaux +0..+10 avec chaque tier Powder, réussite garantie au dixième essai, échec normal, échec critique avec protection au niveau 0, coûts proposés par niveau/rareté et conversions 10:1 à sens unique. Coûts et probabilités restent **[PROPOSÉS]** et non calibrés.
- [x] `equipment_economy_smoke.gd` vérifie les ventes uniques des cinq raretés, le crédit Essence sans Powder, et le rejet d'un fail streak hors plage 0..9. `survival_inventory_smoke.gd` vérifie la confirmation avant vente et le rafraîchissement de l'inventaire; les valeurs de vente restent **[PROPOSÉES]** et non calibrées.
- [x] Revalidation ciblée sous Godot 4.7.2 le 2026-10-17 : `equipment_enhancement_smoke.gd` passe après l’ajout de la sonde d’espérance; les branches de réussite/échec sont toujours couvertes par le service réel.
- [x] Le 2026-10-17, `equipment_economy_smoke.gd` revalide les ventes et couvre aussi le démantèlement des cinq raretés : yields Basic/Refined/Pure attendus, soldes cumulés par tier, suppression de chaque pièce et refus d’un second crédit. Les rendements restent **[PROPOSÉS]**.

## P6.4 — Prix du reroll d’effet unique — 2026-10-17

- [x] Décision utilisateur, réponse A : chaque reroll coûte 1 Powder Pure pour un équipement Legendary ou 1 Powder Prismatic pour un Mythic. La règle est documentée dans le GDD et le registre; le reroll reste à implémenter, donc aucune vérification runtime du débit n’est revendiquée.
- [x] Décision utilisateur, réponse A : garder la conversion 10:1 strictement ascendante, sans restitution ni plafond/provenance supplémentaires. `equipment_enhancement_smoke.gd` couvre le sens ascendant, le refus depuis Prismatic et les conversions 10:1; aucun changement runtime requis pour cette décision.

## P6.4 — Arbitrage et contrôle statistique Enhancement — 2026-10-17

- [x] L’utilisateur valide l’option A : garder les tables de coûts, chances et démantèlement proposées comme base à calibrer par essais; cela ne valide aucun chiffre. Voir le GDD §8 et `docs/planning/DECISIONS_RESTANTES.md`.
- [x] `enhancement_probability_smoke.gd` exécute 800 000 tirages de réussite et 400 000 tirages conditionnels d’échec critique avec le même helper que la transaction de production. Les fréquences seedées par tier/niveau restent dans cinq écarts-types binomiaux des tables **[PROPOSÉES]**; le test contrôle aussi la réussite garantie après neuf échecs consécutifs. Reconfiguration CMake puis CTest ciblé (import Godot, enhancement, service de progression et économie) : **5/5 passent en 4,68 s**.
- [i] Le contrôle vérifie l’implémentation et les tables configurées, il ne calibre pas la provenance/mix des tiers, l’afflux de Powder, les dépenses réelles ou le rythme ressenti. Ces mesures représentatives restent ouvertes; aucune valeur n’a été ajustée ni promue.

## P6.4 — Espérance analytique de l'enhancement — 2026-10-17

- [x] `enhancement_economy_expected_cost.gd` résout les états absorbants (niveau 0–9 × fail streak 0–9) à partir des constantes de `ProgressionService`; la réussite au dixième essai, les pertes critiques avec plancher +0 et le coût appliqué à chaque tentative sont inclus. Le script s’exécute sans écriture de sauvegarde.
- [x] Résultats attendus pour une ligne +0→+10 en gardant le même tier de Powder à chaque tentative :

  | Powder | Tentatives attendues | Coût si Normal | Coût si Mythic | Niveaux perdus par échecs critiques (espérance) |
  |---|---:|---:|---:|---:|
  | Basic | 34,543 | 3 407,15 | 13 628,60 | 2,129 |
  | Refined | 18,844 | 1 771,96 | 7 087,86 | 0,400 |
  | Pure | 14,311 | 1 313,67 | 5 254,69 | 0,081 |
  | Prismatic | 12,425 | 1 126,75 | 4 506,99 | 0,012 |

- [x] Les vingt combinaisons poudre/rareté complètes sont archivées dans [`data/enhancement_expected_cost_20261017.csv`](data/enhancement_expected_cost_20261017.csv); le script peut les régénérer.
- [x] Recalcul sous Godot 4.7.2 sur le checkout courant : les 20 lignes générées correspondent exactement aux valeurs archivées; le modèle ne modifie aucun profil.
- [i] L’espérance est une propriété des chiffres proposés et du modèle de code, pas une validation de rythme. Elle ne modélise ni la provenance et le mélange de tiers, ni les récompenses/démantèlements, ni les conversions réellement choisies. Les probabilités, coûts et rendements restent **[PROPOSÉS]**; la calibration joueur demeure ouverte.

## P6 — CTest après couverture des démantèlements — 2026-10-17

- [x] CTest séquentiel sur le checkout courant : **112/112 tests passent en 75,70 s** sous Godot 4.7.2, après extension de `equipment_economy_smoke.gd` aux yields de démantèlement des cinq raretés.

## P6.5 — Revive unique — 2026-10-17

- [x] Décisions utilisateur, réponses C, B, B, B, A puis B : l’effet `revive_once` équipé accorde au plus un revive par run en Survival et Endless standard; au coup fatal, un dialogue demande confirmation; l’utilisation restaure 50 % des PV max et accorde 3 s d’invulnérabilité. Endless Armorless et Sandbox Lab sont exclus. `revive_knockback` demeure lisible pour les anciennes sauvegardes sans effet gameplay.
- [x] `survival_revive_smoke.gd` charge l’effet via une vraie pièce équipée, vérifie le dialogue fatal, le refus, la confirmation, les PV restaurés, le blocage puis le retour des dégâts, le plafond d’une utilisation, Endless standard, Armorless et le Sandbox diagnostique.
- [x] `survival_inventory_smoke.gd`, `progression_service_smoke.gd`, `endless_standard_session_smoke.gd`, `sandbox_preset_smoke.gd`, `sandbox_lab_smoke.gd` et `survival_run_result_smoke.gd` passent sous Godot 4.7.2; import headless de l’éditeur réussi.
- [i] Les smokes de session affichent à l’arrêt des avertissements ObjectDB et de ressources audio Ogg encore référencées; les tests retournent le code 0. CMake/CTest ne sont pas disponibles localement pour régénérer et exécuter le manifeste après l’ajout du test.

## P6.5 — Effet Elite Haste — 2026-10-16

- [x] `survival_elite_smoke.gd` équipe `elite_haste` dans un profil temporaire isolé, tue un élite via le pipeline de dégâts natif, puis vérifie le bonus de mobilité de 15 %, son expiration après trois secondes simulées et le feedback HUD. Ces valeurs restent **[PROPOSÉES]**.

## P6.5 — Scénarios d’effets uniques — 2026-10-16

- [x] `survival_unique_effects_smoke.gd` vérifie l’absence d’effet sans équipement, le ciblage visible et le cooldown de Lightning Burst, puis l’inactivité d’Evolution Shockwave avant évolution et son unique activation à huit projectiles au tir suivant. Les réglages restent **[PROPOSÉS]**.

## P6.5 — Reroll gratuit du premier coffre — 2026-10-16

- [x] `free_chest_reroll_smoke.gd` équipe le reroll gratuit dans un profil temporaire, l’active au clavier, vérifie que les offres remplacées ne reviennent pas et qu’aucun reroll n’est offert au coffre suivant.
- [x] `progression_service_smoke.gd` vérifie que `revive_knockback` ne peut plus être choisi, mais reste lisible dans un profil qui le contient déjà.

## P5 — Chaînes Lightning — 2026-10-16

- [x] Un arc Lightning ignore désormais sa cible source afin que le saut touche l’ennemi suivant, y compris lorsque les cibles sont très proches; sa position de départ est bornée par l’écart au prochain ennemi.
- [x] `simulation_core_test` vérifie que `lightning_arc:*` ne retouche pas sa source et frappe la cible suivante. `survival_weapon_catalog_smoke.gd` passe dix exécutions consécutives après le correctif.

## P5 — Configuration des coffres — 2026-10-16

- [x] `survival_chest_director_smoke.gd` vérifie les chances configurables Ordinary/Elite, le filet anti-malchance configurable et les coffres boss garantis; `survival_loadout_smoke.gd` couvre les poids des offres.
- [x] Revalidation Godot 4.7.2 : `survival_weapon_catalog_smoke.gd`, `survival_boss_attack_smoke.gd` et `survival_chest_smoke.gd` passent. `survival_elite_smoke.gd` a d'abord révélé que les profils avec deux armes/reliques débloquées ne pouvaient recevoir de coffre, car le drop exigeait exactement trois options; le filtre accepte maintenant tout pool non vide et le smoke élite passe avec cette configuration de débutant. Les smokes arme/coffre signalent encore des objets/resources en usage à leur fermeture, sans échec fonctionnel.
- [ ] Les rerolls d’offres ne sont pas exposés pendant les runs et restent différés jusqu’à l’intégration des effets uniques de progression P6.5.

## P5.1.13 — Magnetic Pulse — 2026-10-16

- [x] `simulation_core_tests` vérifie l’accélération progressive des seules orbes XP dans le rayon, la vitesse maximale, le déplacement non instantané et l’arrêt du mouvement à la fin de l’impulsion.
- [x] `survival_chest_smoke.gd` vérifie l’impulsion périodique, le mouvement visible d’une orbe sans téléportation, sa collecte seulement dans le rayon XP normal, l’arrêt complet pendant la pause, et l’exclusion des coffres.
- [x] La GDExtension Linux et le cœur natif compilent; `simulation_core_tests`, `simulation_worker_tests`, `survival_chest_smoke.gd` et `survival_pause_smoke.gd` passent sous Godot 4.7.2.
- [ ] Autres pickups (soins, ressources, monnaies et bonus temporaires) absents; leurs règles de création/collecte restent à réaliser avant la couverture complète du bonus global validé.
- [ ] Intervalle 20 s, durée 1,5 s, accélération 600 et vitesse max 240 sont **[PROPOSÉS]**, à calibrer; aucune validation de balance n’est revendiquée.

## Run réelle et redémarrage Survival — 2026-10-16

- [x] Lancé depuis l’accueil en Easy avec un profil `XDG_DATA_HOME` temporaire, choix initial manuel, `LOCK HEALTH` et auto-choix des coffres désactivés, aucun HP forcé ni harness de simulation. À vitesse de jeu ×4 choisie dans la pause, la partie s’est terminée en défaite à la vague 1 après 13 s actives et 10 kills.
- [x] L’écran et le profil montrent +12 Essence, +16 Basic Powder, un Magic Ring, un seul `run_id` récompensé, une pièce d’équipement et 10 kills crédités.
- [ ] Cette partie n’a pas atteint les 60 s nécessaires au filet de coffre ni le boss final; la victoire et le coffre garanti restent à observer pendant P5.V3.
- [x] Le contrôle du bouton RUN AGAIN a révélé une perte de difficulté et du service de progression. `survival_run_restart_smoke.gd` vérifie désormais Easy conservé, un nouvel identifiant et une seconde récompense distincte; test enregistré dans CTest.
- [x] Suite CTest complète : 66/66 sous Godot 4.7.2.

## Population ennemie sans plafond — 2026-10-16

- [x] `survival_wave_spawn_smoke.gd` crée des fixtures actives jusqu’au seuil de l’ancienne première vague et confirme qu’un spawn ordinaire supplémentaire est quand même accepté.
- [x] Le smoke vérifie la courbe de population sans plafond fixe et la cadence configurable : facteur Normal 1×, Chaos 1,8×. Les coefficients de densité restent **[PROPOSÉS]**.
- [x] Les tests de spawn, de difficulté et du directeur de vagues passent; toute la suite CTest passe 65/65 en séquentiel sous Godot 4.7.2. Une run de joueur sans assistance reste à valider en P5.V3.

## Scénarios de validation des dix armes — 2026-10-16

- [x] `sandbox_weapon_scenario_runner.gd` lance chaque attaque de production contre des cibles déterministes avec une loadout temporaire en mémoire; `progression_service` est nul et aucun `SaveService` n’est chargé.
- [x] Les dix scénarios passent dans CTest, ainsi que le smoke de validation des fichiers et des entrées invalides : 12/12 tests ciblés, import Godot inclus, sous Godot 4.7.2.
- [x] Chaque scénario écrit métriques et événements dans un JSON de résultat CTest distinct; les fichiers produits restent dans `build/`.
- [x] La suite complète passe 64/64 sous Godot 4.7.2 en séquentiel. Une première exécution parallèle avait déclenché l’échec intermittent déjà connu de `survival_weapon_catalog_smoke`; son rerun isolé puis la suite séquentielle passent.

## Politiques de ciblage exposées dans le Sandbox — 2026-10-16

- [x] `survival_targeting_smoke.gd` vérifie nearest, farthest, highest threat, highest HP, lowest HP, la priorité PV max de Prism dans une grappe dense, les cibles de grappes, le centroïde Meteor, la réduction commune des portées (−71 %, plafond visible de 180 unités), le plafond après bonus de niveau/zone et l’exclusion des ennemis morts, des projectiles et des orbes XP. Ces règles restent **[PROPOSÉES]**.
- [x] `sandbox_ui_smoke.gd` vérifie le sélecteur à neuf politiques, l’ID ou centroïde affiché, les portées et rayons de grappe par défaut, l’effet du choix de politique et de portée, l’effacement après kill-all et la préservation du fixture de sauvegarde normale. Capture Xvfb relue à 640×360; cible, marqueur et réglages restent dans leurs cadres.
- [x] `survival_weapon_catalog_smoke.gd` vérifie le regroupement Lightning/Sawblades/Meteor/Prism, les choix par menace/PV/distance, le ciblage faible PV des Crimson Daggers, le focus PV max de Prism, le maintien/reciblage du Minigun, et les bonus Inferno des niveaux 2–5.
- [x] La suite complète est à 53/53 sous Godot 4.7.2. `survival_run_result_smoke` attend que le worker ait acquitté la pause après `run_over`; ce test passe dix exécutions consécutives. Les smokes profil, unlock, session de difficulté, pause et rendu des profils communs sont enregistrés dans CTest.
- [x] Les dix armes ont des règles de ciblage distinctes couvertes par les fixtures de comportement et les profils Sandbox.
- [ ] Leur équilibrage comparatif reste **[OUVERT]**; les sélecteurs numériques sont **[PROPOSÉS]** et la couverture ne prouve pas leur qualité finale.

> Les cases cochées sont des exécutions documentées. Le binaire Godot local est `tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`; il peut être invoqué directement même s’il n’est pas présent dans le `PATH`.

## Revalidation intégrée P5 — 2026-10-16

- [x] La suite CTest complète passe à 51/51 sous Godot 4.7.2 et Linux C++23 après intégration des smokes de difficulté, de validation du runner et stabilisation du résultat de run; temps CTest total 40,94 s, qui ne constitue pas une mesure de performance en jeu.
- [x] Au contrôle précédent, Godot 4.7.2 officiel exécuté depuis `/tmp`; la suite CTest passait avec 45/45 tests. Depuis, deux tests ont été ajoutés; résultat courant ci-dessus.
- [x] `survival_inventory_smoke.gd` utilise désormais deux équipements de fixture valides et déterministes au lieu de dépendre de récompenses aléatoires; équipement, enhancement, effet unique, compétences et démantèlement passent dans la suite intégrée.
- [x] `survival_elite_smoke.gd` vérifie le Split-on-Death plafonné sous Godot 4.7.2; les smokes voisins Summoner, boss, vagues et durée passent également.

## Profil natif des impacts — 2026-10-16

- [x] `build/simulation_benchmark` (Debug, GCC 14.2, Linux x86-64, AMD EPYC-Milan) exécute deux fois le même workload de 500 ennemis et 2 000 projectiles sur 300 frames à 60 Hz. Sans impacts : moyenne 1,27–1,30 ms avant et 1,08–1,13 ms après.
- [x] La rafale dense `wildfire_impact_burst` mesurait 141,1–143,1 ms/frame en moyenne et 154,4–158,0 ms p95 avant; après avoir évité les requêtes de zone quand le budget de cibles était épuisé, elle mesure 72,6–74,4 ms moyenne et 77,6–82,4 ms p95 (environ 48 % de baisse sur les médianes des deux exécutions).
- [x] `simulation_core` et `simulation_worker` passent après la modification, puis toute la suite CTest passe 47/47. Le stress test extrême reste au-dessus de 16,7 ms; cette charge concentre toutes les cibles et projectiles au même point et ne constitue pas un profil représentatif de Survival. Aucun budget de performance n’est actuellement défini dans les documents.

## Scénario Sandbox des affixes élite — 2026-10-16

- [x] `enemy_profiles_smoke.json` fait apparaître de façon déterministe Hasted, Armored, Regenerating, Volatile, Shielded et Split-on-Death dans le Sandbox; les attentes vérifient leur identité, leur vitesse et les attributs d’affixe publiés.
- [x] `scenario_runner.gd` valide `affix` uniquement sur un profil elite et autorise les six IDs supportés; `scenario_runner_validation_smoke.gd` couvre les cas acceptés/refusés. Le snapshot valide les attributs; le scénario passe avec Godot 4.7.2 sans accéder à la sauvegarde normale.

## Profils communs de P5 — 2026-10-16

- [x] `enemy_profiles_smoke.json` vérifie le spawn Sandbox et les PV/vitesses de Chaser, Sprinter et Tank; `simulation_core_test` vérifie pour les trois le steering conservant la vitesse propre et l’événement de mort typé.
- [x] `survival_combat_visual_smoke.gd` vérifie leurs routes de sprites distinctes et produit une capture Xvfb du combat; test ajouté à CTest sur Linux quand `xvfb-run` est disponible.
- [ ] Profil rapide, HP, menace et contre-jeu final restent **[PROPOSÉS]** jusqu’à validation d’équilibrage; le test confirme leur implémentation, pas leur qualité de tuning.

## Pression de combat sans amélioration — 2026-10-16

- [x] `survival_idle_combat_smoke.gd` vérifie 20 secondes simulées de la première vague en Normal, joueur immobile, arme de départ active et rayon XP/coffre à zéro : 23 ennemis éliminés, 83,3/100 PV restants, aucun XP ni choix collecté. Le défaut historique « aucun dégât jusqu’aux vagues 8–9 » ne se reproduit pas sur ce parcours ciblé; ce n’est pas une validation d’équilibrage complet.

## Boss final — loot et résultat — 2026-10-16

- [x] `survival_final_boss_loot_smoke.gd` vérifie que le boss final déclenche les deux familles de coffres garanties et configurables, que chaque choix laisse la simulation en pause, puis que l’écran de victoire apparaît après le dernier coffre.
- [x] `survival_boss_attack_smoke.gd` et `survival_wave_director_smoke.gd` passent avec le smoke de loot; cela valide transitions, attaques, victoire et séquence de coffres sous harness, pas une run sans assistance (P5.V3).
- [x] (2026-10-16) `survival_wave_director_smoke.gd` observe désormais les deux familles de boss dans le parcours accéléré de 24 vagues et exige que toutes deux aient été traitées avant la victoire. Ce run garde HP élevés, dégâts de boss par DoT de test et choix de coffre automatiques; il ne remplace pas le parcours P5.V3 manuel.
- [x] Revalidation longue après correction du harness : les 10 000 PV de test sont assignés après `_ready()`, qui initialise sinon le joueur à ses PV normaux. Le parcours `--production-duration` passe les 24 vagues, traite les deux boss, résout les coffres garantis et atteint VICTORY sous Godot 4.7.2 en 174 s environ. La première tentative était morte par HP decay avant le boss final; la validation reste assistée et ne clôt pas P5.V3.

## Ciblage du Minigun — 2026-10-16

- [x] `survival_weapon_catalog_smoke.gd` vérifie le contrat catalogue **[PROPOSÉ]** : acquisition de la cible vivante la plus proche plutôt que d’une cible plus menaçante, conservation de la cible verrouillée quand une autre s’approche, puis reciblage après mort ou sortie de portée. Le changement remet à zéro la montée de cadence de Redline.

## Correction du viewport UI — 2026-10-16

- [x] Les interfaces conservent leur viewport logique 1280×800 et la fenêtre initiale 1280×800. Le viewport cible 640×360 de l’Art Bible attend l’adaptation responsive de chaque écran.
- [x] Le thème partagé reprend les couleurs sémantiques de la palette maître, les panneaux opaques et les boutons rectangulaires; Press Start 2P est réservée aux titres, DejaVu Sans au texte courant. Le feedback souris agrandit au survol et décale de 2 px à l’appui. Licences livrées dans `game/assets/fonts/`.
- [x] Import Godot 4.7.2 et 10 smokes ciblés UI passent après le rétablissement du viewport 1280×800, avec un `XDG_DATA_HOME` isolé par script : fondation, hub/layouts 1280×800/1600×900/1920×1080, pause, inventaire, coffre, résultat, navigation et Sandbox.
- [ ] À la date de cette correction, le smoke fenêtré et la suite complète n’avaient pas encore été relancés. La revalidation intégrée ci-dessus couvre depuis l’import et 45 tests CTest; le smoke fenêtré reste à faire.

## Feedback des niveaux d’objets en run — 2026-10-16

- [x] `survival_level_feedback_smoke.gd` vérifie les notifications d’acquisition et de niveaux 1–5 pour armes et reliques; le toast reste visible à temps de simulation figé, disparaît après expiration simulée et reste dans les viewports 640×360, 1280×800 et 1920×1080. Il vérifie aussi les impacts des dix armes pour les cinq niveaux : chaque impact conserve le niveau de sa source et son échelle augmente avec ce niveau (**[PROPOSÉ]**).

## Bonus globaux et évolutions des reliques — 2026-10-16

- [x] `survival_weapon_catalog_smoke.gd` vérifie les bonus globaux des onze reliques aux cinq niveaux; les chiffres sont exercés comme valeurs **[PROPOSÉES]**, sans valider leur équilibre.
- [x] Le même smoke vérifie les dix paires d’évolution : l’offre reste verrouillée jusqu’au niveau 5 de l’arme et de la relique, quel que soit leur ordre d’acquisition; le niveau 5 et la relique sont conservés, l’offre est unique, et seul le dégât de l’arme évoluée gagne le multiplicateur proposé de 25 % après collecte.
- [x] Avec les cinq slots d’armes saturés, il vérifie l’absence d’évolution au niveau 1 lors de l’acquisition d’une arme dont la relique est déjà niveau 5, puis l’apparition au niveau 5; dans l’autre ordre, le coffre réel présente et collecte l’évolution lorsque la relique atteint le niveau 5 après l’arme.
- [x] Vérifie aussi que les armes/évolutions déjà maximisées ne réapparaissent pas dans les offres.
- [x] `survival_contact_damage_smoke.gd` couvre séparément le délai de contact corporel par ennemi et confirme que les projectiles ennemis ne partagent pas ce délai.

## Pause du choix de coffre — 2026-10-16

- [x] `survival_chest_smoke.gd` attend que l’interface ait rejoint le dernier snapshot, puis vérifie pendant 120 ms que la simulation, le temps actif affiché et l’état pause restent figés; il vérifie aussi la reprise après sélection.

## Rendu des évolutions — 2026-10-16

- [x] `survival_weapon_catalog_smoke.gd` observe le projectile `redline` réellement tiré après évolution et vérifie que la collision continue de fonctionner.
- [x] `render_batching_smoke.gd` vérifie le lot de rendu propre à Redline, la silhouette Minigun réutilisée et la teinte rouge néon; les neuf autres formes évoluées restent vérifiées dans leurs lots dédiés.

## Hub Survival — état visuel des destinations inactives — 2026-10-16

- [x] `survival_hub_smoke.gd` vérifie que Succès et Bestiaire utilisent le style atténué, restent activables au focus et gardent le cadre de focus partagé; ils ne sont pas désactivés.
- [x] `survival_hub_layout_smoke.gd` confirme les bornes du hub à 640×360, 1280×720 et 1920×1080.
- [x] `survival_hub_smoke.gd` vérifie la médaille de Succès et le sprite de chaser du Bestiaire, leur taille compacte nearest, leurs teintes atténuées/dorées selon le focus et leur absence de signal d’action.
- [x] Capture fenêtrée avec viewport logique 640×360 relue; Succès et Bestiaire sont visuellement secondaires. Le focus est vérifié par le smoke, l’interaction avec une manette physique n’a pas été vérifiée ici.

## Hub Survival — confirmation de difficulté au lancement — 2026-10-16

- [x] Le bouton primaire reprend la difficulté active et suit la sélection Easy → Normal; le smoke confirme que l’action temporaire sans sauvegarde garde son libellé et son parcours distincts.
- [x] `survival_hub_smoke.gd` passe; `survival_hub_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080.
- [x] Capture fenêtrée du hub relue à 640×360 logique : sélection, statut et bouton principal sont visibles avec le focus.

## Sandbox développeur — largeur du panneau de réglages — 2026-10-16

- [x] `sandbox_ui_smoke.gd` vérifie que la sidebar garde au moins 194 px et que les quatre champs AI Steering s’étendent au-delà de leur minimum de 70 px à 640×360, 1280×720 et 1920×1080.
- [x] Le smoke passe sous Godot 4.7.2 avec un `XDG_DATA_HOME` isolé; son fixture sentinelle de sauvegarde normale reste inchangé et aucune autre sauvegarde n’est créée.
- [x] Capture fenêtrée Xvfb relue au viewport logique 640×360 avec deux entités; réglages et sélection restent visibles, sans débordement horizontal. Souris/manette physiques non testées.

## Inventaire d’équipement — hiérarchie des cartes — 2026-10-16

- [x] `equipment_panel_visual_smoke.gd` contrôle la largeur réservée aux contrôles, la bordure de rareté et le maintien dans les 640 px logiques.
- [x] `ui_viewport_layout_smoke.gd` passe pour toutes les interfaces aux viewports 640×360, 1280×720 et 1920×1080.
- [x] Capture fenêtrée de l’inventaire vérifiée à 640×360 logique et fenêtre 1280×720; les lignes, options, états et actions restent dans le panneau.
- [ ] `survival_inventory_smoke.gd` n’a pas terminé dans le délai de 30 s lors de cette vérification; le processus a été arrêté. Parcours de progression non revalidé dans cette tranche.
- [x] Nouvelle vérification : le smoke hub/inventaire/compétences passe après correction de ses recherches d’icône de rareté et d’action de démantèlement dans l’arborescence actuelle.
- [x] `equipment_panel_visual_smoke.gd` vérifie maintenant les états vide/erreur exclusifs, le contraste, le centrage et la taille 10 px; captures des deux états revues à 640×360 logique.
- [x] `equipment_panel_visual_smoke.gd` vérifie que le nom de l’effet unique est rendu en texte lisible sans séparateurs d’identifiant. Le smoke visuel et `survival_inventory_smoke.gd` passent.

## Arbre de compétences — hiérarchie des nœuds — 2026-10-16

- [x] `skill_tree_panel_visual_smoke.gd` vérifie largeur des choix, bornes logiques, état de prérequis et focus de la fondation.
- [x] `ui_viewport_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080.
- [x] Capture fenêtrée avec viewport logique 640×360 relue; les effets, coûts et relation de prérequis tiennent dans le cadre.
- [x] `skill_tree_panel_visual_smoke.gd` vérifie que les deux choix emploient l’icône skill-node nearest limitée à 12 px; parcours du hub et capture 640×360 revus, puis `ui_viewport_layout_smoke.gd` et `survival_inventory_smoke.gd` passent.

## Pause — hiérarchie visuelle — 2026-10-16

- [x] `pause_panel_visual_smoke.gd` contrôle la largeur des cartes, les libellés d’état/vitesse et le focus des six actions.
- [x] `pause_panel_visual_smoke.gd` vérifie l’accent cyan de reprise et l’accent rouge d’abandon/confirmation; `survival_pause_smoke.gd` passe sans changement du parcours.
- [x] `survival_pause_smoke.gd` passe, y compris Options au-dessus de Pause et invariance des horloges/positions.
- [x] `ui_viewport_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080; captures de Pause et de confirmation revues à 640×360 logique.
- [x] Entrées synthétiques : `launch_navigation_smoke.gd` parcourt le focus avec la croix, active Options avec Entrée et la ferme avec B; `survival_pause_smoke.gd` vérifie que B ouvre/reprend Pause et ferme Options sans faire avancer la run.

## HUD Survival — visibilité de la rangée d’armes — 2026-10-16

- [x] `survival_hud_smoke.gd` vérifie que le texte du loadout a une hauteur visible; ce contrôle détectait une hauteur maximale de zéro.
- [x] Capture 640×360 logique revue avec plusieurs armes; les noms ne sont plus coupés verticalement et les deux cartes restent dans leurs zones.
- [x] `ui_viewport_layout_smoke.gd` passe à 640×360, 1280×720 et 1920×1080.

## HUD Survival — séparation santé et XP — 2026-10-16

- [x] `survival_hud_smoke.gd` vérifie que santé et XP disposent de lignes distinctes, que leurs valeurs/barres suivent le bon état et que les deux lignes restent dans le panneau aux viewports testés.
- [x] `survival_hud_smoke.gd` et `survival_weapon_smoke.gd` passent après le déplacement des contrôles dans leurs lignes dédiées.
- [x] Capture fenêtrée revue à 640×360 logique : barres HP et XP longues, valeurs et rangée d’arme restent visibles et dans la carte.

## Badge d’état du HUD Survival — 2026-10-16

- [x] `survival_hud_smoke.gd` vérifie que le badge d’état change sa bordure avec les états marche et pause, en plus du libellé; exécuté sous Godot 4.7.2, passe.
- [x] (2026-10-16) `survival_hud_smoke.gd` vérifie que le HUD marque comme EVO chacune des dix évolutions du catalogue; l’indicateur compact reste uniforme, les noms complets figurent dans l’inventaire de run.

## Coffres — accent de famille — 2026-10-16

- [x] `survival_chest_choice_smoke.gd` vérifie le titre cyan du coffre d’arme, le titre magenta du coffre de relique, les icônes/descriptions, le focus et l’émission de sélection inchangée.
- [x] `survival_chest_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080 avec descriptions longues et bonus de prochain niveau.
- [x] Le smoke de choix vérifie les styles distincts du nom et de la description, l’icône 32×32 nearest et le texte complet du bouton; `survival_chest_choice_smoke.gd` exécuté sous Godot 4.7.2, passe.
- [x] Les fixtures d’armes et de reliques utilisent les icônes de catalogue actives, afin que le smoke de présentation vérifie les assets réellement affichés dans les coffres.

## Accueil — emblème pixel art — 2026-10-16

- [x] `signal_prism_asset_smoke.gd` vérifie le PNG 32×32 transparent, sa palette maîtresse de 16 couleurs maximum, l’en-tête Aseprite et son intégration nearest dans le menu.
- [x] `process_signal_prism.gd` reproduit l’export depuis la référence générée vers le PNG utilisé et la source Aseprite éditable.
- [x] Import Godot 4.7.2, `ui_foundation_smoke.gd` et `ui_viewport_layout_smoke.gd` passent; capture de l’accueil relue à 640×360 logique dans une fenêtre 1280×720.

## Accueil — composition menu gauche de l’Art Bible — 2026-10-16

- [x] `launch_navigation_smoke.gd` vérifie que la colonne verticale de commandes reste à gauche de l’identité, avec focus initial sur Jouer; Options, Quitter et l’accès discret Sandbox restent accessibles.
- [x] Le smoke de navigation passe, y compris le trajet accueil → Sandbox → accueil; `ui_foundation_smoke.gd`, `signal_prism_asset_smoke.gd` et `ui_viewport_layout_smoke.gd` passent sous Godot 4.7.2.
- [x] Capture fenêtrée Xvfb relue au viewport logique 640×360; les bornes de layout sont vérifiées à 640×360, 1280×720 et 1920×1080.
- [ ] Essais avec souris et manette physiques non effectués; les contrôles restent natifs, focusables et l’ordre clavier/manette est couvert par les smokes.
- [x] `launch_navigation_smoke.gd` passe en headless après ajout de l’emblème; retour du Sandbox vers l’accueil fonctionne toujours.

## Inventaire de run — densité au viewport logique — 2026-10-16

- [x] `survival_pause_inventory_smoke.gd` vérifie le cadre élargi, le focus visible, la navigation clavier, le défilement jusqu’au dernier item et l’absence de mutation du loadout.
- [x] Le panneau reste dans les viewports 640×360, 960×600, 1280×800 et 1600×900; `ui_viewport_layout_smoke.gd` passe aussi aux tailles 640×360, 1280×720 et 1920×1080.
- [x] Capture 640×360 logique relue avec quatre armes et quatre reliques : deux cartes complètes restent visibles avant défilement.
- [x] Le smoke vérifie la hiérarchie nom/évolution/description; `survival_pause_inventory_smoke.gd` exécuté sous Godot 4.7.2, passe.

## Résultat de run — poids des récompenses — 2026-10-16

- [x] `run_result_panel_smoke.gd` vérifie carte 360 px, icône 24×24, focus initial, ordre des actions, victoire/défaite, doublon et échec de sauvegarde.
- [x] Le smoke vérifie que le résumé de palier reprend la médaille existante, et que l’icône disparaît lors d’un résultat sans nouveau palier; `run_result_panel_smoke.gd` exécuté sous Godot 4.7.2, passe.
- [x] Le même smoke vérifie que l’échec de sauvegarde prend l’accent rouge et que l’accent cyan des récompenses est rétabli au prochain résultat.
- [x] `survival_run_result_smoke.gd` confirme que le parcours victoire/défaite et la navigation restent inchangés.
- [x] Capture fenêtrée de l’état d’échec de sauvegarde relue à 640×360 logique; le message est distinguable des récompenses et actions.
- [x] `ui_viewport_layout_smoke.gd` passe aux viewports 640×360, 1280×720 et 1920×1080; capture de victoire avec équipement long relue à 640×360 logique.

## Build et intégration

- [x] Linux P0 : Godot 4.7.2 charge la GDExtension C++23 après import headless du projet.
- [x] P1 ciblé : handles index/génération, snapshots immuables, spawn/despawn, kill all, step, pause/reprise, reset et arrêt du worker.
- [x] Capture/restauration native : capture cohérente à une barrière de commande, validation sans mutation partielle, reprise de la numérotation et exécution des commandes en attente après restauration ; API en mémoire, sans sérialisation fichier ni état gameplay Godot.
- [x] P1 intégration : GDScript charge `CombatSimulation`, soumet un spawn et reçoit le snapshot acquitté sous Godot headless.
- [x] P1 UI : scène Sandbox lançable sans save, inspection par sélection, despawn ciblé et kill all vérifiés sous Godot headless ; tooltips spawn, statut et réglage live vérifiés ; rendu revu à 1280×800.
- [x] Assets pixel art néon : sprites player/ennemis/boss placeholders/projectiles/XP/chests et icônes armes/reliques visibles ; lots MultiMesh par type et rendu de charge revérifiés à 1280×800.
- [x] P2 UI : le Sandbox applique un DoT configurable à l’entité sélectionnée, montre l’état dans l’inspecteur et reçoit un événement de tick identifié.
- [x] P1 scénario : runner JSON vérifie les attentes et exporte métriques, entités, événements et logs ; scénario steering valide la transaction `apply_sandbox_overrides`, ses valeurs de snapshot et le déplacement produit.
- [x] P2 ciblé : requêtes de rayon du spatial hash aux coordonnées négatives, bord de rayon et cellules ; les entités détruites sont exclues.
- [x] P2 ciblé : poursuite d’une cible explicite et séparation locale, y compris deux entités superposées ; scénario Godot headless vérifie les positions obtenues.
- [x] P2 ciblé : projectile rapide contre cible en mouvement, dégâts et mort séquencés, expiration, file d’événements acquittable et affichage Sandbox.
- [x] P2 ciblé : HP initial validé à 100 et fonction pure de HP decay aux exemples de 60 s et 720 s marqués proposés dans le GDD.
- [x] P2 ciblé : menace d’ennemi conservée jusqu’à l’événement de mort ; preview du soin proposé testée à T=1 et aux bornes de menace.
- [x] P3 ciblé : Survival applique le HP decay depuis l’horloge de simulation, le suspend en pause manuelle et pendant le choix initial, puis le reprend après validation ; le soin proposé d’un événement de mort est appliqué une fois.
- [x] P3 ciblé : Lightning Conductor cible deux ennemis distincts, tue les cibles avec ses projectiles et consomme les événements de mort pour le soin.
- [x] P3 UI : HUD Survival affiche le HP initial, l’état de run et les champs temps actif/arme prototype.
- [x] P3 XP : orbe ECS créée à la mort, collecte unique via événements acquittables, progression et HUD niveau vérifiés dans le smoke test Survival headless.
- [x] P3 vagues ciblé : progression de 24 vagues et transitions aux boss 12/24; timer bloqué pendant les placeholders et type d’ennemi préservé dans les événements de mort.
- [x] P4 horloge Survival : progression automatique depuis le temps simulé et arrêt/reprise du timer de vague vérifiés sous Godot headless avec une durée de vague de test réduite.
- [x] P4 run intégrée accélérée : parcours des 24 vagues, morts des deux boss, timer bloqué mais HP decay actif pendant les combats, choix des coffres et écran de victoire vérifiés.
- [x] P4 durée de vague intégrée : une vague configurée à 30 s ne passe à la suivante qu’après 30 s simulées ; vérifié à ×4 en environ 7,7 s réelles.
- [x] Le directeur conserve le reliquat d'un grand delta entre vagues ordinaires, s'arrête aux boss et ignore les durées/deltas non valides sans corrompre son état.
- [x] P3 intégration : traversal accéléré de la session Survival à travers 24 vagues, spawn/défaite des placeholders boss, écran victoire logique et pause finale.
- [x] P3 UI boss : la barre affiche les HP courants/max pour le mid-boss et le boss final; la victoire se distingue de RUN OVER.
- [x] P3 loot : tests des probabilités configurables, garanties et filet 60 s; test Survival death→drop→pickup→choix→application au loadout→reprise; le catalogue demeure **[PROPOSÉ]**.
- [x] P3 placement des drops : `survival_chest_smoke.gd` passe sous Godot 4.7.2 après typage explicite de ses fixtures `Array[Vector2]`; les orbes XP ne chevauchent pas les coffres, les coffres ne se recouvrent pas complètement et un nouveau coffre évite aussi un orbe déjà au sol.
- [x] P3 armes/reliques prototype : tests de collision/tuerie Inferno et Crimson, bonus de dégâts Storm Core/Infernal Heart, bonus de soin Blood Chalice, Bloodstorm niveau 5/relique avec saignement/lifesteal, Infinite Circuit niveau 5/Storm Core avec éclairs ramifiés, et Wildfire niveau 5/relique avec explosion et brûlure de zone. Les cibles initiales, branchements et dégâts/rayon d’explosion restent **[PROPOSÉS]**.
- [x] P3 flux de run : entrée Sandbox→Survival, choix parmi deux armes **[PROPOSÉES]**, résultat de défaite/victoire et vague finale enregistrée comme 24.
- [x] Résultat de run : `run_result_panel_smoke.gd` passe sous Godot 4.7.2; `QUIT TO MENU` reste sous `RUN AGAIN`, émet son signal de navigation et le panneau tient aux viewports testés.
- [x] P3 boss final : une mort réelle génère les chests boss éligibles et la victoire attend la collecte et le choix de chaque chest.
- [x] P3 contact : collision joueur-ennemi, cooldown corps à corps séparé par ennemi, projectiles indépendants, pause/reprise des contrôles et verrouillage après la fin vérifiés sous Godot 4.7.2 headless; 0,35 s **[PROPOSÉ]**.
- [x] P3 contact : rayons joueur/mob alignés sur les sprites (16 + 12 unités), bord exact de contact et séparation du cooldown projectiles ennemis; le rayon joueur préserve encore son statut proposé.
- [x] `survival_contact_damage_smoke.gd` couvre le cercle de contact à 16 + 12 unités, puis vérifie qu’un même ennemi respecte son propre délai corps à corps, un autre peut toucher pendant ce délai et un projectile ennemi reste indépendant. `render_batching_smoke.gd` confirme que le diamètre rendu des mobs (24) et boss (52) vient du même `CollisionRadius` que la simulation.
- [x] (2026-10-16) `survival_loadout_smoke.gd` vérifie le bonus global de chacune des 11 reliques, les dix paires arrivées niveau 5 sans évolution automatique, puis l’activation uniquement après collecte de l’offre d’évolution.
- [x] (2026-10-16) `survival_loadout_smoke.gd` vérifie cinq reliques en capacité normale, puis six armes et six reliques avec le bonus de capacité, et refuse le septième item. `survival_unique_effects_smoke.gd` vérifie en session que deux équipements porteurs de `expanded_loadout` dédupliquent l'effet et activent les deux slots supplémentaires. Ce contrat et ses valeurs restent **[PROPOSÉS]**.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie que les sélecteurs partagés, le ciblage Lightning et Frost Nova ignorent une cible morte encore publiée dans le snapshot; le catalogue complet reste vert.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage initial Lightning **[PROPOSÉ]** : choisit le membre le plus proche d’une grappe chainable plus dense qu’une cible isolée, ignore une cible morte dans cette grappe et garde une seconde racine distincte pour Infinite Circuit.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Crimson Daggers **[PROPOSÉ]** : priorité aux PV les plus faibles, départage par proximité et exclusion des cibles mortes ou hors portée.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie la politique Minigun **[PROPOSÉE]** : acquiert la cible de plus haute menace, conserve son ID malgré une menace plus proche, puis retargete et réinitialise Redline quand la cible meurt ou sort de portée.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Inferno **[PROPOSÉ]** : choisit l’ennemi de plus haute menace dans la portée et départage une menace égale par la proximité.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Toxic Cloud **[PROPOSÉ]** : choisit l’ennemi vivant aux PV les plus élevés dans la portée, ignore une cible morte/hors portée et départage des PV égaux par la proximité.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Sawblades **[PROPOSÉ]** : vise une cible accessible de la grappe la plus dense dans son rayon de ricochet, choisit la plus proche à densité égale et retombe sur l’ennemi le plus proche lorsqu’aucune grappe n’existe.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Void Orb **[PROPOSÉ]** : choisit l’ennemi vivant le plus éloigné dans sa portée et ne produit aucune cible quand il n’y en a pas.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Prism Laser **[PROPOSÉ]** : choisit la cible la plus proche dans le groupe le plus dense et centre les faisceaux secondaires autour de la cible principale.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` vérifie le ciblage Meteor Staff **[PROPOSÉ]** : préfère une grappe plus dense à une cible isolée plus proche, exclut les cibles mortes du centroïde et renvoie une cible vide quand aucun ennemi vivant n’est présent.
- [x] (2026-10-16) `render_batching_smoke.gd` vérifie le ripple intérieur du champ Pandemic : son rayon varie avec le temps restant du projectile, reste borné dans le champ et devient nul pour un rayon nul ou expiré. Le rendu s’appuie sur le temps de simulation, donc son animation gèle en pause ; période 1,2 s **[PROPOSÉE]**.
- [ ] (2026-10-16) Le smoke existant `survival_run_stat_hub_smoke.gd` conserve les contrôles UI et affiche désormais le compteur de bonus XP ; il reste à lui ajouter des assertions sur l'ordre complet de rotation, les effets de stats et la hausse des PV avec ratio conservé. Il n'a pas été exécuté depuis l'implémentation XP.
- [x] (2026-10-16) `survival_weapon_catalog_smoke.gd` passe sous Godot 4.7.2 avec l’offre d’évolution requise pour les prototypes d’évolution testés; les arcs Lightning ne retouchent plus leur cible d’origine au départ.
- [x] Crimson Daggers/Bloodstorm P5 : `simulation_core` vérifie l’orbite native des dagues de base et l’orbite persistante de Bloodstorm sur deux cibles distinctes, ainsi que la capture/restauration; `survival_weapon_catalog_smoke.gd` vérifie le contact à la portée orbitale puis Bleed. Rayon 30, vitesse 5 rad/s et durées 0,8/2,4 s **[PROPOSÉS]**.
- [x] Survival clavier : WASD et flèches déplacent le joueur; les choix de départ et de chest se parcourent au clavier et se confirment avec Espace/Entrée.
- [x] P1 contrat natif : transaction complète de steering validée puis publiée atomiquement; transaction invalide ou mal typée conserve les valeurs précédentes.
- [x] P3 lifesteal : Blood Chalice soigne sur un événement de dégâts non létal; soft cap, efficacité au-dessus du cap et HP maximum vérifiés sous Godot 4.7.2 headless.
- [x] P3 Inferno : impact applique la brûlure configurée et ses ticks contribuent au lifesteal à 25 % du taux théorique.
- [x] Charge worker : 500 ennemis + 2 000 projectiles sont acceptés, le plafond de 2 500 entités est appliqué, puis 2 000 impacts se résolvent sans dépasser le budget réservé d’événements.
- [x] Linux : Godot 4.7.2 charge la GDExtension et GCC 14.2 compile le projet avec `-std=gnu++23`.
- [ ] Godot 4.7.2 charge la GDExtension sur Windows.
- [ ] Vérifier le build Windows et le couple compilateur/dépendances verrouillé.
- [x] Le worker natif ne dépend pas de Godot : ses deux sources n'incluent ni n'appellent l'API Godot; la cible `dopamine_simulation` ne lie pas `godot-cpp`.
- [x] `stop()` libère le worker sans deadlock pendant des soumissions concurrentes; test CTest répété 10 fois avec limite de 10 s.

## ECS / simulation

- [x] (2026-10-15) Frost Nova/Frozen Crown/Absolute Zero sous Godot 4.7.2 : Chill natif ralentit les cibles et se reflète dans le snapshot, Frozen Crown ajoute la vulnérabilité proposée, puis la mort gelée déclenche un shatter non récursif ; smokes de catalogue et tests natifs passés.
- [x] Lifesteal général **[VALIDÉ]** (choix B) : `survival_lifesteal_smoke.gd` échoue avant le correctif avec un build sans Blood Chalice, puis vérifie qu’un coup direct de 40 dégâts soigne au plus 2 HP au taux de base **[PROPOSÉ]** de 5 %. Au niveau 5, Blood Chalice ajoute 25 points au taux de base; les dégâts sur la durée gardent leur facteur proposé de 25 %, et le soft cap/HP max sont vérifiés. `survival_run_stat_hub_smoke.gd` vérifie le total de base et l’icône Blood Chalice pour la statistique.
- [x] Recompilation non nécessaire (GDScript uniquement); CTest séquentiel complet après la tranche Lifesteal : **92/92 passent en 62,61 s** sous Godot 4.7.2, y compris `survival_lifesteal_smoke` et `survival_run_stat_hub_smoke`.
- [i] Les deux smokes ciblés passent mais signalent encore des ressources référencées à la fermeture (2–6 ObjectDB pour lifesteal, et 14 RID CanvasItem/52 ObjectDB pour le test visuel du hub). L’origine n’est pas isolée; ne pas confondre ces avertissements avec un passage sans fuite de ressources.
- [x] (2026-10-17) `survival_weapon_catalog_smoke.gd` vérifie le dégât bonus sur la cible gelée et jusqu’à trois fragments vers ses cibles vivantes les plus proches dans le rayon proposé. Il couvre les cinq sources validées et leurs évolutions, et rejette les sources feu/foudre/poison/glace, les DoT, les fragments récursifs, les cibles hors rayon et un budget de réaction épuisé. Réglages de dégâts/portée/vitesse/nombre restent **[PROPOSÉS]** configurables.
- [x] P5.2.1/2 DoT typés et événements de synergie : `simulation_core_test` vérifie Burn/Poison/Bleed, remplacement et conservation en capture/restauration, ainsi que le rejet d’un type inconnu; `simulation_worker_test` vérifie le format 15 et la conservation du statut dans sa file d’événements; les smokes Survival vérifient Poison/Bleed dans les offres de combat, anneaux distincts et lifesteal Burn. `simulation_core_test` vérifie aussi que l’identité Bleed accompagne le tick létal et son événement death. Les durées et dégâts restent **[PROPOSÉS]**. L’empilement était **[OUVERT]** lors de cette exécution; la décision ultérieure de coexistence des types distincts est **[VALIDÉE, 2026-10-17]** et enregistrée dans le GDD §5.
- [x] P5.2.4 causalité dégâts/récompenses : `survival_damage_causality_smoke.gd` vérifie qu’un projectile létal direct et un DoT létal produisent chacun exactement une mort et une orbe XP; `survival_lifesteal_smoke.gd` couvre le lifesteal distinct sur dégâts directs et ticks Burn.
- [x] Catalogue de combat sous Godot 4.7.2 : dix armes, dix reliques associées et Magnet Heart sans paire ; validation des relations et disponibilité des dix paires prototypées plus Magnet Heart.
- [x] P5.3.1 offres pondérées : `survival_loadout_smoke.gd` vérifie les poids proposés d’amélioration, paire liée, évolution proche et plafond combiné; l’offre conserve trois choix éligibles distincts.
- [x] P5.3.2 transitions de coffre : `survival_chest_smoke.gd` vérifie qu’une liste ou sélection invalide ne ferme pas le choix et ne reprend pas le temps; `survival_pause_inventory_smoke.gd` vérifie le retour au menu Pause en conservant la pause et le focus.
- [x] P5.4.6 difficultés : les smokes progression vérifient refus des difficultés verrouillées, victoire/défaite, progression Easy→Chaos et multiplicateurs Easy/Normal/Chaos distincts pour HP, dégâts, densité et récompenses; les facteurs restent **[PROPOSÉS]**.
- [x] (2026-10-15) Minigun/Overdrive/Redline sous Godot 4.7.2 headless : impact d’un projectile Minigun et baisse du délai de tir avec Overdrive au niveau 2 et Minigun au niveau 5 ; réglages marqués **[PROPOSÉS]**.
- [x] (2026-10-15) Toxic Cloud/Plague Mask/Pandemic sous Godot 4.7.2 headless : poison direct et splash via DoT natif, puis transmission à la mort au niveau 5 ; réglages et limite de cibles **[PROPOSÉS]**.
- [x] Natif C++23 : projectile Toxic Cloud inflige son impact de zone puis émet les ticks DoT bornés par le chemin partagé.
- [x] (2026-10-16) Toxic Cloud natif : après impact, le champ persiste jusqu'à la durée restante du projectile, empoisonne une nouvelle cible dans son rayon et survit à capture/restauration ; le smoke `survival_weapon_catalog_smoke.gd` valide aussi la cible entrante sous Godot 4.7.2. Rayon, durée et application unique par cible **[PROPOSÉS]**.
- [x] (2026-10-16) Catalogue de combat : schéma JSON Schema draft 2020-12 validé avec `jsonschema`; le smoke Godot vérifie le chargeur runtime, dont types stricts, absence de champs inconnus, associations et unicité des évolutions. Les entrées Survival sont filtrées par `available_in_survival`.
- [x] (2026-10-16) `survival_wave_director_smoke.gd` génère 256 ennemis sur une vague 20 seedée et vérifie que les huit familles de Survival apparaissent jusque dans la simulation native; ce smoke ne valide pas leurs poids de spawn **[PROPOSÉS]**.
- [x] (2026-10-16) `survival_boss_attack_smoke.gd` valide les trois phases du Dopamine Core : rayon télégraphié esquivé, zone annoncée, spirale en tirs successifs, invocation phase 2, attaque combinée phase 3, pause et HUD de phase. Le smoke sature aussi le plafond partagé à trois adds en phases 2–3, vérifie le refus des suivants et la réutilisation d’une place après une mort. Motifs et réglages **[PROPOSÉS]**.
- [x] (2026-10-15) Sawblades/Magnetic Coil/Razorstorm : test natif vérifie un ricochet après capture/restauration vers une seconde cible unique ; smoke Survival vérifie deux impacts et le rendu charge un asset SVG dédié. Réglages de rebonds/vitesse **[PROPOSÉS]**.
- [x] (2026-10-15) Meteor Staff/Celestial Eye/Starfall : smoke Survival vérifie une explosion limitée au groupe et les fragments sur deux cibles proches ; l'événement natif expose le type de sa source pour déclencher l'évolution. Valeurs **[PROPOSÉES]**.
- [x] (2026-10-15) Prism Laser/Prism Crystal/Spectrum Collapse : smoke Survival valide le tir prioritaire, deux cibles secondaires distinctes à l’évolution et les chemins de projectile natifs. Cadence, dégâts, progression et bonus de critique **[PROPOSÉS]**.
- [x] (2026-10-15) Void Orb/Singularity/Event Horizon : tests natifs vérifient attraction, impacts pénétrants sur cibles distinctes et capture/restauration ; smoke Survival valide le contrat GDExtension et les impacts. Rayon, force et progression **[PROPOSÉS]**.
- [x] Shooter P5 : télégraphe de visée avant le tir, pause du cycle, déplacement du projectile ECS, exclusion des dégâts sur les ennemis et collision/dégâts sur le joueur vérifiés par `simulation_core` et `survival_shooter_smoke` sous Godot 4.7.2 Linux. Dégâts, vitesse, rayon et cadence **[PROPOSÉS]**.
- [x] Buffer P5 : aura de 150 unités, vitesse d’alliés augmentée de 20 %, exclusion des ennemis hors rayon, fin du buff après la mort du soutien et capture/restauration vérifiées par `simulation_core`; snapshot/sprite par `survival_support_enemy_smoke`; profil par `sandbox_enemy_profiles_scenario`. `simulation_worker` vérifie aussi le format de capture 7. Stats et bonus **[PROPOSÉS]**.
- [x] Elite P5 : sélection Hasted/Armored/Regenerating/Volatile/Shielded/Split-on-Death; facteurs défensifs, blast borné sans chaîne et propagation de l’affixe de mort vérifiée en natif; le smoke `survival_elite_smoke.gd` vérifie le split sous plafond et passe sous Godot 4.7.2. Les autres vérifications couvrent l’affixe publié, l’explosion bornée sans chaîne et le rejet des affixes non implémentés et des types non élite, spawn après cooldown, budget de menace lié à la population, maximum actif, mort via le pipeline commun et chest élite garanti dans le smoke. HP, vitesse, facteur Armored, taux de régénération, rayon/dégâts Volatile, facteur Shielded, nombre de splits, menace, intervalle, chance, limite et formule du budget restent **[PROPOSÉS]**.
- [x] Exploder P5 : profil du scénario, déclenchement de proximité, fuse et dégâts figés en pause, explosion une fois, fuite hors du rayon, élimination et conservation du flux kill/soin/XP/coffre vérifiés par `survival_exploder_smoke`. Stats, cadence, rayon, fuse et dégâts **[PROPOSÉS]**.
- [x] Shielder P5 : réduction de dégâts dans une aura, absence d’effet hors rayon, disparition immédiate à la mort du soutien, source conservée à la capture/restauration vérifiées par `simulation_core`; snapshot, indicateur et sprite par `survival_shielder_smoke`; profil par le scénario Sandbox. Rayon et multiplicateur **[PROPOSÉS]**.
- [x] Summoner P5 : quatre Summoners concurrents, position de spawn télégraphiée, pause du délai, plafond global de trois invocations, slot libéré puis réutilisé, profils et sprites vérifiés par `survival_summoner_smoke`; chiffres et plafond **[PROPOSÉS]**.

Pour le catalogue, la validation JSON et des références a aussi été vérifiée par script Python statique. Le smoke GDScript est enregistré dans CTest et a passé sous Godot 4.7.2 Linux.

- [x] ID index+génération rejette les handles obsolètes après réutilisation d’un index.
- [x] Spawn/despawn via worker et cœur natif ne casse aucun itérateur.
- [x] Les profils ennemis gardent leurs vitesses typées avec HP de vague multiplicatifs ; les multiplicateurs HP nuls ou non finis sont refusés.
- [x] Spatial hash trouve les cibles aux coordonnées négatives, au bord du rayon et aux frontières testées.
- [x] Swept collision détecte les projectiles rapides contre une cible en mouvement.
- [x] Hitboxes dérivées du rendu : radius 12 pour mobs 24 px, radius 26 pour boss 52 px, test projectile normal/boss, résolution des corps mobiles ennemis et steering dimensionné selon leur paire; les rayons AoE ne sont pas élargis par les hitboxes. Vérification native `simulation_core_test` compilée directement avec g++ et exécutée avec succès.
- [x] DoT partagé : ticks en temps simulé, durée, grand pas, remplacement, cible obsolète et événements identifiés.
- [x] Scénario Sandbox JSON applique un DoT, vérifie la santé restante et compte les événements de tick tagués.
- [x] Pas de simulation 1/120, 1/60, 1/30 et 100 ms : position, vitesse et HP restent finis; déplacement égal à la vitesse intégrée, sans saut; DoT indépendant du pas.
- [x] Timers de statuts exprimés en secondes, indépendants du nombre de frames pour les pas testés.
- [x] Les chaînes d'effets respectent le budget : le cœur refuse atomiquement un pas DoT trop riche, le worker explique le refus, un pas plus petit conserve tous les événements dus et les ticks s'arrêtent à l'expiration.

## Communication / rendu

- [x] Snapshots publiés restent immuables après l’étape suivante.
- [x] Les événements restent dans la file jusqu’à acquittement, indépendamment de l’ancienneté du snapshot consommé.
- [x] IDs/numéros de séquence identifient les événements et l’acquittement vide uniquement les événements déjà publiés.
- [x] Smoke Godot headless : 500 ennemis et 2 000 projectiles alimentent trois batches MultiMesh (ennemis, projectiles, orbes XP).
- [x] (2026-10-15) Smoke renderer Godot 4.7.2 : les projectiles Minigun ont un batch séparé qui charge leur texture SVG dédiée.
- [x] (2026-10-15) Smoke renderer Godot 4.7.2 : les projectiles Toxic Cloud ont un batch séparé qui charge leur texture SVG dédiée.
- [x] (2026-10-15) Smoke renderer Godot 4.7.2 : Sawblades/Razorstorm chargent leur batch et texture SVG dédiés.
- [x] (2026-10-15) Smoke renderer Godot 4.7.2 : météore et fragments Starfall utilisent des batches SVG séparés.
- [x] Smoke rendu fenêtré sous Xvfb/Mesa : 500 ennemis et 2 000 projectiles visibles à 1280×800 ; le test vérifie aussi la couleur d'un pixel ennemi connu.
- [ ] Mesurer la cible 60 FPS sur machine de référence et consigner CPU/GPU, P95/P99 ; le rendu logiciel llvmpipe ne valide pas cette cible.
- [x] Benchmark natif reproductible SimulationCore à 500 ennemis + 2 000 projectiles, avec charge sans impacts et rafale Wildfire dense, mesures P50/P95/P99 (voir `PERFORMANCE.md`).

## Sandbox-first

- [x] Sandbox démarre sans save : smoke de base sans `user://saves`; smoke UI séparé avec slot normal sentinelle prouvant que les interactions Sandbox ne changent aucun octet et n'ajoutent aucun fichier aux slots.
- [x] UI Sandbox : spawn, despawn, kill all, pause, reprise, step à durée explicite, vitesse ×2, reset des entités/horloges/overrides live et logs vérifiés sous Godot headless.
- [x] Contrat GDExtension `apply_sandbox_overrides` : quatre paramètres de steering validés avant soumission et exposés dans le snapshot; le worker rejette une configuration invalide sans commit partiel.
- [x] Sandbox applique un DoT configurable à l’entité sélectionnée et expose ses valeurs à l’inspecteur.
- [x] Transaction live de steering : changements UI valides appliqués ensemble et visibles dans le snapshot; entrée native invalide ou mal typée conserve toute la configuration précédente.
- [x] DPS moyen du Sandbox additionne les événements `damage` (dont DoT) et les divise par le temps simulé ; vérifié sur un Step explicite et remis à zéro avec la simulation.
- [x] Limites de ressources : files bornées à 2 048 commandes et 8 192 événements, 2 500 entités, budget de 6 000 événements par avance ; un batch de spawn qui dépasse le plafond ne crée aucune entité partielle et un Step trop coûteux préserve l’état. Vérifié dans le test du worker avec la charge 500 ennemis + 2 000 projectiles.
- [ ] Import d'une save produit une copie isolée ; original inchangé.
- [ ] Preset JSON et share code sont validés, versionnés, avec limites de taille.
- [ ] Snapshot complet reprend composants, queues, clocks, RNG et build.
- [ ] Sandbox ne génère ni équipement permanent, ni achievement officiel, ni classement.

## Progression et modes

- [x] (2026-10-16) `sandbox_lab_smoke.gd` vérifie la scène Lab, l’absence de services de progression/save, le God Mode local commutable, un spawn de dix ennemis avec tir Lightning, le loadout par défaut, Reset depuis le preset actif et le stockage de preset en répertoire isolé. `launch_navigation_smoke.gd` vérifie l’entrée Lab séparée de `SANDBOX DEV`.
- [x] (2026-10-16) `sandbox_preset_smoke.gd` vérifie le round-trip du share code `DSLAB1:`, le schéma fermé, le rejet des champs de chemin, la détection d’une corruption, la limite JSON de 1 Mio, profondeur 16, collections de 256 éléments, et CRUD du magasin sous un répertoire de test isolé avec rejet d’un chemin `../`.
- [x] (2026-10-16) Le même smoke démarre `SandboxLabContext` sans service de progression/save, refuse transactionnellement un preset invalide et n’applique un preset importé que depuis une simulation en pause; le contexte met la simulation en pause avant chargement/import et garde le reset dans l’état de pause.
- [x] (2026-10-16) `sandbox_preset_smoke.gd` vérifie aussi l’application en combat de niveaux, relique, évolution appariée et stat custom, et le rejet d’une évolution appartenant à une autre arme.
- [x] (2026-10-16) Le smoke vérifie que le build de preset hydrate le modèle Sandbox, accepte une arme catalogue et refuse ID inconnu/niveau au-dessus du cap sans remplacer l’état actif. Les caps 64 armes, 128 reliques et niveau 100 restent **[PROPOSÉS]**.

- [x] Survival : run intégrée aux durées nominales de 24 × 30 s (720 s simulées, accélérées ×4), timer arrêté pendant les deux boss et HP decay actif. Le harness augmente les HP du joueur pour isoler le déroulement, applique les dégâts de test aux placeholders et choisit automatiquement les chests ; il ne valide pas l'équilibrage.
- [x] Une instance d'équipement permanente par run Survival, y compris défaite ; slot parmi les six validés et lignes sans statistique répétée. La rareté suit les tables par difficulté et progression de vague **[PROPOSÉES]**; pénalité de mort précoce non implémentée.
- [x] Inventaire Survival consultable : affiche rareté, slot, percentiles et état des rolls proposés ; l’ouverture suspend la simulation et la fermeture la reprend seulement si elle tournait déjà. Test headless et revue du rendu fenêtré.
- [x] Équipement persistant : équiper, déséquiper et remplacer une pièce du même slot ; migration des profils précédents. Le prototype P6 applique maintenant les lignes portées à Survival ; leurs plages restent proposées et non calibrées.
- [x] Progression v5 : migration des profils précédents vers quatre tiers de Powder, conversion 10:1, amélioration de ligne +0..+10, coût de rareté/niveau et pity au dixième essai ; probabilités et coûts restent les valeurs **[PROPOSÉES]** du GDD.
- [x] `progression_service_smoke.gd` exerce maintenant des profils fixtures v1 à v5; vérifie mise à niveau vers v6, conservation des ressources/récompenses déjà attribuées/équipements et initialisation additive des champs absents. La conversion propre à chaque version reste limitée aux schémas explicitement définis dans le code.
- [x] UI Enhancement : sélection du tier Powder, affichage du niveau de ligne et ressources, consommation, retour de résultat et inventaire persistant vérifiés dans `survival_inventory_smoke` et revue fenêtrée.
- [x] Équipement : choix d'un effet unique éligible et démontage persistés. Rendement provisoire. Lightning burst, overflow shield, evolution shockwave, elite haste et reroll gratuit du premier coffre ont des prototypes; le knockback de résurrection est exclu des nouveaux choix et reste sans gameplay défini.
- [x] Skill tree : Vitality (+5 % HP, 50 Essence), Focused Training (+3 % dégâts, 80 Essence), Fleet Footed (+2 % vitesse, 110 Essence) et Steady Aim (+1 point de critique, 140 Essence), valeurs **[PROPOSÉES]**. Prérequis, dépenses, effets en session Survival/Armorless et respec gratuit vérifiés.
- [x] Achievement prototype : kills cumulés et quatre paliers Exterminator **[PROPOSÉS]** crédités une seule fois par run ; bonus dégâts cumulés de l'exemple vérifiés.
- [x] Catalogue d’achievements data-driven : `progression_service_smoke.gd` valide les métadonnées catégorie/métrique/agrégation/secret, les quatre paliers et récompenses des 100 familles dans `game/data/achievement_catalog.json`; le chargeur rejette les entrées manquantes/dupliquées, seuils non croissants ou récompenses non numériques. L’extension à la cible éditoriale proposée de 120 familles et la calibration restent à faire.
- [ ] Rareté ajustée par difficulté/vague et mort précoce, calibrage des rolls, arbitrage vente/démantèlement et validation des bonus. Le rayon de ramassage ne doit jamais affecter la collecte de coffres selon GDD v1.6.
- [x] Revue de code v1.6 : collecte de coffres utilise uniquement `chest_collection_radius`; `pickup_radius_pct` ne l’élargit pas.
- [x] Smoke de régression sous Godot 4.7.2 Linux (`survival_chest_smoke`) : avec `pickup_radius_pct` à 900 %, l’XP distante est collectée et le coffre hors de `chest_collection_radius` reste au sol ; les coffres dans le rayon ouvrent le choix en pause.
- [x] Magnet Heart sous Godot 4.7.2 Linux : disponible sans évolution, bonus XP aux niveaux 1 et 5, plafond de niveau respecté et aucun effet sur le coffre à distance.
- [x] Achievement tiers débloqués une seule fois et bonus cumulés vérifiés pour la famille prototype Exterminator ; le catalogue et les seuils complets restent à définir.
- [ ] Armorless : 3 équipements proposés après chaque vague, 1 choisi ; Flux temporaire.
- [ ] Armorless : amélioration depuis l'inventaire de pause, coût débité du Flux, résultat visible, simulation suspendue et aucun Powder/sauvegarde permanente.
- [x] Armorless : le directeur traverse cinq cycles de boss jusqu'à la vague 60; une session vérifie le temps actif et le HP decay pendant l'état boss alors que l'horloge de vague reste gelée, puis leur continuité après transition. La session suit la formule HP **[PROPOSÉE]** du GDD : ×1,10 jusqu'à la vague 24, puis ×1,055 par vague. La durée de production avec drafts et boss effectivement joués reste à valider.
- [x] `SaveService` : slot JSON versionné, checksum SHA-256, remplacement via temporaire, backup relu après altération/corruption et migration de la fixture v0 dictionnaire brut ; vérifié par `save_service_smoke`. Cette fixture ne définit pas un ancien schéma de production. Le service n’est pas chargé par le Sandbox.
- [x] Progression Survival : gains d’Essence/Powder selon la formule **[PROPOSÉE]** Normal, cumul sur plusieurs runs, défaite récompensée et `run_id` idempotent ; injection du service uniquement par l’entrée Survival et smoke avec slot temporaire isolé.
- [x] Idempotence après redémarrage : `progression_service_smoke.gd` crée un nouveau `ProgressionService`, recharge le même slot, rejoue un `run_id` déjà récompensé et vérifie l’absence de ressources et équipement supplémentaires.
- [x] Récupération de profil après corruption : `progression_service_smoke.gd` corrompt le slot courant, recrée `SaveService` et `ProgressionService`, puis vérifie que le backup précédent est relu et validé sans perdre runs récompensées ni équipement; `save_service_smoke.gd` couvre les contrôles génériques de checksum et JSON.
- [x] **État historique, remplacé par les validations P7B et P8.1/P8.3 du 2026-10-17 :** le mode Endless standard n’était pas encore implémenté à la date de cette entrée.

## Runner headless (CLI P1 implémentée)

```bash
dopamine-sim --scenario benchmark_500_enemies --duration 60 --output results.json
```

Le runner est fourni par `game/scripts/scenario_runner.gd` et consomme un fichier JSON de commandes. Le nom `dopamine-sim` et les options de durée illustrés ci-dessus restent une proposition distincte.

## Audit du 2026-10-15

- `git diff --check` exécuté ; résultat attendu consigné dans la revue du changement.
- Le binaire officiel Godot 4.7.2 a été lancé depuis `/tmp` (il reste absent du PATH). Import headless réussi ; smokes `combat_catalog`, `survival_loadout`, `survival_starting_weapon`, `survival_weapon_catalog`, `survival_inventory` et `survival_chest` réussis.
- Cet import a révélé trois erreurs d’inférence GDScript qui empêchaient Survival/Skill Tree de se charger ; les types de `evolved`, `vitality_cost` et `focus_cost` ont été explicités avant la réussite des smokes.
- Cibles natives non reconstruites dans cet audit ; les résultats historiques ci-dessus restent datés de leurs exécutions précédentes.
- P5 v1.6 (dix armes, onze reliques, familles d’ennemis) n’est pas livré ; dix paires ont un prototype Survival, dont Frost Nova/Absolute Zero. Le smoke `survival_weapon_catalog_smoke` vérifie les impacts prioritaires et les effets de statut/évolution. La progression permanente existante est un prototype anticipé P6.

## UI refonte — ui-foundation (2026-10-15)

- [x] Godot 4.7.2 Linux : import headless du projet avec le Theme UI partagé.
- [x] Smoke `ui_foundation_smoke.gd` : palette et styles, contrôles requis, focus initial, Tab, limites géométriques à 1280×800, 1600×900 et 1920×1080, mapping Entrée/Espace/A et Échap/B.
- [x] Lancement fenêtré de la scène de prévisualisation sous Xvfb aux trois tailles ci-dessus; aucune erreur de script ou de parsing. Le smoke confirme les limites du panneau; la revue fenêtrée complète reste limitée par l’absence d’entrée souris interactive dans l’environnement.
- [ ] Essai avec une manette physique non exécuté : aucun périphérique de jeu n’est présent. Les mappings A/B sont vérifiés dans `InputMap`, ce qui ne prouve pas l’activation sur matériel.
- [ ] Build natif et CTest non exécutés : `cmake` et `ctest` sont absents de l’environnement. Les artefacts de build préexistants ne sont pas considérés comme une validation de ce changement.

## UI refonte — ui-settings (2026-10-15)

- [x] Godot 4.7.2 Linux : import headless du projet et smokes `settings_service_smoke.gd`, `ui_settings_smoke.gd` passés avec `XDG_DATA_HOME` temporaire.
- [x] Service : valeurs par défaut, clamp `[0,100]`, valeur non finie, persistance/relecture, fichier invalide, retour sûr et bus Master fini à −80 dB pour 0 % vérifiés.
- [x] Panneau : Theme, deux réglages, focus initial, synchro/affichage du volume, demande de fermeture par bouton et entrée B synthétique, présence des actions A/B et limites géométriques à 1280×800, 960×600, 1600×900 vérifiés.
- [x] `ui_settings_smoke.gd` vérifie l’ordre DISPLAY → plein écran → séparateur → volume et le style PixelHeading; exécuté sous Godot 4.7.2, passe.
- [x] Slider et CheckButton du Theme utilisent les couleurs de la palette néon; la poignée de volume est un rond pixel 12×12 filtré nearest. `ui_settings_smoke.gd` vérifie aussi que le focus du slider reprend le cadre doré partagé. Smokes `ui_foundation_smoke.gd`, `ui_settings_smoke.gd` et `settings_service_smoke.gd` passent; la capture Options à 640×360 logique en fenêtre 1280×720 a été inspectée.
- [x] Régression : `sandbox_smoke.gd`, `sandbox_ui_smoke.gd` et `survival_entry_smoke.gd` passés avec des profils `XDG_DATA_HOME` isolés. Le service ne dépend pas de `SaveService` et écrit seulement ses préférences dans `user://settings.cfg`.
- [x] Prévisualisation fenêtrée sous Xvfb aux trois tailles sans erreur de script; rendu examiné à 1280×800.
- [ ] Interaction physique souris/clavier/manette non parcourue de bout en bout; aucun contrôleur n’est présent et aucun outil de souris interactive n’est disponible dans cet environnement. Les smokes ajoutent maintenant des événements synthétiques de croix et B, mais ne remplacent pas le contrôle sur matériel.
- [ ] Plein écran sur écran réel et sortie audio sur haut-parleurs/casque non vérifiés; seules les API DisplayServer/AudioServer et leurs valeurs sous headless ont été exercées.
- [x] Test d’intégration de l’écran Options depuis la pause couvert par `survival_pause_smoke.gd` : Retour, Échap et B ramènent à Pause, restaurent le focus et ne font avancer ni temps Simulation, ni temps actif, ni position joueur.
- [ ] Build natif et CTest non exécutés : `cmake` et `ctest` sont absents de l’environnement.

## UI refonte — survival-pause (2026-10-16)

- [x] `survival_pause_smoke.gd` est enregistré dans CTest et vérifie que `LOCK HEALTH` apparaît sous la vitesse, bloque dégâts PV/bouclier lorsqu'il est actif puis restaure le calcul normal à sa désactivation.
- [x] Validation intégrée : `simulation_core`, scénario Sandbox des profils, smoke Pause, smoke visuel sous Xvfb et `survival_weapon_catalog_smoke` passent; la suite CTest complète passe 53/53. Après un échec isolé précédent sur Infinite Circuit, le catalogue a passé directement, trois répétitions consécutives puis cette suite complète.
- [x] Godot 4.7.2 Linux : import headless réussi; `survival_pause_smoke.gd` vérifie ouverture/reprise, focus, temps Simulation/actif/vague et positions joueur/ennemi figés, retour d’Options par bouton/Échap et bornes Pause aux viewports 960×600, 1280×800 et 1600×900.
- [x] `survival_pause_inventory_smoke.gd` vérifie la projection en lecture seule de deux armes/deux reliques, noms, niveaux, descriptions, icônes et évolution active; l’ouverture place le focus sur le premier objet, les flèches déplacent le focus et le défilement, le contour doré est visible et les icônes 24×24 utilisent le filtrage nearest.
- [x] Le même smoke ferme l’inventaire par B synthétique et vérifie le retour du focus à Pause en maintenant la run gelée.
- [x] `survival_pause_inventory_smoke.gd` et `ui_viewport_layout_smoke.gd` passent; bounds de l’inventaire testés à 640×360, 1280×720 et 1920×1080.
- [x] `survival_abandon_smoke.gd` vérifie focus sûr, annulation souris/Échap/B, bounds de la confirmation, retour à l’accueil, suppression de session et absence de changement aux ressources, objets ou runs récompensées du profil.
- [x] Régressions passées : `survival_starting_weapon_smoke`, `survival_chest_choice_smoke`, `survival_chest_smoke`, `survival_hud_smoke`, `run_result_panel_smoke`, `survival_run_result_smoke`, `survival_loadout_smoke`, `survival_inventory_smoke`, `survival_wave_director_smoke`, `survival_wave_duration_smoke`, `survival_entry_smoke`, `survival_hub_smoke`, `survival_hub_layout_smoke`, `launch_navigation_smoke`, `ui_settings_smoke`, `settings_service_smoke`, `sandbox_smoke` et `sandbox_ui_smoke`.
- [x] L’assertion historique de `combat_catalog_smoke.gd` est à nouveau satisfaite : le catalogue décrit maintenant les dagues orbitantes validées par le GDD.
- [ ] Parcours matériel complet souris/clavier/manette non réalisé; le focus, les actions A/B et les contrats bouton/Échap sont testés sous headless, mais aucun périphérique ni entrée fenêtrée interactive n’était disponible.
- [ ] CTest/build natif non exécutés : `ctest` et `cmake` sont absents du PATH. `git diff --check` passe.

## Vitesse de run Survival (2026-10-16)

- [x] `survival_speed_control_smoke.gd` : choisir ×4 dans le menu Pause applique la vitesse au moteur de combat et à `Engine.time_scale`, puis quitter Survival restaure ×1.
- [x] `survival_pause_smoke.gd` et `survival_wave_duration_smoke.gd` passent avec le nouveau contrôle; la vague simulée de 30 secondes avance correctement à ×4.


## UI refonte — sandbox-ui (2026-10-16)

- [x] `render_visual_smoke.gd` sous Xvfb/Mesa : scène Sandbox vérifiée à 640×360 logiques dans la fenêtre par défaut 1280×720; les entités restent découpées dans la zone de simulation, sans recouvrir l’accueil. llvmpipe passe le smoke; audio et V-Sync indisponibles dans le conteneur.
- [x] `sandbox_ui_smoke.gd` : Theme partagé, grille métriques, focus initial, spawn/inspection/DoT, pause/reprise, step/vitesse, tuning/reset et sauvegarde sentinelle inchangée. Godot 4.7.2 headless passe avec `XDG_DATA_HOME` temporaire isolé.
- [x] `sandbox_ui_smoke.gd` vérifie aussi la barre d’outils cyan (pause/reprise), jaune (step) et rouge (reset). Capture à 640×360 logique relue; les accentuations ne changent pas l’isolation de la sauvegarde sentinelle.
- [x] `sandbox_ui_smoke.gd` couvre le badge de statut dans ses états pause/marche; exécuté sous Godot 4.7.2 avec `XDG_DATA_HOME` isolé, passe.
- [x] `ui_foundation_smoke.gd` vérifie les états normal/survol/appui/focus des barres de défilement horizontales/verticales du Theme; `sandbox_ui_smoke.gd` vérifie que le préfixe compact `WGT` tient dans le réglage d’espacement tout en gardant le tooltip explicatif. Capture Sandbox 1280×720 inspectée : poignée bleu ardoise bordée cyan, champ `WGT 0.5` entier.
- [x] `sandbox_smoke.gd` : vérification de base Sandbox.
- [x] Vérification statique : `main.gd` et la scène Sandbox ne référencent pas `SaveService` ni les services de progression. Le Sandbox conserve son chemin isolé vers le prototype Survival.
- [x] Import éditeur Godot 4.7.2 headless et `git diff --check`.
- [ ] Interaction physique souris/clavier/manette non parcourue; focus initial et styles natifs de focus vérifiés dans le smoke, matériel absent.
- [ ] Build natif/CTest non exécutés : `cmake` et `ctest` absents du PATH.


## Clôture UI intégrée (2026-10-16)

- [x] Suite ciblée de 21 smokes UI/intégration passés sous Godot 4.7.2 Linux avec profils `XDG_DATA_HOME` temporaires isolés : foundation, settings, navigation, hub/layout, HUD, départ, coffres, résultats, pause/inventaire/abandon, loadout, durée de vague, entrée et Sandbox. La liste exacte est dans [`INTEGRATION-ui-refonte.md`](../../tasks/ui-refonte/INTEGRATION-ui-refonte.md).
- [x] Import éditeur headless et rendu `render_visual_smoke.gd` sous Xvfb/Mesa passés; inspection du Sandbox à 640×360 logiques confirme le clipping du playfield.
- [x] Clôture documentaire des sept modules dans `tasks/ui-refonte/` et mise à jour de la carte de capacités.
- [ ] Interaction physique manette/souris, plein écran sur écran réel et sortie audio matérielle non vérifiés.
- [ ] Build natif et CTest non exécutés : `cmake` et `ctest` ne sont pas dans le PATH.
- [ ] `combat_catalog_smoke.gd` conserve une assertion historique dague-orbite contredite par le catalogue actuel; sans rapport avec les changements UI.

## Art UI et catalogue — icônes dédiées (2026-10-16)

- [x] Import Godot 4.7.2 headless réussi après ajout des icônes générées du catalogue.
- [x] `catalog_icon_assets_smoke.gd` passe : les 10 icônes d’armes, 10 icônes d’évolution et 11 icônes de reliques font 32×32, restent sous la limite de 16 couleurs, et possèdent un PNG et une source Aseprite valide.
- [x] `survival_chest_choice_smoke.gd`, `survival_pause_inventory_smoke.gd`, `ui_foundation_smoke.gd` et `survival_hud_smoke.gd` passent avec les nouvelles icônes et le Theme arcade à angles droits.
- [ ] `survival_weapon_catalog_smoke.gd` échoue sur sa vérification de branche Infinite Circuit après l’ajout visuel. Aucun comportement de combat n’a été modifié dans le lot; le scénario attend que des projectiles atteignent six cibles avant un délai de deux secondes. À isoler avant la clôture de la refonte.
- [ ] Aucun parcours physique souris/manette, export depuis l’application Aseprite, build natif ou test matériel n’a été réalisé dans ce lot.

## Art UI — icônes de progression (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` passe pour les 16 icônes UI supplémentaires : 32×32, limite de 16 couleurs, PNG et source Aseprite.
- [x] `survival_inventory_smoke.gd`, `run_result_panel_smoke.gd`, `ui_foundation_smoke.gd`, `survival_hub_layout_smoke.gd` et `launch_navigation_smoke.gd` passent.
- [x] `sandbox_ui_smoke.gd` passe avec un `XDG_DATA_HOME` neuf et isolé; son premier lancement avait réutilisé les données de smokes précédents et invalidé sa sentinelle de sauvegarde.

## Navigation manette — retour/annuler (2026-10-16)

- [x] `survival_hub_smoke.gd` injecte B pour fermer les panneaux équipement/compétences en restaurant le focus, puis revenir à l’accueil depuis le hub.
- [x] `run_result_panel_smoke.gd` injecte B depuis l’écran de résultat et vérifie la demande « quitter vers le menu ».
- [x] `sandbox_ui_smoke.gd` injecte B pour revenir à l’accueil et compare la sauvegarde de progression sentinelle avant/après.
- [x] Les trois smokes ci-dessus passent sous Godot 4.7.2 via Xvfb avec `XDG_DATA_HOME` isolé. Les avertissements ALSA indiquent l’absence de sortie audio et le fallback vers le driver dummy; aucun échec de script n’est émis.
- [ ] Interaction avec une manette physique non exécutée; les événements synthétiques vérifient la logique UI et ne remplacent pas le contrôle sur matériel.

## Repère de défilement — inventaire de run (2026-10-16)

- [x] Les totaux d’armes/reliques indiquent maintenant les commandes de défilement clavier et molette, au-dessus de la liste.
- [x] `survival_pause_inventory_smoke.gd` passe sous Godot 4.7.2; la capture logique 640×360 a été inspectée et le repère tient sur une ligne.

## Revalidation de la refonte UI (2026-10-16)

- [x] Import éditeur Godot 4.7.2 réussi, y compris la réimportation de la tuile Survival mise à jour.
- [x] Les 18 smokes ciblés passent sous Xvfb/Mesa, avec un `XDG_DATA_HOME` distinct : `ui_foundation_smoke`, `ui_settings_smoke`, `launch_navigation_smoke`, `survival_hub_smoke`, `survival_hub_layout_smoke`, `ui_viewport_layout_smoke`, `survival_hud_smoke`, `survival_chest_choice_smoke`, `survival_chest_layout_smoke`, `run_result_panel_smoke`, `survival_pause_smoke`, `survival_pause_inventory_smoke`, `survival_abandon_smoke`, `survival_inventory_smoke`, `sandbox_ui_smoke`, `catalog_icon_assets_smoke`, `pilot_scene_visual_smoke` et `render_visual_smoke`.
- [x] Les bounds UI passent de 640×360 à 1920×1080; le smoke HUD contrôle aussi les tailles intermédiaires jusqu’à 1600×900. Les captures Survival et Sandbox ont été générées; la capture récente de l’inventaire est inspectée à 640×360.
- [x] Le smoke Sandbox conserve son profil sentinelle inchangé; le smoke d’assets contrôle dimensions, palettes, sources Aseprite et la densité réduite de la tuile active.
- [ ] Manette physique, plein écran sur écran réel et sortie audio matérielle restent à vérifier; la simulation de manette est synthétique et l’audio utilise le driver dummy en environnement Xvfb.

## Revue visuelle de l’accueil — 2026-10-17

- [x] Corriger `launch_navigation_smoke.gd` : l’option `--capture` capturait auparavant le Sandbox Lab après navigation, malgré le nom `dopamine-launch-menu.png`. La capture est maintenant faite sur l’accueil revenu du Sandbox, avant d’ouvrir le Lab.
- [x] `launch_navigation_smoke.gd -- --capture` passe sous Godot 4.7.2 avec Xvfb/Mesa llvmpipe; la capture logique 640×360 a été inspectée. La colonne de menu à gauche, l’identité à droite, le focus initial sur Jouer et l’accès Sandbox secondaire respectent la composition prévue.
- [ ] La capture llvmpipe ne valide pas le rendu sur écran physique; les tailles supérieures restent couvertes par les smokes de géométrie, sans inspection visuelle dédiée dans ce passage.

## Revue visuelle du hub Survival — 2026-10-17

- [x] `survival_hub_layout_smoke.gd -- --capture` passe sous Godot 4.7.2/Xvfb et produit `/tmp/dopamine-survival-hub.png` à 640×360; la capture a été inspectée. Difficulté choisie et verrouillées, statut de profil, records, équipement/compétences et trois parcours de lancement restent dans la surface logique, avec la carte de préparation mise en évidence.
- [x] Les viewports 640×360, 1280×720 et 1920×1080 restent couverts par le smoke de bounds et d’absence de chevauchement.
- [ ] Revue des tailles agrandies sur rendu réel et navigation avec souris/manette physiques non effectuées.

## Icône catalogue — Lightning Conductor (2026-10-16)

- [x] Référence générée dédiée conservée dans `game/assets/source/catalog_weapons/`; le builder remplace l’ancienne cellule aplatie et régénère le PNG 32×32 ainsi que sa source Aseprite depuis `DEDICATED_ICON_REFERENCES`.
- [x] `catalog_icon_assets_smoke.gd` vérifie la référence de reconstruction et les contraintes existantes de dimensions, palette et source éditable.
- [x] `catalog_icon_assets_smoke.gd`, coffre avec capture, `survival_hud_smoke.gd` et `survival_pause_inventory_smoke.gd` passent sous Godot 4.7.2; l’icône a été inspectée dans la carte du coffre.

## Art combat — roster statique (2026-10-16)

- [x] Import Godot 4.7.2, `catalog_icon_assets_smoke.gd` (9 ennemis, élite, 2 boss; dimensions 24×24/96×96, impacts 64×64, palette et sources), `render_batching_smoke.gd`, `sandbox_ui_smoke.gd` avec profil isolé et `survival_entry_smoke.gd` passent.
- [x] `pilot_scene_visual_smoke.gd` sous Xvfb/Mesa : joueur et chasers de la nouvelle planche visibles; HUD deux coins inspecté à 1280×800.
- [x] Après déplacement timer/vague/état vers le panneau de droite : `survival_hud_smoke.gd`, `survival_weapon_smoke.gd`, `survival_wave_director_smoke.gd` et `survival_pause_smoke.gd` passent.
- [x] Le HUD a été recomposé en deux cartes de coin pour le viewport logique 640×360. Les bounds et l’écartement passent de 640×360 à 1920×1080; les smokes HUD/armes/vagues/pause passent, et la fenêtre 1280×720 a été rendue et inspectée sous Xvfb/Mesa.
- [ ] Le HUD a depuis été resserré pour le viewport logique 640×360 en deux cartes de coin; les smokes vérifient les bounds et l’écartement, mais leur version actuelle n’a pas été exécutée dans cet environnement, où `godot` est absent.
- [ ] `survival_weapon_catalog_smoke.gd` conserve l’échec Infinite Circuit décrit ci-dessus; les règles de combat n’ont pas été touchées dans le lot de sprites.
- [ ] Les boss sont des prototypes abstraits et restent non canoniques; aucun test ne valide une animation ou une identité de boss.

Note de clôture : le blocage historique du smoke `sandbox_ui_smoke.gd` décrit dans le compte rendu initial de `launch-navigation` est résolu; les deux smokes Sandbox passent désormais avec des profils temporaires isolés.

## Récupération CMake `godot-cpp` (2026-10-16)

- [x] Cause : `CMakeLists.txt` associait `GIT_SHALLOW TRUE` à un `GIT_TAG` en SHA, combinaison non prise en charge par CMake. L’épingle de commit reste identique; le clone superficiel a été retiré.
- [x] Configuration propre depuis le dépôt avec CMake 3.31.6 et GCC 14.2 : `godot-cpp` récupéré, 2 135 fichiers générés, configuration terminée.
- [x] Build complet Debug : `dopamine_simulation`, tests natifs, `godot-cpp` et `libdopamine.linux.template_debug.x86_64.so` compilés.
- [x] CTest : 2/2 tests natifs passés (`simulation_core`, `simulation_worker`). Smoke `sandbox_smoke.gd` sous Godot 4.7.2 : pont et GDExtension chargés.

## Pilote visuel — scène de combat (2026-10-16)

- [x] Premier lot : joueur cyan 32×32, chaser 24×24 et projectile Lightning Conductor 16×16, dans la palette validée avec au plus 16 couleurs chacun. Chaque PNG dispose d’une source `.aseprite` éditable à un calque; les animations joueur restent à produire.
- [x] `pilot_asset_batch_smoke.gd` vérifie la présence, les dimensions, le plafond de couleurs et la concordance en-tête/dimensions PNG↔Aseprite.
- [x] `survival_entry_smoke.gd`, `survival_hud_smoke.gd` et `survival_weapon_smoke.gd` passent sous Godot 4.7.2 headless. Import éditeur headless réussi.
- [x] `pilot_scene_visual_smoke.gd` sous Xvfb/Mesa rend et sauvegarde la scène Survival à 1280×800; inspection confirme la lecture des sprites au centre de l’arène. Aucun service Sandbox/progression ni règle de combat n’a changé.
- [x] Le tile de sol généré a été écarté de la scène après inspection, sa répétition créant un bruit visuel trop dense; le sol actuel reste actif.
- [ ] Ce pilote attend la revue artistique avant la production en série. Audio et V-Sync ne sont pas disponibles dans le conteneur de rendu.

## Art combat — projectiles pixel (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` : les 24 projectiles exportés mesurent 16×16, ont une source Aseprite valide et respectent le plafond de 16 couleurs.
- [x] `render_batching_smoke.gd` : base et évolutions utilisent les textures dédiées dans les batches de projectile actifs.
- [ ] `survival_weapon_catalog_smoke.gd` garde l’échec historique Infinite Circuit déjà consigné; ce lot change le rendu des projectiles, pas leurs règles ni leur simulation.
- [ ] Les traînées, projectiles beam continus et animations de projectile ne sont pas couverts par cette planche statique; conventions d’animation encore **[OUVERTES]**.

## Art environnement — sol Survival provisoire (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` vérifie les dimensions et sources Aseprite du sol candidat et de l’overlay pixel art; le sol candidat respecte les 32 couleurs de la palette maître.
- [x] À ce stade historique, `pilot_scene_visual_smoke.gd` confirme l’overlay pixel art à 1280×800; le sol candidat reste hors du jeu car son motif répétitif est trop perceptible, donc `survival_ground.svg` est conservé. Ce sol a depuis été remplacé par `survival_ground_pixel.png` (section « Sol Survival pixel art »). Le biome canonique reste **[OUVERT]**.

## Art pickups Survival (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` vérifie le coffre 32×32 et l’orbe XP 16×16, leurs PNG/Aseprite, et leur plafond de 16 couleurs.
- [x] Les deux textures sont branchées aux appels de rendu déjà existants; aucune règle de collecte ou récompense n’a changé.

## Art accueil — skyline (2026-10-16)

- [x] `process_title_skyline.gd` régénère le PNG 640×360 et sa source Aseprite mono-calque depuis la référence aplatie, avec 30 couleurs de la palette maître.
- [x] `catalog_icon_assets_smoke.gd` contrôle dimensions, palette et en-tête/dimensions Aseprite.

## Responsive Sandbox — panneau latéral (2026-10-16)

- [x] `sandbox_ui_smoke.gd` vérifie les limites des boutons Spawn/Despawn/Kill et l’absence de défilement horizontal à 640×360, 1280×720 et 1920×1080.
- [x] Le formulaire de création place le type, le nombre, les PV et les vitesses sur des rangées étroites pour respecter la largeur de la colonne; les actions Sandbox et l’isolation de sauvegarde sont conservées.
- [x] Smoke Sandbox UI sous Godot 4.7.2 avec `XDG_DATA_HOME` temporaire isolé.

## Sol Survival pixel art (2026-10-16)

- [x] Historique : `process_survival_ground.gd` produisait une texture répétable 256×256 depuis une référence générée; cette version est remplacée après revue du rendu répété.
- [x] `process_survival_ground_tile.gd` produit le PNG et la source Aseprite mono-calque de la tuile 16×16 active, avec trois teintes sombres de la palette maître et des bords opposés identiques.
- [x] `catalog_icon_assets_smoke.gd` vérifie dimensions, palette restreinte, densité maximale de six pixels d’accent par tuile, couture sans joint visible, source Aseprite et branchement dans Survival; `pilot_scene_visual_smoke.gd` permet d’inspecter le sol répété en combat.
- [x] Les textures SVG, l’ancien sol 256×256 et le candidat moss/stone restent hors du rendu actif; aucune collision ni logique de combat ne change.

### Réduction du bruit de répétition (2026-10-16)

- [x] La tuile active passe des amas répétés de 2×2/3×3 pixels à cinq accents isolés sur 256 pixels, sans changer la grille 16×16, les trois teintes ou la couture.
- [x] Le PNG et la source Aseprite sont régénérés; contrôle statique de l’en-tête PNG/Aseprite, de la palette, du nombre d’accents et des bords opposés réussi.
- [ ] `catalog_icon_assets_smoke.gd` et le rendu de scène n’ont pas été rejoués après cette modification : aucun exécutable Godot n’est disponible dans cet environnement.

## Animations du héros pixel art (2026-10-16)

- [x] Les feuilles idle/marche 4×4 utilisent des frames natives 32×32, une palette limitée à 16 couleurs et des sources Aseprite éditables; ligne des directions Bas/Gauche/Droite/Haut **[PROPOSÉE]**.
- [x] Le contrôleur choisit les frames selon la direction déjà lue par les contrôles et reprend l’image idle quand le joueur s’arrête; contrôles, vitesse et collisions inchangés.
- [x] `catalog_icon_assets_smoke.gd`, `player_controller_smoke.gd`, `survival_entry_smoke.gd` et `pilot_scene_visual_smoke.gd` passent; rendu du personnage inspecté en jeu à 640×360 logique.

## Explosion de pixels à la mort d’un ennemi (2026-10-16)

- [x] L’événement de mort d’un ennemi dessine huit fragments carrés de la palette maître; le burst suit le temps de simulation, se fige en pause et ne crée aucune entité de combat.
- [x] `survival_weapon_smoke.gd` vérifie huit fragments par burst et l’absence de burst pour les projectiles ennemis; la capture en jeu confirme le rendu du burst.
- [x] Durée 0,32 s et nombre de pixels sont **[PROPOSÉS]**; dégâts, cibles, collisions et récompenses inchangés.

## Traînées visuelles des projectiles (2026-10-16)

- [x] `render_batching_smoke.gd` vérifie que les trajectoires orientent les traits derrière les projectiles, que leur plafond visuel tient sous forte charge et qu’ils sont effacés avec les entités.
- [x] Le renderer Survival et le Sandbox dessinent ces traits sous les sprites; inspection d’une capture Survival logique 640×360.
- [x] Longueur, cyan neutre et budget maximal de 256 sont **[PROPOSÉS]**; le mapping couleur par élément reste **[OUVERT]**.
- [x] `render_visual_smoke.gd` passe après alignement de ses positions de stress sur la zone Sandbox visible et sur le viewport logique 640×360; rendu dense revu visuellement.

## Enseignes animées de l’accueil (2026-10-16)

- [x] `launch_navigation_smoke.gd` vérifie la couche de skyline et l’avancement de son horloge de clignotement, en plus des parcours/focus existants.
- [x] Capture de l’accueil inspectée à 640×360; les trois enseignes restent dans les marges visibles du décor et derrière la carte de menu.
- [x] Les périodes de 1,4 à 2,2 s et la phase sombre sont **[PROPOSÉES]**; le rythme exact de clignotement reste **[OUVERT]**.

## Hiérarchie des titres UI (2026-10-16)

- [x] Les titres d’écran et de sections dans l’accueil, Options, hub, choix de coffre, inventaires, pause, résultats et Sandbox utilisent la variation de thème `PixelHeading`; les textes de description conservent la fonte sans moderne.
- [x] `ui_foundation_smoke.gd` vérifie la police et la couverture des titres; `survival_pause_inventory_smoke.gd` couvre aussi les en-têtes créés dynamiquement.
- [x] `run_result_panel_smoke.gd`, `survival_hud_smoke.gd` et `ui_viewport_layout_smoke.gd` passent; les vues principales sont inspectées à 640×360 logiques.
- [x] `run_result_panel_smoke.gd` vérifie les états sans sauvegarde, victoire, doublon et échec de sauvegarde avec une récompense longue; le panneau et chacun de ses contrôles restent contenus de 640×360 à 1920×1080.
- [x] Press Start 2P est l’association **[PROPOSÉE]** pour `PixelHeading`; le choix exact de police reste **[OUVERT]**.

## Sources éditables des assets actifs (2026-10-16)

- [x] `catalog_icon_assets_smoke.gd` passe sous Godot 4.7.2 pour catalogue, icônes UI, roster, projectiles, impacts, environnement, récompenses et fond skyline; il vérifie les dimensions, palettes et sources Aseprite attendues.
- [x] Le smoke d’assets vérifie aussi le PNG/source Aseprite 96×96 du Dopamine Core, sa transparence, sa palette ≤16 couleurs et son routage depuis l’entité `final_boss`; `survival_boss_attack_smoke.gd` passe avec le nouveau sprite chargé.
- [x] `simulation_core` vérifie le déplacement temporisé prioritaire au steering et sa continuité après capture/restauration; `simulation_worker` vérifie le format de snapshot mis à jour. `survival_boss_attack_smoke.gd` vérifie la télégraphie et le déplacement de charge du Pulse Warden en phase 3, ainsi que sa séquence radiale.
- [x] Le smoke `survival_run_result_smoke.gd` attend que le worker ait confirmé la reprise et la vitesse ×4 avant de déclencher le test de mort; cela évite de mesurer la durée de démarrage asynchrone du worker.
- [x] `survival_weapon_catalog_smoke.gd` attend que la vitesse de simulation soit appliquée et n’active les armes qu’après création des cibles pour stabiliser la baseline de collisions. Le scénario Frost Nova refroidit désormais une cible survivante puis la tue séparément pour vérifier le shatter sur une mort effectivement gelée. Le scénario Crimson vérifie les deux impacts attendus.
- [x] Le smoke Infinite Circuit a mis au jour une origine de tir erronée des branches (créées au-delà de leur cible, vers l’extérieur) ; elles partent maintenant du parent vers la cible suivante. Le test couvre le comportement de chaîne et d’évolution.
- [x] `survival_wave_director_smoke.gd` vérifie que le timer de vague reste suspendu pendant les deux boss, que le decay joueur continue et que les spawns réguliers reprennent après le mid-boss de vague 12. Le smoke garde un intervalle de spawn court en mode accéléré pour tester cette reprise dans la fenêtre de run.
- [x] `survival_wave_duration_smoke.gd` compare la durée de vague au temps de simulation déjà traité par `SurvivalSession`, en tenant compte du temps écoulé avant le début de la mesure; le contrôle a passé trois exécutions de suite.
- [x] `survival_chest_smoke.gd` vérifie Magnetic Pulse niveau 5 : l’orbe accélère progressivement dans 300 % du rayon, ne se téléporte pas et n’est collectée qu’à la portée normale; le rayon de coffre reste indépendant. Le smoke contrôle aussi le gel du timer et du mouvement en pause. Intervalle 20 s, durée 1,5 s, accélération 600 et vitesse max 240 sont **[VALIDÉS, 2026-10-17]**.
- [x] Après ces changements, build natif Debug et suite CTest complète sous Godot 4.7.2 avec `XDG_DATA_HOME` isolé : 44/44 passent. Les smokes `survival_weapon_catalog_smoke`, `survival_run_result_smoke` et `survival_wave_director_smoke` ont également passé plusieurs exécutions ciblées.
- [x] `pilot_asset_batch_smoke.gd` passe pour les exports animés du joueur et leurs sources; `signal_prism_asset_smoke.gd` passe pour l’emblème et son intégration à l’accueil.
- [x] L’audit de références runtime ne trouve plus d’asset SVG parmi les visuels chargés par les scènes/scripts; les anciens SVG restants sont des références inactives, sauf une référence historique dans `combat_catalog_smoke.gd`.

## Repères visuels de l’équipement (2026-10-16)

- [x] Les lignes d’équipement affichent séparément l’icône de leur emplacement et celle de leur rareté, en 24×24 et nearest.
- [x] `equipment_panel_visual_smoke.gd` vérifie les ressources, les tailles, le filtrage et les bounds à 640×360, 1280×720 et 1920×1080 sous Godot 4.7.2.
- [x] Capture fenêtrée Xvfb relue à 640×360 logique; les icônes sont distinctes et lisibles près du détail de l’objet.

## Icône de ressource dans l’arbre de compétences (2026-10-16)

- [x] Le solde d’essence reprend l’icône dédiée de la Bible d’assets, en nearest, sans changer son calcul ni les prérequis des nœuds.
- [x] `skill_tree_panel_visual_smoke.gd` vérifie l’icône, le filtrage et la valeur affichée sous Godot 4.7.2.

## Branche visuelle de l’arbre de compétences (2026-10-16)

- [x] `skill_tree_panel_visual_smoke.gd` couvre les deux nœuds existants, le connecteur, la séparation entre action et effet/coût proposé et les statuts de déverrouillage; smoke passé sous Godot 4.7.2.
- [x] Les effets/coûts utilisent 8 px avec retour à la ligne; le smoke échoue si leur taille passe sous ce seuil.
- [x] Capture fenêtrée sous Xvfb relue à 640×360 logique; le cadre et les deux cartes tiennent dans le viewport, le texte est plus lisible, et le focus reste visible.
- [x] `ui_viewport_layout_smoke.gd` vérifie toutes les interfaces à 640×360, 1280×720 et 1920×1080.

## Repère XP du HUD (2026-10-16)

## Déblocages d’armes et de reliques (2026-10-16)

- [x] `progression_service_smoke.gd` vérifie les starters, les prérequis de Crimson Daggers puis Blood Chalice, les coûts **[PROPOSÉS]**, et le remboursement/réinitialisation au respec.
- [x] `progression_service_smoke.gd` achète toutes les branches d’équipement puis confirme que les 10 armes et 11 reliques sont disponibles et que le respec rembourse tous leurs coûts.
- [x] `survival_loadout_smoke.gd` vérifie le filtrage des offres et des choix de départ selon les déblocages, puis le chargement du catalogue complet; `survival_hub_smoke.gd` confirme les deux choix d’arme et les deux reliques de départ d’un profil neuf.
- [x] `survival_entry_smoke.gd` vérifie que le Sandbox n’injecte pas de ProgressionService; il conserve donc son catalogue complet.
- [x] `skill_tree_panel_visual_smoke.gd` couvre le défilement, les cartes générées de tout l’équipement, les coûts proposés, les prérequis et les IDs émis.
- [x] Le smoke vérifie aussi que le focus clavier révèle le dernier déblocage dans le viewport; capture Xvfb relue à 640×360 logique.

## Arbre de compétences 100 nœuds (2026-10-16)

- [x] `progression_service_smoke.gd` achète les 100 nœuds selon leurs prérequis, vérifie le proxy linéaire proposé de 29,7 points, confirme les déblocages et le remboursement total au respec.
- [x] `survival_armorless_mode_smoke.gd` applique le profil complet à de vraies sessions Survival et Armorless : HP +10,7 %, dégâts +9 %, mobilité +6 %, critique +4 points, dix armes et onze reliques.
- [x] `skill_tree_panel_visual_smoke.gd` vérifie le rendu des 94 nœuds générés, le focus clavier jusqu’au dernier rang et la capture à 640×360 logique; les trois viewports passent dans `ui_viewport_layout_smoke.gd`.
- [x] Le même smoke vérifie que les infobulles de rangs de statistiques et de déblocages d’équipement nomment leurs prérequis respectifs; exécution ciblée Godot 4.7.2 réussie le 2026-10-17.
- [x] Réexécuter via CTest le 2026-10-17 : `godot_project_import` et `skill_tree_panel_visual_smoke` passent (2/2), ce qui vérifie aussi l’intégration du script de scène au projet importé.
- [x] Le panneau présente les 94 entrées générées sous trois en-têtes — rangs de statistiques, armes et reliques — dans l’ordre du service. Le smoke vérifie libellés et ordre; exécution directe et CTest passent le 2026-10-17.
- [ ] Le proxy linéaire ne remplace pas la calibration d’équivalence de puissance des profils, qui reste dans P6.9.

## Économie proposée de l’arbre de compétences (2026-10-16)

- [x] `progression_service_smoke.gd` vérifie 15 900 Essence cumulée, 4 160 pour les 17 nœuds d’équipement et une moyenne de 2,78 victoires normales vague 24 par déblocage équipement, calculée sur la récompense GDD **[PROPOSÉE]** de 88 Essence.
- [x] À supposer que chaque run atteigne le boss final et gagne, l’arbre complet équivaut à 257 victoires Easy, 181 Normal, 113 Hard, 73 Nightmare ou 46 Chaos avec les multiplicateurs d’Essence **[PROPOSÉS]**.
- [ ] Cette conversion en victoires équivalentes est seulement analytique; fréquence de runs, récompenses de défaite, ventes et ressenti des coûts restent à observer en P6.9.

- [x] Le HUD reprend l’orbe XP 16×16 à sa taille native et en nearest, sans changer les valeurs ni le calcul de progression.
- [x] `survival_hud_smoke.gd` vérifie l’asset, sa taille, son filtrage et les bounds des lignes; exécuté avec Godot 4.7.2, passe.

## Icônes de préparation du hub (2026-10-16)

- [x] Équipements et arbre de compétences réutilisent chacun leur icône pixel dédiée en taille compacte, nearest.
- [x] `survival_hub_smoke.gd` couvre les ressources d’icône, la taille et le filtrage; exécuté avec Godot 4.7.2, passe avec les parcours, destinations inactives et focus.

## Rappel de reprise dans la pause (2026-10-16)

- [x] Le statut du menu indique que la touche Échap reprend la run; le contrôle et le gel de simulation restent inchangés.
- [x] `pause_panel_visual_smoke.gd` vérifie le rappel et les accents d’action; exécuté avec Godot 4.7.2, passe.

## Actions compactes de l’équipement (2026-10-16)

- [x] Équiper/déséquiper et démanteler partagent maintenant une rangée; cyan et rouge distinguent leurs intentions, sans changer les signaux ni les règles.
- [x] `equipment_panel_visual_smoke.gd` vérifie l’ordre, les couleurs, le rendement complet dans l’infobulle et le libellé visible sans troncature.
- [x] `survival_inventory_smoke.gd` passe sous Godot 4.7.2; équipement, amélioration, effet unique, compétences et démantèlement restent fonctionnels.

## Revalidation intégrée des interfaces (2026-10-16)

- [x] Les 26 smokes UI/flux passent sous Godot 4.7.2 avec un `XDG_DATA_HOME` distinct par smoke : fondation, Options, navigation, hub, HUD, choix de départ/coffre, pause, inventaire, résultat, Sandbox et layouts.
- [x] `sandbox_ui_smoke.gd` passe huit fois d’affilée après que le test a suspendu son polling UI pendant la lecture des événements d’un pas déterministe; le fonctionnement du Sandbox n’a pas changé.
- [x] Le smoke d’entrée contrôle les TextureRect des cartes d’arme; le smoke loadout vérifie le niveau suivant et retrouve l’offre ciblée dans les tirages randomisés sans supposer qu’elle figure dans un tirage particulier.

## P8.5 — Reset cooldowns Sandbox Lab (2026-10-16)

- [x] `sandbox_lab_smoke.gd` échoue avant l’implémentation si la commande est absente, puis vérifie que `RESET COOLDOWNS` remet à zéro les dix horloges d’attaque de la session Lab.
- [x] Smoke passé sous Godot 4.7.2 avec un `XDG_DATA_HOME` neuf; le contexte n’a ni `ProgressionService` ni `SaveService` normal. Les avertissements ObjectDB/resource à la fermeture restent présents dans ce smoke.

## P8.5 — Commande de vague et God Mode Sandbox Lab (2026-10-16)

- [x] `sandbox_lab_smoke.gd` vérifie le saut à la vague 17, la remise du timer à zéro, le maintien des spawns automatiques désactivés et le rejet d’une vague 0; God Mode désactivé reste désactivé après l’import JSON qui remplace la session.
- [x] Smoke passé sous Godot 4.7.2 avec `XDG_DATA_HOME` neuf. Ces commandes restent propres au contexte Sandbox et ne touchent pas la progression normale.

## P8.5 — Diagnostics RNG et DPS Sandbox Lab (2026-10-16)

- [x] `sandbox_lab_smoke.gd` vérifie que le seed du preset active un RNG local à la session Lab, que le spawn d’ennemi journalise des tirages avec leur motif, que le tampon RNG reste borné à 256, et que l’arme de départ produit des dégâts réels ventilés par source dans les trois fenêtres DPS.
- [x] `ui_viewport_layout_smoke.gd` passe pour 640×360, 1280×720 et 1920×1080 après l’ajout du panneau; les smokes `survival_weapon_catalog_smoke.gd` et `survival_boss_attack_smoke.gd` passent avec le RNG Sandbox désactivé.
- [x] Le smoke Sandbox retourne 0; Godot signale encore 2 instances ObjectDB et 1 ressource en usage à la fermeture, sans échec fonctionnel.
- [ ] Les valeurs de tuning restent **[PROPOSÉES]**; ces diagnostics n’effectuent ni calibration représentative, ni enregistrement persistant.

## P8.2 — Build visuel du Sandbox Lab et lisibilité du PHUB (2026-10-16)

- [x] `sandbox_lab_smoke.gd` vérifie l’ajout et le changement de niveau d’arme/relique sans doublons, l’ajout d’une stat, puis l’application du build à la simulation Sandbox en pause. Le contexte reste isolé des services de progression et sauvegarde normale.
- [x] Le même smoke couvre un équipement visuel par slot/stat, son effet sur le bonus effectif, et un override LIVE de dégâts qui change le multiplicateur réellement utilisé sans modifier le preset actif.
- [x] Les overrides LIVE sont vérifiés sur dégâts, chance critique, vitesse et HP max, puis leur effacement est contrôlé après reconstruction; le build applique aussi dégâts, vitesse et HP max au combat.
- [x] `survival_run_stat_hub_smoke.gd` vérifie le résumé transparent en lignes verticales icône + valeur et les détails avec libellé au-dessus, icône et total en dessous; navigation Tab et horloges de run continuent de fonctionner.
- [x] `ui_viewport_layout_smoke.gd` passe à 640×360, 1280×720 et 1920×1080; les deux smokes ciblés passent avec Godot 4.7.2.
- [x] Le contrat LIVE/REBUILD/RESTART et ses bornes sont définis dans `docs/architecture/INTERFACES.md`. `sandbox_lab_smoke.gd` vérifie le build REBUILD en pause, l’effacement des overrides LIVE transitoires et le seed RESTART appliqué seulement au Reset; `sandbox_preset_smoke.gd` vérifie le rejet transactionnel d’un preset/build invalide; `sandbox_snapshot_smoke.gd` vérifie le refus d’un snapshot invalide sans mutation. Les valeurs Sandbox restent des outils d’essai, pas des paramètres de balance validés.
- [x] Le maximum de cinq niveaux suit le contrat du GDD; les builds et spawns gardent leurs bornes de contenu explicites (64 armes/128 reliques dans le schéma, 5 slots par famille en session, 500 ennemis par commande, 2 500 entités simultanées). Aucun niveau >5 n’est ajouté au combat.

## P8.3 — Validation des champs importés/partagés (2026-10-16)

- [x] `sandbox_preset_smoke.gd` confirme que le code partagé ne sérialise que les champs publics du schéma v1 et rejette récursivement des champs `script`, `command`, chemin système, secret, identifiant et données de profil dans `overrides`, avant validation ou export.
- [x] Le même smoke vérifie que les IDs de preset ne peuvent pas sortir de `user://sandbox/presets`, que les champs inconnus au niveau racine sont rejetés, et qu’un preset/une construction invalide ne remplace pas le build Sandbox actif. Revalidé sous Godot 4.7.2; `sandbox_lab_smoke.gd` passe aussi avec preset et store.
- [ ] Les textes name/description sont libres et saisis par l'utilisateur; ils ne sont pas inspectés pour une éventuelle information que l'utilisateur y mettrait lui-même. Aucun service ne collecte ou n'injecte des données de profil dans ces champs.

## P8.7 — Limite de lecture des presets stockés — 2026-10-17

- [x] `sandbox_preset_store.gd` vérifie la taille du fichier avant `get_as_text()`. `sandbox_preset_smoke.gd` écrit un preset local dépassant `MAX_JSON_BYTES`, vérifie le rejet `too_large`, puis confirme que l’index des presets valides l’ignore.
- [x] Les smokes `sandbox_preset_smoke.gd` et `sandbox_lab_smoke.gd` passent sous Godot 4.7.2 avec `XDG_DATA_HOME` séparés; le second confirme la session isolée, le reset et la préservation des saves normales.

## Compilation MSVC du benchmark natif — 2026-10-16

- [x] Le premier workflow Windows a atteint la compilation GDExtension, mais le build complet échouait sur `native/benchmarks/simulation_benchmark.cpp` : MSVC ne définit pas `__VERSION__`.
- [x] Le benchmark affiche désormais `_MSC_FULL_VER` sous MSVC, `__VERSION__` sous GCC/Clang et une valeur de repli ailleurs.
- [x] Vérifié localement avec `c++ -std=c++23 -Wall -Wextra -Wpedantic -I native/include -fsyntax-only native/benchmarks/simulation_benchmark.cpp`, puis avec `_MSC_VER` et `_MSC_FULL_VER` définis pour compiler la branche MSVC.
- [ ] Le workflow Windows relancé après cette correction doit encore confirmer la compilation MSVC, l’export et le démarrage de l’exécutable.

## P7A — Records locaux Armorless — 2026-10-16

- [x] `armorless_records_smoke.gd` vérifie la migration additive v7→v9, les records séparés par difficulté, l’ordre vague > temps de survie > kills et les récompenses Armorless idempotentes au-delà de la vague 24.
- [x] Endless standard prototype **[PROPOSÉ]** : `endless_standard_progression_smoke.gd` vérifie migration v8→v9, déblocage Survival, records et récompenses idempotentes sans équipement; `survival_hub_smoke.gd` vérifie verrouillage, lancement avec difficulté/progression choisies et affichage du record; `endless_standard_session_smoke.gd` couvre abandon/mort, résultat et persistance sans nouvel équipement.
- [x] P7B continuation **[PROPOSÉE]** : après victoire Survival, l’écran propose de terminer ou de continuer; le prototype crédite la victoire, démarre une run Endless distincte à la vague 25, garde HP/build/niveaux et libère le focus de l’écran de résultat. `endless_standard_session_smoke.gd` vérifie la continuation, les deux IDs de récompense, le record Endless et l’absence de seconde pièce d’équipement. Les HP Endless croissent de 5,5 % par vague après 24 **[PROPOSÉ]**. CTest complet : 95/95 réussis sous Godot 4.7.2.
- [x] La décision **[VALIDÉE]** accorde Essence, Basic Powder et achievements, sans équipement permanent. Le smoke confirme qu’une run Easy vague 30 ajoute 53 Essence et 77 Basic Powder selon la formule **[PROPOSÉE]**, compte les achievements de run, ne crédite aucun achievement d’équipement permanent et ne récompense pas deux fois le même run_id.
- [x] Le résultat présente ressources, paliers d’achievement et record personnel dans des lignes séparées, sans équipement Armorless; `run_result_panel_smoke.gd` vérifie le rendu.
- [x] `survival_hub_smoke.gd` vérifie que le hub affiche le record de la difficulté sélectionnée après rechargement du profil; `survival_hub_layout_smoke.gd` mesure le texte et vérifie les bornes à 640×360, 1280×720 et 1920×1080.
- [x] La vue `RECORDS` affiche les cinq records locaux en lecture seule; le smoke vérifie le résultat stocké, l’état vide, la fermeture à la manette et la restauration du focus. La géométrie du modal passe aux trois viewports.
- [x] Les sept tests ciblés progression/migration/Sandbox/Armorless passent sous CTest.
- [ ] Suite complète au 2026-10-16 : 69/84 passent. Dix scénarios d’armes Sandbox échouent à compiler la session car `Sfx` est absent de leur contexte de script; les autres échecs observés sont `combat_catalog_smoke`, `survival_starting_weapon_smoke`, `survival_unique_effects_smoke`, `free_chest_reroll_smoke` et `sandbox_steering_scenario`.
- [ ] Une session Armorless complète en durée de production reste à valider.
- [x] Le 2026-10-16, six smokes Armorless passent via `tools/run_godot_test.sh` : état temporaire, générateur, directeur jusqu’à cinq cycles boss/vague 60, application/isolation de progression, session de douze drafts avec boss 12, et records/idempotence. Cette intégration courte ne remplace pas une session complète de production.
- [x] `armorless_session_cycle_smoke.gd` compare les empreintes SHA-256 des fichiers de sauvegarde normale avant/après; les profils déjà présents ne provoquent plus de faux échec et toute création/modification de fichier est détectée.
- [x] Vérifications ciblées après ajout des récompenses Armorless : `armorless_records_smoke.gd`, `survival_armorless_mode_smoke.gd`, `run_result_panel_smoke.gd`, `progression_service_smoke.gd`, `survival_difficulty_unlock_smoke.gd` et `survival_run_result_smoke.gd` passent sous Godot 4.7.2. Les avertissements ObjectDB de fermeture sur certains smokes de résultat sont présents sans échec d’assertion.

## P5 — Régression intégration combat — 2026-10-16

- [x] Douze smokes ciblés passent sous Godot 4.7.2 via `tools/run_godot_test.sh` : catalogue d’armes, coffres, directeur de drops, élites, Buffer, Shielder, Summoner, Exploder, attaques de boss, loot du boss final, causalité des dégâts et difficulté de session.
- [x] Certains smokes de session terminent avec des avertissements ObjectDB/ressources encore référencées; leurs assertions passent. Ces sorties ne prouvent pas l’absence de fuite mémoire en session longue.
- [ ] Cette validation automatisée ne remplace pas P5.V3 : une victoire en interface réelle, sans HP forcés, sélection automatique ni boss tué par script, reste à réaliser.

## P5 — Confirmation de validation manuelle — 2026-10-17

- [x] Le créateur confirme avoir déjà effectué les vérifications manuelles demandées et que tout est bon. Cette confirmation couvre le parcours manuel du catalogue Sandbox demandé pour P5.V4 ainsi que la run de bout en bout, le choix manuel d’un coffre et la persistance sans doublon; aucun détail par arme, build, difficulté ou plateforme n’a été fourni.
- [ ] Le profilage représentatif CPU/GPU et des armes reste à réaliser avec des mesures reproductibles; la confirmation manuelle ne le remplace pas.

## P5.V4 — Revue et checkpoint — 2026-10-17

- [x] Revue des références GDD/ADR/architecture et de l’état P5 : catalogue, règles de coffres, réactions, ennemis/boss et parcours Sandbox sont couverts par les smokes ciblés consignés ci-dessus; les statuts **[PROPOSÉ]** des valeurs de combat restent inchangés.
- [x] Depuis le checkout courant, `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1` passe **112/112 tests en 76,25 s** sous Godot 4.7.2, dont Sandbox, Survival, les dix scénarios d’armes, progression, Armorless et Endless standard.
- [i] Ce checkpoint valide l’intégration et non l’équilibrage. Restent au registre P9 les runs représentatives, l’équilibrage Chaos, la complétion Armorless sans assistance et le profilage sur iGPU cible.

## P5 — Comparaison contrôlée des armes — 2026-10-17

- [x] `combat_weapon_balance_survey.gd` exécute les dix armes dans trois configurations chacune via `SurvivalSession`: niveau 1, niveau 5 avec relique niveau 5 sans évolution, et build évolué. Les 30 scénarios de chacune des trois formations (cibles groupées, cible unique, huit Chasers mobiles) passent sur 18 secondes simulées; les commandes reproductibles et DPS observés sont consignés dans `PERFORMANCE.md`.
- [x] Le survey confirme 21 volleys Crimson par scénario de 18 s et 174/314/585 collisions selon le build dans la formation d’approche; cible fixe et vague mobile produisent des résultats très différents. Cela illustre la limite des cibles immobiles, sans conclure sur l’équilibre global.
- [ ] Ces formations synthétiques omettent mouvement du joueur, autres archétypes, drops et choix de niveau; elles ne ferment pas le calibrage sur runs représentatives ni le profilage GPU sur matériel de référence.

## P5/P6 — Revalidation coffre et effets uniques — 2026-10-16

- [x] `free_chest_reroll_smoke.gd` et `survival_unique_effects_smoke.gd` passent sous Godot 4.7.2 après avoir donné à leurs profils fixtures les déblocages qu'ils utilisent réellement.
- [x] Le reroll gratuit n'est proposé que si le pool contient assez d'offres inédites pour remplacer tout le choix en cours; le test vérifie le reroll clavier avec trois choix inédits.
- [x] Après correction du test d'ordre aléatoire et des fixtures de coffre/capacité, les 19 smokes P5 sélectionnés plus l'import Godot passent ensemble (20/20).
- [x] Revalidation de tous les tests CTest hors scénarios `sandbox_*` : 64/64 passent en séquentiel sous Godot 4.7.2, incluant combat natif, Survival, contenu P5, progression, Armorless et interfaces.
- [x] `sandbox_steering_scenario` passe après mise à jour de sa position attendue : la hitbox ennemie est maintenant alignée à 12 unités de rayon et la séparation des corps écarte les deux chasers de 24 unités au total.
- [x] Le runner d'armes charge désormais la scène Survival après l'initialisation du projet au lieu de la précharger depuis son script SceneTree; les dix scénarios Sandbox d'armes passent.
- [x] `survival_weapon_smoke.gd` verrouille les PV de son fixture pour mesurer le soin sur élimination sans le confondre avec le HP decay accéléré; vingt répétitions directes passent.
- [x] Suite CTest complète : 86/86 passent en séquentiel sous Godot 4.7.2 après ces corrections. Le run précédent (72/86 avant corrections) reste l'historique de la régression trouvée.
- [ ] La victoire P5.V3 en run réelle, sans assistance, reste à réaliser.

## P5 — Revalidation ciblée native et boss — 2026-10-16

- [x] Les exécutables natifs existants `build/simulation_core_tests` et `build/simulation_worker_tests` terminent avec code 0.
- [x] Sous Godot 4.7.2 headless, `survival_weapon_catalog_smoke.gd` et `survival_boss_attack_smoke.gd` terminent avec code 0.
- [ ] Les deux smokes émettent encore des avertissements ObjectDB/ressources à la fermeture; la sortie détaillée du smoke boss identifie `boss_telegraph.wav` et ses `AudioStreamPlaybackWAV` encore référencés. La gestion SFX est suivie séparément; cette vérification ne démontre pas une fuite en session de production.
- [ ] Ces smokes ciblés ne ferment pas l’équilibrage du combat ni P5.V3.

## P5 — Coexistence Burn/Poison et Toxic Ignition — 2026-10-16

- [x] `native/tests/simulation_core_test.cpp` couvre Burn et Poison actifs simultanément sur une cible, leurs ticks sur horloges indépendantes, leur conservation lors de la capture/restauration, et l’observation du Poison préexistant par un impact direct Inferno qui ajoute Burn.
- [x] Le même test natif applique maintenant un projectile Toxic Ignition avec dégâts de zone à une cible portant déjà Burn et Poison; il confirme les dégâts sur une cible voisine et la conservation des deux effets sur la cible déclencheuse après l’explosion. `simulation_core_tests` recompilé et exécuté avec code 0.
- [x] `survival_weapon_catalog_smoke.gd` passe sous Godot 4.7.2 : Toxic Ignition part d’un impact direct appliquant le second statut, inflige 50 % du coup dans le rayon configuré, respecte le cooldown par cible, ignore les ticks DoT et rejette un budget épuisé. L’explosion porte l’ID de l’impact déclencheur et un budget de zéro; `simulation_core_test` vérifie ces champs après capture/restauration du projectile natif.
- [x] Build CMake complet et suite CTest séquentielle : 86/86 tests passent après l’ajout du budget de chaîne et le format snapshot 15. Les bibliothèques manquantes du CMake portable ont été extraites dans `/tmp` pour ce run; aucune dépendance du dépôt ni installation système n’a été modifiée.
- [x] Le smoke ajoute un chemin intégré réel : Toxic Cloud applique Poison par projectile natif, Inferno applique Burn par projectile natif, puis l’événement Survival déclenche l’explosion. Une cible à 40 px reçoit le blast de 10 dégâts, une autre à 70 px reste intacte, et la cible déclencheuse conserve Burn et Poison. Trois exécutions headless isolées passent.
- [ ] La victoire P5.V3 sans assistance et l’équilibrage de Toxic Ignition restent à vérifier en run réelle; les tests automatisés ne les remplacent pas.

## P5 — Stabilité du smoke Frost Nova — 2026-10-16

- [x] Le smoke plaçait ses cibles à 20–30 unités malgré le facteur de portée Survival `180/620`, puis laissait les armes de départ tirer en parallèle du scénario Absolute Zero. Les cibles sont maintenant positionnées par rapport au joueur dans la zone effective et les attaques automatiques sont désactivées après le tir Frost explicite.
- [x] `survival_weapon_catalog_smoke.gd` passe quatre exécutions consécutives avec un `XDG_DATA_HOME` isolé; `survival_loadout_smoke.gd` passe aussi sous Godot 4.7.2.
- [x] Suite CTest complète : `LastTest.log` enregistre 86/86 tests réussis en séquentiel sous Godot 4.7.2, après les modifications présentes dans le worktree. Le fichier `LastTestsFailed.log` était ancien et ne correspondait pas à cette exécution.

## P5 — Bonus de soin par élimination de Blood Chalice — 2026-10-16

- [x] Le bonus de kill healing par niveau de Blood Chalice est centralisé dans `_equipment_kill_healing`, qui est utilisé par les deux chemins de mort (ennemis natifs et Exploder). Les multiplicateurs auparavant appliqués séparément aux appels ont été retirés pour éviter un double bonus.
- [x] `survival_lifesteal_smoke.gd` vérifie les niveaux 1 à 5 et passe après avoir d’abord échoué au niveau 1 sur l’implémentation précédente. Les smokes `survival_run_stat_hub_smoke.gd` et `survival_weapon_catalog_smoke.gd` passent aussi sous Godot 4.7.2.

## P4 — Choix de l’arme de départ — 2026-10-16

- [x] `survival_starting_weapon_smoke.gd` cherchait Inferno Sprayer par index fixe alors que les deux offres de départ sont mélangées. Le test sélectionne maintenant l’offre par son titre affiché.
- [x] Le smoke passe cinq exécutions consécutives sous Godot 4.7.2 headless, en vérifiant la pause avant sélection puis la reprise de simulation, du temps actif et du HP decay après choix.
- [ ] Le smoke conserve un avertissement de ressource à la fermeture; cela n’affecte pas ses assertions fonctionnelles.

## P8.2 — Override typé des PV ennemis Sandbox — 2026-10-17

- [x] `sandbox_preset_smoke.gd` vérifie l’acceptation de `enemy_hp` valide et le rejet des autres clés d’override et d’un multiplicateur au-delà de 1000.
- [x] `sandbox_lab_smoke.gd` vérifie le contrôle et la sauvegarde du multiplicateur 2, puis importe un preset à ×3 et confirme que Spawn produit un Chaser à 60 PV via la commande native (20 PV de base ×3).
- [x] Le smoke Lab vérifie ×2 sur les nouveaux Chasers (75 → 150 px/s) puis l’import d’un preset à ×3 (75 → 225 px/s); le scénario de profils vérifie ×2 sur un Elite Hasted (100 → 200 px/s). Les smokes preset, scénario et natif rejettent les valeurs sous ×0,1 et au-dessus de ×10.
- [x] `sandbox_lab_smoke.gd` vérifie la taille de lot Spawn par défaut (10), une commande personnalisée de trois ennemis, son export/import par preset et les limites de 500 par commande et 2 500 entités; `sandbox_preset_smoke.gd` refuse les nombres fractionnaires et au-dessus de 500.
- [x] `sandbox_lab_smoke.gd` vérifie le contrôle LIVE du decay HP, son facteur dans le calcul de perte, le preset, et l’absence d’effet quand les diagnostics Sandbox sont désactivés; `sandbox_preset_smoke.gd` vérifie les bornes 0–10. `sandbox_snapshot_smoke.gd` vérifie capture, restauration et synchronisation UI.
- [x] Le même smoke change le type Spawn à Sprinter, sauvegarde puis importe ce choix; il vérifie aussi l’affixe Volatile sur un Elite importé (PV, vitesse, rayon/dégâts d’explosion). Presets avec type ou affixe hors roster rejetés. `sandbox_snapshot_smoke.gd` restaure Elite/Volatile après modification en Tank/Hasted et confirme le spawn suivant.
- [x] Le même smoke vérifie qu’un changement de dégâts de contact met à jour la session Lab et le preset; `sandbox_preset_smoke.gd` vérifie le chargement de cette valeur et le rejet d’une valeur négative.
- [x] `sandbox_snapshot_smoke.gd` capture un dégât de contact à 3, une vitesse ennemie à ×2, un lot Spawn de trois ennemis et le profil Sprinter, les modifie puis confirme que la restauration rétablit les contrôles/preset; le lot suivant reprend les réglages et les rejets de snapshot invalide laissent les quatre entités intactes.
- [x] `sandbox_lab_smoke.gd` vérifie que la seed modifiée reste en attente jusqu’au Reset, que la capture de snapshot est refusée pendant ce délai et que le Reset relance l’RNG à la nouvelle seed; le preset sauvegardé conserve cette seed.
- [x] `sandbox_preset_smoke.gd` accepte `mid_boss` et `final_boss` comme profils Spawn; `sandbox_lab_smoke.gd` sélectionne et crée chaque boss individuellement avec le multiplicateur de PV configuré, puis vérifie que Reset les retire. Le profil boss et la limite d’un seul boss sont conservés dans le contexte/preset du Lab.
- [x] `sandbox_snapshot_smoke.gd` capture un preset avec `final_boss`, le modifie, restaure le checkpoint et vérifie le preset ainsi que le sélecteur ennemi restaurés.
- [x] Le contrôle LIVE est intégré aux presets sauvegardés/partagés; il ne retouche pas les entités existantes et n’est pas transmis à Survival normal. Les bornes sont des limites techniques du Sandbox, pas des valeurs de balance validées.

## P8.5 — Commande Restore HP Sandbox — 2026-10-17

- [x] `sandbox_lab_smoke.gd` réduit les PV, conserve un bouclier de 4,5, déclenche `RESTORE HP` en pause et vérifie les PV max, le bouclier inchangé et le temps de simulation identique.
- [x] Le contrôle agit sur `SandboxLabContext.session` uniquement; une session terminée doit être redémarrée.
- [ ] Le comportement est un prototype associé à une commande **[PROPOSÉE]** du GDD, pas une décision de design promue.

## P5 — Fixture Thermal Shock et checkpoint complet — 2026-10-17

- [x] Après un échec de `survival_weapon_catalog_smoke.gd` dans CTest, le smoke a été répété jusqu’à reproduire l’échec : le hit Burn→Chill manquait alors que Chill→Burn passait. Le fixture espaçait ses cibles de seulement 20 px et laissait les armes automatiques actives; ces conditions rendaient les collisions dépendantes du mouvement.
- [x] Les deux cibles sont maintenant séparées, les armes automatiques désactivées, et les diagnostics d’échec affichent séquences/hits observés. Le smoke catalogue passe 10 fois de suite.
- [x] CTest séquentiel complet sous Godot 4.7.2 : **87/87 tests passent en 61,40 s**, incluant le smoke catalogue, le Sandbox Lab, les snapshots, les scénarios des dix armes et le rendu sous Xvfb.
- [ ] Le checkpoint est exécuté sur l’hôte Linux actuel; il ne remplace pas le profilage GPU de référence ou les parcours humains de P5/P6/P7.

## P7A — Survey Armorless sans invulnérabilité — 2026-10-17

- [x] `armorless_natural_run_survey.gd` démarre Armorless Easy avec l’arme de départ normale, spawns et dégâts de contact actifs, PV non verrouillés, sans kills scriptés; un kite simple pilote le joueur et le harness auto-sélectionne le premier draft. Le seed règle le RNG de vague, du loadout, de l’état Armorless et du générateur d’équipement. Le script vérifie aussi l’absence d’écriture dans `user://saves`.
- [x] Trois essais accélérés ×4 (Engine et simulation) : seed 20261017, défaite vague 2 à 51,54 s actives, 14 kills, niveau 3; seed 20261018, défaite vague 2 à 50,75 s, 6 kills, niveau 2; seed 20261019, défaite vague 4 à 108,21 s, 46 kills, niveau 2. Ces mesures ont été écartées du relevé à vitesse réelle, car le contrôleur frame-driven réagit différemment sous fast-forward.
- [x] Deux essais à vitesse réelle du seed 20261017 : défaite vague 2 à 50,29 s actives (20 kills, niveau 3), puis défaite vague 1 à 23,96 s (7 kills, niveau 2). Malgré RNG de gameplay et de drafts seedés, le pilotage synthétique via Input dépend du cadencement de frames; les résultats ne sont pas statistiquement reproductibles et ne représentent pas un parcours humain. Aucun paramètre **[PROPOSÉ]** n’est modifié.
- [x] Revalidation sur le checkout courant, seed 20261018 à vitesse réelle (Engine et simulation ×1) : défaite vague 2 à 49,50 s actives, 9 kills, niveau 3, 11 920 unités parcourues; le script confirme que `user://saves` n’a pas changé. Le seed qui avait donné une autre issue sous fast-forward varie donc aussi avec le cadencement réel. Godot signale 2 instances ObjectDB et 1 ressource encore référencées à la fermeture.
- [x] Nouvelle répétition sur ce checkout, seed 20261017 à vitesse réelle sous Xvfb/Mesa : défaite vague 2 à 59,32 s actives, 9 kills, niveau 3, 0/100 HP et 14 271,9 unités parcourues; le script confirme à nouveau que `user://saves` n’a pas changé. Les deux passages du même seed produisent encore des trajectoires et résultats différents; cela confirme le caractère exploratoire du bot et ne calibre pas le mode.
- [x] Ajouter `--movement=stationary` au survey pour comparer le kite à un repère immobile sans modifier le défaut kite. Au seed 20261018, le parcours immobile meurt vague 1 après 11,73 s (7 kills, niveau 3); le kite meurt vague 2 après 43,91 s (5 kills, niveau 1). Une exécution kite précédente du même seed a donné 33,56 s et zéro kill. Les trois parcours terminent sans écrire `user://saves`; les valeurs divergent avec le cadencement et le choix auto des drafts n’est pas une décision humaine. Aucune valeur de combat **[PROPOSÉE]** n’est modifiée.
- [x] Nouvelle exécution à vitesse réelle, seed `20261020`, avec PV ordinaires, draft auto-choisi, sans kill scripté ni service de progression : défaite vague 2 après 54,44 s actives, 10 kills, niveau 3 et 13 103,9 unités parcourues. Le contrôle du survey ne détecte aucune écriture dans `user://saves`.
- [x] Recontrôle le 2026-10-17, seed `20261018`, mêmes conditions à vitesse réelle : défaite vague 1 après 23,89 s actives, 3 kills, niveau 2 et 5 772 unités parcourues. Aucun changement de `user://saves` détecté. La divergence par rapport aux essais précédents confirme que le bot à entrées frame-driven n’est pas une base de calibration.
- [i] Comme les essais précédents, ce kite synthétique meurt avant le premier boss et ne remplace pas une run humaine complète; aucun paramètre **[PROPOSÉ]** n’est modifié.
- [ ] Ces runs meurent avant le premier boss de vague 12; la session complète Armorless de production reste à valider manuellement, avec ses décisions de draft et sans assistance.


## P8.1/P8.3 — Sélecteur de mode Sandbox Lab — 2026-10-17

- [x] `sandbox_lab_smoke.gd` vérifie le sélecteur clavier/manette (OptionButton focusable), ses trois options exécutables, le défaut Survival, la sérialisation des modes et l’application à la session isolée.
- [x] `sandbox_preset_smoke.gd` vérifie que Endless standard s’exécute dans `SandboxLabContext` avec PV verrouillés, sans `ProgressionService`/`SaveService` normaux; les règles de P7B restent **[PROPOSÉES]**.
- [x] `sandbox_lab_smoke.gd` passe sous Godot 4.7.2 headless.

## P9.4 — Parcours clavier et manette synthétique — 2026-10-17

- [x] `survival_hub_smoke.gd` envoie Entrée sur Équipements puis Arbre de compétences, et Échap pour les fermer; chaque fermeture doit rendre le focus à son bouton d’origine. Le smoke dédié passe sous Godot 4.7.2 headless.
- [x] `keyboard_menu_journey_smoke.gd` parcourt avec de vrais événements clavier synthétiques l’accueil, Options, le hub, le choix de l’arme de départ, un coffre d’arme, Pause, Options depuis Pause, l’inventaire de run et la reprise. Il vérifie le focus des contrôles clés, l’objet choisi, l’état de pause et l’horloge immobile pendant Options; la run n’est pas terminée et les données utilisateur sont isolées par `XDG_DATA_HOME` dans CTest.
- [x] Le même parcours au D-pad/A/B synthétiques vérifie que le style de focus non vide et bordé est présent sur le choix d’arme et du coffre. CTest lance séparément clavier et manette simulée, chacun avec son `XDG_DATA_HOME` dédié; aucun périphérique physique n’est utilisé.
- [x] Les deux vérifications ciblées passent sous Godot 4.7.2 headless. Des instances ObjectDB/ressources restent signalées à l’arrêt des sessions, comme dans des smokes Survival existants; aucune assertion n’échoue.
- [x] Suite complète après ajout des deux parcours et de leur isolement CTest : **97/97 tests passent en 66,36 s en séquentiel** sous Godot 4.7.2 et CMake 3.31.12.

## P9.4 — Contraste des contrôles inactifs — 2026-10-17

- [x] Un contrôle de contraste ajouté à `survival_hub_smoke.gd` a d’abord échoué sur les couleurs précédentes : le texte `InactiveButton` (#64708C) mesurait 3,11:1 et le texte des `Button`/`OptionButton` désactivés (#586381) 2,58:1, sur leur fond #1B2340.
- [x] Les trois variations utilisent maintenant #A5AEC3, couleur secondaire validée dans `docs/ART_BIBLE.txt`; le ratio mesuré est 6,94:1. Le test calcule le ratio de luminance pour les trois variations et exige au moins 4,5:1. Le smoke passe sous Godot 4.7.2; la capture `/tmp/dopamine-survival-hub.png` a été inspectée à 640×360 logique sous Xvfb/Mesa llvmpipe.
- [x] CTest complet après le changement partagé de Theme : **91/91 tests passent en 64,76 s** avec `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`.
- [ ] Ce contrôle couvre seulement les trois variations citées; le contraste des autres composants, la hiérarchie HUD, les options de réduction des effets et les écrans sur matériel réel restent à vérifier.

## P9.4 — Contraste des libellés du HUD Survival — 2026-10-17

- [x] `survival_hud_smoke.gd` calcule le contraste des six libellés de santé, XP, équipement, temps, vague et difficulté contre le fond `CompactPanel` et exige un ratio minimal de 4,5:1.
- [x] Le même smoke compose ces panneaux sur quatre fonds de scène de la palette ART_BIBLE (ombre, rouge, cyan, jaune) et exige 4,5:1 pour chaque libellé, y compris le badge d’état. Le contraste est calculé à partir des couleurs et de l’alpha du panneau; ce n’est pas une mesure par capture de chaque scène complète.
- [x] Le smoke passe directement sous Godot 4.7.2 headless avec un `XDG_DATA_HOME` isolé.
- [i] La couverture de fonds s’appuie sur la composition des couleurs de la palette, pas sur chaque arrière-plan de gameplay rendu. La taille perçue des textes, la hiérarchie, et le rendu sur écran/GPU réel restent à vérifier.

## P9.7 — Validation Windows Debug et run Easy complète — 2026-10-17

- [x] Le rapport fourni depuis le clone Windows montre la configuration CMake/MSVC x64, la compilation de `libdopamine.windows.template_debug.x86_64.dll` et des exécutables natifs, puis **108/108 tests CTest réussis en séquentiel** sous Godot 4.7.2.
- [x] Le CSV versionné [`data/windows_survival_profile.csv`](data/windows_survival_profile.csv) contient 802 secondes d’échantillons, une run Easy jusqu’à la victoire Survival puis le début d’Endless. Cette capture confirme l’exécution de la GDExtension dans une vraie session de jeu.
- [i] Le journal de la première tentative de capture mentionne aussi des ressources importées manquantes et une erreur de script pendant l’initialisation; la capture finale existe néanmoins et couvre une session complète. Ce rapport ne documente pas un build Release ni une exportation Windows autonome.
- [ ] Checkout propre, export Release, extraction et lancement Windows restent à vérifier. Le parcours avec périphérique physique et les réglages de rendu sur matériel restent ouverts.

## P5.1.5 — Homing léger Magnetic Coil — 2026-10-17

- [x] Le test natif `simulation_core_test.cpp` vérifie la correction d’angle bornée par le temps simulé, la conservation de vitesse et la sauvegarde/restauration du projectile; il échouait avant l’ajout des champs de homing.
- [x] `survival_weapon_catalog_smoke.gd` confirme que Magnetic Coil niveau 4 ne configure aucun homing, que le niveau 5 le configure sur Sawblades/Razorstorm, et que le rayon transmis respecte le plafond de ciblage visible.
- [x] Build Debug de la GDExtension et CTest séquentiel complet : **92/92 tests passent en 62,79 s** avec `PATH=/tmp/cmake-3.31.12-linux-x86_64/bin:$PATH cmake --build build --parallel 4 && PATH=/tmp/cmake-3.31.12-linux-x86_64/bin:$PATH ctest --test-dir build --output-on-failure -j1`.
- [i] Le smoke catalogue isolé affiche à la fermeture 2 instances ObjectDB et une ressource encore référencées; CTest demeure vert. La vitesse angulaire proposée (1 rad/s) et son rayon de recherche ne sont pas calibrés en run représentative.

## P5.1.13 — Synergies Magnet Heart — 2026-10-17

- [x] `survival_magnet_heart_synergy_smoke.gd` vérifie que chaque effet attend le niveau 5 des deux reliques; Magnetic Coil accroît la vitesse maximale du pulse, Celestial Eye en étend le rayon, et Singularity déplace les orbes XP vers Event Horizon pendant qu’un Void Orb distant est actif. Le smoke confirme la découverte des deux types de champ.
- [x] Les orbes XP restent hors de l’attraction native Void Orb sans la synergie Magnet Heart + Singularity; un test cœur natif conserve cette séparation. Les coffres restent exclus de toute attraction.
- [x] Revalidation ciblée le 2026-10-17 : import Godot, `survival_magnet_heart_synergy_smoke` et `survival_chest_smoke` passent sous CTest (**3/3**).
- [x] Les trois synergies et leurs paramètres sont **[VALIDÉS, 2026-10-17]** : reliques niveau 5 pendant le pulse, Coil ×1,5 vitesse max, Singularity attire l’XP vers le champ Void Orb/Event Horizon, Celestial Eye ×1,5 rayon.
- [i] Décision utilisateur **[VALIDÉE, 2026-10-17]** : définir l’interaction Magnet Heart dans le contrat de chaque pickup futur. Aucun n’existe actuellement; leur ajout et leur comportement restent conditionnels et ne sont pas inférés depuis Magnet Heart.

## P5 — Décisions Thermal Shock et Magnet Heart — 2026-10-17

- [x] Le créateur valide Thermal Shock : coup direct Burn↔Chill, impact supplémentaire égal à 50 % des dégâts déclencheurs, cooldown local d’une seconde par cible; DoT et impacts de réaction exclus du chaînage.
- [x] Le créateur valide Magnet Heart dans le périmètre des pickups existants : +25 % de rayon XP par niveau; Magnetic Pulse niveau 5 toutes les 20 s pendant 1,5 s dans 300 % du rayon, accélération 600 et vitesse max 240; collecte dans le rayon XP normal; pause figée; coffres exclus. Les trois synergies sont validées au niveau 5 pendant le pulse, avec les paramètres consignés ci-dessus.
- [i] Les anciennes runs exploratoires Thermal Shock ne calibrent pas ces décisions. L’attraction des soins, ressources, monnaies et bonus temporaires reste hors périmètre jusqu’à la définition de ces pickups.

## P7A — Courbe de PV Armorless conforme au prototype GDD — 2026-10-17

- [x] `armorless_wave_director_smoke.gd` échouait avant correction car le calcul partageait la courbe Survival ×1,12 plafonnée à ×12. Le test vérifie désormais le facteur GDD aux vagues 24, 25 et 60 : `1,10^(w−1)` jusqu’à 24, puis `1,10^23 × 1,055^(w−24)`.
- [x] Smoke Armorless, smoke des multiplicateurs Survival et smoke de session Endless standard passent sous Godot 4.7.2; les deux autres modes gardent leurs courbes respectives. Le smoke Endless affiche au shutdown 2 instances ObjectDB et 1 ressource référencées, sans assertion échouée.
- [x] CTest complet après la correction : **112/112 passent en séquentiel en 74,59 s** avec `/tmp/cmake-3.31.12-linux-x86_64/bin/ctest --test-dir build --output-on-failure -j1`, incluant l’ensemble Sandbox, progression et scénarios Survival.
- [i] Cette correction aligne le prototype sur la formule **[PROPOSÉE]** du GDD; elle ne valide pas ses coefficients ni l’équilibrage de longue durée.

## P7B — Directeur Endless standard — 2026-10-17

- [x] `survival_wave_director_smoke.gd` vérifie le prototype **[PROPOSÉ]** : après la vague 24, les cycles continuent sans victoire et un mid-boss revient aux vagues 24 et 36.
- [i] Cette preuve ne couvre que le directeur et sa cadence de boss. Les parcours de lancement, continuation, mort/abandon, récompenses, records et persistance sont couverts par `endless_standard_progression_smoke.gd`, `endless_standard_session_smoke.gd` et les contrôles du hub consignés dans la section de validation P7B ci-dessus. Les règles et valeurs de scaling restent **[PROPOSÉES]**; les mesures de run représentatives restent à faire.

## P9.8 — Staging Linux Release depuis `adefcc9` — 2026-10-17

- [x] `tools/package_linux_staging.sh` a reconstruit un checkout Git archivé du commit `adefcc9e55fadef0fb3fdd3b4e2b7420918416ad` avec CMake 3.31.12, GCC 14.2.0, Godot 4.7.2 et `godot-cpp` verrouillé. La compilation Release native, l’import propre, l’export Linux/X11 filtré, l’extraction, la présence des exécutables/notices/licences, l’absence de ressources de développement, la résolution des bibliothèques et le lancement headless de l’exécutable avec la GDExtension Release adjacente passent.
- [x] Archive : `DopamineSurvivor-linux-adefcc9-staging.tar.gz`, 31 979 129 octets, SHA-256 `b57429acb8e802711714093298fd2f8e12244bc21dd5b4f529a10e25c9f899a9`; manifeste SHA-256 généré à côté dans `build/linux/staging/`.
- [i] Staging Linux x86_64 non versionné et non distribuable; aucune version de jeu n’est assignée. Cette preuve ne couvre ni installation machine distincte, GPU physique, sauvegardes interactives, provenance complète des assets/audio, Windows, autres plateformes ni notes de version.

## P9.8 — Staging Linux Release depuis `65ed8d0` — 2026-10-17

- [x] `tools/package_linux_staging.sh` a reconstruit un checkout Git archivé du commit `65ed8d0`, avec CMake 3.31.12, GCC 14.2.0, Godot 4.7.2 et `godot-cpp` verrouillé. Build Release vierge, import/export Linux/X11 filtré, extraction, notices/licences, exclusion des ressources de développement, résolution des bibliothèques et démarrage headless de l’exécutable extrait avec GDExtension Release adjacente passent.
- [x] Archive non distribuable : `DopamineSurvivor-linux-65ed8d0-staging.tar.gz`, SHA-256 `e7a6dd0f9e4947babb6ec20c800a0a213aab9bbce6b193670da2934cc0b6a99d`; manifeste SHA-256 généré à côté dans `build/linux/staging/`.
- [i] Il s’agit d’un staging Linux x86_64 non versionné et non distribuable; cela ne clôt pas les validations d’installation distincte, GPU réel, sauvegardes en usage, autres plateformes ni les gates de release finale.

## P9.7 — Diagnostic Windows CI export — 2026-10-17

- [x] Le run GitHub Actions `39062222551` (source `23c6185`) a compilé les GDExtensions Debug et Release, mais n’a pas produit l’exécutable Windows. Le journal signale aussi des échantillons audio non importés et `CombatSimulation` indisponible dans `sandbox_smoke.gd`; PowerShell a continué, car Godot a retourné le code 0 malgré l’assertion du script. Ce run est en échec et ne valide pas l’export.
- [x] `tools/build_windows.ps1` attend maintenant la fin d’import avec l’option Godot documentée `--import`, capture et affiche les sorties d’import/smoke/export, et traite les erreurs d’import, assertions GDScript et l’absence de `CombatSimulation` comme des échecs même si Godot retourne 0.
- [x] Le run de suivi `39063197171` (source `769a7d7`) a passé les contrôles d’import et le smoke GDExtension; la commande d’export Godot a ensuite retourné 0 sans sortie ni exécutable attendu. Le script utilise désormais un nom d’exécutable sans espace, active les logs détaillés d’export et rapporte le contenu du dossier si Godot retourne encore un succès sans créer le fichier.
- [x] Les runs `39065092341` (`624f8c3`) et `39065384720` (`40b70e5`) passent l’import, le smoke GDExtension et l’export Release. Le lancement de l’exécutable atteint ensuite le contrôle PowerShell mais échoue parce que `$LASTEXITCODE` reste vide pour ce binaire GUI; le message d’échec n’indique alors aucun code numérique. Ces runs ne publient pas d’artefact.
- [x] Le run `39065473294` (`a867f28`) reproduit le même échec au lancement. Le workflow résout maintenant le chemin de l’exécutable et utilise `Start-Process -Wait -PassThru`, en conservant stdout/stderr et en lisant `ExitCode` du processus (`8525832`).
- [x] Le run `39067587437` (commit `858efb6`, [GitHub Actions](https://github.com/SkyDogzz/Dopamine/actions/runs/39067587437)) passe le build Windows x64, l’import/GDExtension Release, l’export, le démarrage headless et les tests natifs; l’artefact `dopamine-survivor-windows-x86_64` a été publié. Archive téléchargée : 74 053 567 octets, SHA-256 `e6bea3e6b19381dd8385cb2980cd59015ddf15d11bad8b45336932675a1f4e70`, conforme au digest GitHub; après extraction, EXE et DLL sont bien des PE32+ x86-64. Cette version du workflow lançait depuis le dossier d’export avant publication.
- [x] Le run `39070143031` (commit `a6c8636`, [GitHub Actions](https://github.com/SkyDogzz/Dopamine/actions/runs/39070143031)) passe le workflow actuel sur `windows-2022` : checkout propre, build MSVC, import/GDExtension Release, export autonome, archive/extraction dans `RUNNER_TEMP`, démarrage headless du jeu extrait sans erreur de chargement, tests natifs et publication de l’artefact. L’API GitHub indique 74 054 098 octets, digest `sha256:5e5984856c34ea29813b5a15c9558e6011d8677c2d3fc222cf29c2ef437f12ec`. Le runner a vérifié le contenu extrait avant publication; aucun téléchargement local de ce nouvel artefact n’a été effectué.
- [x] Les runs `39071499095` (`4333878`) et `39071606317` (`6559be1`) ont aussi passé après des changements de code; leur exécution confirme que le pipeline est resté vert sur ces snapshots. Le run `39072675433` pour la documentation audio est en cours au moment de ce relevé et n’est pas utilisé comme preuve.
- [i] Cette validation automatise le build/export et le démarrage headless; elle ne remplace pas une run interactive Windows au clavier/manette, ni le rendu et l’audio sur matériel physique.
