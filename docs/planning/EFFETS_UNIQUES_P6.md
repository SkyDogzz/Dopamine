# Contrats prototypes des effets uniques P6

Les effets ci-dessous sont les seuls effets sélectionnables et exécutés en Survival au 2026-10-16. Leurs chiffres et comportements sont **[PROPOSÉS]**, non calibrés; le tableau décrit le prototype courant, pas une validation de balance.

| ID | Prérequis | Déclencheur | Portée / limite | Feedback actuel | Statut |
|---|---|---|---|---|---|
| `lightning_burst` | Effet sur une pièce permanente équipée; session Survival normale | Chaque tir d’arme admissible lance un roll de 10%; après une création réussie, cooldown interne de 2 s simulées | Ennemi le plus proche dans la portée Lightning visible; projectile à 50% des dégâts de base de l’arme, avec aire et vitesse projectile d’équipement | Projectile éclair dédié et bref message HUD `LIGHTNING BURST` | **[PROPOSÉ]**; scénario de gameplay dédié à ajouter |
| `overflow_shield` | Effet équipé et lifesteal reçu par la session | Après application du soft cap de soin, la partie qui dépasse les PV manquants alimente le bouclier | 50% du soin excédentaire après soft cap; plafond à 10% des PV max; expiration après 5 s simulées; absorbe les dégâts avant les PV | Valeur `SHIELD` dans le HUD HP pendant qu’il reste du bouclier | **[PROPOSÉ]**; couvert par `survival_inventory_smoke.gd` |
| `evolution_shockwave` | Effet équipé et au moins une arme évoluée dans le loadout de run | Premier tir admissible après qu’une évolution est active; une fois par run | Huit projectiles radiaux depuis le joueur; vitesse 400, dégâts de base du tir, rayon 6, durée 0,3 s | Huit projectiles dédiés et bref message HUD `EVOLUTION SHOCKWAVE` | **[PROPOSÉ]**; scénario de gameplay dédié à ajouter |
| `elite_haste` | Effet équipé | Mort d’un ennemi de type élite | +15% de mobilité du joueur pendant 3 s simulées; une nouvelle élimination rafraîchit l’échéance, sans cumul | Bref message HUD `ELITE HASTE · +15% MOVE` | **[PROPOSÉ]**; couvert par `survival_elite_smoke.gd` |
| `free_first_chest_reroll` | Effet équipé et premier coffre de récompense de famille arme/relique avec assez d’offres inédites | Action explicite REROLL dans le choix du coffre | Une fois par run; les options déjà affichées sont exclues; la simulation reste en pause | Bouton REROLL dans le panneau de coffre | **[PROPOSÉ]**; couvert par `free_chest_reroll_smoke.gd` |

`equipped_unique_effects()` déduplique un même ID actif porté sur plusieurs pièces. `revive_knockback` demeure accepté en lecture pour les anciennes saves, mais n'est plus proposé aux nouvelles pièces et n'a pas de comportement de jeu.

## Couverture manquante

- Ajouter un scénario déterministe pour `lightning_burst`, avec contrôle du gating équipé/non équipé, de la cible dans la portée et du cooldown.
- Ajouter un scénario déterministe pour `evolution_shockwave`, avec gating avant/après évolution et une seule activation par run.
- Comparer ces valeurs **[PROPOSÉES]** sur plusieurs builds avant calibrage; ne pas changer leur statut sans validation explicite.
