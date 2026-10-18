# Preuves visuelles — 2026-10-18

Captures 640×360 générées avec Godot 4.7.2 sous Xvfb/Mesa llvmpipe. Les smokes associés aux parcours ont tous terminé sans échec; ALSA a basculé sur le pilote audio dummy et n’apporte aucune preuve d’écoute.

| Capture | SHA-256 | Revue |
|---|---|---|
| `launch-menu.png` | `ab60b24696238f5c2558287827d610aa2ddd0deab1cb8f8e3ba8d147bc9984d4` | Composition validée dans l’Art Bible : navigation à gauche, identité à droite. |
| `survival-hub.png` | `efa56a85a46fa4e12a5a64c9fc8644c076dd84f03191bab94af81a7570511f15` | Panneaux et parcours de préparation restent lisibles dans le viewport logique. |
| `skill-tree.png` | `f97bef7d87ce0e5ce3fd3805f33824c47b55b84a5523a987f821b2fde91d9042` | Graphe ramifié à 640×360, intégré au fond réel du hub Survival assombri; nœud sélectionné, détails, boutons élargis et libellés à 9 px visibles. Le contenu, coûts et effets restent **[PROPOSÉS]** ou **[OUVERTS]**. |
| `equipment.png` | `fdf7f1367464be670107084e95e347886b31b1357700d9bb2d1d71603cdc29a5` | Six slots, inventaire équipable, commandes de remplacement et variation avant/après visibles; le cadre Neon suit le focus manette/clavier sur l’anneau équipé. |
| `survival-combat.png` | `42a848645e910f5c69a070365279f1d00f76f23fae8f5c6ee2cb0500ebb15239` | Combat chargé : familles d’ennemis, projectiles, impacts, XP, télégraphe et faisceaux visibles. |
| `catalog-icons.png` | `cf37687d14edcfb90d0c0bbdefa811e2580f20973e302c1fb0e46370968eb37a` | Planche de contrôle pour icônes d’armes, évolutions et reliques; revue des silhouettes en grille. |
| `states/options.png` | `3c240b6341e63824130e22832a3f5fd56d64c2fde20d9505e8fce75ab6c5ec37` | Options générales, audio, accessibilité et focus initial. |
| `states/pause.png` | `691217da7f20fc4ed3e12b3adfeddb0cdb3e00a3cc80d6b1bedd2256161f65c6` | Pause, état figé, vitesse, verrouillage et focus visible sur `RESUME`. |
| `states/pause-confirmation.png` | `41af7f0d83eab32b75d28e0e792ed6f8f75446377d4f3caf99cc0679dc76551e` | Confirmation d’abandon au-dessus de la pause; focus initial sur `KEEP PLAYING`, action de danger séparée. |
| `states/chest.png` | `2b00b1173914a331e2883adde411946bfaa7136515e960018d6bcc4011b5f90a` | Choix d’offres dans le vrai HUD d’une session Survival sans ennemis; les valeurs sont des données temporaires de smoke, pas du contenu validé. |
| `states/run-inventory.png` | `c1c83ce62a0b81789969e539bf648f94fc6b87b18da8b20b4c30649b443b4d61` | Inventaire en run avec arme et relique d’échantillon. |
| `states/run-result.png` | `337676fda0d9404fc03637f4e711af700a9b9f0f587f399c1427f3f156ec2012` | Résultat de victoire et actions de continuation/relance/retour intégrés au HUD de la session; récompenses synthétiques de smoke. |
| `states/armorless-records.png` | `5fa3a9b21280ddc9aabdf4bbd6a83088ed2ed213900e9c6eabd2dd7b879291c2` | Panneau records Armorless avec une entrée de démonstration. |
| `states/sandbox.png` | `9d1e1394fd6432eaaa8b312c54a0bacbeacfce8b8f25316329b55601740c67b7` | Sandbox isolé avec badge `PAUSED / NO SAVE` et cadre de focus visible sur `ACCUEIL`; rendu capturé dans le contexte `main.tscn`. |
| `states/sandbox-lab.png` | `7b1a95d8a44a5eba9d05d287f60e0056f7b1074725946a0723d7f81e79561904` | Sandbox Lab à 640×360 : fond sombre Neon uniforme, simulation et commandes visibles, cadre de focus sur `PAUSE`, configuration accessible par défilement; HUD et caméra de la session masquée isolés. |
| `states/equipment-error.png` | `3dea4b4b5eb9e5316a8009a66ab27b96aae5f23452a64b00a31d6bf922c4a5c8` | Profil équipement illisible affiché au-dessus du vrai hub Survival; actions bloquées et focus sur fermeture. |
| `states/skill-tree-error.png` | `8566ae2e4947b6df6f9fb9d342fe9979d04335b7a0121011de8f4961e045c553` | Profil d’arbre indisponible au-dessus du vrai hub, actions bloquées et focus visible sur fermeture. |
| `states/starting-loadout.png` | `d2d6c855ac34d4271114f9eb31bc985f6b94a14e121cc48d8d08f953145f4c5f` | Choix d’arme de départ dans la vraie scène de run Survival; exemple temporaire du Sandbox et focus initial visibles. |
| `states/survival-hud.png` | `ed78943b4797d945231a7ccfcadfddbf84ee49d888f2ee5cf8de4c8f7f06e2cb` | HUD en run avec HP/bouclier, XP, arme, vague, temps, difficulté et badge actif. |
| `states/survival-boss-hud.png` | `f5060fd10d20cf8e6bd34495c8f94d06b7069bcdb0c689cc469889a4eb972fd6` | HUD boss visible sous les panneaux de coin, libellé pixel cyan et barre de vie magenta; état boss simulé dans le smoke. |
| `states/survival-boss-feedback.png` | `43c32b77df8bdca24eaf66918c91ad7ca0cf106b1ea6e31eb5dd792ab00b65a6` | HUD boss et feedback jaune d’acquisition d’objet simultanés, sans chevauchement. |
| `states/revive-confirmation.png` | `49d97303f48138e0b7b864bc706fb32b729a21e47260bee4d3d3b39720c5463f` | Dialogue revive Neon dans le viewport, focus visible sur `REVIVE`, choix de refus distinct; recapturé après contrôle multi-résolution. |
| `states/revive-declined-result.png` | `5dce4e914f11077cd6ccea3695c616aca04c58ae4bcfe86ba61b2ad8c250404c` | Écran RUN OVER intégré au HUD après refus; la run temporaire est enregistrée et les récompenses/équipement du fixture s’affichent; recapturé par le smoke de revive. |
| `states/run-stat-detail.png` | `ffb25b728ba1449e7f473fd9c5f3168ff7dcce4c05eebf59bcf7901b1f294a77` | Détail Tab des statistiques avec focus sur fermeture, contributions colorées et liste défilante. |
| `states/equipment-no-compatible.png` | `957331de59220a65e19a0972f12ba5855c5120a91893404398f3ca5d2fe78f21` | Inventaire non vide sans pièce compatible avec le slot bottes, capturé au-dessus du hub réel; état vide explicite et aperçu « no change ». |
| `states/equipment-action-failed.png` | `07b2de9f9157f70cb9abc163f7f8ae6dca5798ed3b5c78e82ae3b2d99f5dcc31` | L’action ÉQUIPER d’une pièce devenue obsolète échoue via le vrai service; le panneau reste ouvert avec la pièce affichée et une bannière explicite. |
| `states/equipment-details.png` | `ca61681cf2aaab4e20176a3f0970c054faf4898220b961cc21efa4657694acd3` | Mode Details à 640×360 : actions d’amélioration, effet unique, vente/démantèlement dans la liste défilante; CLOSE reste fixe et visible. Le smoke vérifie aussi que le scroll vertical est actif et la fenêtre contenue à trois viewports. |
| `states/equipment-sell-confirmation.png` | `bf26ff5ef969c2103cc16ac3d735ca30c8c450c9db8b8c4ed158ba5f2dbd09a3` | Confirmation Neon de vente à 640×360 : montant et irréversibilité visibles, focus initial sur CANCEL; bounds vérifiés aux trois viewports ciblés. Cette capture a permis de remplacer l’ancien dialogue système gris. |

Les captures UI ont été régénérées le 2026-10-18 après passage des surfaces de panneaux à une opacité complète, puis inspectées pour les contextes hub, coffre en run, skill tree et inventaire d’équipement. Les hashes indexés sont recalculés depuis les fichiers archivés; plusieurs états ont donc changé. L’utilisateur a confirmé que le texte courant et les labels pixel du hub et de l’équipement sont lisibles à 640×360. Ces images valident le rendu virtualisé ciblé, pas le GPU matériel ni les contrôles physiques. La revue audio en contexte reste **[OUVERTE]** à la demande de l’utilisateur de poursuivre sans écoute.

Les onze premières captures `states/*.png` ont été générées par `game/tests/ui_states_evidence_smoke.gd` sous Godot 4.7.2/Xvfb/Mesa llvmpipe. Le coffre et le résultat utilisent les instances déjà montées sous `SurvivalSession/HUD`, avec génération d’ennemis désactivée. Les deux états de profil indisponible sont au-dessus du vrai hub Survival avec un service isolé. `equipment_panel_visual_smoke.gd` capture aussi l’état sans pièce compatible dans le hub réel, sans toucher à la sauvegarde normale. Les autres captures viennent des smokes `survival_entry_smoke.gd`, `survival_hud_smoke.gd`, `survival_revive_smoke.gd` et `survival_run_stat_hub_smoke.gd`; elles couvrent l’échec réel d’une mutation d’équipement dans le hub et la confirmation de vente. Les états de revue utilisent des données temporaires; aucune sauvegarde normale n’est écrite. Ces captures ne couvrent pas toutes les erreurs, branches de focus, tailles ni contrôles physiques.

## Parcours du paquet Linux/X11 Release — build du 2026-10-18

Le paquet de staging actuel provient de l’archive propre du commit `f3141f3`: 29 878 857 octets, SHA-256 `1fa1303bb60a7c59e4e820a4a2fced206759075a2ba4c499d4c2459e1e9b763e`. L’exécutable extrait fait 75 119 888 octets (SHA-256 `ac550146ae12ac0e5e1ad37f821bdfe918763eb0f84bfa05cc87bdda4d579db7`); sa GDExtension Release fait 1 140 456 octets (SHA-256 `27597dbc63f81492a19c821d809cf0c5001ff1f0b9cb0bafeffdf7e767e2d5b2`). Avec un `XDG_DATA_HOME` jetable, le paquet suit menu → hub → équipement → arbre de compétences → choix d’arme → combat → pause sous Xvfb/Mesa llvmpipe à 1280×720, via XTest. Les sept captures ont été régénérées et inspectées; le journal ne contient aucun `ERROR:`. Le processus a été arrêté après les captures (`SIGTERM`). Le pilote audio était `Dummy`; aucun contrôleur physique ni sortie audio réelle n’a été essayé.

| Capture | SHA-256 |
|---|---|
| `release-linux/dopamine-release-menu.png` | `23f32cf7c8c68e2a9ae41cc68f3cd4e48bb22bbf7b42568d71f07b5947807bd6` |
| `release-linux/dopamine-release-hub.png` | `859b7d532e0054a17b60ff3e09a9458d0a959bb29b22b937db6ac819c169fc83` |
| `release-linux/dopamine-release-equipment.png` | `dfd45c1f502c2d0846f5dd50e842dae49a725b32a0eb63a4a445481bd664654f` |
| `release-linux/dopamine-release-skill-tree.png` | `54cdac0f93f1b1f183272bff49edd39ef6c42a18f6a55624211cc2371919b19b` |
| `release-linux/dopamine-release-weapon-choice.png` | `e441dbb077fba2ddf4cd73bcede2eedc13fd694a072eaf921b6a5bc3cfb6b9c0` |
| `release-linux/dopamine-release-combat.png` | `6c1fd0ed4aefc6c3dd8a27b824ce7dca10ca55852853b00c8bde58fafa9741f5` |
| `release-linux/dopamine-release-pause-final.png` | `bffaf00dc0dafe16e891ea16f94c165a0d3fab355f5836f1f234bc1b497fa49d` |

C’est une preuve de lancement relocalisé sur l’hôte Debian courant; pas une installation sur machine distincte ni une validation matérielle.

## Audio

`adaptive-music-transition.wav` est un extrait stéréo de 30 secondes préparé pour écoute humaine. Il rejoue les cinq stems en boucle avec les courbes de gain et les vitesses de fondu du contrôleur runtime, et superpose des SFX de combat représentatifs. Un gain maître unique sert seulement à rendre l’extrait audible; le niveau final en jeu reste **[PROPOSÉ]**. Source reproductible : `python3 game/tools/render_adaptive_audio_preview.py`. SHA-256 : `e6c35273bf80e3a8385b09d83a1715c4c31ae2b003672c94360e789388520766`.

`adaptive-music-runtime-capture.wav` est une capture stéréo PCM16, 44,1 kHz, de 12,26 s prise sur le bus Master par `AudioEffectRecord` dans Godot 4.7.2 avec le pilote Dummy. Elle utilise le véritable autoload `Sfx` et `adaptive_survival_music.gd`; `game/tests/adaptive_survival_music_runtime_capture.gd` inscrit des marqueurs pour vagues 1, 8, 16 et 24, télégraphe et phase boss, pause, reprise et fin de run. SHA-256 : `667ce7238edccb80e69b37fb5c18916753306da985291bad74acc219bde140b3`. Mesures PCM : pic `0.7300` (`-2.73 dBFS`), RMS global `0.07035` (`-23.06 dBFS`), zéro échantillon écrêté. La capture confirme que le moteur produit un signal continu et mesurable aux contextes marqués; ces mesures ne valident ni le niveau perçu, ni le masquage des cues, ni la qualité ou la fluidité audibles. Ce n’est pas une session réelle de combat et le mix/gains restent **[PROPOSÉS]**.

Écoute locale : `ffplay docs/art/evidence/2026-10-18/adaptive-music-transition.wav`. Le 2026-10-18, l’utilisateur a demandé de poursuivre sans retour d’écoute. L’extrait et le mix restent donc **[OUVERTS — non écoutés/approuvés par l’utilisateur]**; cette décision n’est pas une approbation audio.

## Revue des fontes

L’utilisateur a confirmé le 2026-10-18 que le texte courant et les labels pixel des captures `survival-hub.png` et `equipment.png` sont lisibles à taille normale en 640×360. Cela documente la lisibilité de ces deux vues; la direction typographique finale et les tailles sur tous les états restent **[OUVERTES]**.
