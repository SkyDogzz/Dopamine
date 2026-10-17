# Checklist de livraison

État de préparation fondé sur le dépôt au 2026-10-17. Ce document suit les critères P9.8 sans déclarer le jeu prêt à publier. Les statuts de conception restent ceux du GDD : **[VALIDÉ]**, **[PROPOSÉ]**, **[OUVERT]**.

## Identité et artefacts

- [x] Produit Godot identifié comme `Dopamine Survivor`; moteur ciblé Godot 4.7.2 stable, natif C++23 et `godot-cpp` verrouillé à `b8530af7546a3fcae80cef2477526569fd42ffc2`.
- [x] Une exportation locale Linux/X11 x86_64 existe et démarre le menu puis une run Survival; le binaire et la GDExtension côte à côte démarrent aussi après relocation locale. Les limites sont consignées dans [`../qa/TESTS.md`](../qa/TESTS.md).
- [ ] **[OUVERT]** Fixer la version du jeu et la convention de version des artefacts. `game/project.godot` ne définit actuellement aucune `config/version`; ne pas déduire une version de release du numéro de Godot ni d’un hash Git.
- [ ] Construire depuis un checkout propre reproductible pour chaque plateforme de release; distinguer les exports vérifiés localement des artefacts réellement distribuables.
- [ ] Pour chaque artefact retenu, consigner plateforme/architecture, commit source, versions de Godot/templates/toolchain, commandes, taille et SHA-256.
- [x] Vérifier le paquet Linux non versionné de staging (exécutable, GDExtension, notices, licences référencées, extraction et démarrage headless); les sommes et limites sont dans [`../qa/TESTS.md`](../qa/TESTS.md). Ce paquet est explicitement non distribuable.
- [x] Automatiser et exécuter `tools/package_linux_staging.sh` depuis le snapshot propre `c318888`; compilation Release CMake vierge, inventaire, notices, extraction, SHA-256 et démarrage sont consignés dans la QA. La version commerciale reste **[OUVERTE]**.
- [x] Refaire la reconstruction complète depuis `379b9aad23bb9d6284722b485e2f094fd5d7c15d`; archive `DopamineSurvivor-linux-379b9aa-staging.tar.gz` (31 966 641 octets), SHA-256 `bbfb3f2d20ecd143005c588c7d1419c54e5c48cd3a434a181a7279094e73790c`, extraction et démarrage headless de l’exécutable avec sa GDExtension Release vérifiés. Détails dans [`../qa/TESTS.md`](../qa/TESTS.md); toujours non distribuable.
- [x] Refaire la reconstruction complète depuis `f80690965b76b8d58c033b1c36a71af98ecccf88`; archive `DopamineSurvivor-linux-f806909-staging.tar.gz` (31 968 166 octets), SHA-256 `f2da78adb6398e82f4547441d57f19d919935966e21840cfc2f90195ffe6edc9`, extraction, vérification des bibliothèques et démarrage headless avec sa GDExtension Release vérifiés. Détails dans [`../qa/TESTS.md`](../qa/TESTS.md); toujours non distribuable.
- [x] Refaire la reconstruction complète depuis `7b20dd485f1078bce51531839554d0e6b9fadfc9`; archive `DopamineSurvivor-linux-7b20dd4-staging.tar.gz` (31 974 354 octets), SHA-256 `c4530505fe31fbe2bfa9122c3a37aa5f9ff290ede7814c562b35d19563b83393`, extraction, dépendances et démarrage headless avec GDExtension Release vérifiés. Le paquet inclut Endless standard dans le Sandbox Lab; il reste non distribuable.
- [x] Refaire le staging depuis `78f37e46d3773307d822dfe89f808cc3575b4e70`; archive `DopamineSurvivor-linux-78f37e4-staging.tar.gz` (31 977 842 octets), SHA-256 `4616c25c2cae69b1e0db9ad118b1c60ed2a0823fe3544f904e630d3e1b792bfc`, extraction, bibliothèques et démarrage headless avec GDExtension Release vérifiés. Inclut le sprite prototype du Pulse Warden; toujours non distribuable.
- [x] Refaire le staging depuis `8d91079560020a140b3a48cb6189fb7da909ec91`; archive `DopamineSurvivor-linux-8d91079-staging.tar.gz` (31 988 718 octets), SHA-256 `d6430957e88c72e3b89f87802ac87836341eb65fdad225a9bbdeaf7123888faa`, extraction, bibliothèques, notices et démarrage headless avec GDExtension Release vérifiés. Inclut le correctif des compteurs de continuation Endless; toujours non distribuable.
- [x] Renforcer le vérificateur d’archive : après extraction, exiger les exécutables et notices référencées et refuser les ressources de développement. Vérifié par un staging propre depuis `fa64298`, archive `DopamineSurvivor-linux-fa64298-staging.tar.gz` (31 977 821 octets), SHA-256 `8bcf9259bd6f987840f76afd6577607d39c97d7ecbd028aaa7382eeb5d21985c`; les détails figurent dans [`../qa/TESTS.md`](../qa/TESTS.md). Cette validation n’en fait pas une release distribuable.
- [x] Rebuild propre depuis `adefcc9` avec compilation Release vierge, export, extraction, contrôle des bibliothèques/notices et démarrage headless : `DopamineSurvivor-linux-adefcc9-staging.tar.gz` (31 979 129 octets), SHA-256 `b57429acb8e802711714093298fd2f8e12244bc21dd5b4f529a10e25c9f899a9`. Toujours non versionné et non distribuable; voir [`../qa/TESTS.md`](../qa/TESTS.md).

## Contenu et critères d’acceptation

- [ ] Faire l’audit final de contenu contre les critères du GDD v1.6 et de la roadmap P5–P9; les prototypes présents ne prouvent pas à eux seuls que les jalons de contenu, calibration et run complète sont achevés.
- [x] Vérifications automatisées de stabilité et d’isolation Sandbox consignées : CTest Linux 91/91 (instantané du 2026-10-17), soak Survival/Sandbox et empreintes des sauvegardes normales; une capture Windows séparée rapporte 108/108 CTest sous MSVC/Godot 4.7.2. Les dates et limites de chaque preuve sont dans [`../qa/TESTS.md`](../qa/TESTS.md).
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
- P9.7 — plateformes : export Linux x86_64 vérifié sur l’hôte de développement; build Windows Debug, GDExtension et run Easy complète vérifiés sur le PC Windows du créateur. Export Windows Release après extraction, machine Linux distincte, périphériques physiques et rendu matériel cible restent ouverts.
- P9.8 — staging Linux filtré reconstruit depuis `65ed8d0`; contenu extrait, dépendances et démarrage vérifiés (SHA-256 `e7a6dd0f9e4947babb6ec20c800a0a213aab9bbce6b193670da2934cc0b6a99d`). Version d’artefact, audit de provenance des assets/audio, validation des sauvegardes, autres plateformes et notes de version restent ouverts. Détails dans [`../qa/TESTS.md`](../qa/TESTS.md).
