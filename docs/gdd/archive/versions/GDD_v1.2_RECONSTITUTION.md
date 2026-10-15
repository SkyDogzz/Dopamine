# Dopamine Survivor — GDD v1.2 (reconstitution historique)

> **RECONSTITUTION, PAS DOCUMENT ORIGINAL.** Cette version est reconstruite à partir des décisions chronologiques retrouvées dans les échanges et des sections du GDD v1.5 consolidé. Les formulations et paramètres détaillés des sections extraites peuvent avoir été affinés après la version concernée ; ils ne constituent pas une transcription mot pour mot de v1.2.

## Objet de cette version

Ajout officiel de Achievement Mastery : familles de succès et récompenses cumulatives permanentes.

Ce document représente les **ajouts identifiés à la version 1.2**, à appliquer cumulativement aux versions antérieures. Il ne prétend pas restituer leur texte historique exact.


## 10 — Achievement Mastery (officiel v1.2)

[VALIDÉ] 100–150 familles d'achievements ; cible éditoriale 120 familles. Quatre paliers Bronze, Silver, Gold, Diamond. Bonus permanents cumulables, statistiques et effets spéciaux. Défis secrets récompensés. Progression conservée entre toutes les runs. Indépendance totale vis-à-vis du respec du skill tree. Budget de puissance totale : +10–15 % équivalent global ; cible proposée +12 %.

[PROPOSÉ] Répartition des 120 familles : Combat 25 ; Survival 15 ; Weapons 20 ; Relics & Evolutions 15 ; Equipment 15 ; Difficulty & Bosses 15 ; Progression 10 ; Secrets 5. Jusqu'à 480 récompenses de palier.

Exemple Exterminator : 100 / 1 000 / 10 000 / 100 000 kills cumulés ; bonus par palier +0,05 / +0,10 / +0,15 / +0,20 points de pourcentage de dégâts ; total +0,50 % au Diamond. Autres exemples : coups critiques, élites tuées, dégâts par arme, guérison cumulée, boss vaincus, équipement démantelé, enhancements réussis, runs Chaos, évolutions déclenchées.

Effets uniques proposés : Lightning supplémentaire occasionnel ; bouclier temporaire issu du soin excédentaire ; onde de choc à la première évolution ; vitesse temporaire après élimination d'élite ; reroll gratuit du premier chest ; onde de recul à la résurrection. Aucun achievement ne désactive le HP decay ni ne procure de revive infini.

Données : AchievementDefinition {id, category, secret, metric, aggregation, tiers[threshold,rewards]}; métriques de vie cumulées (sum), records (max), et état des tiers. Les récompenses sont reconstruites à partir des tiers acquis au chargement ; jamais dupliquées dans le save. Events idempotents ; secrets suivis avant révélation.

[À TESTER] Les bonus spécialisés et utilitaires ne s'additionnent pas naïvement au budget de puissance ; mesurer des builds de référence complets.

<a id="11"></a>
