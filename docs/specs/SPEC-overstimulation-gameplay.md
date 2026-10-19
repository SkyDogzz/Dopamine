# Spécification — Survival hyperactif

**Statut : proposition complète à relire.** La direction des 18 capacités est **[VALIDÉE par l’utilisateur, 2026-10-19]**. Les règles et valeurs ci-dessous sont **[PROPOSÉES]**; aucune intégration ne commence avant la revue de cette spécification.

## Objectif

Donner à Survival et à sa continuation Endless standard un rythme volontairement hyperactif : pics fréquents, séries qui récompensent l’action, surprises lisibles et retours visuels/sonores marqués. Le joueur garde le contrôle du déplacement et peut identifier les dangers au milieu des effets.

La présentation intense est la valeur par défaut. « Effets visuels réduits » retire les effets décoratifs et les secousses, mais conserve les télégraphes, marqueurs d’objectif et signaux de danger nécessaires au gameplay. Armorless et Sandbox restent hors périmètre de progression; le Sandbox ne reçoit jamais d’accès à la sauvegarde ou à la progression normale.

## Choix détaillés proposés

### 1. Combo d’éliminations

- Une élimination ajoute un kill à la chaîne si elle arrive dans les **4 secondes** suivant la précédente et si le joueur n’a pas reçu de dégâts depuis la précédente.
- La chaîne se rompt après **4 secondes sans kill** ou immédiatement à la réception de dégâts. La rupture retire aussi le bonus temporaire du combo.
- Les paliers sont **3, 6, 10, 15 et 25 kills**. Un nouveau palier affiche son nombre, un nom court, une animation et un son propres.
- Chaque palier donne **+5 % de vitesse d’attaque par palier atteint** pendant **4 secondes**. Le bonus est renouvelé, jamais empilé, et le palier supérieur remplace le précédent.
- Le compteur et son timer sont affichés près du HUD de run; le feedback ne masque jamais le joueur ni un télégraphe.

### 2. Pression et accalmies

- Chaque vague dure toujours **30 secondes**.
- Vagues 1–4 : **5 s de montée, 20 s de pression, 5 s d’accalmie**.
- Vagues 5–12 : **5 s de montée, 22 s de pression, 3 s d’accalmie**.
- Vagues 13–24 : **5 s de montée, 23 s de pression, 2 s d’accalmie**.
- La montée annonce visuellement/sonorement le pic et augmente progressivement les apparitions. Pendant l’accalmie, la cadence d’apparition est divisée par deux; les ennemis déjà présents et les attaques persistantes restent dangereux.
- Les boss gardent leur phase dédiée, sans accalmie forcée.

### 3. Objectifs courts de vague

- Un objectif apparaît toutes les **deux vagues non-boss**, sur les vagues paires; les transitions de boss ne reçoivent pas d’objectif. La suite reprend après le boss.
- Durée : **15 secondes**. Un seul objectif est actif à la fois.
- Trois types tirés au sort : éliminer un quota adapté à la vague; éliminer une cible prioritaire marquée; rester **8 secondes cumulées** dans une zone mobile de rayon **72 px**.
- Réussite : **15 % de la jauge XP vers le prochain niveau** et **+10 % de vitesse d’attaque pendant 6 secondes**, avec un payoff visuel/sonore.
- Échec ou expiration : aucune perte, aucun dégât gratuit, aucune rupture automatique du combo.

### 4. Événements surprises annoncés

- Un événement se déclenche environ toutes les **trois vagues non-boss**. Les événements prévus pour les vagues 12 et 24 sont reportés après le boss, pas supprimés.
- Une alerte générique apparaît **5 secondes** avant; elle ne révèle pas la mutation. À l’activation, le nom et les règles de l’événement deviennent visibles.
- Durée : **15 secondes**. Survivre jusqu’à la fin accorde **15 % de progression XP**; être vaincu avant la fin ne retire rien d’autre que la récompense.
- Premier paquet d’anomalies :
  - **Feral Surge** : cadence de spawn +50 %, vitesse ennemie +15 %.
  - **Overclock** : vitesse d’attaque joueur +20 %, vitesse ennemie +15 %.
  - **Magnetic Storm** : rayon d’attraction XP ×2 et orbes XP accélérés vers le joueur.
  - **Prism Break** : chaque 8e élimination déclenche une explosion de zone à 100 % des dégâts de base de l’arme.
- Tirage uniforme entre anomalies éligibles; même anomalie deux fois de suite interdite.

### 5. Combinaisons de mutations

- **20 %** des événements tirent une seconde anomalie et les activent ensemble pendant les mêmes 15 secondes.
- Maximum : **deux anomalies**. Les paires incompatibles (par exemple deux effets « chaque 8e kill ») sont exclues par une petite table de compatibilité.
- L’événement combiné est annoncé par le même signal générique; ses deux noms et effets sont révélés à son déclenchement.
- L’événement reste hors des combats de boss; il peut coïncider avec un objectif de vague.

### 6. Esquive parfaite

- Une esquive parfaite est enregistrée quand un projectile ennemi ou une charge télégraphiée aurait touché le rayon de collision du joueur dans les **250 ms**, mais le joueur sort effectivement de la zone avant l’impact sans subir de dégâts.
- Aucun dash ni invulnérabilité n’est ajouté. Le déplacement normal suffit.
- Récompense : **20 points de style**, léger son/flash local et **+10 % de vitesse d’attaque pendant 2 secondes**. Une même attaque ne peut récompenser qu’une esquive.
- Une esquive parfaite ne peut pas se déclencher à partir du HP decay, du contact déjà encaissé ou d’un effet allié.

### 7. Zone de risque/récompense

- Une zone à haute énergie apparaît une fois toutes les **4 vagues**, hors boss, pendant **12 secondes**.
- Y rester **4 secondes cumulées** charge une décharge. Sortir ne perd pas la progression; recevoir des dégâts ne l’efface pas.
- Décharge : **+20 % de dégâts et +20 % de zone pendant 8 secondes**, plus **15 points de style**.
- Le cercle est très visible, sa progression est lisible, et sa présence n’altère jamais un télégraphe de boss.

### 8. Bonus mobile à intercepter

- Un noyau XP néon traverse l’arène toutes les **45 secondes** de gameplay, reste **8 secondes** puis disparaît.
- Il est attiré par le rayon de collecte comme l’XP, mais peut aussi être touché directement par le joueur.
- Ramassage : **20 % de progression vers le prochain niveau** et **10 points de style**. Le rater n’entraîne aucune pénalité.
- Le noyau a une silhouette, une couleur et un son qui le distinguent clairement de l’XP ordinaire.

### 9. Jauge de style

- Jauge de **0 à 100**, visible dans le HUD, qui ne diminue pas avec le temps.
- Gains : élimination ordinaire **+1**; élite **+8**; esquive parfaite **+20**; objectif réussi **+25**; zone de risque chargée **+15**; bonus mobile ramassé **+10**.
- À 100, déclenchement automatique d’un **Style Burst de 6 secondes** : **+15 % de vitesse d’attaque et +10 % de zone**. La jauge retombe à 0; les points excédentaires sont conservés jusqu’à 100 après le burst.
- Un même événement ne donne pas de points deux fois; l’élimination par explosion en chaîne n’est pas comptée comme une nouvelle élimination de joueur pour la jauge.

### 10. Mutations temporaires de build

- Offres après les vagues **6, 12 et 18**; à la vague 12, l’offre vient après la défaite du mid-boss. Le joueur choisit une carte parmi trois, et le jeu est mis en pause pendant le choix.
- La mutation choisie dure jusqu’à l’offre suivante ou la fin de la run. Une seule mutation issue de ce système est active à la fois.
- Premier paquet de six cartes, tirage sans doublons dans une offre :
  - **Redline** : vitesse d’attaque +20 %, vitesse ennemie +10 %.
  - **Chain Reaction** : chaque 8e kill provoque une explosion à 100 % des dégâts de base.
  - **Experience Storm** : rayon de collecte XP +50 %, vitesse joueur +10 %.
  - **Blood Rush** : soin par élimination +50 %, HP decay +20 %.
  - **Frozen Tempo** : zone des armes +25 %, cadence de spawn ennemie +15 %.
  - **Prism Volley** : dégâts critiques +25 %, dégâts de base −10 %.
- La mutation est toujours affichée dans le HUD avec son bénéfice et sa contrepartie.

### 11. Objets maudits

- Une offre d’objet maudit remplace une option normale dans **20 % des coffres d’élite ou de boss**; elle ne peut pas apparaître dans les coffres ordinaires.
- C’est un choix facultatif et explicitement signalé. Un objet maudit est temporaire, n’occupe pas de slot permanent, reste jusqu’à la fin de la run et ne peut pas être retiré.
- Un seul objet maudit actif à la fois. En prendre un autre n’est possible qu’en remplaçant le précédent; le remplacement est présenté comme tel.
- Premier paquet de quatre : **Blood Debt** (+40 % dégâts, HP decay +35 %); **Glass Cannon** (+60 % dégâts, PV maximum −35 %); **Red Hunger** (+30 % vitesse d’attaque, ennemis +25 % vitesse); **Volatile Core** (éliminations explosent à 150 % dégâts, dégâts de contact joueur +50 %).

### 12. Surchauffe automatique des armes

- Comme les armes tirent automatiquement, la surchauffe est liée au tir soutenu, sans bouton de tir manuel.
- Chaque activation d’arme ajoute **12 chaleur** sur 100; le refroidissement est de **10 points/s** quand l’arme n’attaque pas.
- À 100, l’arme déclenche un **Overdrive de 2 secondes** : **+35 % cadence** et effets d’arme accentués. La chaleur retombe à **25**; aucun arrêt forcé du tir.
- Chaque arme possède sa jauge et sa signature visuelle; le HUD montre seulement les armes en train de chauffer et l’Overdrive actif.
- Les armes à activation lente utilisent le même système avec une valeur de chaleur ajustée à leur cadence lors de la calibration, sans modifier leur contrôle automatique.

### 13. Synergies spectaculaires arme/relique

- La synergie existante est amplifiée quand l’arme et sa relique associée sont niveau 5 et que l’évolution est acquise. Le feedback de combo est garanti à la première activation, puis au plus une fois toutes les **12 secondes** par paire.
- Chaque proc utilise le fonctionnement existant de l’arme; les effets ci-dessous sont les propositions de signature, sans créer de nouvelle arme/relique :
  - Lightning Conductor + Storm Core : arc éclair supplémentaire vers 3 ennemis.
  - Inferno Sprayer + Infernal Heart : explosion Burn sur les éliminations enflammées.
  - Crimson Daggers + Blood Chalice : retour de soin visible sur les Bleed.
  - Void Orb + Singularity : aspiration brève vers la trajectoire de l’orbe.
  - Frost Nova + Frozen Crown : anneau de gel suivi d’un shatter.
  - Minigun + Overdrive Engine : rafale Redline perforante.
  - Meteor Staff + Celestial Eye : impact Starfall en petite salve.
  - Sawblades + Magnetic Coil : ricochet Razorstorm additionnel.
  - Toxic Cloud + Plague Mask : propagation Pandemic vers les cibles proches.
  - Prism Laser + Prism Crystal : faisceaux Spectrum supplémentaires.
- Les procs ne modifient pas le RNG de la simulation, ne s’enchaînent pas entre eux et ne passent pas outre les budgets de réactions existants.

### 14. Compositions d’ennemis complémentaires

- À partir de la vague 4, chaque vague reçoit une composition dominante construite uniquement avec les archétypes existants. L’apparition reste progressive; aucun plafond global d’ennemis vivants n’est introduit.
- Motifs proposés, rotation déterministe par vague :
  - **Hunt** : Sprinters qui poussent le joueur vers les Chasers.
  - **Crossfire** : Shooters protégés par Tanks.
  - **Nest** : Summoners et soutiens protégés par Shielers.
  - **Blast** : Exploders forçant le déplacement au milieu des Chasers.
  - **Pursuit** : élite et Sprinters, avec soutien rare.
- La difficulté augmente le nombre relatif des rôles complémentaires, sans supprimer les télégraphes ni faire apparaître plusieurs élites de menace maximale au même instant.

### 15. Patterns combinés de boss

- Sur les boss de vagues 12 et 24, chaque **troisième attaque principale** devient une combinaison séquentielle de deux patterns connus.
- Le premier pattern finit avant le télégraphe du second; pause de **0,6 s** entre les deux. Les hitboxes ne se chevauchent pas sans télégraphe distinct.
- Combinaisons proposées : radial → charge; charge → tir ciblé; rayon → zone; spirale → summon. La combinaison est tirée selon la phase et exclut le pattern principal immédiatement précédent.
- En Chaos, cette combinaison remplace le follow-up déjà programmé pour ce cycle, elle ne s’y ajoute pas.

### 16. Finishers

- Les ennemis non-boss passent en état finisher à **10 % de PV ou moins**; marqueur bref au-dessus de la cible.
- Le prochain impact direct les élimine si l’impact aurait normalement retiré au moins 10 % de leurs PV maximum; sinon il inflige normalement ses dégâts. Pas de finisher sur boss ni sur le joueur.
- L’élimination déclenche une réaction dédiée, une petite secousse et une explosion de rayon **48 px** infligeant **50 % des dégâts de l’impact** aux ennemis voisins.
- Le kill et l’XP sont crédités une seule fois; le finisher ne propage pas d’autre finisher.

### 17. Explosion en chaîne à la mort d’un boss

- À la mort d’un boss, explosion de rayon **160 px**; les ennemis touchés subissent **20 % de leurs PV maximum** en dégâts et sont repoussés.
- Tout ennemi éliminé par cette explosion propage une explosion secondaire de rayon **72 px**, dégâts à **50 %** de la dernière explosion, avec un maximum de **3 bonds**.
- Les morts donnent leurs soins/XP normaux une seule fois. Les explosions ne détruisent pas les projectiles ennemis, n’endommagent pas le joueur et ne peuvent tuer un autre boss.

### 18. Mode optionnel « encore plus intense »

- Option de run disponible avec les difficultés de départ; séparée de la difficulté choisie et désactivée par défaut.
- Effets : cadence d’apparition +25 %; événements surprises toutes les **2 vagues non-boss** au lieu de 3; chance de double mutation **40 %**; bonus mobile toutes les **30 secondes**.
- Les statistiques de boss/dégâts directs ne changent pas; les télégraphes restent identiques.
- Récompenses de fin de run : Essence et Powder ×**1,15**. Le multiplicateur est affiché avant le lancement.
- Le mode fonctionne en Survival et Endless standard; absent d’Armorless et du Sandbox.

## Parcours d’intégration proposé

1. `encounter-rhythm` : phases de vague, objectifs, événements, anomalies et compositions.
2. `combat-payoffs` : combo, esquive, bonus mobile, style, mutations et objets maudits.
3. `weapon-signatures` : surchauffe et synergies d’évolution.
4. `boss-pressure` : patterns combinés, finishers et explosion en chaîne.
5. `intensity-mode` : sélection de run, multiplicateurs et récompenses.
6. `sensory-feedback` et `reactive-audio` : relier chaque événement aux retours visuels et sonores avec les options existantes.

Chaque incrément conserve les frontières de SimulationCore, Survival, progression normale et Sandbox; ajoute ses vérifications ciblées après revue et approbation de cette spec; puis documente la calibration séparément. Les valeurs proposées pourront être ajustées après mesures de runs représentatives.

## Critères d’acceptation

- Les 18 capacités sont identifiables en jeu et leurs règles décrites dans le HUD ou une présentation courte.
- Les moments de pression et de payoff se distinguent par le rythme, l’audio et les signaux visuels.
- Les événements et objectifs restent compréhensibles pendant un combat dense; les attaques dangereuses gardent la priorité visuelle.
- Les effets sont déterministes pour une seed de run donnée et ne mutent pas le flux RNG natif de combat hors génération normale d’événements.
- Les récompenses de run, les limites et les options d’effets réduits sont cohérentes entre Survival et Endless standard.
- Le Sandbox ne lit, ne modifie et ne crédite aucune donnée de progression normale.
- Les builds débutant, intermédiaire et complet restent jouables; les bonus temporaires n’outrepassent pas les caps documentés.

## Questions restant à la revue

- Corriger, accepter ou écarter chaque règle et valeur proposée dans les 18 sections.
- Confirmer le périmètre Survival + Endless standard et les exclusions Armorless/Sandbox.
- Après validation de cette spec, faire une calibration de run avant de promouvoir les valeurs proposées en décisions définitives.
