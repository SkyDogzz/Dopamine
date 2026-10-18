# Preuves visuelles — 2026-10-18

Captures 640×360 générées avec Godot 4.7.2 sous Xvfb/Mesa llvmpipe. Les smokes associés aux parcours ont tous terminé sans échec; ALSA a basculé sur le pilote audio dummy et n’apporte aucune preuve d’écoute.

| Capture | SHA-256 | Revue |
|---|---|---|
| `launch-menu.png` | `15b7e227a6e3e28e16558e7a1d930861b99c26cc01bd4a92dd22156a3a7ef88a` | Composition validée dans l’Art Bible : navigation à gauche, identité à droite. |
| `survival-hub.png` | `263d7f54da56cf32a19c4d0dd73cbc3ed5c25aa1d831a1138a4f7df35943c28e` | Panneaux et parcours de préparation restent lisibles dans le viewport logique. |
| `skill-tree.png` | `4b416ddea4e9a00c76cb197c5f160da20e258ea7b9389794e691774af8ca70df` | Graphe de prototype ramifié; la capture montre une portion navigable. Le contenu, coûts et effets restent **[PROPOSÉS]** ou **[OUVERTS]**. |
| `equipment.png` | `49136c8b371097b35c9a8170db46391e2fccf9937666f5906f6850a1695ca0c9` | Six slots, inventaire équipable, commandes de remplacement et variation avant/après visibles. |
| `survival-combat.png` | `f21fa83502f25d9787f3ed564e035d0c0e2544e0707161779d38558920ed4ecb` | Combat chargé : familles d’ennemis, projectiles, impacts, XP, télégraphe et faisceaux visibles. |
| `catalog-icons.png` | `3a7553654256a1e65213dc46ca01dac92ab740dd9e907d2dcc0bffd61a239cd9` | Planche de contrôle pour icônes d’armes, évolutions et reliques; revue des silhouettes en grille. |

Ces images valident le rendu virtualisé ciblé, pas le GPU matériel ni les contrôles physiques. La revue audio en contexte reste **[OUVERTE]** faute de sortie audio dans l’environnement.

## Audio

`adaptive-music-transition.wav` est un extrait stéréo de 30 secondes préparé pour écoute humaine. Il rejoue les cinq stems en boucle avec les courbes de gain et les vitesses de fondu du contrôleur runtime, et superpose des SFX de combat représentatifs. Un gain maître unique sert seulement à rendre l’extrait audible; le niveau final en jeu reste **[PROPOSÉ]**. Source reproductible : `python3 game/tools/render_adaptive_audio_preview.py`. SHA-256 : `e6c35273bf80e3a8385b09d83a1715c4c31ae2b003672c94360e789388520766`.

Écoute locale : `ffplay docs/art/evidence/2026-10-18/adaptive-music-transition.wav`. Le 2026-10-18, l’utilisateur a demandé de poursuivre sans retour d’écoute. L’extrait et le mix restent donc **[OUVERTS — non écoutés/approuvés par l’utilisateur]**; cette décision n’est pas une approbation audio.

## Revue des fontes

L’utilisateur a confirmé le 2026-10-18 que le texte courant et les labels pixel des captures `survival-hub.png` et `equipment.png` sont lisibles à taille normale en 640×360. Cela documente la lisibilité de ces deux vues; la direction typographique finale et les tailles sur tous les états restent **[OUVERTES]**.
