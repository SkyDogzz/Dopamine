# Spec: `interface-overhaul` — Refonte complète de l’interface

## Objectif

Refaire visuellement tous les écrans et composants UI existants dans le style arcade pixel sobre de l’Art Bible, avec des parcours plus lisibles sans changer les règles validées des écrans existants. Inclut les écrans de menu, options, hub, Survival, overlays, résultats, progression, équipement et Sandbox développeur.

## Stack et emplacement

Godot 4.7.2, GDScript, scènes `Control`, Theme sous `game/themes/`, écrans et scripts sous `game/scenes/` et `game/scripts/`. Respecter ADR-011 et `docs/architecture/ARCHITECTURE.md`.

## Commandes de vérification

- `godot --headless --editor --path game --quit`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/ui_foundation_smoke.gd`
- `tools/run_godot_test.sh godot --headless --path game --script res://tests/ui_viewport_layout_smoke.gd`
- Lancer les smokes d’écran existants ou adaptés pour les parcours touchés; tester aux viewports logiques 640×360 et rendus 1280×720 / 1920×1080.

## Structure et contrats

- Réutiliser des composants Godot `Control`; prendre en charge souris, clavier et manette dès le hub.
- Navigation, actions, focus visible, options, sauvegardes et transitions existants restent fonctionnels.
- L’UI Sandbox reste dans son contexte isolé et n’accède pas au service de progression normale.
- Préserver la pause stricte, l’inventaire de run en lecture seule et les parcours de résultat.
- Les écrans détaillés arbre de compétences et équipement sont définis dans leurs spécifications dédiées.

## Style et règles de code

Pixel arcade sobre : panneaux opaques bordés, boutons rectangulaires, titres pixel et textes lisibles, transitions rapides, cibles interactives accessibles, focus clavier/manette visible. Le glow UI est rendu dynamiquement. Garder les chaînes textuelles localisables et les scènes/scripts simples.

GDScript utilise des noms `snake_case`, des types explicites pour les références de nœuds importantes et des signaux pour séparer la présentation des actions de service, selon les scènes UI existantes.

## Stratégie de vérification

Smokes de fondation et de parcours, bornes de layout aux viewports ciblés, navigation synthétique souris/clavier/manette, revue de captures pour chaque écran et états (normal, focus, désactivé, erreur, confirmations). Une revue visuelle explicite reste nécessaire.

## Limites

- Toujours respecter ADR-011 et la séparation Sandbox/progression.
- Toujours préserver les actions validées des écrans, sauf extensions explicitement décrites dans des specs dédiées.
- Arbitrage requis pour les points ouverts de navigation, typographie et accessibilité lorsqu’ils bloquent le wireframe final.
- Ne jamais activer de lien Succès/Bestiaire sans fonctionnalité correspondante ni rendre accessible la progression depuis le Sandbox.

## Critères de réussite

- Tous les écrans réellement utilisés ont été refaits et les outils de prévisualisation sont distingués des écrans livrés.
- Aucun parcours ni état interactif validé n’est perdu; souris, clavier et manette sont utilisables avec focus visible.
- Layouts sans débordement aux tailles cibles, captures revues et smokes ciblés passés.
- L’isolation Sandbox est couverte par une vérification dédiée.

## Questions ouvertes

Arbitrer les fontes exactes, tailles/espacements et navigation manette détaillée lorsqu’ils empêchent le dessin final; préserver les choix confirmés et propositions existantes comme tels.

## Avancement (2026-10-18)

- **[PROPOSÉ]** L’accueil, les options, le hub, plusieurs overlays Survival, le résultat, l’inventaire de run et l’interface Sandbox ont déjà été retouchés à travers des tranches précédentes; les fondations/theme, tailles ciblées et parcours sont couverts par les smokes existants. Le graphe de compétences (`15a9071`) et l’écran de loadout six slots (`5eadb12`) complètent les deux vues dédiées.
- **[VALIDÉ]** L’écran Sandbox reste isolé de la progression normale; ses smokes et ceux de l’accueil/hub, de la pause et des vues de run protègent les parcours concernés.
- **[OUVERT]** La preuve visuelle finale de chaque écran/état aux viewports cibles, la revue du focus de toutes les actions et l’essai avec appareils physiques ne sont pas encore exhaustifs. Cette capacité reste en cours jusqu’à leur consignation; les changements de style précédents ne suffisent pas seuls à la marquer terminée.
- **[PROPOSÉ]** Deux fontes originales remplacent les fichiers tiers retirés : `NeonArcadePixel` pour les titres/valeurs de dégâts et `NeonArcadeUI` pour le texte courant. Sources FontForge conservées et smoke de glyphes/intégration passé. La lisibilité est visible dans les captures indexées dans `docs/art/evidence/2026-10-18/`, mais choix final et tailles restent **[OUVERTS]** jusqu’à revue complète écran par écran.
- **[VALIDÉ — LISIBILITÉ CIBLÉE, 2026-10-18]** L’utilisateur confirme que le texte courant et les labels pixel sont lisibles à taille normale dans les captures 640×360 du hub et de l’équipement. Cela ne valide pas encore la direction typographique finale ni toutes les vues/états; la revue globale reste **[OUVERTE]**.
- **[VALIDÉ — LAYOUT SANDBOX LAB, 2026-10-18]** Le Sandbox Lab adopte une page défilante à 640×360 afin de conserver simulation et commandes principales à l’écran tout en gardant toutes les sections accessibles. La session Survival cachée masque son `CanvasLayer` HUD et désactive sa caméra, qui autrement décalait le canvas global. `sandbox_lab_layout_smoke.gd` contrôle les viewports 640×360, 1280×720 et 1920×1080; capture revue dans `docs/art/evidence/2026-10-18/states/sandbox-lab.png`. Cette vérification virtualisée ne couvre pas les périphériques physiques.
- **[VALIDÉ — FOCUS SANDBOX LAB, 2026-10-18]** Le focus initial est placé sur `PAUSE` avec le cadre Neon visible; `sandbox_lab_smoke.gd` vérifie son déplacement par clavier et D-pad. Cela ne remplace pas l’essai avec un contrôleur physique.
- **[VALIDÉ — FOCUS SANDBOX DÉVELOPPEUR, 2026-10-18]** La capture `states/sandbox.png` montre le cadre focus sur `ACCUEIL`; `sandbox_ui_smoke.gd` vérifie le déplacement vers `PLAY SURVIVAL` au clavier et retour au D-pad. L’essai sur contrôleur physique reste **[OUVERT]**.
- **[VALIDÉ — ÉTATS VISUELS SUPPLÉMENTAIRES, 2026-10-18]** La suite `ui_states_evidence_smoke.gd` produit 11 captures 640×360, dont focus de pause, confirmation d’abandon et profils indisponibles pour équipement/arbre; chaque image a été inspectée et son hash est indexé dans le README de preuves. La revue de toutes les branches interactives reste **[OUVERTE]**.
- **[VALIDÉ — SURVIVAL ET HUD BOSS, 2026-10-18]** Les smokes d’entrée et HUD produisent aussi des captures 640×360 du choix d’arme initial, du HUD actif et du HUD boss. Leur revue a révélé que le libellé boss utilisait la police par défaut et se superposait au HUD HP; il est maintenant compact, cyan, avec barre magenta et placé sous les panneaux de coin. Une capture combinée confirme qu’il ne recouvre pas le feedback jaune d’acquisition d’objet; les smokes contrôlent le style, l’absence de chevauchement et les bornes de viewport. Hashes dans le README de preuves. La revue d’autres états et la validation sur matériel restent **[OUVERTES]**.
