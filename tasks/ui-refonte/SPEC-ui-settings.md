# Spec : `ui-settings`

**Statut : approuvée par l’utilisateur.** Cette spec suit `ui-foundation` dans la carte approuvée. Le plan détaillé reste à valider avant toute implémentation.

## Statuts de référence

- **[VALIDÉ]** Le menu Options expose le plein écran et le volume général. Il est accessible depuis l’accueil et pendant une run; son ouverture depuis la pause ne fait pas avancer la simulation ni ses horloges.
- **[VALIDÉ]** Les interfaces sont utilisables à la souris, au clavier et à la manette, avec un focus visible.
- **[VALIDÉ]** L’isolation Sandbox/progression normale est stricte; le Sandbox développeur existant reste sans accès à `SaveService` ni à la progression.
- **[PROPOSÉ]** Les préférences sont appliquées immédiatement, conservées entre les lancements dans une configuration utilisateur dédiée, et chargées au démarrage.
- **[PROPOSÉ]** « Plein écran » alterne les modes fenêtre et plein écran exclusif de Godot. Le volume général est un curseur 0–100 %, appliqué au bus Master; 0 coupe le son.
- **[OUVERT]** Courbe de conversion du curseur en décibels, valeur initiale du volume, comportement précis du mode d’affichage selon la plateforme et retour visuel d’une erreur d’application.

## Objectif

Fournir un écran Options réutilisable depuis le menu d’accueil, puis depuis le menu de pause, avec uniquement le réglage de plein écran et le volume général confirmé pour cette tranche.

## Périmètre

- Un écran ou panneau réutilisable attaché au thème `dopamine_ui.tres`.
- Un contrôle de plein écran et un contrôle continu de volume général, avec libellés d’état compréhensibles.
- Application immédiate des changements et restauration de leur état lors du chargement selon le comportement de persistance retenu.
- Navigation au clavier/manette avec focus visible, activation native, et interaction souris.
- Un contrat d’ouverture/fermeture qui laisse le propriétaire de l’écran gérer la navigation. Le panneau Options ne reprend, ne met pas en pause et ne modifie aucune horloge de simulation.
- Configuration de préférences globale distincte des sauvegardes de progression; le Sandbox peut partager les préférences système sans recevoir de dépendance vers `SaveService`, les données de run ou les services de progression.

## Hors périmètre

- Remapping, presets graphiques, taille UI, réduction des flashs, couleurs daltoniens et réglages de nombres de dégâts, même si l’ADR-011 les retient à terme.
- Réglages audio supplémentaires, mixage par bus, contrôles VFX, contrôles de gameplay ou écran d’accessibilité étendu.
- Modification de la simulation, de la sauvegarde de progression ou du comportement pause/reprise de Survival.
- Présenter une configuration globale comme une sauvegarde de progression; aucune donnée de profil ou de run n’y est stockée.

## Hypothèses techniques proposées

1. Utiliser les API natives Godot `DisplayServer` et `AudioServer`, sans plugin ni dépendance externe.
2. Charger les réglages persistants tôt au démarrage pour que le plein écran et le volume soient actifs avant l’affichage du menu.
3. Garder les préférences dans un fichier dédié sous `user://`, séparé du chemin `user://saves` géré par `SaveService`; valider les valeurs lues et retomber sur les défauts en cas de fichier absent ou invalide.
4. Faire du panneau Options un contrôle d’interface sans référence aux scènes Survival, au Sandbox, à `CombatSimulation` ou aux services de progression. L’intégration dans la pause sera vérifiée lors du module `survival-pause`.
5. Réutiliser les contrôles natifs et le thème partagé; ne créer un service singleton que si le chargement au démarrage et le partage entre écrans l’exigent au plan.

## Critères d’acceptation

- [ ] Options montre les deux réglages confirmés, sans commandes ou réglages non implémentés.
- [ ] Le plein écran et le volume général ont un état lisible, changent dès l’interaction et restent synchronisés quand l’écran est rouvert.
- [ ] Les préférences choisies sont restaurées au démarrage si la persistance proposée est validée; fichier absent, illisible ou valeurs hors limites donnent des valeurs par défaut sûres.
- [ ] Le panneau se parcourt à la souris, au clavier et à la manette; le focus initial et le retour vers le propriétaire de navigation sont visibles et cohérents.
- [ ] Le contrôle de volume couvre tout son intervalle, affiche sa valeur et permet le silence à 0 % sans valeur NaN ou infinie transmise à `AudioServer`.
- [ ] L’ouverture et la fermeture du panneau ne manipulent aucun état de simulation. Une intégration depuis une pause maintient simulation et horloges suspendues; cette vérification d’intégration complète est réalisée avec `survival-pause`.
- [ ] Les préférences utilisent un fichier distinct des saves; les tests confirment l’absence d’appel ou de dépendance vers `SaveService` et les services de progression.
- [ ] L’interface utilise le thème partagé, conserve un focus visible et s’adapte au viewport logique existant.

## Vérification prévue

- Smoke ciblé sous Godot headless pour affichage des deux réglages, bornes/validation, application via des doubles ou points d’observation disponibles, persistance et chemins par défaut en cas de configuration invalide.
- Import du projet Godot 4.7.2 et régression des smokes pertinents.
- Revue fenêtrée à 1280×800, 960×600 et 1600×900, puis parcours souris, clavier et manette lorsque le matériel est disponible.
- Essai de pause intégré reporté au checkpoint `survival-pause`; un test isolé du panneau ne prétendra pas prouver que Survival est figé.
- Toute impossibilité d’essai sur matériel réel sera consignée sans être marquée comme réussite.

## Risques et réponses

| Risque | Réponse |
|---|---|
| L’écran Options appelé depuis la pause reprend implicitement la run à sa fermeture. | Garder l’état de pause sous l’autorité de l’écran appelant; le panneau ne reçoit aucune référence à la simulation. Vérifier l’intégration dans `survival-pause`. |
| Les préférences système contaminent les saves Sandbox ou Survival. | Stocker seulement deux préférences système dans un fichier distinct; ne pas utiliser `SaveService` ni les API de progression. |
| Le changement plein écran varie selon la plateforme. | Utiliser le mode natif Godot et consigner les plateformes réellement vérifiées; détails de bascule restent **[OUVERTS]** jusqu’au plan. |

## Critère de sortie

La spec est satisfaite quand son contenu et ses choix proposés/ouvert sont validés, puis décomposés en plan et tâches avant toute modification du code.
