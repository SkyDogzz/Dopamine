# Preuves visuelles — 2026-10-18

Captures 640×360 générées avec Godot 4.7.2 sous Xvfb/Mesa llvmpipe. Les smokes associés aux parcours ont tous terminé sans échec; ALSA a basculé sur le pilote audio dummy et n’apporte aucune preuve d’écoute.

| Capture | SHA-256 | Revue |
|---|---|---|
| `launch-menu.png` | `15b7e227a6e3e28e16558e7a1d930861b99c26cc01bd4a92dd22156a3a7ef88a` | Composition validée dans l’Art Bible : navigation à gauche, identité à droite. |
| `survival-hub.png` | `900623d972ef6d1943040f081a3ee7e5cbc7357d4a7f40c5e98d034889fed645` | Panneaux et parcours de préparation restent lisibles dans le viewport logique. |
| `skill-tree.png` | `54033cebcd09c16c22c254151d7de2f998db865d0f6b038126bb1369581320c3` | Graphe ramifié à 640×360, intégré au fond réel du hub Survival assombri; nœud sélectionné, détails, boutons élargis et libellés à 9 px visibles. Le contenu, coûts et effets restent **[PROPOSÉS]** ou **[OUVERTS]**. |
| `equipment.png` | `49136c8b371097b35c9a8170db46391e2fccf9937666f5906f6850a1695ca0c9` | Six slots, inventaire équipable, commandes de remplacement et variation avant/après visibles; le cadre Neon suit le focus manette/clavier sur l’anneau équipé. |
| `survival-combat.png` | `e876f54d3b0f7f323b7495cd54368991e210d0da126e5b504aaf21667dbf8b52` | Combat chargé : familles d’ennemis, projectiles, impacts, XP, télégraphe et faisceaux visibles. |
| `catalog-icons.png` | `cf37687d14edcfb90d0c0bbdefa811e2580f20973e302c1fb0e46370968eb37a` | Planche de contrôle pour icônes d’armes, évolutions et reliques; revue des silhouettes en grille. |
| `states/options.png` | `7777bc770de2b71396314d98d19a0a45384e15b91cf8f65de0bd59f531745fe2` | Options générales, audio, accessibilité et focus initial. |
| `states/pause.png` | `8766c97a910850d99fff262e7ec2ced0cd589813776d78f1e578bc81f4d6dd15` | Pause, état figé, vitesse, verrouillage et focus visible sur `RESUME`. |
| `states/pause-confirmation.png` | `5d02d19431ec29d13574f2da5ad69f4e94555413f113696dff48e0a6c8d06283` | Confirmation d’abandon au-dessus de la pause; focus initial sur `KEEP PLAYING`, action de danger séparée. |
| `states/chest.png` | `9a67eecefa823116c8530f6e2d99929291a0d81e4e51bff4a04ee00ce609e958` | Choix d’offres dans le vrai HUD d’une session Survival sans ennemis; les valeurs sont des données temporaires de smoke, pas du contenu validé. |
| `states/run-inventory.png` | `e269ed61c160063d4a92c44c7596cf58b056f9defbca1bdc7305576366b93f8e` | Inventaire en run avec arme et relique d’échantillon. |
| `states/run-result.png` | `27e1197ee4282ebf8866c83dc6c13757d0e5f3620ce92f383fc2914d2a068462` | Résultat de victoire et actions de continuation/relance/retour intégrés au HUD de la session; récompenses synthétiques de smoke. |
| `states/armorless-records.png` | `5fa3a9b21280ddc9aabdf4bbd6a83088ed2ed213900e9c6eabd2dd7b879291c2` | Panneau records Armorless avec une entrée de démonstration. |
| `states/sandbox.png` | `32d998625488d852d33d30993c6b653c56fb853ca5a5c8955564ff5f3addf80f` | Sandbox isolé avec badge `PAUSED / NO SAVE` et cadre de focus visible sur `ACCUEIL`; rendu capturé dans le contexte `main.tscn`. |
| `states/sandbox-lab.png` | `7b1a95d8a44a5eba9d05d287f60e0056f7b1074725946a0723d7f81e79561904` | Sandbox Lab à 640×360 : fond sombre Neon uniforme, simulation et commandes visibles, cadre de focus sur `PAUSE`, configuration accessible par défilement; HUD et caméra de la session masquée isolés. |
| `states/equipment-error.png` | `46afadddfe2520d2183bf29b12f6f6cf295d346082b6d9de80e4ce0d08bce7e2` | Profil équipement illisible affiché au-dessus du vrai hub Survival; actions bloquées et focus sur fermeture. |
| `states/skill-tree-error.png` | `12c89d51f3f76878d721bd8a07856d9dfd8d7d5c1b24ab273a07c6cad559bd26` | Profil d’arbre indisponible au-dessus du vrai hub, actions bloquées et focus visible sur fermeture. |
| `states/starting-loadout.png` | `d496cedb3e5fff0d8577fc4900a48fa9113316fa529dc5e08908bd9995c88da8` | Choix d’arme de départ dans la vraie scène de run Survival; exemple temporaire du Sandbox et focus initial visibles. |
| `states/survival-hud.png` | `ed78943b4797d945231a7ccfcadfddbf84ee49d888f2ee5cf8de4c8f7f06e2cb` | HUD en run avec HP/bouclier, XP, arme, vague, temps, difficulté et badge actif. |
| `states/survival-boss-hud.png` | `f5060fd10d20cf8e6bd34495c8f94d06b7069bcdb0c689cc469889a4eb972fd6` | HUD boss visible sous les panneaux de coin, libellé pixel cyan et barre de vie magenta; état boss simulé dans le smoke. |
| `states/survival-boss-feedback.png` | `43c32b77df8bdca24eaf66918c91ad7ca0cf106b1ea6e31eb5dd792ab00b65a6` | HUD boss et feedback jaune d’acquisition d’objet simultanés, sans chevauchement. |
| `states/revive-confirmation.png` | `f46bc2f92bb709fbfacd79adddd1dfabd05c540a8164aa54212ca45aec9008e6` | Dialogue revive Neon dans le viewport, focus visible sur `REVIVE`, choix de refus distinct; recapturé après contrôle multi-résolution. |
| `states/revive-declined-result.png` | `c2fc27f78b5ed66d72155e1e26dd066e9c36a17f4cabc47b14203806cf90f5a9` | Écran RUN OVER intégré au HUD après refus; la run temporaire est enregistrée et les récompenses/équipement du fixture s’affichent; recapturé par le smoke de revive. |
| `states/run-stat-detail.png` | `ffb25b728ba1449e7f473fd9c5f3168ff7dcce4c05eebf59bcf7901b1f294a77` | Détail Tab des statistiques avec focus sur fermeture, contributions colorées et liste défilante. |
| `states/equipment-no-compatible.png` | `fd1919e19868444f2150f0fa960e92867302a52e350d91cf294ced4214ea5b41` | Inventaire non vide sans pièce compatible avec le slot bottes, capturé au-dessus du hub réel; état vide explicite et aperçu « no change ». |
| `states/equipment-action-failed.png` | `e3bc149c79aec65f604461fc83d5e54c37d4519f8420f0f15f0e15aaef85604b` | L’action ÉQUIPER d’une pièce devenue obsolète échoue via le vrai service; le panneau reste ouvert avec la pièce affichée et une bannière explicite. |
| `states/equipment-details.png` | `4709bfcccc3087ace59b89dc0384ed3c065a730c57baa934ae1ac80ace2ce2c4` | Mode Details à 640×360 : actions d’amélioration, effet unique, vente/démantèlement dans la liste défilante; CLOSE reste fixe et visible. Le smoke vérifie aussi que le scroll vertical est actif et la fenêtre contenue à trois viewports. |
| `states/equipment-sell-confirmation.png` | `0d3e0212a7ca64cc26ce38ca57784d1a7fc6c0cff82d90b6dde0524ae6478146` | Confirmation Neon de vente à 640×360 : montant et irréversibilité visibles, focus initial sur CANCEL; bounds vérifiés aux trois viewports ciblés. Cette capture a permis de remplacer l’ancien dialogue système gris. |

Les captures ont été régénérées après import des exports graphiques renouvelés le 2026-10-18 et inspectées. La planche catalogue, le hub et le combat ont changé de hash; les autres captures sont identiques. La capture du skill tree a ensuite été refaite avec le vrai hub Survival derrière le panneau : l’ancien gris extérieur provenait du viewport par défaut du smoke isolé, alors que le jeu l’intègre sur le fond sombre du hub. L’utilisateur a confirmé que le texte courant et les labels pixel du hub et de l’équipement sont lisibles à 640×360. Ces images valident le rendu virtualisé ciblé, pas le GPU matériel ni les contrôles physiques. La revue audio en contexte reste **[OUVERTE]** à la demande de l’utilisateur de poursuivre sans écoute.

Les onze premières captures `states/*.png` ont été générées par `game/tests/ui_states_evidence_smoke.gd` sous Godot 4.7.2/Xvfb/Mesa llvmpipe. Le coffre et le résultat utilisent les instances déjà montées sous `SurvivalSession/HUD`, avec génération d’ennemis désactivée. Les deux états de profil indisponible sont au-dessus du vrai hub Survival avec un service isolé. `equipment_panel_visual_smoke.gd` capture aussi l’état sans pièce compatible dans le hub réel, sans toucher à la sauvegarde normale. Les autres captures viennent des smokes `survival_entry_smoke.gd`, `survival_hud_smoke.gd`, `survival_revive_smoke.gd` et `survival_run_stat_hub_smoke.gd`; elles couvrent l’échec réel d’une mutation d’équipement dans le hub et la confirmation de vente. Les états de revue utilisent des données temporaires; aucune sauvegarde normale n’est écrite. Ces captures ne couvrent pas toutes les erreurs, branches de focus, tailles ni contrôles physiques.

## Parcours du paquet Linux/X11 Release — build du 2026-10-18

Le paquet de staging actuel provient de l’archive propre du commit `e3d0c4f`: 29 878 849 octets, SHA-256 `0681a9110d9a6510edaefe2e3bedd83f5fed7907338c5921c7d0fc53cb8339f2`. L’exécutable extrait fait 75 119 888 octets (SHA-256 `86f90e2ecda55d351165c8301fc55375610400e2edd4b13f1a1520fee3e79750`); sa GDExtension Release fait 1 140 456 octets (SHA-256 `3f929d4abe737ae8abfafcba3233c80898071866eeeeab7fbbd2b0f66aaecd56`). Avec un `XDG_DATA_HOME` jetable, le paquet suit menu → hub → équipement → arbre de compétences → choix d’arme → combat → pause sous Xvfb/Mesa llvmpipe à 1280×720, via XTest. Les sept captures ont été régénérées et inspectées; le journal ne contient aucun `ERROR:`. Le processus a été arrêté après les captures (`SIGTERM`). Le pilote audio était `Dummy`; aucun contrôleur physique ni sortie audio réelle n’a été essayé.

| Capture | SHA-256 |
|---|---|
| `release-linux/dopamine-release-menu.png` | `23f32cf7c8c68e2a9ae41cc68f3cd4e48bb22bbf7b42568d71f07b5947807bd6` |
| `release-linux/dopamine-release-hub.png` | `859b7d532e0054a17b60ff3e09a9458d0a959bb29b22b937db6ac819c169fc83` |
| `release-linux/dopamine-release-equipment.png` | `dfd45c1f502c2d0846f5dd50e842dae49a725b32a0eb63a4a445481bd664654f` |
| `release-linux/dopamine-release-skill-tree.png` | `54cdac0f93f1b1f183272bff49edd39ef6c42a18f6a55624211cc2371919b19b` |
| `release-linux/dopamine-release-weapon-choice.png` | `bd16460173f70b5417ac121d6987141471e4faaa1efbe37f5b5ce562d5d1413d` |
| `release-linux/dopamine-release-combat.png` | `381e4243a8145a5c31035705d1f2b44d8582f48939c00b09ae608e297ff563d2` |
| `release-linux/dopamine-release-pause-final.png` | `161bae6563bbc8ab9740491681a99b84dfd76d3de51b6d01cffe435f9ad501c6` |

C’est une preuve de lancement relocalisé sur l’hôte Debian courant; pas une installation sur machine distincte ni une validation matérielle.

## Audio

`adaptive-music-transition.wav` est un extrait stéréo de 30 secondes préparé pour écoute humaine. Il rejoue les cinq stems en boucle avec les courbes de gain et les vitesses de fondu du contrôleur runtime, et superpose des SFX de combat représentatifs. Un gain maître unique sert seulement à rendre l’extrait audible; le niveau final en jeu reste **[PROPOSÉ]**. Source reproductible : `python3 game/tools/render_adaptive_audio_preview.py`. SHA-256 : `e6c35273bf80e3a8385b09d83a1715c4c31ae2b003672c94360e789388520766`.

`adaptive-music-runtime-capture.wav` est une capture stéréo PCM16, 44,1 kHz, de 12,26 s prise sur le bus Master par `AudioEffectRecord` dans Godot 4.7.2 avec le pilote Dummy. Elle utilise le véritable autoload `Sfx` et `adaptive_survival_music.gd`; `game/tests/adaptive_survival_music_runtime_capture.gd` inscrit des marqueurs pour vagues 1, 8, 16 et 24, télégraphe et phase boss, pause, reprise et fin de run. SHA-256 : `667ce7238edccb80e69b37fb5c18916753306da985291bad74acc219bde140b3`. Mesures PCM : pic `0.7300` (`-2.73 dBFS`), RMS global `0.07035` (`-23.06 dBFS`), zéro échantillon écrêté. La capture confirme que le moteur produit un signal continu et mesurable aux contextes marqués; ces mesures ne valident ni le niveau perçu, ni le masquage des cues, ni la qualité ou la fluidité audibles. Ce n’est pas une session réelle de combat et le mix/gains restent **[PROPOSÉS]**.

Écoute locale : `ffplay docs/art/evidence/2026-10-18/adaptive-music-transition.wav`. Le 2026-10-18, l’utilisateur a demandé de poursuivre sans retour d’écoute. L’extrait et le mix restent donc **[OUVERTS — non écoutés/approuvés par l’utilisateur]**; cette décision n’est pas une approbation audio.

## Revue des fontes

L’utilisateur a confirmé le 2026-10-18 que le texte courant et les labels pixel des captures `survival-hub.png` et `equipment.png` sont lisibles à taille normale en 640×360. Cela documente la lisibilité de ces deux vues; la direction typographique finale et les tailles sur tous les états restent **[OUVERTES]**.
