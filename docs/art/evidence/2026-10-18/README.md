# Preuves visuelles — 2026-10-18

Captures 640×360 générées avec Godot 4.7.2 sous Xvfb/Mesa llvmpipe. Les smokes associés aux parcours ont tous terminé sans échec; ALSA a basculé sur le pilote audio dummy et n’apporte aucune preuve d’écoute.

| Capture | SHA-256 | Revue |
|---|---|---|
| `launch-menu.png` | `15b7e227a6e3e28e16558e7a1d930861b99c26cc01bd4a92dd22156a3a7ef88a` | Composition validée dans l’Art Bible : navigation à gauche, identité à droite. |
| `survival-hub.png` | `900623d972ef6d1943040f081a3ee7e5cbc7357d4a7f40c5e98d034889fed645` | Panneaux et parcours de préparation restent lisibles dans le viewport logique. |
| `skill-tree.png` | `4b416ddea4e9a00c76cb197c5f160da20e258ea7b9389794e691774af8ca70df` | Graphe de prototype ramifié; la capture montre une portion navigable. Le contenu, coûts et effets restent **[PROPOSÉS]** ou **[OUVERTS]**. |
| `equipment.png` | `49136c8b371097b35c9a8170db46391e2fccf9937666f5906f6850a1695ca0c9` | Six slots, inventaire équipable, commandes de remplacement et variation avant/après visibles. |
| `survival-combat.png` | `e876f54d3b0f7f323b7495cd54368991e210d0da126e5b504aaf21667dbf8b52` | Combat chargé : familles d’ennemis, projectiles, impacts, XP, télégraphe et faisceaux visibles. |
| `catalog-icons.png` | `cf37687d14edcfb90d0c0bbdefa811e2580f20973e302c1fb0e46370968eb37a` | Planche de contrôle pour icônes d’armes, évolutions et reliques; revue des silhouettes en grille. |
| `states/options.png` | `7777bc770de2b71396314d98d19a0a45384e15b91cf8f65de0bd59f531745fe2` | Options générales, audio, accessibilité et focus initial. |
| `states/pause.png` | `bddb73c1f6f8ecaee76190a53e001fce78a308568149f3ab4f8beff48687b0f9` | Pause, état figé, vitesse, verrouillage et actions/focus clavier. |
| `states/chest.png` | `331d56eb75e79b0ae502885f9a1a912ef7203d69530e214bac8f35857e912a46` | État de choix d’offres représentatives; valeurs de la capture sont des données de smoke, pas du contenu validé. |
| `states/run-inventory.png` | `e269ed61c160063d4a92c44c7596cf58b056f9defbca1bdc7305576366b93f8e` | Inventaire en run avec arme et relique d’échantillon. |
| `states/run-result.png` | `430edf770fe9a2ac33c0a206cc99bbb2aeca307016270e55d4fce311f61dcdd4` | Résultat de victoire et actions de continuation/relance/retour; récompenses synthétiques de smoke. |
| `states/armorless-records.png` | `5fa3a9b21280ddc9aabdf4bbd6a83088ed2ed213900e9c6eabd2dd7b879291c2` | Panneau records Armorless avec une entrée de démonstration. |
| `states/sandbox.png` | `32d998625488d852d33d30993c6b653c56fb853ca5a5c8955564ff5f3addf80f` | Sandbox isolé avec badge `PAUSED / NO SAVE`; rendu capturé dans le contexte `main.tscn`. |

Les captures ont été régénérées après import des exports graphiques renouvelés le 2026-10-18 et inspectées. La planche catalogue, le hub et le combat ont changé de hash; les autres captures sont identiques. L’utilisateur a confirmé que le texte courant et les labels pixel du hub et de l’équipement sont lisibles à 640×360. Ces images valident le rendu virtualisé ciblé, pas le GPU matériel ni les contrôles physiques. La revue audio en contexte reste **[OUVERTE]** à la demande de l’utilisateur de poursuivre sans écoute.

Les sept captures `states/*.png` ont été générées par `game/tests/ui_states_evidence_smoke.gd` sous Godot 4.7.2/Xvfb/Mesa llvmpipe. Le smoke construit chaque scène avec des exemples visuels temporaires; il ne modifie aucun profil. Les panneaux coffre et résultat sont centrés par le conteneur parent utilisé à l’intégration. Ces captures étendent la revue aux états secondaires, mais ne prouvent pas toutes les erreurs, branches de focus, tailles ni contrôles physiques.

## Audio

`adaptive-music-transition.wav` est un extrait stéréo de 30 secondes préparé pour écoute humaine. Il rejoue les cinq stems en boucle avec les courbes de gain et les vitesses de fondu du contrôleur runtime, et superpose des SFX de combat représentatifs. Un gain maître unique sert seulement à rendre l’extrait audible; le niveau final en jeu reste **[PROPOSÉ]**. Source reproductible : `python3 game/tools/render_adaptive_audio_preview.py`. SHA-256 : `e6c35273bf80e3a8385b09d83a1715c4c31ae2b003672c94360e789388520766`.

Écoute locale : `ffplay docs/art/evidence/2026-10-18/adaptive-music-transition.wav`. Le 2026-10-18, l’utilisateur a demandé de poursuivre sans retour d’écoute. L’extrait et le mix restent donc **[OUVERTS — non écoutés/approuvés par l’utilisateur]**; cette décision n’est pas une approbation audio.

## Revue des fontes

L’utilisateur a confirmé le 2026-10-18 que le texte courant et les labels pixel des captures `survival-hub.png` et `equipment.png` sont lisibles à taille normale en 640×360. Cela documente la lisibilité de ces deux vues; la direction typographique finale et les tailles sur tous les états restent **[OUVERTES]**.
