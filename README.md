# flutter_testing_shit

Roguelite de combat au tour par tour par vagues, avec progression persistante et invocation gacha, développé en Flutter.

## Le jeu

Vous dirigez une équipe de héros à travers des **vagues d'ennemis thématiques** générées procéduralement (Bandits, Cultistes, Mages, Empire, Fantômes, Géants, Monstres...). Chaque bloc de 5 vagues partage une thématique et se termine par un ennemi plus coriace ; plus vous avancez, plus les ennemis sont forts et équipés de reliques.

- **Combat au tour par tour** : attaque de base ou compétence (à charges/cooldown), critiques, vol de vie, effets de statut (poison, saignement, brûlure), doubles attaques, log de combat.
- **Mode automatique** : un toggle "Auto Attack" permet d'enchaîner les tours automatiquement.
- **Marchand** entre les vagues pour dépenser son or, et drops d'objets à l'issue des combats.
- **Sauvegarde automatique** de la progression (throttlée), avec migration des anciennes sauvegardes.

## Progression

- **Niveaux** : chaque héros/créature progresse de 1 à 50 en XP, avec un scaling de stats dégressif par niveau.
- **Invocation gacha** : dépensez des gemmes pour invoquer de nouvelles créatures (tirage simple ou x10 avec pity garantissant une rareté minimale). Les doublons se convertissent en XP bonus pour la créature déjà possédée.
- **Évolution** : une créature possédée au niveau max peut évoluer vers sa forme suivante contre des gemmes (ex. Slime → Gros Slime → Roi Slime, ou Paladin → Crusader → Holy Champion pour les héros de départ).
- **Équipement** : casque, gants, torse, arme (un par emplacement) + reliques (cumulables), avec bonus de stats, procs à l'impact et résistances aux effets de statut.

## Contenu actuel

| Catégorie | Nombre |
|---|---|
| Héros de départ | 6 |
| Créatures du bestiaire (mobs) | 49 (dont 7 boss) |
| Objets | 33 |
| Compétences | 11 |
| Créatures invocables au total (catalogue) | 67 |

Système de rareté à 6 paliers : Commune (1★) → Peu commune (2★) → Rare (3★) → Épique (4★) → Légendaire (5★) → Mythique (6★).

## Stack technique

- **Flutter** (SDK ^3.9.0), logique de jeu "à la main" (pas de moteur de jeu ni de gestion d'état externe — `StatefulWidget` + `BattleController`).
- Dépendances principales : `path_provider` (sauvegardes), `flutter_launcher_icons`.
- Localisation FR/EN maison (`LocalizedText`), français par défaut.
- Plateformes cibles : Android, iOS, Windows, macOS, Linux, Web.

## Démarrage

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

La suite couvre notamment le combat, le ciblage, la génération de vagues, les objets, l'invocation gacha, l'évolution et l'écran de démarrage.

## État du projet

Version actuelle : `0.4.3`. Le système d'invocation gacha (créatures, raretés, évolution, grille d'équipement) est en cours de finalisation.
