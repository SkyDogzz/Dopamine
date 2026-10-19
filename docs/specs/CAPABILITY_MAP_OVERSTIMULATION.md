# Carte de capacités — Overstimulation

**Statut : [PROPOSÉ] — à valider avant les specs et l’implémentation.**

Objectif : donner à Survival une identité volontairement intense et généreuse. Le rythme, les combats, les récompenses et la présentation audiovisuelle doivent créer des pics mémorables, des retours fréquents et une montée perceptible, sans rendre les menaces illisibles. L’intensité élevée est la présentation par défaut; les réglages d’accessibilité existants restent respectés.

| Module | Responsabilité | Dépend de |
|---|---|---|
| `encounter-rhythm` | Faire varier le tempo et la composition pendant la run : respirations courtes, montées, vagues de pression et événements de combat identifiables. | — |
| `combat-payoffs` | Donner des retours rapprochés et satisfaisants aux éliminations, séries, niveaux, coffres et synergies; relier les actions du joueur aux pics de récompense. | `encounter-rhythm` |
| `sensory-feedback` | Accorder les impacts, morts, pickups, télégraphes, caméra et effets aux événements de combat, avec une hiérarchie visuelle lisible et les contrôles d’intensité nécessaires. | `encounter-rhythm`, `combat-payoffs` |
| `reactive-audio` | Faire réagir les SFX et les couches musicales aux événements et à l’intensité réelle du combat. | `encounter-rhythm`, `combat-payoffs` |

**Ordre proposé :** `encounter-rhythm` → `combat-payoffs` → `sensory-feedback` et `reactive-audio`.

**Limites de conception proposées :** rester dans l’architecture Sandbox-first et ne jamais faire progresser la sauvegarde normale depuis le Sandbox; conserver les options de réduction des effets; différencier visuellement récompenses, dégâts reçus et dangers; préserver le contrôle du joueur pendant les pics.

**Critère global proposé :** une run ne doit plus donner l’impression que seules les stats et la densité changent. Chaque tranche de jeu doit comporter des variations perceptibles de tempo, des occasions de payoff rapprochées et une présentation sonore/visuelle qui réagit à ce que le joueur fait et affronte.

**Hors de cette carte :** aucun chiffre de fréquence, d’intensité, de durée, de multiplicateur ou de récompense n’est validé. Les valeurs actuelles restent des prototypes jusqu’à spécification et calibration.
