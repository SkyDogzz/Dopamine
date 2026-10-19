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

## Banque d’idées à trier — [PROPOSÉ]

Ces idées sont des pistes de design uniquement. Aucune n’est sélectionnée, validée ou planifiée pour implémentation.

### Réponses aux actions du joueur

- Secousse brève à l’impact d’une arme lourde; réponse plus marquée contre un élite ou un boss.
- Série d’éliminations avec compteur de combo, effets et son qui montent par paliers.
- Dernier ennemi d’un groupe : micro-pause d’impact, flash de couleur et effet sonore distinct à sa mort.
- Coup critique : dégâts agrandis, couleur dédiée, son percutant et légère secousse.
- Montée de niveau mise en scène par une très courte suspension, une onde autour du joueur, une fanfare et une révélation du choix.
- Ramassage groupé d’XP : trajectoires qui convergent en accélérant et compteur qui s’emballe à l’approche d’un niveau.
- Élite vaincu : effet lié à son affixe, récompenses projetées et annonce brève de l’ennemi éliminé.
- Synergie d’armes : effet de convergence, symbole ou nom bref au déclenchement d’une combo.

### Réponses aux actions ennemies

- Charge de boss : tension visuelle/sonore pendant le télégraphe, puis forte secousse à l’impact; conserver une fenêtre d’esquive lisible.
- Menace proche : contour, couleur ou signal sonore directionnel qui varie avec le danger.
- Dégâts reçus : bordure orientée vers l’attaque, son distinct et réaction du joueur, renforcés à bas PV.
- Densité de menaces élevée : musique plus dense et rythme plus nerveux, puis relâchement après le pic.

### Récompenses et événements

- Coffre rare : ouverture en plusieurs temps, rayon lumineux, révélation de l’objet et accent sonore selon la rareté.
- Compétence prête : halo ou icône pulsante, suivi d’un retour visuel et sonore à l’activation.

### Secousses d’écran

- Réserver les secousses aux événements marquants comme les impacts lourds, grosses éliminations et attaques de boss; calibrer séparément leur durée et leur amplitude.
- Garder la lecture des menaces et le confort visuel comme contraintes à vérifier quand ces pistes seront triées.

### Autres pistes à trier

- Finisher spectaculaire quand un ennemi passe sous un seuil de vie.
- Esquive au dernier instant récompensée par un bref ralenti, un cue sonore et une possibilité de contre-attaque.
- Zone à risque qui charge une attaque ou augmente les gains tant que le joueur y reste.
- Arène réactive après un pic d’éliminations : lumière au sol ou onde visuelle.
- Surchauffe d’arme : maintenir le tir charge une attaque plus puissante avec une montée audiovisuelle.
- Déclenchement automatique périodique de l’effet le plus spectaculaire d’une arme ou relique.
- Vague surprise annoncée avec mutation temporaire et récompense dédiée.
- Bonus rare qui traverse l’écran et demande au joueur de se déplacer pour l’attraper.
- Survie à très bas PV récompensée par une courte poussée de puissance.
- Explosion de mort de boss qui élimine ou repousse les ennemis proches.
- Jauge de style nourrie par déplacements, esquives, éliminations et combos, qui améliore le prochain coffre.
- Signature de feedback propre à chaque arme pour ses impacts, éliminations et synergies.
- Entrée de boss théâtrale avec annonce sonore et changement visuel bref, sans longue perte de contrôle.
- Présentation en rafale des niveaux gagnés simultanément.
- Coupure momentanée de certains sons avant un impact majeur pour renforcer le contraste.
- Variantes de patterns de boss qui combinent ou densifient des attaques déjà rencontrées.
- Traînées et sons de vitesse déclenchés par déplacement rapide ou traversée d’un groupe.
- Objectif court pendant une vague, par exemple éliminer les soutiens ou tenir une zone, avec récompense dédiée.

**Hors de cette carte :** aucun chiffre de fréquence, d’intensité, de durée, de multiplicateur ou de récompense n’est validé. Les valeurs actuelles restent des prototypes jusqu’à spécification et calibration.
