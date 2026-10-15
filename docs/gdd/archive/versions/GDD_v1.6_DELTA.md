# Dopamine Survivor — GDD v1.6 · Delta à fusionner avec v1.5

> **Ce document est un delta, pas une version complète autonome.** Le GDD v1.5 reste la base. Les chiffres et effets indiqués « proposés » ne sont pas validés.

## Armes — décisions validées

- 10 armes distinctes, 5 slots, 5 niveaux par arme ; aucun doublon hors Sandbox.
- Ciblage automatique propre à chaque arme, avec importance du positionnement du joueur.
- Arme de départ choisie parmi les armes débloquées proposées.
- Améliorations fixes surtout statistiques et changement visuel à chaque niveau.
- Évolution majeure automatique dès que l'arme atteint le niveau 5 et que sa relique associée est possédée, quel que soit le niveau de cette dernière. Une évolution par arme, sans consommer la relique ; l'arme conserve le niveau 5.
- Une arme niveau 5 non évoluée est exclue des upgrades ordinaires.

| Arme | Comportement | Évolution |
|---|---|---|
| Lightning Conductor | Éclairs en chaîne entre ennemis | Infinite Circuit |
| Inferno Sprayer | Jet de feu directionnel automatique | Wildfire |
| Crimson Daggers | Dagues en orbite autour du joueur, non lancées | Bloodstorm |
| Void Orb | Orbe lente traversante attirant les ennemis | Event Horizon |
| Frost Nova | Onde de gel centrée sur le joueur | Absolute Zero |
| Minigun | Tir automatique très rapide mono-cible | Redline |
| Meteor Staff | Météores ciblant les groupes | Starfall |
| Sawblades | Lames rebondissant entre ennemis | Razorstorm |
| Toxic Cloud | Nuages empoisonnés persistants | Pandemic |
| Prism Laser | Rayon continu suivant la cible prioritaire | Spectrum Collapse |

### Progressions d'armes proposées, non validées

| Arme | N2 | N3 | N4 | N5 |
|---|---|---|---|---|
| Lightning | +20 % dégâts | +1 rebond | -15 % cooldown | +25 % dégâts |
| Inferno | +20 % dégâts | +15 % portée | +20 % largeur | +25 % Burn |
| Daggers | +20 % dégâts | +1 dague | +20 % vitesse orbitale | +25 % dégâts |
| Void | +20 % dégâts | +20 % rayon d'attraction | +15 % durée | +25 % attraction |
| Frost | +20 % dégâts | +20 % rayon | +20 % durée Chill | -20 % cooldown |
| Minigun | +20 % dégâts | +25 % cadence | +15 % précision | +25 % cadence |
| Meteor | +20 % dégâts | +20 % rayon | -15 % délai impact | +30 % dégâts |
| Sawblades | +20 % dégâts | +1 rebond | +20 % vitesse | +25 % dégâts |
| Toxic | +20 % DOT | +20 % rayon | +20 % durée | +25 % DOT |
| Prism | +20 % dégâts | +20 % portée | +15 % suivi | +25 % dégâts |

## Reliques — décisions validées

- 11 reliques au total : 10 reliques associées à une arme et **Magnet Heart**, indépendante.
- 5 slots normaux ; chaque relique niveau 1–5, bonus globaux utiles indépendamment de l'arme associée et mécanique spéciale à haut niveau.
- Synergies entre reliques autorisées ; pas de limite artificielle de réactions, mais protections techniques contre boucles infinies.

### Magnet Heart — nouvelle relique validée

- Relique utilitaire, sans arme associée ni évolution.
- Augmente le rayon de ramassage et attire les objets au sol éligibles : XP, soins, ressources, monnaies, bonus temporaires.
- **N'attire jamais les coffres**, y compris via son effet niveau 5.
- L'exclusion des coffres s'applique aussi aux autres bonus de ramassage (équipement, arbre de compétences, autres reliques).
- Les coffres restent au sol et exigent proximité ou interaction du joueur.

**Valeurs proposées, non validées** : niveaux 1 à 5 : +25 %, +50 %, +75 %, +100 %, +125 % de rayon. Au niveau 5, « Magnetic Pulse » toutes les 20 s attire les objets éligibles dans un rayon de 300 % du rayon de base, sans coffres. Les objets accélèrent vers le joueur au lieu d'être téléportés.

**Synergies proposées** : Magnetic Coil (vitesse d'attraction), Singularity (attraction d'XP par gravité), Celestial Eye (rayon d'impulsion).

### Autres reliques — effets proposés, non validés

| Relique | Bonus niveau 5 proposé | Mécanique proposée |
|---|---|---|
| Storm Core | +20 % chance Shock | Décharge proche |
| Infernal Heart | +25 % Burn | Explosion des cibles brûlées |
| Blood Chalice | +5 % lifesteal | Overheal transformé en bouclier |
| Singularity | +25 % contrôle | Dégâts sur groupes |
| Frozen Crown | +25 % Chill | Vulnérabilité des cibles gelées |
| Overdrive Engine | +20 % cadence | Accélération des tirs successifs |
| Celestial Eye | +15 % AoE | Double impact possible |
| Magnetic Coil | +20 % vitesse projectile | Homing léger |
| Plague Mask | +25 % DOT | Propagation à la mort |
| Prism Crystal | +15 % dégâts critiques | Projectile secondaire sur critique |

## Évolutions — effets proposés, non validés

- Infinite Circuit : éclairs ramifiés et Shock.
- Wildfire : Burn contagieux, explosion à la mort.
- Bloodstorm : tempête orbitale de dagues, Bleed et lifesteal.
- Event Horizon : trou noir persistant puis effondrement.
- Absolute Zero : fragmentation des ennemis gelés.
- Redline : cadence croissante en tir continu.
- Starfall : fragments de météores.
- Razorstorm : ricochets et pénétration.
- Pandemic : Poison contagieux et nouveaux nuages.
- Spectrum Collapse : faisceaux secondaires.

## Réactions proposées, non validées

| Réaction | Conditions | Effet |
|---|---|---|
| Thermal Shock | Burn + Freeze | Dégâts immédiats |
| Toxic Ignition | Poison + Burn | Explosion chimique |
| Shatter | Freeze + Impact/Shred | Fragments et dégâts |
| Electroplague | Poison + Shock | Propagation du poison |
| Gravity Collapse | Gravity + Impact | Dégâts de zone accrus |
| Hemorrhage | Bleed + critique | Saignement accéléré |

Overcharge impliquant un éventuel statut Wet/conducteur reste à définir. Synergies proposées : Storm Core/Frozen Crown, Infernal Heart/Plague Mask, Blood Chalice/Overdrive Engine, Singularity/Celestial Eye, Magnetic Coil/Prism Crystal.

## Coffres — décisions validées

- Trois options par coffre, selon son type ; tirage orienté vers améliorations et synergies.
- Anti-malchance, rerolls limités par progression ; quand les slots sont pleins, seulement les upgrades disponibles.
- Gameplay en pause pendant les choix ; vérifier l'évolution après toute acquisition ou amélioration.
- Probabilités, pity exact, récompense de substitution et rerolls chiffrés restent ouverts.

## Ennemis — décisions validées

- 8–12 familles au lancement, mêlée, rapides, tanks, ranged, supports, explosifs.
- Ennemis coopérant via buffs, boucliers, invocations ; élites avec affixes ; tirs télégraphiés et esquivables.

**Proposés, non validés** : Swarmers, Rushers, Bruisers, Spitters, Snipers, Exploders, Shielders, Buffers, Summoners, Phasers ; affixes Armored, Hasted, Volatile, Regenerating, Shielded, Split-on-Death. Threat Director avec budget et règles d'incompatibilité.

## Boss — décisions validées

- Boss vagues 12 et 24 ; 2–3 phases selon HP, patterns bullet-hell lisibles.
- Difficultés supérieures ajoutant mécaniques et patterns ; invocations limitées ; coffres et ressources garantis.

**Proposés, non validés** : Wave 12 « Pulse Warden » (radiaux, charges, invocations, combinaisons) ; Wave 24 « Dopamine Core » (rayons, zones dangereuses, spirales, combinaisons).

## Joueur et survie

- Déplacement précis sans inertie, aucun dash de base ; dash possible par équipement.
- HP decay actif pendant tout le gameplay, transitions et boss compris ; pause réelle suspendant le decay proposée.
- Soin par kills, lifesteal, effets rares ; invulnérabilité de contact brève.
- Formule provisoire inchangée : `HP_decay_per_second = 1.5 + 0.004 * elapsed_gameplay_seconds`.
- Séparer temps de jeu, temps de vague et temps réel.

## Progression, effets et équilibre

- Équipement impactant les builds, effets uniques Legendary/Mythic, synergies arme/statut, respec du skill tree gratuit.
- **Proposé** : ajouter `pickup_radius` au pipeline global de stats avec exclusion absolue des coffres.
- Damage numbers agrégés, critiques visibles, feedback hit/flash/particules/son/hitstop sélectif ; transformation visuelle des armes par niveau ; priorité aux télégraphes ; option VFX réduits ; synthwave/EDM adaptative.
- Toutes les armes viables avec rôles distincts, RNG contrôlé, secrets, synergies et rejouabilité via difficultés/Endless.

## Architecture et roadmap — modifications proposées

- ADR-007 : causalité et réactions élémentaires.
- ADR-014 : Sandbox-first et tests d'armes/DPS/statuts/synergies.
- Nouveaux ADR proposés : 015 Weapon & Relic Framework ; 016 Status & Reaction System ; 017 Loot & Run Progression ; 018 Enemy & Boss Director. Ne pas réutiliser un identifiant existant.

| Phase | Contenu |
|---|---|
| P0 | Fondations techniques |
| P1 | Sandbox minimal |
| P2 | Combat core et statuts |
| P3 | 3 armes, 3 reliques, évolutions et DPS meter |
| P4 | Vertical slice Survival |
| P5 | 10 armes, 11 reliques, évolutions, ennemis |
| P6 | Progression permanente |
| P7 | Endless et Armorless |
| P8 | Sandbox Lab complet |
| P9 | Équilibrage, polish, livraison |

Le Sandbox doit être fonctionnel dès P1 et s'enrichir progressivement.

## Consignes de fusion

1. Lire v1.5 et les ADR existants.
2. Ne fusionner que les ajouts ou modifications, en conservant tout le reste.
3. Priorité aux décisions validées ; **ne pas promouvoir les propositions au rang de décisions**.
4. Mettre à jour le total : 10 armes, 11 reliques, 5 slots de chaque.
5. Appliquer l'exclusion des coffres à toute mécanique de ramassage magnétique.
6. Vérifier les références croisées et signaler les contradictions restantes.
7. Nommer la version documentaire v1.6, sans changer la version du jeu.
