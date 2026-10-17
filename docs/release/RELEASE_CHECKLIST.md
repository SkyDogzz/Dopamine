# Checklist de livraison

État de préparation fondé sur le dépôt au 2026-10-17. Ce document suit les critères P9.8 sans déclarer le jeu prêt à publier. Les statuts de conception restent ceux du GDD : **[VALIDÉ]**, **[PROPOSÉ]**, **[OUVERT]**.

## Identité et artefacts

- [x] Produit Godot identifié comme `Dopamine Survivor`; moteur ciblé Godot 4.7.2 stable, natif C++23 et `godot-cpp` verrouillé à `b8530af7546a3fcae80cef2477526569fd42ffc2`.
- [x] Une exportation locale Linux/X11 x86_64 existe et démarre le menu puis une run Survival; le binaire et la GDExtension côte à côte démarrent aussi après relocation locale. Les limites sont consignées dans [`../qa/TESTS.md`](../qa/TESTS.md).
- [ ] **[OUVERT]** Fixer la version du jeu et la convention de version des artefacts. `game/project.godot` ne définit actuellement aucune `config/version`; ne pas déduire une version de release du numéro de Godot ni d’un hash Git.
- [ ] Construire depuis un checkout propre reproductible pour chaque plateforme de release; distinguer les exports vérifiés localement des artefacts réellement distribuables.
- [ ] Pour chaque artefact retenu, consigner plateforme/architecture, commit source, versions de Godot/templates/toolchain, commandes, taille et SHA-256.
- [x] Vérifier le paquet Linux non versionné de staging (exécutable, GDExtension, notices, licences référencées, extraction et démarrage headless); les sommes et limites sont dans [`../qa/TESTS.md`](../qa/TESTS.md). Ce paquet est explicitement non distribuable.
- [x] Refaire un paquet staging filtré depuis le snapshot propre `c90a2c6`; compilation Release CMake vierge, inventaire du contenu, notices, extraction et démarrage avec profil Godot vierge sont consignés dans la QA. La version commerciale reste **[OUVERTE]**.

## Contenu et critères d’acceptation

- [ ] Faire l’audit final de contenu contre les critères du GDD v1.6 et de la roadmap P5–P9; les prototypes présents ne prouvent pas à eux seuls que les jalons de contenu, calibration et run complète sont achevés.
- [x] Vérifications automatisées de stabilité et d’isolation Sandbox consignées : CTest 91/91 sur le checkout courant, soak Survival/Sandbox et fingerprints des sauvegardes normales. Les limites de cette preuve sont dans [`../qa/TESTS.md`](../qa/TESTS.md).
- [ ] Vérifier sur une installation de release la création, migration, backup et restauration des sauvegardes, puis confirmer qu’une partie temporaire/Sandbox ne modifie aucune sauvegarde normale.
- [ ] Parcourir le jeu exporté à la souris, au clavier et à la manette sur chaque plateforme retenue; vérifier focus, lisibilité, rendu et sortie audio sur matériel.
- [x] Relire le contenu du staging Linux `c90a2c6` : journal d’export avec scènes, scripts, données, polices, sprites, audio et extension; les ressources `tests/`, `tools/` et `assets/source/` sont exclues. La portée et les limites sont consignées dans [`../qa/TESTS.md`](../qa/TESTS.md).

## Dépendances, licences et provenance

- [x] Inventaire de départ disponible dans [`../../THIRD_PARTY_NOTICES.md`](../../THIRD_PARTY_NOTICES.md) : Godot/godot-cpp et polices embarquées y sont identifiés; textes de licences des polices conservés dans `game/assets/fonts/`.
- [x] Archives d’informations de copyright et de licences Godot 4.7.2 disponibles dans `licenses/`.
- [x] Comparer les deux archives Godot au retour du template Linux release 4.7.2 : 102 composants et 19 textes correspondent exactement; la méthode et la portée Linux seule sont consignées dans [`../../THIRD_PARTY_NOTICES.md`](../../THIRD_PARTY_NOTICES.md).
- [x] Inclure les notices et textes de polices/Godot dans le paquet Linux de staging, en conservant les chemins référencés.
- [ ] Répéter la comparaison pour chaque autre template distribué et inclure ses notices dans le paquet versionné correspondant.
- [x] Faire un contrôle mécanique des sources d’image : les 136 PNG avec correspondance de base et les trois exceptions hors du dossier de références sont décrits dans [`../art/INVENTAIRE_ASSETS_UI.md`](../art/INVENTAIRE_ASSETS_UI.md) et [`../art/asset_exceptions.txt`](../art/asset_exceptions.txt).
- [ ] Vérifier la provenance et les droits de chaque asset livré, y compris les fichiers générés, les sources éditables et toute attribution requise; les inventaires artistiques ne valent pas clearance complète.
- [ ] **[OUVERT]** Confirmer avec le responsable audio l’inventaire, la provenance et les notices des sons effectivement livrés. Ne pas considérer les fichiers de prévisualisation ou les recettes de génération comme preuve que le mix du jeu est terminé.

## Distribution et communication

- [ ] Préparer un paquet autonome par plateforme avec exécutable, GDExtension et notices requises; vérifier son démarrage depuis un répertoire fraîchement extrait.
- [ ] Produire les sommes de contrôle et conserver les artefacts correspondant au commit de release.
- [ ] Rédiger les notes de version depuis les changements livrés, avec les prérequis, contrôles et emplacement des sauvegardes.
- [ ] Ne publier qu’après résolution des critères de livraison requis et revue finale des preuves. Aucune publication n’est effectuée par cette checklist.

## État connu

- P9.6 — stabilité/sauvegardes : cochée dans la roadmap, avec limite explicite pour l’interruption réelle au niveau système de fichiers.
- P9.7 — plateformes : export Linux x86_64 et parcours logiciel vérifiés sur l’hôte courant; validation machine propre, matériel réel et Windows restent ouvertes.
- P9.8 — staging Linux filtré reconstruit depuis `c90a2c6` et démarré après extraction; version d’artefact, audit de provenance des assets/audio, validation des sauvegardes, autres plateformes et notes de version restent ouverts.
