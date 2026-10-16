# Carte des capacités — refonte des interfaces

Cette carte consigne l’intention approuvée par interview et l’état des modules. Les identifiants restent les références stables des specs et plans. Le bilan fonctionnel antérieur est dans [`tasks/ui-refonte/INTEGRATION-ui-refonte.md`](tasks/ui-refonte/INTEGRATION-ui-refonte.md).

Les états « Livré » ci-dessous décrivent la tranche fonctionnelle et visuelle intégrée le 2026-10-16. Une extension d’intention confirmée le même jour demande maintenant de recréer tous les assets visuels existants et manquants et de refaire graphiquement toutes les interfaces selon l’Art Bible; cette nouvelle tranche n’est pas encore implémentée. Son inventaire est dans [`docs/art/INVENTAIRE_ASSETS_UI.md`](docs/art/INVENTAIRE_ASSETS_UI.md).

La direction artistique partagée est décrite dans [`docs/ART_BIBLE.txt`](docs/ART_BIBLE.txt); ses choix **[VALIDÉS]** gouvernent les écrans de cette carte.

| Module | Responsabilité | Dépendances | État |
|---|---|---|---|
| [`ui-foundation`](tasks/ui-refonte/SPEC-ui-foundation.md) | Thème partagé, composants réutilisables, navigation au focus, adaptation aux résolutions et langage visuel pixel art néon lisible. | — | Fondations précédentes livrées; refonte visuelle complète en cours |
| `ui-settings` | Options accessibles depuis le menu et la pause : plein écran et volume général. Les réglages doivent préserver l’état de pause de la run. | `ui-foundation` | Fonctionnel livré; visuel à reprendre |
| [`launch-navigation`](tasks/ui-refonte/SPEC-launch-navigation.md) | Écran de lancement, navigation vers le hub ou l’entrée Sandbox discrète, retour à l’accueil et fermeture du jeu. | `ui-foundation`, `ui-settings` | Fonctionnel livré; visuel à reprendre |
| [`survival-hub`](tasks/ui-refonte/SPEC-survival-hub.md) | Sélection Survival/difficulté, accès aux équipements et à l’arbre de compétences avant la run, boutons Succès/Bestiaire inactifs, lancement explicite de run. | `launch-navigation`, `ui-foundation` | Fonctionnel livré; visuel à reprendre |
| `survival-hud` | Refonte de l’interface en run : HUD, choix de coffre et écran de résultat, avec hiérarchie lisible et états de run clairs. | `ui-foundation`, `survival-hub` | Fonctionnel livré; visuel en cours |
| `survival-pause` | Pause/reprise, options, inventaire de run en lecture seule et abandon avec confirmation; la simulation et les horloges restent figées dans les écrans de pause. | `ui-settings`, `survival-hud` | Fonctionnel livré; visuel à reprendre |
| `sandbox-ui` | Refonte des écrans du Sandbox développeur existant et de ses contrôles, en conservant son isolation stricte des sauvegardes et de la progression normale. | `ui-foundation`, `ui-settings` | Fonctionnel livré; visuel à reprendre |

## Ordre de réalisation

`ui-foundation` → `ui-settings` → `launch-navigation` → `survival-hub` → `survival-hud` → `survival-pause` → `sandbox-ui`.

Cet ordre pose d’abord les conventions visuelles et d’entrée, puis les parcours qui consomment l’état Survival; le Sandbox reste une tranche finale indépendante du système de progression.

## Frontières

- Le Sandbox couvert ici est le Sandbox développeur déjà présent. Le Sandbox Lab joueur de P8 reste hors périmètre fonctionnel de cette refonte.
- Les écrans Succès et Bestiaire existent comme entrées visuelles, sans comportement ni données inventés.
- Les multiplicateurs de difficulté du GDD restent **[PROPOSÉS]**. La progression séquentielle Easy → Normal → Hard → Nightmare → Chaos est **[VALIDÉE]**.
- Toute donnée de run consultée depuis la pause est en lecture seule; équipement permanent et arbre de compétences ne sont pas modifiables pendant une run.
- Aucune capacité Sandbox ne reçoit d’accès à `SaveService` ou à la progression normale.
