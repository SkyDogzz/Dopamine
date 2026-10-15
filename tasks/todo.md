# Suivi du goal — roadmap Dopamine Survivor

Roadmap détaillée et audit GDD/code : [`docs/planning/ROADMAP.md`](../docs/planning/ROADMAP.md). Chaque ligne parente reste un jalon ; les sous-tâches sont des tranches courtes à fermer séparément avec leur vérification. Garder les propositions et questions ouvertes au statut indiqué dans le GDD.

## Terminé (QA historique)

- [x] **P0** Linux/Godot 4.7.2/C++23/GDExtension : build et import headless documentés.
- [x] **P1** Cœur natif, worker, snapshots et Sandbox développeur MVP ; isolation de sauvegarde couverte historiquement.
- [x] **P2 fondation** ECS, spatial hash, steering, projectiles balayés, dégâts, événements et DoT.
- [x] **P3 prototype** Trois armes/reliques/évolutions et compteur DPS Sandbox prototypés.
- [x] **P4 prototype** Parcours Survival 24 vagues, XP, chests, HUD, résultats et boss placeholders.
- [x] Audit statique GDD/code et roadmap détaillée P0–P9 mis à jour.

> Les coches précédentes résument l’implémentation et QA historique, pas une réexécution des tests dans la session courante. Voir `docs/qa/TESTS.md`.

## P5 — Contenu v1.6 (jalon actif)

- [ ] **P5.1 — Compléter les armes, reliques et évolutions**
  - [x] **P5.1.1 — Contrat catalogue :** définitions des dix armes, dix reliques associées et Magnet Heart ; relations contrôlées au chargement ; cinq paires prototypées et Magnet Heart sont disponibles en Survival. JSON Schema reste à intégrer.
  - Pour chaque nouvelle paire, faire les petites tranches suivantes dans l’ordre :
    - [ ] Ajouter les définitions stables arme/relique/évolution et valider les références.
    - [ ] Ajouter uniquement l’attaque de base de l’arme et vérifier son ciblage Sandbox.
    - [ ] Ajouter l’effet de relique et vérifier chacun de ses niveaux.
    - [ ] Ajouter l’évolution et tester avant/après acquisition de la relique.
    - [ ] Ajouter le feedback visuel des niveaux et de l’évolution.
    - [ ] Faire le smoke de cette paire avant de commencer la suivante.
  - [ ] Ajouter une définition de données Void Orb/Singularity/Event Horizon.
  - [ ] Ajouter Frost Nova/Frozen Crown/Absolute Zero.
  - [x] Ajouter un prototype Minigun/Overdrive Engine/Redline ; chiffres de progression et cadence **[PROPOSÉS]**, projectile propre ajouté ; feedback par niveau/évolution encore à faire.
  - [x] Ajouter un prototype Toxic Cloud/Plague Mask/Pandemic ; DoT partagé en zone et propagation bornée à la mort ; le nuage visuel persistant et les statuts multiples restent à faire, valeurs **[PROPOSÉES]**.
  - [ ] Ajouter Meteor Staff/Celestial Eye/Starfall.
  - [ ] Ajouter Sawblades/Magnetic Coil/Razorstorm.
  - [ ] Ajouter Toxic Cloud/Plague Mask/Pandemic.
  - [ ] Ajouter Prism Laser/Prism Crystal/Spectrum Collapse.
  - [x] Ajouter Magnet Heart comme relique sans évolution ; appliquer le rayon XP **[PROPOSÉ]** et préserver l'exclusion des chests.
  - [ ] Étendre Magnet Heart aux autres collectibles et à l'impulsion **[PROPOSÉE]** de niveau 5.
  - [ ] Vérifier les niveaux 1–5, feedback visuel et règles d’évolution sur une paire à la fois.
  - [ ] Corriger Bloodstorm : dagues orbitantes, puis smoke collisions/saignement/lifesteal.
  - [ ] Vérifier les cinq slots normaux et les exceptions de capacité par effet unique actif.
  - **Vérifier :** smoke Sandbox pour chaque paire, niveaux max, évolution avant/après acquisition de relique.

- [ ] **P5.2 — Statuts et synergies**
  - [ ] Définir durée, cumul/remplacement et expiration des statuts utilisés par le catalogue.
  - [ ] Vérifier dégâts directs, DoT, lifesteal et événements de mort sans double attribution.
  - [ ] Garder les réactions nommées désactivées jusqu’à validation ; Overcharge reste **[OUVERT]**.
  - **Vérifier :** scénarios Sandbox d’application, expiration et effets en chaîne bornés.

- [ ] **P5.3 — Chests et règles de run**
  - [ ] Vérifier trois options uniques, objets max, slots pleins et armes niveau 5 non évoluées.
  - [ ] Vérifier pause/reprise et évolution après chaque acquisition/amélioration.
  - [ ] Garder probabilités/poids/rerolls proposés configurables tant qu’ils ne sont pas arbitrés.
  - [x] Ajouter le smoke `pickup_radius` élevé : XP collectée à distance, chest inchangé.
  - [x] Exécuter ce smoke sous Godot 4.7.2 Linux ; XP collectée, coffre toujours hors de portée.
  - **Vérifier :** smoke chest ciblé puis test de run.

- [ ] **P5.4 — Ennemis et boss**
  - [ ] Ajouter une famille mêlée distincte et smoke spawn/déplacement/mort.
  - [ ] Ajouter une famille rapide et smoke son contre-jeu.
  - [ ] Ajouter une famille distance et projectile télégraphié esquivable.
  - [ ] Ajouter soutien puis explosif comme deux comportements séparés.
  - [ ] Compléter jusqu’à 8–12 familles et couvrir les compositions de vagues.
  - [ ] Ajouter un affixe d’élite avec budget et récompense, puis étendre le catalogue.
  - [ ] Implémenter une phase de mid-boss à la fois, puis boss final à phases.
  - [ ] Ajouter sélection/déblocage séquentiel des difficultés ; conserver multiplicateurs proposés.
  - **Vérifier :** scénario par famille/affixe, esquive des projectiles et transitions de boss.

- [ ] **P5.5 — Validation de sortie**
  - [ ] Parcourir tout le catalogue dans Sandbox sans harness qui choisit les résultats.
  - [ ] Jouer une run Survival complète avec HP normaux et boss pilotés par le joueur.
  - [ ] Exécuter la batterie QA P5 et profilage représentatif.
  - [ ] Mettre à jour GDD/interfaces/ADR selon les seules décisions confirmées.
  - [ ] Committer le jalon puis s’arrêter avant P6.

## P6 — Progression permanente (prototype anticipé, non terminée)

- [ ] **P6.1 — Équipement**
  - [ ] Vérifier chacun des six slots, remplacement et lignes sans doublon.
  - [ ] Vérifier une pièce garantie après victoire et défaite classique.
  - [ ] Ajouter rolls selon difficulté/vague/mort précoce après décision des valeurs.
- [ ] **P6.2 — Statistiques et effets uniques**
  - [ ] Vérifier HP, vitesse, dégâts, cadence, critique, soin, aire, cooldown, XP et vitesse projectile.
  - [ ] Vérifier bonus de pickup sur XP, jamais sur chest.
  - [ ] Relier chaque effet unique à un déclencheur ou le retirer des choix actifs.
- [ ] **P6.3 — Powder/enhancement**
  - [ ] Vérifier chaque tier, conversion 10:1 et niveaux +0 à +10.
  - [ ] Couvrir échec critique et garantie à la dixième tentative.
  - [ ] Arbitrer vente/démantèlement, reroll et anti-exploit avant verrouillage.
- [ ] **P6.4 — Skill tree**
  - [ ] Valider schéma d’un node et ses prérequis/coût/effet.
  - [ ] Étendre par petites branches vers 100–150 nodes.
  - [ ] Vérifier bonus, achats et respec gratuit.
- [ ] **P6.5 — Achievements**
  - [ ] Valider schéma d’une famille et quatre paliers.
  - [ ] Étendre par catégories vers 100–150 familles.
  - [ ] Vérifier attribution idempotente et budget de bonus.
- [ ] **P6.6 — Saves et calibration**
  - [ ] Tester fixtures de migration, backup et restauration après corruption.
  - [ ] Vérifier absence de double récompense après redémarrage.
  - [ ] Mesurer plusieurs builds/difficultés et retoucher uniquement les valeurs arbitrées.

## P7 — Endless / Armorless

- [ ] **Armorless — règles et contexte**
  - [ ] Ajouter le contexte de mode sans équipement permanent.
  - [ ] Vérifier skill tree et achievements actifs.
  - [ ] Ajouter une transition après une vague vers l’écran de draft.
- [ ] **Armorless — draft temporaire**
  - [ ] Générer trois équipements temporaires.
  - [ ] Appliquer un choix et reprendre la simulation.
  - [ ] Vérifier que l’équipement temporaire est supprimé en fin de run.
- [ ] **Armorless — Flux et vague**
  - [ ] Ajouter solde Flux temporaire.
  - [ ] Améliorer une ligne puis vérifier coûts/plafond +10.
  - [ ] Ajouter boss toutes les 12 vagues et pause de timer.
  - [ ] Vérifier HP decay et budget de densité sur une session longue.
- [ ] **Armorless — récompenses**
  - [ ] Faire arbitrer les récompenses persistantes avant de les créditer.
  - [ ] Tester absence d’équipement permanent garanti tant que la règle reste ouverte.
- [ ] **Endless standard — décision avant code**
  - [ ] Décider déblocage et entrée depuis le menu.
  - [ ] Décider continuation après Survival et conservation du build/HP.
  - [ ] Décider difficulté, sortie, records, boss et récompenses.
- **Vérifier :** une vague, un boss, un draft, une amélioration et un test de longue durée.

## P8 — Sandbox Lab joueur

- [ ] **P8.1 — Entrée isolée**
  - [ ] Ajouter l’entrée Sandbox au menu principal.
  - [ ] Vérifier qu’elle démarre sans créer/lire le profil normal.
- [ ] **P8.2 — Build et overrides**
  - [ ] Ajouter la sélection d’une arme/relique/niveau au build initial.
  - [ ] Implémenter une commande LIVE et vérifier son application.
  - [ ] Implémenter une commande REBUILD puis une RESTART, chacune testée séparément.
- [ ] **P8.3 — Presets et partage**
  - [ ] Ajouter export/import JSON versionné.
  - [ ] Rejeter les JSON trop grands et champs inconnus.
  - [ ] Ajouter code de partage avec checksum et tester un code altéré.
- [ ] **P8.4 — Import de save en copie**
  - [ ] Charger un profil en lecture seule.
  - [ ] Construire sa copie modifiable dans Sandbox.
  - [ ] Comparer le profil source avant/après import.
- [ ] **P8.5 — Outils et snapshots**
  - [ ] Ajouter god mode, spawn, kill all et commandes de vague séparément.
  - [ ] Ajouter logs et DPS par source.
  - [ ] Capturer puis restaurer horloges, RNG, queues, config et build.
- [ ] **P8.6 — Caps et séparation**
  - [ ] Mesurer une commande extrême et fixer une limite.
  - [ ] Tester preset invalide sans effet secondaire.
  - [ ] Vérifier absence de récompense, succès officiel, classement et écriture de save.
- **Vérifier :** tests sentinelles prouvent absence de récompense, succès, classement et écriture de save.

## P9 — Équilibrage et livraison

- [ ] **P9.1 — Équilibrage**
  - [ ] Mesurer une arme à la fois avec la même scène et le même build.
  - [ ] Comparer armes de base puis évolutions.
  - [ ] Mesurer durée et fréquence des chests sur un build courant.
  - [ ] Calibrer soin/decay/lifesteal/XP/économie par difficulté.
- [ ] **P9.2 — Présentation/commandes**
  - [ ] Vérifier feedback d’un dégât direct et d’un critique.
  - [ ] Vérifier lisibilité d’un télégraphe lorsque l’écran est chargé.
  - [ ] Vérifier options audio/VFX et réduction d’effets.
  - [ ] Parcourir les menus clavier/flèches puis manette avec focus visible.
- [ ] **P9.3 — Performance/stabilité**
  - [ ] Choisir iGPU et scène de charge de référence.
  - [ ] Mesurer CPU/GPU/mémoire et P50/P95/P99.
  - [ ] Faire un soak test Sandbox puis un soak test Survival.
  - [ ] Tester fermeture worker et reprise après interruption de save.
- [ ] **P9.4 — Livraison**
  - [ ] Refaire build/import/lancement Linux sur checkout propre.
  - [ ] Refaire build/import/lancement Windows sur checkout propre.
  - [ ] Vérifier licences/dépendances puis rédiger notes de version.
  - [ ] Compléter la checklist release avant toute publication.
- **Vérifier :** joindre configuration, résultats et dates aux rapports QA de release.
