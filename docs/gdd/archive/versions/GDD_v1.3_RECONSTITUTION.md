# Dopamine Survivor — GDD v1.3 (reconstitution historique)

> **RECONSTITUTION, PAS DOCUMENT ORIGINAL.** Cette version est reconstruite à partir des décisions chronologiques retrouvées dans les échanges et des sections du GDD v1.5 consolidé. Les formulations et paramètres détaillés des sections extraites peuvent avoir été affinés après la version concernée ; ils ne constituent pas une transcription mot pour mot de v1.3.

## Objet de cette version

Ajout officiel du mode Endless Armorless et de son équipement temporaire.

Ce document représente les **ajouts identifiés à la version 1.3**, à appliquer cumulativement aux versions antérieures. Il ne prétend pas restituer leur texte historique exact.


## 13 — Endless Armorless (officiel v1.3)

[VALIDÉ] Mode Endless autonome : aucun équipement permanent actif. Skill tree et Achievement Mastery restent actifs. Les armes et reliques sont reconstruits normalement pendant la run. Après CHAQUE vague terminée : un Equipment Draft de trois propositions, dont une seule est choisie. Slots entièrement aléatoires et indépendants : chaque proposition a 1/6 de chances pour chacun des six slots ; aucun filet de sécurité pour slots vides. Probabilité qu'un slot précis apparaisse dans un draft : 1−(5/6)^3 ≈ 42,13 %.

[VALIDÉ] Les objets sélectionnés sont temporaires et disparaissent à la fin de la run. Amélioration possible grâce au Flux, ressource temporaire spécifique à Armorless. Legendary/Mythic : libre choix de l'effet unique parmi les effets éligibles. Difficultés Easy à Chaos. Classement : vague la plus haute, puis temps de survie le plus long, puis nombre de kills ; classements séparés par difficulté.

[PROPOSÉ] Raretés selon vague, en % Normal/Magic/Mystic/Legendary/Mythic : vagues 1–5 : 55/35/9/1/0 ; 6–15 : 25/40/27/7/1 ; 16–30 : 5/20/45/25/5 ; 31–50 : 0/5/25/50/20 ; 51+ : 0/0/10/55/35. Multiplicateur de poids selon difficulté : Easy 0,80 ; Normal 1 ; Hard 1,15 ; Nightmare 1,35 ; Chaos 1,60, appliqué sous forme poids_r × multiplicateur^indice_r, puis normalisé.

[PROPOSÉ] Flux gagné à la fin de la vague w : 5+2w ; coût d'amélioration au niveau E : ceil(5×1,5^E×multiplicateur_rareté), multiplicateurs 1 / 1,25 / 1,5 / 2 / 2,5. Bonus de ligne +8 % par niveau ; max +10 ; échecs et pity analogues à l'enhancement normal. Flux jamais convertible en Powder.

[PROPOSÉ] HP ennemis Armorless : HP0 × multiplicateur_difficulté × (1,10^(w−1) si w≤24, sinon 1,10^23 × 1,055^(w−24)). HP decay identique au système de base, sans reset. Boss toutes les 12 vagues ; timers suspendus pendant boss, decay maintenu. Densité bornée par budget de performance.

[PROPOSÉ] Récompenses persistantes possibles : Essence, Powder, achievements et records, mais pas d'équipement permanent garanti. Ce dernier point reste une proposition à confirmer ; la règle d'un équipement garanti s'applique explicitement aux runs classiques.

[À TESTER] Draft à trois slots identiques, objets multiples d'un slot, gestion de l'inventaire temporaire, remplacement d'un équipement qui fournit un slot d'arme, destruction de Flux à la mort, sauvegarde/reprise et anti-double-attribution.

<a id="14"></a>
