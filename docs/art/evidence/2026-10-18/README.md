# Preuves visuelles — 2026-10-18

Captures 640×360 générées avec Godot 4.7.2 sous Xvfb/Mesa llvmpipe. Les smokes associés aux parcours ont tous terminé sans échec; ALSA a basculé sur le pilote audio dummy et n’apporte aucune preuve d’écoute.

| Capture | SHA-256 | Revue |
|---|---|---|
| `launch-menu.png` | `15b7e227a6e3e28e16558e7a1d930861b99c26cc01bd4a92dd22156a3a7ef88a` | Composition validée dans l’Art Bible : navigation à gauche, identité à droite. |
| `survival-hub.png` | `900623d972ef6d1943040f081a3ee7e5cbc7357d4a7f40c5e98d034889fed645` | Panneaux et parcours de préparation restent lisibles dans le viewport logique. |
| `skill-tree.png` | `4b416ddea4e9a00c76cb197c5f160da20e258ea7b9389794e691774af8ca70df` | Graphe de prototype ramifié; la capture montre une portion navigable. Le contenu, coûts et effets restent **[PROPOSÉS]** ou **[OUVERTS]**. |
| `equipment.png` | `49136c8b371097b35c9a8170db46391e2fccf9937666f5906f6850a1695ca0c9` | Six slots, inventaire équipable, commandes de remplacement et variation avant/après visibles; le cadre Neon suit le focus manette/clavier sur l’anneau équipé. |
| `survival-combat.png` | `e876f54d3b0f7f323b7495cd54368991e210d0da126e5b504aaf21667dbf8b52` | Combat chargé : familles d’ennemis, projectiles, impacts, XP, télégraphe et faisceaux visibles. |
| `catalog-icons.png` | `cf37687d14edcfb90d0c0bbdefa811e2580f20973e302c1fb0e46370968eb37a` | Planche de contrôle pour icônes d’armes, évolutions et reliques; revue des silhouettes en grille. |
| `states/options.png` | `7777bc770de2b71396314d98d19a0a45384e15b91cf8f65de0bd59f531745fe2` | Options générales, audio, accessibilité et focus initial. |
| `states/pause.png` | `8766c97a910850d99fff262e7ec2ced0cd589813776d78f1e578bc81f4d6dd15` | Pause, état figé, vitesse, verrouillage et focus visible sur `RESUME`. |
| `states/pause-confirmation.png` | `5d02d19431ec29d13574f2da5ad69f4e94555413f113696dff48e0a6c8d06283` | Confirmation d’abandon au-dessus de la pause; focus initial sur `KEEP PLAYING`, action de danger séparée. |
| `states/chest.png` | `331d56eb75e79b0ae502885f9a1a912ef7203d69530e214bac8f35857e912a46` | État de choix d’offres représentatives; valeurs de la capture sont des données de smoke, pas du contenu validé. |
| `states/run-inventory.png` | `e269ed61c160063d4a92c44c7596cf58b056f9defbca1bdc7305576366b93f8e` | Inventaire en run avec arme et relique d’échantillon. |
| `states/run-result.png` | `430edf770fe9a2ac33c0a206cc99bbb2aeca307016270e55d4fce311f61dcdd4` | Résultat de victoire et actions de continuation/relance/retour; récompenses synthétiques de smoke. |
| `states/armorless-records.png` | `5fa3a9b21280ddc9aabdf4bbd6a83088ed2ed213900e9c6eabd2dd7b879291c2` | Panneau records Armorless avec une entrée de démonstration. |
| `states/sandbox.png` | `32d998625488d852d33d30993c6b653c56fb853ca5a5c8955564ff5f3addf80f` | Sandbox isolé avec badge `PAUSED / NO SAVE` et cadre de focus visible sur `ACCUEIL`; rendu capturé dans le contexte `main.tscn`. |
| `states/sandbox-lab.png` | `fbe146065ce9bdb6b56ebfcb6e2fa4b0774776b7c532c7c581519184d103999a` | Sandbox Lab à 640×360 : simulation et commandes visibles, cadre de focus sur `PAUSE`, configuration accessible par défilement; HUD et caméra de la session masquée isolés. |
| `states/equipment-error.png` | `72543ce0ec19690959e484134f6cc86ad26f1bf0b908a3d086360f76e85ab5ac` | État d’erreur équipement avec profil illisible et focus visible sur fermeture. |
| `states/skill-tree-error.png` | `69ab64b98fc803f04462c3162f68588c7ec67c4d421a2877aaf4da284567de28` | Profil d’arbre indisponible, actions verrouillées et focus visible sur fermeture. |
| `states/starting-loadout.png` | `d496cedb3e5fff0d8577fc4900a48fa9113316fa529dc5e08908bd9995c88da8` | Choix d’arme de départ dans la vraie scène de run Survival; exemple temporaire du Sandbox et focus initial visibles. |
| `states/survival-hud.png` | `ed78943b4797d945231a7ccfcadfddbf84ee49d888f2ee5cf8de4c8f7f06e2cb` | HUD en run avec HP/bouclier, XP, arme, vague, temps, difficulté et badge actif. |
| `states/survival-boss-hud.png` | `f5060fd10d20cf8e6bd34495c8f94d06b7069bcdb0c689cc469889a4eb972fd6` | HUD boss visible sous les panneaux de coin, libellé pixel cyan et barre de vie magenta; état boss simulé dans le smoke. |
| `states/survival-boss-feedback.png` | `43c32b77df8bdca24eaf66918c91ad7ca0cf106b1ea6e31eb5dd792ab00b65a6` | HUD boss et feedback jaune d’acquisition d’objet simultanés, sans chevauchement. |
| `states/revive-confirmation.png` | `c4eeefca719a9ea6d5d88faf8ceffd728d431dcf61646b68003c53fd8ea302ef` | Dialogue revive Neon dans le viewport, focus visible sur `REVIVE`, choix de refus distinct. |
| `states/revive-declined-result.png` | `83d55e0ad0953af43baf9645291c4f05d0381adbfdb37aecf3d5d193c756ca2e` | Écran RUN OVER après refus; indique l’échec de sauvegarde du run synthétique de durée nulle dans le profil de smoke. |
| `states/run-stat-detail.png` | `ffb25b728ba1449e7f473fd9c5f3168ff7dcce4c05eebf59bcf7901b1f294a77` | Détail Tab des statistiques avec focus sur fermeture, contributions colorées et liste défilante. |
| `states/equipment-no-compatible.png` | `d1bf947ad781772ef3763c0059cdbb82ba82e30080bc9820eb40f75d17dae156` | Inventaire non vide mais sans pièce compatible avec le slot bottes; état vide explicite et aperçu « no change ». |
| `states/equipment-action-failed.png` | `e3bc149c79aec65f604461fc83d5e54c37d4519f8420f0f15f0e15aaef85604b` | L’action ÉQUIPER d’une pièce devenue obsolète échoue via le vrai service; le panneau reste ouvert avec la pièce affichée et une bannière explicite. |

Les captures ont été régénérées après import des exports graphiques renouvelés le 2026-10-18 et inspectées. La planche catalogue, le hub et le combat ont changé de hash; les autres captures sont identiques. L’utilisateur a confirmé que le texte courant et les labels pixel du hub et de l’équipement sont lisibles à 640×360. Ces images valident le rendu virtualisé ciblé, pas le GPU matériel ni les contrôles physiques. La revue audio en contexte reste **[OUVERTE]** à la demande de l’utilisateur de poursuivre sans écoute.

Les onze premières captures `states/*.png` ont été générées par `game/tests/ui_states_evidence_smoke.gd` sous Godot 4.7.2/Xvfb/Mesa llvmpipe. Neuf captures supplémentaires viennent des smokes `equipment_panel_visual_smoke.gd`, `survival_entry_smoke.gd`, `survival_hud_smoke.gd`, `survival_revive_smoke.gd` et `survival_run_stat_hub_smoke.gd`; elles couvrent aussi un slot sans pièce compatible et l’échec réel d’une mutation d’équipement dans le hub. Les états de revue utilisent des données temporaires; aucune sauvegarde normale n’est écrite. Les panneaux coffre et résultat sont centrés par le conteneur parent utilisé à l’intégration. Ces captures ne couvrent pas toutes les erreurs, branches de focus, tailles ni contrôles physiques.

## Parcours du paquet Linux/X11 Release — build du 2026-10-18

Le binaire exporté depuis `565b177` et son sidecar GDExtension ont été copiés dans un dossier temporaire vide, puis démarrés avec un `XDG_DATA_HOME` neuf : code 0, aucune erreur ni bibliothèque manquante. Le parcours sous Xvfb/Mesa llvmpipe utilise des touches clavier synthétiques via XTest et suit menu → hub → choix d’arme → combat → pause. Les cinq captures 1280×720 sont dans `release-linux/`; elles ont été inspectées et montrent le rendu du paquet exporté. Le pilote audio était `Dummy`, aucun contrôleur physique ni sortie audio n’a été essayé.

| Capture | SHA-256 |
|---|---|
| `release-linux/dopamine-release-menu.png` | `4deda85c9002ee309cfb3c7739128551f66624d8fc92e58695e40253ec4275fd` |
| `release-linux/dopamine-release-hub.png` | `bd18454012fe598bb2adc7107ef1a0cccb9d4b9e4ab1285614e018adb0eb938b` |
| `release-linux/dopamine-release-weapon-choice.png` | `fa56c34614f39fdf0de320025765ef7e13ac1a654da00476481d840375e1db0c` |
| `release-linux/dopamine-release-combat.png` | `d867cf457068a92f3c4b8be91876a6d60799cc826f84acdd76f3d83c4bc9dd9d` |
| `release-linux/dopamine-release-pause-final.png` | `f39ea87f425f6c7089647e275cfffb2be59da38977576c87199d6fd4f6ac8020` |

Hashes du paquet : exécutable 75 113 712 octets, SHA-256 `a529f38c3d6cb292422d6539d9a3929e7464b7375174cb1808fd878a3a093004`; GDExtension 1 140 440 octets, SHA-256 `a6d148c988fcb78476b3e43fb721869a0b2fddc1251e78ed1033231690b05dfa`. C’est une preuve de lancement relocalisé sur l’hôte Debian courant; pas une installation sur machine distincte ni une validation matérielle.

## Audio

`adaptive-music-transition.wav` est un extrait stéréo de 30 secondes préparé pour écoute humaine. Il rejoue les cinq stems en boucle avec les courbes de gain et les vitesses de fondu du contrôleur runtime, et superpose des SFX de combat représentatifs. Un gain maître unique sert seulement à rendre l’extrait audible; le niveau final en jeu reste **[PROPOSÉ]**. Source reproductible : `python3 game/tools/render_adaptive_audio_preview.py`. SHA-256 : `e6c35273bf80e3a8385b09d83a1715c4c31ae2b003672c94360e789388520766`.

`adaptive-music-runtime-capture.wav` est une capture stéréo PCM16, 44,1 kHz, de 12,26 s prise sur le bus Master par `AudioEffectRecord` dans Godot 4.7.2 avec le pilote Dummy. Elle utilise le véritable autoload `Sfx` et `adaptive_survival_music.gd`; `game/tests/adaptive_survival_music_runtime_capture.gd` inscrit des marqueurs pour vagues 1, 8, 16 et 24, télégraphe et phase boss, pause, reprise et fin de run. SHA-256 : `667ce7238edccb80e69b37fb5c18916753306da985291bad74acc219bde140b3`. Mesures PCM : pic `0.7300` (`-2.73 dBFS`), RMS global `0.07035` (`-23.06 dBFS`), zéro échantillon écrêté. La capture confirme que le moteur produit un signal continu et mesurable aux contextes marqués; ces mesures ne valident ni le niveau perçu, ni le masquage des cues, ni la qualité ou la fluidité audibles. Ce n’est pas une session réelle de combat et le mix/gains restent **[PROPOSÉS]**.

Écoute locale : `ffplay docs/art/evidence/2026-10-18/adaptive-music-transition.wav`. Le 2026-10-18, l’utilisateur a demandé de poursuivre sans retour d’écoute. L’extrait et le mix restent donc **[OUVERTS — non écoutés/approuvés par l’utilisateur]**; cette décision n’est pas une approbation audio.

## Revue des fontes

L’utilisateur a confirmé le 2026-10-18 que le texte courant et les labels pixel des captures `survival-hub.png` et `equipment.png` sont lisibles à taille normale en 640×360. Cela documente la lisibilité de ces deux vues; la direction typographique finale et les tailles sur tous les états restent **[OUVERTES]**.
