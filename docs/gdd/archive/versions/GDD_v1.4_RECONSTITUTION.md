# Dopamine Survivor — GDD v1.4 (reconstitution historique)

> **RECONSTITUTION, PAS DOCUMENT ORIGINAL.** Cette version est reconstruite à partir des décisions chronologiques retrouvées dans les échanges et des sections du GDD v1.5 consolidé. Les formulations et paramètres détaillés des sections extraites peuvent avoir été affinés après la version concernée ; ils ne constituent pas une transcription mot pour mot de v1.4.

## Objet de cette version

Ajout officiel du Sandbox Lab isolé de la progression.

Ce document représente les **ajouts identifiés à la version 1.4**, à appliquer cumulativement aux versions antérieures. Il ne prétend pas restituer leur texte historique exact.


## 14 — Sandbox Lab (officiel v1.4)

[VALIDÉ] Sandbox Lab est accessible depuis le menu principal avant toute création/lecture de sauvegarde. Ce n'est pas un mode de progression. Presque tous les paramètres peuvent être modifiés, y compris des valeurs extrêmes. Édition en direct pendant la run. Build initial totalement libre : armes, reliques, équipement, statistiques et niveaux. Presets indépendants, export/import JSON et code de partage. Import d'une sauvegarde normale autorisé uniquement en copie isolée modifiable. Outils obligatoires : spawn, kill all, DPS meter, god mode, contrôle de vitesse, logs. Valeurs dangereuses : avertissement et limite technique de sécurité.

[VALIDÉ] Aucun gain d'Essence/Powder permanent, aucun achievement officiel, aucun score classé. Aucune modification de sauvegarde normale. Copie dans un contexte mémoire séparé ; import à sens unique Normal → Sandbox, jamais l'inverse.

Familles d'overrides : Player (HP, decay, dégâts, mobilité, crit, soins, revives) ; Weapons/Relics (capacité, niveaux, duplications, évolutions, cooldowns, projectiles) ; Loot (drops, chests, choix, poids, garanties) ; XP ; Enemies/Waves (stats, densité, spawn, bosses, scaling, durée) ; Equipment (stats, rareté, effets, enhancements) ; Progression simulée (skill tree, achievements) ; Simulation (seed, vitesse, invincibilité, métriques).

Architecture : BaseBalanceConfig → SandboxOverrideLayer → RuntimeConfigResolver → systèmes de jeu existants. Les changements sont typés LIVE (immédiat), REBUILD (reconstruire le composant), RESTART (redémarrer la simulation). Les modifications multiples s'appliquent transactionnellement ; rollback si erreur. Tous les systèmes lisent la configuration effective plutôt que des constantes codées en dur.

[PROPOSÉ] Presets : schema_version, preset_id, name, description, base_mode, seed, overrides, flags, initial_build. Codes : préfixe DSLAB1:, JSON canonique compressé, Base64URL, somme de contrôle ; validation de taille et décompression bornée ; jamais de script, commande, chemin système ou données privées. Sauvegardes locales distinctes : user://saves/ et user://sandbox/{presets,snapshots,logs}.

[PROPOSÉ] DPS : fenêtre 1 s, 10 s et run ; dégâts par arme/évolution/effet, critiques, coups, cibles, overkill. Logs événements et RNG. Commandes : spawn, kill all avec ou sans loot, reset cooldowns, restore HP, freeze AI, clear projectiles, jump wave, give item.

[PROPOSÉ] Seuils indicatifs normal / avertissement / hard cap : armes 5–6 / 15+ / 64 ; reliques 5–6 / 20+ / 128 ; ennemis 200–500 / 750+ / 2 000 ; projectiles variable / 5 000+ / 20 000 ; vitesse ×1 / ×4+ / ×16 ; XP ×1 / ×100+ / ×10 000. Hard caps à profiler, pas des garanties de performance.

<a id="15"></a>
