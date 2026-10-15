# Roadmap — Sandbox-first (révisée)

**Décision acceptée :** le Sandbox est le premier environnement interactif après les fondations. Les estimations et jalons ci-dessous sont **proposés** et non contractuels.

| Phase | Objectif | Critère de sortie |
|---|---|---|
| P0 | Godot 4.7.2, GDExtension, C++23, monorepo, CI, schémas JSON | Build Linux et appel C++ depuis Godot ; validation Windows avant livraison multi-plateforme |
| P1 | **Developer Sandbox MVP** : spawn, despawn, pause, step, vitesse, métriques, logs, reset | Simuler des entités sans Survival et exporter métriques |
| P2 | Combat Core : ECS, AI, spatial hash, collisions, dégâts, HP | 500 ennemis + 2 000 projectiles dans benchmark reproductible ; vérifier 60 FPS |
| P3 | Sandbox Combat : éditeur de stats, armes, god mode, DPS meter, inspecteur | Tester une arme et son DPS sans jouer une run |

| P4 | Survival : 24 vagues, boss, XP, chests, 3 armes/reliques | Une run complète jouable |
| P5 | Progression : gear, Powder, Essence, skill tree, achievements, saves | Persistance sûre sur plusieurs runs |
| P6 | Endless et Armorless : Flux, draft temporaire, scaling | Modes utilisant le même combat core |
| P7 | Sandbox Lab joueur complet : presets, share codes, snapshots, isolation, UI | Accessible sans save ; aucune progression normale altérée |
| P8 | Contenu complet, balance, accessibilité, Steam, optimisation | Régressions vertes et cible perf atteinte |

P5 progress status (2026-10-15): proposed equipment ranges now produce visible values and all twelve equipped stat lines affect Survival; rarity-based proposed dismantle yields are live. Four Powder tiers, enhancement, effect-choice prototype, two proposed skill nodes with respec, and cumulative Exterminator prototype tiers are implemented. The six unique effects remain inert; sale was deferred by the prototype proposal; the 120-entry skill/achievement catalogs are not authored or playable. P5 is **not complete**. Do not begin P6 until these gaps and the GDD's open economy/content contracts are resolved.

P3 groundwork: the shared simulation core, developer Sandbox UI, and JSON scenarios can apply and verify one configurable damage-over-time status per selected entity. Inferno Sprayer and the level-5 Bloodstorm evolution use the same core status and apply the GDD-proposed reduced lifesteal rate. Infinite Circuit branches lightning from its level-5 initial targets, and level-5 Wildfire adds a proposed area explosion that spreads burn to nearby enemies. Evolution tuning remains proposed; other weapon-specific evolution effects remain future work.

## Sandbox MVP — spécification minimum

- Scène de simulation vide et lancement direct depuis menu développeur.
- Spawn/despawn par type, nombre et position ; kill all.
- Pause, resume, step d'une **durée explicite** (ex. 1/60 s), speed ×0.25 à ×4.
- Inspecteur d'entité : ID/génération, composants, position, HP, vitesse.
- Overlay FPS, frame time, temps simulation, collisions, entités, projectiles.
- Variables runtime HP/dégâts/vitesse/spawn modifiables via transactions.
- Reset/restart sans redémarrer Godot ; logs horodatés d'événements.
- Scénarios headless JSON exécutables sans UI et export de métriques.

## Definition of Done transversale

- Chaque nouveau système dispose d'un scénario Sandbox, d'un test automatisé et de métriques.
- Aucune modification du gameplay ne requiert d'attendre une vague pour être testée.
- Les changements live ne laissent jamais une configuration partiellement appliquée.
- Les erreurs de thread, migrations et crashs sont enregistrés sans bloquer le rendu.
- Le Sandbox développeur et le Sandbox joueur partagent les APIs, mais pas les permissions.

## Jalons techniques critiques

- **P0** : prouver la compatibilité Godot 4.7.2 ↔ godot-cpp et toolchain C++23.
- **P1** : garantir l'isolation thread principal/worker, la commande Step et le stop propre.
- **P2** : mesurer CPU/GPU, P95/P99, tester les grands deltas et swept collisions.
- **P4** : valider les contrats joueur/boss ↔ ECS et la progression par événements.
- **P7** : tester les snapshots complets et la reprise, ainsi que la séparation des saves.

## Priorités d'implémentation retenues

- Le développement et la première validation se font sous Linux ; la livraison Windows prévue par ADR-013 reste inchangée.
- Le Sandbox développeur P1 est le premier environnement jouable, avant le mode Survival complet, conformément à ADR-014.
- La validation accompagne chaque étape ; la batterie complète intervient aux grandes avancées, pas après chaque petite implémentation.
