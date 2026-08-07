# ⚔️ Last Line

**Roguelite de combat au tour par tour avec progression persistante et système gacha, développé en Flutter — moteur de jeu, économie et systèmes de combat écrits entièrement "à la main", sans framework de jeu externe.**

> Projet solo, pensé et construit comme un vrai produit : architecture modulaire, suite de tests conséquente, et systèmes de jeu interconnectés (combat, progression, invocation, équipement) qui tiennent la route à l'échelle.

## Aperçu

Vous dirigez une équipe de héros à travers des **vagues d'ennemis thématiques générées procéduralement** (Bandits, Cultistes, Mages, Empire, Fantômes, Géants, Monstres...). Chaque bloc de 5 vagues partage une thématique et se termine par un ennemi plus coriace ; la difficulté et l'équipement des ennemis montent en puissance au fil de la run.

- **Combat au tour par tour** : attaque de base ou compétences (charges/cooldown), critiques, vol de vie, effets de statut (poison, saignement, brûlure), attaques doubles, log de combat complet.
- **Mode automatique** : un toggle "Auto Attack" enchaîne les tours pour accélérer le grind.
- **Marchand** entre les vagues, drops d'objets en fin de combat.
- **Sauvegarde automatique** (throttlée) avec migration transparente des anciennes sauvegardes.

## Progression & méta-jeu

- **Niveaux** : chaque héros/créature progresse de 1 à 50 avec un scaling de stats dégressif.
- **Invocation gacha** : dépensez des gemmes pour invoquer de nouvelles créatures (tirage simple ou x10 avec pity garantissant une rareté minimale). Les doublons se convertissent en XP bonus.
- **Évolution** : une créature au niveau max évolue vers sa forme suivante contre des gemmes (ex. *Slime → Gros Slime → Roi Slime*, ou *Paladin → Crusader → Holy Champion* pour les héros de départ).
- **Équipement** : casque, gants, torse, arme (un par emplacement) + reliques cumulables, avec bonus de stats, procs à l'impact et résistances aux effets de statut.

## Ce que ce projet démontre techniquement

- **Architecture en couches claire** : modèles immuables, logique de jeu isolée (`GameBalance`, `WaveGenerator`, moteur de combat), état exposé à l'UI via un `BattleController` composé de **mixins spécialisés** (tour, ciblage, auto-attaque, inventaire, XP, outils dev) plutôt qu'une God Class monolithique.
- **Économie de jeu pilotée par des budgets de stats** : les 6 paliers de rareté (Commune → Mythique) dérivent leurs statistiques d'une formule de budget partagée, appliquée aussi bien aux créatures invocables qu'aux vagues d'ennemis — un changement d'équilibrage se propage à tout le contenu sans retouche manuelle catalogue par catalogue.
- **Catalogue de contenu unifié** : un seul modèle de données (`CreatureDef`) sert à la fois les héros de départ et le bestiaire, avec un système de chaînes d'évolution déclaratif et une localisation FR/EN co-localisée aux données.
- **Simulateur de balance automatisé** : une suite dédiée (`test/balance`) fait tourner des runs simulées en masse et exporte un rapport CSV, utilisée pour valider chaque changement d'équilibrage avant de le livrer.
- **Persistance robuste** : sauvegarde versionnée avec migration automatique des anciens formats, adaptée au web comme au desktop/mobile.
- **Qualité** : **125 tests** (unitaires, contrôleur de combat, ciblage, génération de vagues, invocation, évolution, écran de démarrage...), `flutter analyze` propre, code 100 % Dart/Flutter multiplateforme.

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

- **Flutter** (SDK ^3.9.0) — logique de jeu "à la main" (pas de moteur de jeu ni de gestion d'état externe : `StatefulWidget` + `ChangeNotifier`/`BattleController`).
- Dépendances principales : `path_provider` & `shared_preferences` (sauvegardes), `flutter_launcher_icons`.
- Localisation FR/EN maison (`LocalizedText`), français par défaut.
- **Multiplateforme** : Android, iOS, Windows, macOS, Linux, Web — depuis une base de code unique.

## Roadmap

- 🎨 Refonte visuelle des écrans de combat et de l'inventaire (cartes de personnage, mise en page responsive).
- 🖼️ Animations et effets visuels sur les compétences et les invocations.
- 🌍 Extension du contenu (nouvelles vagues thématiques, objets, compétences).
- 🔊 Ajout d'audio (musiques, effets sonores).

## Démarrage

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

La suite couvre notamment le combat, le ciblage, la génération de vagues, les objets, l'invocation gacha, l'évolution, l'écran de démarrage, et un simulateur de balance dédié.

## Auteur

Développé par Matéo Sacré.
