# Carte des capacités — refonte des interfaces

Cette carte organise l’intention approuvée par interview avant la rédaction des specs par module. Les identifiants sont stables et servent de référence aux specs et au plan d’implémentation.

| Module | Responsabilité | Dépendances |
|---|---|---|
| `ui-foundation` | Thème partagé, composants réutilisables, navigation au focus, adaptation aux résolutions et langage visuel pixel art néon lisible. | — |
| `ui-settings` | Options accessibles depuis le menu et la pause : plein écran et volume général. Les réglages doivent préserver l’état de pause de la run. | `ui-foundation` |
| `launch-navigation` | Écran de lancement, navigation vers le hub ou l’entrée Sandbox discrète, retour à l’accueil et fermeture du jeu. | `ui-foundation`, `ui-settings` |
| `survival-hub` | Sélection Survival/difficulté, accès aux équipements et à l’arbre de compétences avant la run, boutons Succès/Bestiaire inactifs, lancement explicite de run. | `launch-navigation`, `ui-foundation` |
| `survival-hud` | Refonte de l’interface en run : HUD, choix de coffre et écran de résultat, avec hiérarchie lisible et états de run clairs. | `ui-foundation`, `survival-hub` |
| `survival-pause` | Pause/reprise, options, inventaire de run en lecture seule et abandon avec confirmation; la simulation et les horloges restent figées dans les écrans de pause. | `ui-settings`, `survival-hud` |
| `sandbox-ui` | Refonte des écrans du Sandbox développeur existant et de ses contrôles, en conservant son isolation stricte des sauvegardes et de la progression normale. | `ui-foundation`, `ui-settings` |

## Ordre de réalisation proposé

`ui-foundation` → `ui-settings` → `launch-navigation` → `survival-hub` → `survival-hud` → `survival-pause` → `sandbox-ui`.

Cet ordre pose d’abord les conventions visuelles et d’entrée, puis les parcours qui consomment l’état Survival; le Sandbox reste une tranche finale indépendante du système de progression.

## Frontières

- Le Sandbox couvert ici est le Sandbox développeur déjà présent. Le Sandbox Lab joueur de P8 reste hors périmètre fonctionnel de cette refonte.
- Les écrans Succès et Bestiaire existent comme entrées visuelles, sans comportement ni données inventés.
- Les multiplicateurs de difficulté du GDD restent **[PROPOSÉS]**. La progression séquentielle Easy → Normal → Hard → Nightmare → Chaos est **[VALIDÉE]**.
- Toute donnée de run consultée depuis la pause est en lecture seule; équipement permanent et arbre de compétences ne sont pas modifiables pendant une run.
- Aucune capacité Sandbox ne reçoit d’accès à `SaveService` ou à la progression normale.
