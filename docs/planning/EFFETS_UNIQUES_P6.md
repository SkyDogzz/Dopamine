# Contrats prototypes des effets uniques P6

Les effets ci-dessous sont les effets sélectionnables et exécutés en Survival au 2026-10-16. Leurs chiffres et comportements sont **[PROPOSÉS]**, non calibrés; le tableau décrit le prototype courant, pas une validation de balance.

| ID | Prérequis | Déclencheur | Portée / limite | Feedback actuel | Statut |
|---|---|---|---|---|---|
| `lightning_burst` | Effet sur une pièce permanente équipée; session Survival normale | Chaque tir d’arme admissible lance un roll de 10%; après une création réussie, cooldown interne de 2 s simulées | Ennemi le plus proche dans la portée Lightning visible; projectile à 50% des dégâts de base de l’arme, avec aire et vitesse projectile d’équipement | Projectile éclair dédié et bref message HUD `LIGHTNING BURST` | **[PROPOSÉ]**; gating, portée, cooldown et feedback couverts par `survival_unique_effects_smoke.gd`; chiffres non calibrés |
| `overflow_shield` | Effet équipé et lifesteal reçu par la session | Après application du soft cap de soin, la partie qui dépasse les PV manquants alimente le bouclier | 50% du soin excédentaire après soft cap; plafond à 10% des PV max; expiration après 5 s simulées; absorbe les dégâts avant les PV | Valeur `SHIELD` dans le HUD HP pendant qu’il reste du bouclier | **[PROPOSÉ]**; couvert par `survival_inventory_smoke.gd` |
| `evolution_shockwave` | Effet équipé et au moins une arme évoluée dans le loadout de run | Premier tir admissible après qu’une évolution est active; une fois par run | Huit projectiles radiaux depuis le joueur; vitesse 400, dégâts de base du tir, rayon 6, durée 0,3 s | Huit projectiles dédiés et bref message HUD `EVOLUTION SHOCKWAVE` | **[PROPOSÉ]**; gating avant/après évolution, huit projectiles, unicité par run et feedback couverts par `survival_unique_effects_smoke.gd`; chiffres non calibrés |
| `elite_haste` | Effet équipé | Mort d’un ennemi de type élite | +15% de mobilité du joueur pendant 3 s simulées; une nouvelle élimination rafraîchit l’échéance, sans cumul | Bref message HUD `ELITE HASTE · +15% MOVE` | **[PROPOSÉ]**; couvert par `survival_elite_smoke.gd` |
| `free_first_chest_reroll` | Effet équipé et premier coffre de récompense de famille arme/relique avec assez d’offres inédites | Action explicite REROLL dans le choix du coffre | Une fois par run; les options déjà affichées sont exclues; la simulation reste en pause | Bouton REROLL dans le panneau de coffre | **[PROPOSÉ]**; couvert par `free_chest_reroll_smoke.gd` |
| `expanded_loadout` | Effet sur une pièce permanente équipée; session Survival normale | Initialisation de la capacité du loadout | +1 slot d'arme et +1 slot de relique, chacun plafonné à six; les doublons du même effet ne s'empilent pas | L'inventaire décrit l'effet; les offres permettent de remplir les slots supplémentaires | **[PROPOSÉ]**; couvert par `survival_unique_effects_smoke.gd` et `survival_loadout_smoke.gd` |

`equipped_unique_effects()` déduplique un même ID actif porté sur plusieurs pièces. `revive_once` est l’ID validé pour le revive. `revive_knockback` demeure accepté en lecture pour les anciennes saves, mais n'est plus proposé aux nouvelles pièces et n'a pas de comportement de jeu.

Le GDD valide le principe de revives rares. Décisions utilisateur du 2026-10-17, réponses C, B, B, B, A puis B : l’effet `revive_once` équipé accorde un revive, au maximum une fois par run en Survival et Endless standard; au coup fatal, le jeu demande confirmation avant consommation; si le joueur confirme, il revient à 50 % de ses PV max avec 3 secondes d’invulnérabilité. `revive_knockback` reste lisible pour les anciennes saves sans comportement de revive. Endless Armorless et le Sandbox Lab sont exclus; l’effet peut maintenant être implémenté dans ces deux modes normaux.

## Calibration encore ouverte

- Le smoke `survival_unique_effects_smoke.gd` passe sous Godot 4.7.2 et couvre les prérequis équipés, la cible à portée, le cooldown, l’évolution préalable, l’émission des huit projectiles et l’unicité d’activation.
- Comparer ces valeurs **[PROPOSÉES]** sur plusieurs builds avant calibrage; ne pas changer leur statut sans validation explicite.
