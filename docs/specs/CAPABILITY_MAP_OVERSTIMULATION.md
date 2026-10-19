# Carte de capacités — Overstimulation

**Statut : carte des modules [PROPOSÉE]; 18 capacités de gameplay ci-dessous [VALIDÉES le 2026-10-19]; règles détaillées et implémentation [À SPÉCIFIER].**

Objectif : donner à Survival une identité volontairement intense et généreuse. Le rythme, les combats, les récompenses et la présentation audiovisuelle doivent créer des pics mémorables, des retours fréquents et une montée perceptible, sans rendre les menaces illisibles. L’intensité élevée est la présentation par défaut; les réglages d’accessibilité existants restent respectés.

| Module | Responsabilité | Dépend de |
|---|---|---|
| `encounter-rhythm` | Faire varier le tempo et la composition pendant la run : respirations courtes, montées, vagues de pression et événements de combat identifiables. | — |
| `combat-payoffs` | Donner des retours rapprochés et satisfaisants aux éliminations, séries, niveaux, coffres et synergies; relier les actions du joueur aux pics de récompense. | `encounter-rhythm` |
| `sensory-feedback` | Accorder les impacts, morts, pickups, télégraphes, caméra et effets aux événements de combat, avec une hiérarchie visuelle lisible et les contrôles d’intensité nécessaires. | `encounter-rhythm`, `combat-payoffs` |
| `reactive-audio` | Faire réagir les SFX et les couches musicales aux événements et à l’intensité réelle du combat. | `encounter-rhythm`, `combat-payoffs` |

**Ordre proposé :** `encounter-rhythm` → `combat-payoffs` → `sensory-feedback` et `reactive-audio`.

## Capacités de gameplay validées — 2026-10-19

L’utilisateur a validé la présence des idées suivantes dans la conception Survival. Cela n’en valide pas encore les valeurs, les règles de détail, la présentation ou le calendrier de réalisation; ceux-ci restent **[OUVERTS]**.

1. Combo d’éliminations avec compteur, sons et effets qui montent par paliers.
2. Alternance de vagues de pression et de brèves accalmies.
3. Objectifs courts en pleine vague avec récompense immédiate.
4. Événements surprises annoncés avec mutation temporaire et récompense spéciale.
5. Chevauchement de modificateurs pour créer des situations rares.
6. Esquive au dernier instant récompensée par un bref ralenti et une contre-attaque.
7. Zone à risque/récompense qui charge une attaque ou augmente les gains.
8. Bonus rare mobile à intercepter dans l’arène.
9. Jauge de style alimentée par déplacements, esquives, éliminations et combos.
10. Mutations temporaires choisies pour transformer le build.
11. Objets maudits avec bonus puissant et contrainte jusqu’à la fin de run.
12. Surchauffe d’arme qui charge une attaque plus puissante.
13. Synergies spectaculaires entre armes et reliques.
14. Compositions d’ennemis complémentaires qui créent des situations nouvelles.
15. Patterns de boss combinés ou densifiés.
16. Finishers spectaculaires sur des ennemis affaiblis.
17. Explosion de mort du boss qui repousse ou élimine les ennemis proches.
18. Mode optionnel « encore plus intense » avec davantage d’événements, de densité et de surprises.

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

## Hors gameplay — menus et parcours — [PROPOSÉ]

Pistes d’ambiance, d’anticipation et de récompense entre les combats. Elles sont indépendantes des idées de gameplay ci-dessus et ne sont pas sélectionnées ni planifiées.

- Menu d’accueil vivant : skyline animée, néons qui grésillent, circulation et silhouettes en mouvement.
- Réaction distincte des boutons au focus : son, éclat et mouvement bref au survol ou au changement de sélection.
- Lancement de run théâtral : transition énergique avec zoom, balayage lumineux et montée musicale, puis arrivée rapide dans le hub.
- Hub qui reflète la progression avec une vitrine animée du personnage, des armes débloquées et des records.
- Équipement mis en scène : aperçu visuel de l’objet sélectionné, carte animée et effets liés à sa rareté.
- Découverte animée d’une entrée du Codex, avec silhouettes et descriptions révélées progressivement.
- Succès célébrés par un toast visible, un badge animé et un récapitulatif des bonus acquis.
- Arbre de compétences avec tracé lumineux entre les nœuds, onde d’énergie après achat et aperçu du prochain palier.
- Résultat de run rythmé par des compteurs qui s’incrémentent par étapes, la mise en avant des records et un accès rapide à « Relancer ».
- Identité sonore cohérente avec des sons distincts de navigation, confirmation, déblocage, erreur et rareté.
- Transitions courtes entre menus, avec glissements ou flashs brefs adaptés à l’action et reprise rapide du contrôle.
- Écran de chargement avec conseil court sur une arme, une synergie ou un ennemi et élément visuel animé.
- Décor réactif qui varie subtilement selon l’onglet, la difficulté choisie ou la progression.
- Meilleure vague ou dernier résultat affiché dans le hub pour soutenir l’envie de relancer une run.
- Révélation de déblocage expliquant ce qui vient d’être obtenu et ce que cela permet avant la prochaine run.

## Idées générales — [PROPOSÉ]

Pistes qui peuvent traverser plusieurs systèmes ou définir l’identité globale des runs. Elles restent à trier.

- Donner à chaque run un modificateur ou une règle spéciale visible qui influe sur les choix.
- Introduire des événements rares et annoncés qui bousculent brièvement le rythme habituel.
- Proposer des choix entre récompenses incompatibles ou bonus puissants avec une contrepartie claire.
- Résumer la signature de chaque run : build, relique, boss et moment fort qui l’ont rendue unique.
- Offrir des objectifs personnels courts, optionnels et adaptés au build courant.
- Faire varier le décor avec des palettes, météo néon ou anomalies, parfois liées au combat.
- Créer des compositions d’ennemis qui se répondent et produisent des situations nouvelles.
- Reconnaître les actions maîtrisées ou risquées sans exiger une partie parfaite.
- Faire progresser les possibilités de jeu avec de nouvelles armes, variantes ou événements, au-delà des bonus statistiques.
- Envisager un mode optionnel « encore plus intense » avec davantage d’événements, de densité et de surprises.
- Utiliser de brèves accalmies ou coupures sonores pour renforcer le contraste avant les pics.
- Garder un journal des moments marquants et le présenter comme le récit de la run.
- Faire évoluer le comportement d’une arme selon la relique qui l’accompagne.
- Aux paliers choisis, proposer une mutation temporaire qui transforme le build.
- Faire dépendre une partie des récompenses de boss de la manière dont il est vaincu.
- Proposer une graine quotidienne identique pour tous, avec comparaison de score asynchrone.
- Permettre à des événements de se chevaucher et de créer des combinaisons rares.
- Introduire des objets maudits : bonus très puissant accompagné d’une contrainte qui dure jusqu’à la fin de la run.
- Ajouter un détour risqué pour sauver un PNJ et gagner une amélioration ou un vendeur temporaire.
- Créer un rival récurrent qui peut survivre, revenir renforcé et varier selon la rencontre précédente.
- Attribuer des badges de run à des exploits singuliers, par exemple gagner avec très peu de vie après un boss.
- Faire varier l’arène ou la séquence finale selon le build ou les événements rencontrés.
- Explorer un mode dédié aux combinaisons de build volontairement excessives.
- Permettre de placer un totem ou un champ persistant qui modifie l’arène jusqu’à la fin de la run.
- Annoncer mystérieusement une possibilité de nouvel ennemi ou de relique sans révéler son moment d’apparition.
- Proposer des choix de route entre une séquence dangereuse à forte récompense et une voie plus sûre.
- Créer des variantes de run courtes de 5 à 10 minutes, avec objectif et build imposés.

**Hors de cette carte :** aucun chiffre de fréquence, d’intensité, de durée, de multiplicateur ou de récompense n’est validé. Les valeurs actuelles restent des prototypes jusqu’à spécification et calibration.
