# Suivi du goal

## Phase 0 — Fondations Linux

- [x] Projet Godot 4.7.2 + GDExtension C++23 créé.
- [x] `godot-cpp` verrouillé au commit `b8530af7546a3fcae80cef2477526569fd42ffc2`.
- [x] CMake compile et Godot charge l’extension via import headless puis lancement headless.

## Phase 1 — Cœur partagé

- [ ] Modèle ECS minimal et tests ciblés.
- [ ] Worker, file de commandes et snapshots cohérents.
- [ ] Contrat natif documenté.

## Phase 2 — Sandbox développeur MVP

- [ ] Contrôles de simulation et spawn/despawn.
- [ ] Inspecteur, métriques et logs.
- [ ] Runner headless, export et isolation des saves.

## Phase 3 — Combat core

- [ ] Mouvement, ennemis, spatial hash, projectiles et dégâts.
- [ ] HP decay, soins et règles de combat testables dans le Sandbox.

## Phase 4 — Premier playable Survival

- [ ] Vagues, XP, chests, 3 armes/reliques, mid-boss et boss final.
- [ ] HUD, fin de run, sauvegarde minimale et vérification QA complète.
