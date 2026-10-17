# Suivi du goal — roadmap Dopamine Survivor

Roadmap détaillée et audit GDD/code : [`docs/planning/ROADMAP.md`](../docs/planning/ROADMAP.md). Chaque ligne parente reste un jalon ; les sous-tâches sont des tranches courtes à fermer séparément avec leur vérification. Garder les propositions et questions ouvertes au statut indiqué dans le GDD.

## Terminé (QA historique)

- [x] **P0** Linux/Godot 4.7.2/C++23/GDExtension : build et import headless documentés.
- [x] **P1** Cœur natif, worker, snapshots et Sandbox développeur MVP ; isolation de sauvegarde couverte historiquement.
- [x] **P2 fondation** ECS, spatial hash, steering, projectiles balayés, dégâts, événements et DoT.
- [x] **P3 prototype initial** Trois paires de base et compteur DPS Sandbox prototypés ; dix paires ont maintenant un prototype, selon l’avancement P5.
- [x] **P4 prototype** Parcours Survival 24 vagues, XP, chests, HUD, résultats et boss placeholders.
- [x] Audit statique GDD/code et roadmap détaillée P0–P9 mis à jour.

> Les coches précédentes résument l’implémentation et QA historique, pas une réexécution des tests dans la session courante. Voir `docs/qa/TESTS.md`.

## P5 — Contenu v1.6 (jalon actif)

- [ ] **P5.1 — Compléter les armes, reliques et évolutions**
  - [x] **P5.1.1 — Contrat catalogue :** dix armes, dix reliques associées et Magnet Heart ; références contrôlées au chargement et JSON Schema validé. Les dix paires et Magnet Heart sont disponibles en Survival.
  - Pour chaque nouvelle paire, faire les petites tranches suivantes dans l’ordre :
    - [x] Ajouter les définitions stables arme/relique/évolution et valider les références pour les dix paires.
    - [x] Ajouter les attaques et vérifier le ciblage des dix armes dans Survival/Sandbox.
    - [x] Ajouter les bonus de relique et vérifier leurs cinq niveaux.
    - [x] Ajouter les évolutions et vérifier les deux ordres d’acquisition de la relique.
    - [x] Ajouter le feedback visuel des niveaux et des évolutions.
    - [x] Vérifier chaque paire par smoke avant d’étendre le catalogue.
  - [x] Ajouter un prototype Frost Nova/Frozen Crown/Absolute Zero : Chill natif et shatter borné ; valeurs **[PROPOSÉES]**.
  - [x] Prototyper Void Orb/Singularity/Event Horizon : projectile lent perçant et attraction native ; réglages **[PROPOSÉS]**.
  - [x] Ajouter un prototype Minigun/Overdrive Engine/Redline ; projectile, feedback par niveau et évolution ajoutés ; chiffres de progression et cadence **[PROPOSÉS]**.
  - [x] Ajouter un prototype Toxic Cloud/Plague Mask/Pandemic ; DoT partagé en zone, nuage visuel persistant et propagation bornée à la mort ; les statuts multiples sont pris en charge. Valeurs **[PROPOSÉES]**.
  - [x] Ajouter un prototype Sawblades/Magnetic Coil/Razorstorm ; ricochets natifs vers des cibles non touchées et vitesse de projectile bonus, chiffres **[PROPOSÉS]**.
  - [x] Ajouter un prototype Meteor Staff/Celestial Eye/Starfall ; ciblage de groupe, explosion et fragments, réglages **[PROPOSÉS]**.
  - [x] Prototyper Prism Laser/Prism Crystal/Spectrum Collapse (réglages **[PROPOSÉS]**).
  - [x] Ajouter Magnet Heart comme relique sans évolution ; appliquer le rayon XP **[PROPOSÉ]** et préserver l'exclusion des chests.
  - [x] Magnet Heart attire les orbes XP et son impulsion de niveau 5 ; les soins, ressources, monnaies et bonus temporaires restent **[OUVERTS]** jusqu’à ce que ces pickups soient définis.
  - [x] Vérifier les niveaux 1–5, feedback visuel et règles d’évolution sur les dix paires.
  - [x] Bloodstorm : dagues orbitantes ; smoke des collisions, du saignement et du lifesteal.
  - [x] Vérifier les cinq slots normaux, l’extension proposée à six et le non-cumul d’un même effet unique actif. Les valeurs de capacité restent **[PROPOSÉES]**.
  - [x] Vérifier par smoke Sandbox/Survival les dix paires, niveaux max et évolution avant/après acquisition de relique.

- [ ] **P5.2 — Statuts et synergies**
  - [x] Définir et vérifier application, durée, remplacement, expiration, dégâts directs/DoT, lifesteal et événements de mort sans double attribution.
  - [x] Valider Toxic Ignition et borner sa chaîne ; Thermal Shock reste **[PROPOSÉ]**, les autres réactions nommées attendent arbitrage et Overcharge reste **[OUVERT]**.
  - [x] Vérifier par smokes Sandbox/Survival l’application, l’expiration et les effets en chaîne bornés.
  - [ ] Équilibrer les réactions proposées sur des runs représentatives.

- [ ] **P5.3 — Chests et règles de run**
  - [x] Vérifier trois options uniques, objets max, slots pleins et armes niveau 5 non évoluées.
  - [x] Vérifier pause/reprise et évolution après chaque acquisition/amélioration.
  - [x] Garder probabilités/poids/rerolls proposés configurables tant qu’ils ne sont pas arbitrés ; leur calibration et arbitrage restent ouverts.
  - [x] Ajouter le smoke `pickup_radius` élevé : XP collectée à distance, chest inchangé.
  - [x] Exécuter ce smoke sous Godot 4.7.2 Linux ; XP collectée, coffre toujours hors de portée.
  - [x] Exécuter les smokes ciblés du directeur, du loadout, des chests et de leurs transitions.
  - [ ] Vérifier le choix d’un coffre et les récompenses dans une run complète jouée en interface.

- [ ] **P5.4 — Ennemis et boss**
  - [x] Ajouter les familles mêlée, rapide, distance, soutien, explosif, shielder et summoner ; vérifier les profils et leurs comportements.
  - [x] Compléter le roster à huit familles et couvrir les compositions seedées de vagues.
  - [x] Ajouter les six affixes d’élite proposés avec budget, récompense et limites d’invocation.
  - [x] Implémenter et tester les phases du mid-boss et du boss final, leurs télégraphes et esquives.
  - [x] Ajouter la sélection et le déblocage séquentiel des difficultés ; les multiplicateurs restent **[PROPOSÉS]**.
  - [x] Vérifier par scénarios et smokes les familles, affixes, attaques et transitions de boss.
  - [ ] Calibrer les profils, affixes et patterns sur des runs représentatives.

- [ ] **P5.5 — Validation de sortie**
  - [ ] Parcourir manuellement tout le catalogue dans le Sandbox interactif.
  - [ ] Jouer une run Survival complète avec HP normaux et boss pilotés par le joueur.
  - [x] Exécuter la batterie CTest complète : 86/86 passent en séquentiel sous Godot 4.7.2 le 2026-10-17.
  - [ ] Effectuer un profilage représentatif CPU/GPU et des armes.
  - [ ] Mettre à jour GDD/interfaces/ADR selon les seules décisions confirmées.
  - [ ] Committer le jalon puis poursuivre P6–P9 selon le goal principal actif.

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
