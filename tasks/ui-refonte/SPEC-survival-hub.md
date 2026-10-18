# Spec : `survival-hub`

**Statut : implémentée et livrée.** Difficultés, préparation, panneaux existants et transmission vers Survival sont vérifiés par smokes; Chaos garde les limites [OUVERT] et les multiplicateurs restent [PROPOSÉ].

## Statuts de référence

- **[VALIDÉ]** Survival est le seul mode jouable; le hub propose une action explicite pour lancer une run.
- **[VALIDÉ]** Les difficultés sont Easy, Normal, Hard, Nightmare et Chaos. Easy est débloquée au départ; chacune des suivantes se débloque après une victoire dans la difficulté précédente.
- **[VALIDÉ]** L’équipement permanent et l’arbre de compétences se consultent et se modifient dans le hub avant la run; ils ne sont pas modifiables pendant une run.
- **[VALIDÉ — EXTENSION UTILISATEUR]** Succès ouvre le suivi des achievements avec bonus permanents et préparation Steam; l’ancien Bestiaire devient le Codex consultable depuis le hub, avec ennemis, armes, reliques et combos existants.
- **[VALIDÉ]** L’accueil expose les records; le hub présente les records Armorless locaux des cinq difficultés en lecture seule, sans modifier la progression.
- **[VALIDÉ]** La scène de démarrage est l’accueil; **Jouer** transmet au hub. Le Sandbox reste strictement séparé de la progression normale et de `SaveService`.
- **[PROPOSÉ]** Les entrées visibles mais inactives Succès/Bestiaire gardent un style atténué tout en conservant le focus clavier/manette visible; elles ne sont pas désactivées pour préserver leur atteignabilité.
- **[PROPOSÉ]** Le choix Easy/Normal/Hard/Nightmare/Chaos applique provisoirement les multiplicateurs numériques du GDD, centralisés pour pouvoir être recalibrés. Les chiffres gardent le statut **[PROPOSÉ]** et ne sont pas présentés comme équilibrés ou validés.
- **[PROPOSÉ]** Une nouvelle visite du hub présélectionne Easy; le choix de difficulté n’est mémorisé qu’au lancement de la run.
- **[PROPOSÉ]** Le dernier boss de la vague 24 vaincu constitue la victoire qui débloque la difficulté suivante. Une défaite ou un abandon ne débloque rien.
- **[OUVERT]** Les comportements spéciaux propres à Chaos, leurs règles et leur implémentation; aucun pattern Chaos inédit n’est créé par ce module.

## Multiplicateurs de difficulté — statut inchangé : [PROPOSÉ]

Le GDD propose ces valeurs initiales. La proposition d’implémentation est de les utiliser comme réglage provisoire, sans changer leur statut éditorial ni prétendre à un calibrage final.

| Difficulté | PV ennemis | Dégâts ennemis | Densité | Essence | Powder |
|---|---:|---:|---:|---:|---:|
| Easy | 0,75 | 0,70 | 0,80 | 0,70 | 0,70 |
| Normal | 1,00 | 1,00 | 1,00 | 1,00 | 1,00 |
| Hard | 1,50 | 1,30 | 1,20 | 1,60 | 1,50 |
| Nightmare | 2,20 | 1,70 | 1,50 | 2,50 | 2,30 |
| Chaos | 3,20 | 2,30 | 1,80 | 4,00 | 3,50 |

La victoire sur les boss, l’ordre des difficultés et l’accès progressif sont **[VALIDÉS]**; ces multiplicateurs restent **[PROPOSÉS]** même si la proposition d’usage provisoire est approuvée.

## Objectif

Compléter le parcours **Jouer → préparation Survival → lancement explicite d’une run**. Centraliser dans le hub la sélection de difficulté, les modifications d’équipement permanent et de compétences, puis transmettre les choix au parcours de run normal.

## Codex — extension acceptée

Le Codex est une fenêtre de référence en lecture seule accessible depuis le hub. Les noms/sprites/descriptions d’armes et reliques restent consultables, mais indiquent si l’objet est verrouillé dans le profil; un combo ne révèle l’évolution que si arme et relique sont toutes deux débloquées. Les ennemis restent `INCONNU` sans portrait jusqu’à leur première apparition dans une run Survival ou Endless normale. Les rencontres sont ajoutées au profil normal à la fin de la run; les runs Armorless, temporaires sans sauvegarde et Sandbox n’alimentent pas ce suivi. Les données d’armes/reliques viennent de `combat_catalog.json`; les profils/patterns/chiffres ennemis proposés restent marqués comme tels.

## Succès — extension acceptée

Le bouton Succès ouvre un panneau de progression en lecture seule pour les 100 familles et leurs quatre paliers. Il affiche progression, prochains seuils et bonus permanents obtenus/à obtenir; les familles secrètes restent masquées jusqu’à progression. Les paliers utilisent des identifiants API Steam stables (`DOP_ACH_<FAMILLE>_<PALIER>`) et les récompenses nouvellement obtenues sont retournées par `ProgressionService` pour un futur pont Steamworks. Le SDK Steam et l’App ID ne sont pas encore configurés; les conditions, statistiques et montants des bonus du catalogue restent **[PROPOSÉS]** et à calibrer.

## Périmètre

- Créer le hub Survival comme destination du signal `play_requested` de `launch-navigation`.
- Montrer Survival comme seul mode jouable; ne pas créer de sélection de mode supplémentaire.
- Afficher les cinq difficultés avec leurs états verrouillé/déverrouillé, la prochaine condition de déblocage et la difficulté choisie.
- Persister les déblocages séquentiels dans le profil normal existant et relier la victoire de run à l’octroi du prochain déblocage. Ajouter une migration de profil non destructive si le schéma doit évoluer.
- Réutiliser les panneaux existants d’équipement permanent et d’arbre de compétences dans le hub, en conservant les fonctionnalités déjà présentes de ces panneaux.
- Retirer l’accès de modification à ces panneaux depuis l’interface d’une run; les bonus sélectionnés dans le hub sont chargés au démarrage de la run.
- Afficher Succès et Codex comme panneaux focusables en lecture seule. Les succès lisent `achievement_progress` et le catalogue JSON; le Codex dérive les rencontres et déblocages du profil normal.
- Afficher un accès focusable aux records Armorless par difficulté; la table utilise les données locales existantes et indique les difficultés sans record.
- Ajouter un bouton explicite **Lancer la run** qui utilise la voie Survival normale, passe la difficulté sélectionnée et conserve le choix d’arme initial déjà présenté au début de la session.
- Afficher proprement une erreur de profil indisponible sans créer de nouveau fichier ou profil de secours qui contournerait `SaveService`.
- Préserver les contrôles souris/clavier/manette, l’ordre de focus visible, le thème partagé et la direction pixel art néon.

## Hors périmètre

- Ajouter d’autres modes ou modifier les règles de combat/équilibrage depuis le Codex ou le panneau Succès.
- Modifier le Sandbox, lui donner accès au profil normal, ou partager ses données avec le hub.
- Ajouter des règles spéciales à Chaos pendant que leurs comportements restent **[OUVERTS]**.
- Refaire le HUD en run, les coffres ou les résultats; ces éléments appartiennent à `survival-hud`.
- Ajouter des actions d’Options dans le hub ou toucher au menu de pause.
- Rééquilibrer les ennemis, les vagues, les récompenses, les statistiques d’équipement ou les compétences au-delà du transport des multiplicateurs provisoires explicités dans la présente spec.

## Parcours proposé

1. Depuis l’accueil, **Jouer** ouvre le hub et donne le focus à l’action Survival principale.
2. Easy est sélectionnée par défaut. Une difficulté verrouillée reste visible, explique qu’une victoire dans la difficulté précédente est requise et ne peut pas être sélectionnée.
3. Les panneaux Équipement et Compétences s’ouvrent depuis le hub. Ils utilisent le profil normal et rendent le focus au bouton d’origine à la fermeture.
4. Succès ouvre les 100 familles avec progression, bonus et paliers; CODEX ouvre les entrées ennemis, armes, reliques et combos. Les listes sont parcourables au clavier/manette; Échap ferme le panneau et rend le focus au bouton d’ouverture.
5. **Lancer la run** transmet la difficulté retenue à la session Survival normale. La session applique l’équipement et les bonus de compétence chargés; son choix d’arme initial reste le premier choix de gameplay de la run.
6. Une victoire normale dans la difficulté sélectionnée débloque la difficulté suivante dans le profil. Une défaite ou un abandon ne modifie pas les déblocages.

## Critères d’acceptation

- [x] **Jouer** depuis l’accueil ouvre le hub; la navigation retour vers l’accueil fonctionne et restaure un focus visible.
- [x] Le hub présente Survival comme seul mode jouable et une commande clairement identifiée pour lancer la run.
- [x] Easy est disponible sur un profil neuf; Normal, Hard, Nightmare et Chaos respectent l’ordre séquentiel de déblocage.
- [x] Une victoire sur la difficulté courante débloque uniquement la suivante; défaite, abandon et doublon de récompense ne font pas progresser les déblocages.
- [x] Les déblocages sont persistés dans le profil normal et restaurés après redémarrage; les anciens profils migrent sans perte des données existantes.
- [x] Les multiplicateurs appliqués correspondent à la table GDD provisoire ci-dessus, restent centralisés et sont identifiés **[PROPOSÉS]** dans la documentation/code de tuning.
- [x] Le choix de difficulté atteint la session et la récompense; la session consomme les multiplicateurs pertinents sans modifier les comportements spéciaux encore ouverts de Chaos.
- [x] Les panneaux existants Équipement et Compétences sont utilisables dans le hub; les changements s’appliquent à la run suivante.
- [x] La vue Records Armorless compare les cinq difficultés en lecture seule; Échap/manette ferme le panneau et rend le focus à l’action d’ouverture.
- [x] Pendant une run, aucun contrôle ou chemin UI ne permet de modifier l’équipement permanent ou l’arbre de compétences.
- [x] Succès présente les familles, bonus et paliers, et le Codex présente les objets verrouillés tout en cachant les ennemis non rencontrés. Les deux panneaux sont atteignables au clavier/manette et restituent le focus à la fermeture; l’interaction avec des périphériques physiques reste à essayer.
- [x] L’action **Lancer la run** ouvre le parcours de run normal, transmet la difficulté et conserve le choix d’arme initial.
- [x] Aucune donnée du Sandbox n’est lue/modifiée; aucune dépendance Sandbox → `SaveService` ou progression n’est ajoutée.
- [x] La navigation et les panneaux restent lisibles aux résolutions UI de référence, avec focus visible et sans action nécessitant une souris.

## Vérifications prévues

- Smokes du hub sur profil neuf, profils migrés, difficulté sélectionnée/verrouillée, panneaux et contrat de lancement.
- Tests de progression pour déblocage après victoire, ordre séquentiel, défaite/abandon et octroi idempotent.
- Smoke d’intégration hub → session : difficulté transmise, choix de départ affiché, bonus d’équipement/compétence appliqués.
- Régression des tests Survival de profil, entrée, choix d’arme initial, équipement et arbre de compétences; test Sandbox d’isolation.
- Vérification statique des dépendances et des chemins de sauvegarde : profil normal réservé aux services de progression; Sandbox sans accès.
- Revue fenêtrée et navigation clavier/manette/souris aux tailles déjà utilisées par les autres modules UI; consigner le matériel non disponible.

## Risques et réponses

| Risque | Réponse |
|---|---|
| Les multiplicateurs proposés sont pris pour de l’équilibrage accepté. | Les centraliser, conserver leur statut **[PROPOSÉ]** dans la spec et la documentation de tuning, et éviter d’afficher des valeurs comme garanties de balance. |
| Une migration de profil efface ou remet à zéro une progression. | Étendre le profil de façon non destructive et couvrir les anciennes versions ainsi que les nouvelles sauvegardes par des tests ciblés. |
| Les contrôles d’équipement restent accessibles pendant une run. | Enlever les points d’entrée de l’interface de run et vérifier l’absence de mutation par interaction en run; ne pas se limiter à masquer une fenêtre. |
| La sélection du hub contamine le Sandbox. | Le hub seul reçoit `ProgressionService`; conserver le Sandbox sur sa scène et son contexte actuels sans dépendance de sauvegarde. |
| Chaos invite à inventer des mécaniques. | N’implémenter que les multiplicateurs **[PROPOSÉS]** de la table; garder ses comportements spéciaux **[OUVERTS]**. |

## Critère de sortie

La spec, le plan et les tâches sont exécutés. Les multiplicateurs restent **[PROPOSÉS]** et les règles spéciales Chaos **[OUVERTES]**.
