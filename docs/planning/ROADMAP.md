# Roadmap de Dopamine Survivor — GDD v1.6

Cette roadmap traduit le GDD consolidé [v1.6](../gdd/GDD_v1.6.md) en jalons vérifiables. Les règles marquées **[VALIDÉ]** sont des contrats de conception ; les paramètres **[PROPOSÉ]** restent configurables et ne deviennent pas des décisions par leur implémentation ; les sujets **[OUVERT]** doivent être arbitrés avant d'en dépendre. Les numéros P0–P9 reprennent le découpage du delta v1.6.

**Séquence confirmée :** Linux-first ; Sandbox développeur MVP dès P1 ; mode Survival jouable en P4 ; extension de contenu P5 ; progression permanente P6. Le Sandbox et Survival partagent le cœur de simulation, avec permissions et sauvegardes séparées. La fin de P5 est le prochain grand arrêt demandé ; P6 et les phases suivantes restent planifiées et ne sont pas engagées ici.

## État global vérifié

| Phase | État | Vérification disponible / écart restant |
|---|---|---|
| P0 — Fondations | **Terminé sous Linux** | QA documente Godot 4.7.2, C++23, GDExtension et build. Build Windows restant. |
| P1 — Sandbox minimal | **Terminé** | Scénarios et tests Sandbox documentés, y compris pause, step, vitesse, reset, inspection, métriques, logs et isolation des saves. |
| P2 — Combat core/statuts | **Partiellement terminé** | ECS, spatial hash, projectiles, DoT et HP decay testés. Familles d'ennemis, comportements et cible de performance iGPU restent à compléter/mesurer. |
| P3 — Prototype armes/reliques | **Prototype livré, critères incomplets** | Trois armes/reliques et trois évolutions partiellement implémentées ; DPS Sandbox disponible. Réactions de statut générales, contrats complets et couverture de comportement restent à faire. |
| P4 — Vertical slice Survival | **Prototype jouable livré, validation d'équilibrage incomplète** | Traversée QA des 24 vagues et placeholders boss ; run intégrée accélérée documentée. Patterns boss, difficulté équilibrée, sauvegarde/récompense finale complète et contenu final restent ouverts. |
| P5 — Contenu v1.6 | **Non commencé comme jalon de contenu** | Il reste à livrer 10 armes, 11 reliques, évolutions et 8–12 familles d'ennemis. Les trois paires actuelles sont une base P3. |
| P6 — Progression permanente | **Prototype anticipé, jalon incomplet** | Code de progression existe déjà (équipement, enhancement, deux nodes, Exterminator prototype) ; plusieurs valeurs restent proposées, contenu incomplet, et quelques effets uniques n'ont pas de gameplay. Ne pas confondre avec P5 v1.6. |
| P7 — Endless et Armorless | **À faire** | Armorless a des règles validées et des paramètres proposés ; Endless standard conserve des règles [OUVERTES]. |
| P8 — Sandbox Lab complet | **À faire** | Presets, codes de partage et snapshots/reprise complets restent à livrer ; le Sandbox développeur P1 est déjà utilisable. |
| P9 — Équilibrage et livraison | **À faire** | Mesures iGPU réelles, build Windows, tuning, accessibilité, longues sessions et préparation release. |

## P0 — Fondations techniques

**Objectif :** rendre le dépôt reproductible sous Linux avant l'extension du gameplay.

- [x] Projet Godot 4.7.2, extension C++, standard C++23 et dépendance `godot-cpp` verrouillée.
- [x] Cœur natif sans dépendance Godot, CMake et build Linux documentés.
- [x] Vérifier l'import Godot headless et le chargement de l'extension.
- [ ] Vérifier périodiquement versions/disponibilité des outils sur un environnement Linux propre.
- [ ] Valider le build et chargement Windows (ADR-013).
- [ ] Documenter CI/builds reproductibles multiplateformes si la voie de livraison l'exige.

**Sortie :** build Linux propre + smoke d'intégration ; build Windows avant livraison Windows.

## P1 — Sandbox développeur minimal

**Objectif :** premier environnement interactif, lançable sans save et avant Survival.

- [x] Spawn/despawn, kill all, pause/reprise, step à durée explicite, contrôle de vitesse et reset.
- [x] Inspecteur d'entité, métriques, logs et scénarios headless JSON avec export.
- [x] Transactions de configuration atomiques ; limites de ressources et arrêt propre du worker.
- [x] Vérifier que le Sandbox ne lit ni n'altère les sauvegardes Survival.
- [ ] Maintenir chaque nouveau comportement de combat accessible et observable dans le Sandbox.

**Sortie :** critères MVP satisfaits sous Godot, sans progression normale ni sauvegarde nécessaire.

## P2 — Combat core et statuts

**Objectif :** règles de simulation réutilisables et contrôlables dans Sandbox.

- [x] ECS, handles sûrs, snapshots, spatial hash et requêtes de proximité.
- [x] Mouvement de poursuite/séparation, projectiles rapides, collisions balayées, dégâts et événements de mort acquittables.
- [x] DoT générique, HP decay et soins proposés par menace avec horloge simulée.
- [ ] Ajouter des comportements distincts d'ennemis et clarifier les interfaces joueur/boss ↔ simulation.
- [ ] Définir les statuts nécessaires aux armes v1.6 ; les réactions élémentaires restent **[PROPOSÉES]** jusqu'à validation de leurs contrats et de l'ADR-007.
- [ ] Ajouter budgets/causalité anti-boucles pour chaînes, explosions, statuts et réactions (ADR-007/015/016 à examiner, sans créer de décisions implicites).
- [ ] Tester grands deltas, expirations, statuts concurrents, événements et scénarios Sandbox reproductibles.
- [ ] Mesurer CPU/GPU et P95/P99 sur matériel représentatif ; les benchmarks natifs existants ne prouvent pas seuls 60 FPS iGPU.

**Sortie :** statuts et effets reproductibles, plafonnés, inspectables et couverts par scénarios.

## P3 — Prototype trois armes, reliques, évolutions et DPS

**Objectif :** éprouver les contrats de combat et le flux de test avant l'extension du catalogue.

- [x] Prototypes Lightning Conductor, Inferno Sprayer, Crimson Daggers et Storm Core, Infernal Heart, Blood Chalice.
- [x] Infinite Circuit, Wildfire et Bloodstorm ont des comportements de prototype ; les valeurs sont **[PROPOSÉES]**.
- [x] DPS Sandbox agrégé à partir des événements de dégâts.
- [ ] Formaliser définitions data-driven, ciblage, niveaux 1–5, plafonds, unicité et résolutions d'évolution.
- [ ] Compléter instrumentation DPS par source/arme/statut/critique si nécessaire aux tests d'équilibre.
- [ ] Étendre scénarios Sandbox aux dégâts, statuts, évolutions, effets combinés et absence de réaction indésirable.
- [ ] Modifier ADR-014 pour couvrir explicitement armes/DPS/statuts/synergies ; examiner ADR-015 Weapon & Relic Framework et ADR-016 Status & Reaction System comme propositions.

**Sortie :** trois paires traversent les parcours Sandbox et Survival sans divergence du cœur partagé ; effets et mesures vérifiables.

## P4 — Vertical slice Survival

**Objectif :** run classique complète de 24 vagues utilisant le combat core.

- [x] Déplacement joueur, HP decay, soins, XP, HUD, progression automatique d'XP prototype.
- [x] Directeur 24 vagues de 30 s, événements de boss vagues 12/24 et transitions de fin.
- [x] Drops, collecte de coffres, choix parmi trois options et application au loadout.
- [x] Trois armes/reliques et évolution prototypes dans le flux de run.
- [x] Scénario QA d'une run accélérée et run aux durées nominales simulées ; boss placeholders et HP joueur augmentés dans le harness pour isoler les transitions.
- [ ] Implémenter patterns de boss lisibles en 2–3 phases ; noms et patterns précis restent **[PROPOSÉS]**, phases et boss aux vagues 12/24 **[VALIDÉS]**.
- [ ] Vérifier les choix sans récompense disponible, pauses de chest et évolution automatique à chaque acquisition/amélioration.
- [ ] Compléter et valider le contrat de récompense permanente par run sans donner accès aux saves depuis Sandbox.
- [ ] Séparer/contrôler les horloges gameplay, vague et temps réel ; suspendre decay pendant les vraies pauses, y compris choix de chest.
- [ ] Parcours de jeu normal sans harness : vérifier survie, progression, victoire/défaite et reprise des contrôles.

**Sortie :** une run classique jouable bout en bout ; le harness QA n'est pas présenté comme preuve d'équilibrage.

## P5 — Contenu v1.6 : dix armes, onze reliques, ennemis

**Objectif :** compléter le contenu de combat initial conforme aux décisions v1.6. Les comportements décrits comme validés fixent l'identité ; chiffres de progression, patterns nommés et effets de reliques demeurent proposés tant qu'ils ne sont pas validés.

### Armes et reliques

- [ ] Livrer 10 armes distinctes avec ciblage adapté au comportement et influence notable du positionnement.
- [ ] Compléter les sept armes au-delà des trois prototypes : Void Orb, Frost Nova, Minigun, Meteor Staff, Sawblades, Toxic Cloud et Prism Laser (sept nouvelles armes).
- [ ] Livrer 11 reliques : dix associées aux armes et Magnet Heart utilitaire sans paire d'évolution ; conserver cinq slots normaux (huit reliques supplémentaires par rapport aux trois prototypes actuels).
- [ ] Implémenter progression visuelle à chacun des cinq niveaux d'arme, et transformation visuelle majeure de l'évolution.
- [ ] Une évolution unique automatique par arme au niveau 5 si la relique associée est possédée à n'importe quel niveau ; conserver le niveau 5.
- [ ] Exclure l'arme niveau 5 non évoluée du pool de ses améliorations ordinaires ; aucun doublon en run normale, doublons autorisés dans Sandbox.
- [ ] Respecter limites de capacité d'équipement v1.5 et exceptions Legendary/Mythic seulement si leur effet est actif et applicable.
- [ ] Ajouter Magnet Heart au pool normal de reliques, sans arme associée, et respecter ses bonus globaux de ramassage.
- [ ] Invariant obligatoire : aucun effet de rayon de ramassage (relique, équipement, skill tree, bonus temporaire) n'attire ni ne collecte les coffres. Les coffres restent ramassés par déplacement. Vérifier les orbes XP et autres collectibles éligibles indépendamment.
- [ ] Tables de progression des armes dans le GDD annexe restent **[PROPOSÉES]** ; ne pas les verrouiller comme équilibre accepté.

### Statuts, synergies, coffre

- [ ] Éprouver interactions émergentes via dégâts/statuts et réactions élémentaires proposées (Thermal Shock, Toxic Ignition, Shatter, Electroplague, Gravity Collapse, Hemorrhage) après décision de leurs contrats ; Overcharge reste **[OUVERT]**. Le GDD dit à la fois que les réactions entre statuts sont validées et que les exemples nommés sont proposés : préciser ce niveau de contrat avant implémentation globale.
- [ ] Garder budgets/identifiants d'événement/idempotence pour empêcher cascades infinies sans limiter artificiellement les synergies.
- [ ] Appliquer les trois choix, anti-malchance, disponibilité lorsque slots pleins, pause, rerolls limités issus de progression et vérification d'évolution après chaque récompense.
- [ ] Garder poids, pity, nombre de rerolls et récompense de substitution **[OUVERTS]** ou configurables tant que non arbitrés.

### Ennemis et boss

- [ ] Livrer entre 8 et 12 familles au lancement couvrant mêlée, rapides, tank, distance, soutien et explosifs ; interactions buffs/protection/invocations ; élites à affixes ; projectiles télégraphiés et esquivables.
- [ ] Les dix archétypes exemples, six affixes et Threat Director du GDD restent **[PROPOSÉS]** : sélectionner/valider un catalogue avant de les déclarer contractuels.
- [ ] Boss lisibles de 2–3 phases, difficulté supérieure ajoutant patterns/mécaniques, invocations sous budget et présence aux vagues 12/24.
- [ ] Les noms Pulse Warden/Dopamine Core et leurs patterns restent **[PROPOSÉS]**.
- [ ] Ajouter assets, effets, sons et tests d'accessibilité visuelle pour télégraphes et projectiles.

### Vérification et sortie P5

- [ ] Scénarios Sandbox par famille d'arme, ciblage et positionnement, mesures DPS, niveaux 1–5, évolution, cumul de statuts, interactions et cas limites.
- [ ] Tests de coffre : unicité, armes/reliques niveau max, slots pleins, Magnet Heart n'attire jamais les coffres, pause et évolution automatique.
- [ ] Tests d'ennemis : affixes compatibles, buffs/protection/summons bornés, projectiles télégraphiés esquivables et boss en phases.
- [ ] Une run complète Survival utilise le contenu de release P5 sans harness de progression forcé ; assurer performance représentative.
- [ ] Batterie complète et revue des documents/ADR au checkpoint P5.

**Sortie :** dix armes, onze reliques, évolutions et 8–12 familles de créatures prêtes selon le GDD ; invariants du coffre et du Sandbox vérifiés. Après cette sortie, s'arrêter avant P6 conformément à la consigne de portée actuelle.

## P6 — Progression permanente

**État :** un prototype a été développé en avance sur l'ordre des phases. Il ne vaut pas fermeture du jalon ; les exemples et valeurs de `PROPOSITION_P5.md` restent **[PROPOSÉ]**.

- [ ] Finaliser les six slots, rarités, une pièce garantie par run classique et les plages de rolls selon arbitrages v1.5/v1.6.
- [ ] Valider application des 12 lignes de stat et effets globaux, notamment l'exclusion absolue des coffres pour `pickup_radius`.
- [ ] Finaliser Powder, conversions, coûts/probabilités enhancement, démantèlement/vente et reroll d'effet après résolution des sujets **[OUVERTS]**.
- [ ] Définir et livrer le graphe 100–150 nodes (cible éditoriale ~120), prérequis, déblocages, effets et respec gratuit ; répartitions et coût proposés non verrouillés.
- [ ] Définir et livrer 100–150 familles d'achievements (cible ~120), quatre tiers, métriques, secrets et récompenses persistantes idempotentes.
- [ ] Activer ou retirer proprement les six effets uniques ; les effets sans contrat (reroll chest, résurrection) restent sans effet de gameplay jusqu'à définition des systèmes requis.
- [ ] Migrations versionnées, reprise, atomicité et non double-attribution ; vérifier isolation Sandbox.
- [ ] Mesurer puissance cumulée par builds de référence et ajuster sans changer silencieusement les valeurs **[PROPOSÉES]**.

**Sortie :** progression complète, persistante, migrable et validée à travers runs ; aucune interaction avec Sandbox.

## P7 — Endless standard et Armorless

- [ ] Armorless : aucun équipement permanent actif ; skill tree/achievements actifs ; draft de trois après chaque vague, choix d'un ; objets temporaires ; Flux temporaire ; bosses toutes les 12 vagues. Règles de mode **[VALIDÉES]**.
- [ ] Implémenter les transitions, pause/draft, inventaire temporaire, enhancements Flux, mort/victoire et destruction de Flux.
- [ ] Garder raretés/scaling/Flux proposés configurables ; arbitrer récompenses persistantes Armorless, records et sauvegarde/reprise.
- [ ] Endless standard : résoudre d'abord les règles **[OUVERTES]** d'accès, sortie, progression et récompenses ; ne pas supposer la poursuite après la vague 24.
- [ ] Tests longue durée, scaling, budgets d'ennemis/projectiles et idempotence des récompenses.

**Sortie :** Armorless conforme aux décisions retenues ; Endless standard seulement après arbitrages documentés.

## P8 — Sandbox Lab complet

Le Sandbox développeur est livré dès P1 ; cette phase ajoute les capacités destinées au joueur.

- [ ] Presets bornés/versionnés et codes de partage, JSON validé, charge utile limitée, sans exécution de script ou chemin arbitraire.
- [ ] Build initial libre et overrides live transactionnels selon les contrats du GDD.
- [ ] Import de save uniquement en copie isolée Normal → Sandbox, original inchangé.
- [ ] Snapshot complet/restauration incluant simulation, RNG, horloges, commandes et build ; reprise déterministe.
- [ ] UI et outils requis : spawn, kill all, god mode, DPS, vitesse, logs et commandes ; hard caps.
- [ ] Tests bit-à-bit d'isolation ; aucune Essence/Powder, progression/achievement officiel ou classement produit.

**Sortie :** joueur peut expérimenter sans sauvegarde normale et sans fuite de progression.

## P9 — Équilibrage, polish et livraison

- [ ] Valider viabilité et rôles des dix armes, RNG anti-malchance, builds dominants et synergies.
- [ ] Calibrer HP decay/soins/lifesteal, raretés, loot, économies et progression selon décisions acceptées.
- [ ] VFX/audio adaptatifs, chiffres de dégâts agrégés/critiques visibles, télégraphes lisibles et option de réduction des VFX.
- [ ] Accessibilité, clavier/flèches/manette, UI, lisibilité et options.
- [ ] Mesurer 60 FPS sur GPU intégré de référence et consigner CPU/GPU/P95/P99 ; effectuer soak tests et tests de stabilité.
- [ ] Build Linux et Windows propre, migration de save, sauvegarde/reprise et régression complète.
- [ ] Préparer livraison premium/Steam seulement après la validation QA.

**Sortie :** critères de performance, qualité, contenu et plateforme mesurés et documentés.

## ADR et dépendances documentaires

- ADR-007 : examiner l'ajout des réactions élémentaires et de la causalité ; conserver le statut ACCEPTÉ et écrire une proposition de changement avant toute révision.
- ADR-014 : compléter la stratégie de tests Sandbox-first pour armes, DPS, statuts et synergies ; ne pas changer son orientation ACCEPTÉE.
- ADR-015 Weapon & Relic Framework, ADR-016 Status & Reaction System, ADR-017 Loot & Run Progression, ADR-018 Enemy & Boss Director : propositions de nouveaux ADR seulement. Lire les ADR existants et créer ces décisions lorsque la conception est prête ; ne pas inventer leur statut.

## Contradictions et points à surveiller

- Le maximum de cinq reliques normales (v1.5) et le total de 11 reliques (v1.6) décrivent respectivement la capacité équipée et le catalogue total : conserver cette distinction.
- La règle v1.5 autorise certains effets Legendary/Mythic à étendre les capacités à six ; garder cette exception, sans qu'elle contredise cinq slots de base v1.6.
- La règle de collecte v1.6 exclut toujours les coffres, quelle que soit la source du bonus `pickup_radius` ; c'est un invariant système.
- Les nombres d'armes/reliques au stade P3 désignent le vertical slice ; les dix armes et onze reliques sont la cible P5.
- Les patterns détaillés des boss, chiffres d'armes/reliques, familles et affixes exemples, réactions et synergies sont encore **[PROPOSÉS]** ou **[OUVERTS]** selon le GDD.

## Méthode de validation

Tests ciblés pour chaque tranche logique ; batterie plus large aux jalons P3/P4/P5/P6/P7/P8/P9. Les tests ne sont indiqués comme exécutés que lorsqu'une exécution réelle est documentée. Commit explicite à chaque tranche cohérente et push sur `origin` conformément à `AGENTS.md`.
