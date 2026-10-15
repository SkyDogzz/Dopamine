# Tests d'acceptation et validation

## Build et intégration

- [x] Linux P0 : Godot 4.7.2 charge la GDExtension C++23 après import headless du projet.
- [x] P1 ciblé : handles index/génération, snapshots immuables, spawn/despawn, kill all, step, pause/reprise, reset et arrêt du worker.
- [ ] Godot 4.7.2 charge la GDExtension sur Windows et Linux.
- [ ] Le projet C++23 compile avec versions verrouillées.
- [ ] Aucune API Godot non thread-safe n'est appelée depuis le worker.
- [ ] `stop()` libère le worker sans deadlock, même sous charge.

## ECS / simulation

- [ ] ID index+génération rejette les handles obsolètes.
- [ ] Spawn/despawn via command buffer ne casse aucun itérateur.
- [ ] Spatial hash trouve les collisions attendues aux frontières des cellules.
- [ ] Swept collision détecte les projectiles rapides.
- [ ] Deltas 1/120, 1/60, 1/30 et pics 100 ms ne causent pas de NaN ni de téléportation non maîtrisée.
- [ ] Timers de statuts exprimés en secondes, indépendants du nombre de frames.
- [ ] Les chaînes d'effets respectent le budget sans perdre silencieusement les événements critiques.

## Communication / rendu

- [ ] Snapshot lu par Godot reste immuable jusqu'à release.
- [ ] Snapshots périmés jetables sans perte d'événements de mort/récompense.
- [ ] IDs/numéros de séquence permettent de dédupliquer les événements.
- [ ] Rendu MultiMesh fonctionne avec 500 ennemis et 2 000 projectiles.
- [ ] 60 FPS cible sur machine de référence ; consigner CPU/GPU, P95/P99.

## Sandbox-first

- [ ] Sandbox démarre sans sauvegarde créée ou chargée.
- [ ] Spawn, kill all, pause, resume, step, speed, reset et logs fonctionnent.
- [ ] Changement live valide est atomique ; changement invalide rollback.
- [ ] DPS meter et inspecteur affichent des métriques cohérentes.
- [ ] Import d'une save produit une copie isolée ; original inchangé.
- [ ] Preset JSON et share code sont validés, versionnés, avec limites de taille.
- [ ] Snapshot complet reprend composants, queues, clocks, RNG et build.
- [ ] Sandbox ne génère ni équipement permanent, ni achievement officiel, ni classement.
- [ ] Caps CPU/mémoire limitent une configuration extrême sans corruption.

## Progression et modes

- [ ] Survival : 24 vagues de 30 s, timer boss en pause, HP decay actif.
- [ ] Une récompense d'équipement permanent par run Survival, y compris défaite.
- [ ] Achievement tiers débloqué une seule fois ; bonus cumulés.
- [ ] Armorless : 3 équipements proposés après chaque vague, 1 choisi ; Flux temporaire.
- [ ] Save JSON atomique, backup et migrations sur fixtures anciennes.
- [ ] Le mode Endless standard reste à finaliser avant ses tests de validation.

## Runner headless (CLI proposée)

```bash
dopamine-sim --scenario benchmark_500_enemies --duration 60 --output results.json
```

Le CLI est une **spécification**, pas un exécutable déjà fourni.
