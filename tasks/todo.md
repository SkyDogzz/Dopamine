# Suivi du goal

## Phase 0 — Fondations Linux

- [x] Projet Godot 4.7.2 + GDExtension C++23 créé.
- [x] `godot-cpp` verrouillé au commit `b8530af7546a3fcae80cef2477526569fd42ffc2`.
- [x] CMake compile et Godot charge l’extension via import headless puis lancement headless.

## Phase 1 — Cœur partagé

- [x] Modèle ECS minimal (Transform2D, Velocity2D, Health, EnemyType) et test ciblé.
- [x] Worker, file de commandes, pause/reprise/step et snapshots immuables.
- [x] Contrat natif documenté et pont GDExtension smoke-testé.

## Phase 2 — Sandbox développeur MVP

- [x] Contrôles de simulation et spawn/despawn.
- [x] Inspecteur, métriques et logs.
- [x] Runner headless, export JSON des métriques et absence d’accès aux saves normales.

## Phase 3 — Combat core

- [ ] Mouvement, ennemis, spatial hash, projectiles et dégâts.
- [x] Spatial hash uniforme minimal avec requête de rayon native ; paramètres de cellule à profiler.
- [ ] HP decay, soins et règles de combat testables dans le Sandbox.

## Phase 4 — Premier playable Survival

- [ ] Vagues, XP, chests, 3 armes/reliques, mid-boss et boss final.
- [ ] HUD, fin de run, sauvegarde minimale et vérification QA complète.
