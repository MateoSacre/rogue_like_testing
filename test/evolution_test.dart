import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/creatures.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/models/creature_rarity.dart';
import 'package:flutter_testing_shit/src/progression/player_progress.dart';

PlayerProgress _owning(String id, {required int level, required int gems}) {
  return PlayerProgress(
    gems: gems,
    unlockedHeroes: {id},
    heroProgress: {id: HeroProgress(level: level)},
  );
}

void main() {
  group('Evolution chains (data)', () {
    test('every evolution target exists and is one rarity tier up', () {
      for (final source in creatureCatalog) {
        final targetId = evolutionTargetId(source.id);
        if (targetId == null) continue;
        final target = creatureById(targetId);
        expect(target, isNotNull, reason: '${source.id} → $targetId missing');
        expect(
          target!.rarity.stars,
          source.rarity.stars + 1,
          reason: '${source.id} (${source.rarity}) → $targetId (${target.rarity})',
        );
      }
    });

    test('evolution targets are never summonable', () {
      for (final source in creatureCatalog) {
        final targetId = evolutionTargetId(source.id);
        if (targetId == null) continue;
        expect(creatureById(targetId)!.summonable, isFalse, reason: targetId);
      }
    });

    test('every category 1★ common has a two-step line, starters too', () {
      // Slime line, as the flagship example.
      expect(evolutionTargetId('Slime'), 'Gros Slime');
      expect(evolutionTargetId('Gros Slime'), 'Roi Slime');
      expect(evolutionTargetId('Roi Slime'), isNull); // terminal at 3★
      // Starters evolve up to 5★.
      expect(evolutionTargetId('Mage'), 'Archmage');
      expect(evolutionTargetId('Archmage'), 'Grand Archmage');
      expect(evolutionTargetId('Grand Archmage'), isNull);
    });
  });

  group('Evolve action', () {
    test('a maxed, affordable creature evolves and is consumed', () {
      final cost = GameBalance.evolutionCost(CreatureRarity.uncommon);
      final progress = _owning(
        'Slime',
        level: GameBalance.maxHeroLevel,
        gems: cost,
      );

      expect(progress.canEvolve('Slime'), isTrue);
      final newId = progress.evolve('Slime');

      expect(newId, 'Gros Slime');
      expect(progress.gems, 0);
      expect(progress.isUnlocked('Slime'), isFalse); // consumed
      expect(progress.isUnlocked('Gros Slime'), isTrue);
      expect(progress.levelFor('Gros Slime'), 1); // restarts at level 1
    });

    test('cannot evolve below max level', () {
      final progress = _owning('Slime', level: 1, gems: 99999);
      expect(progress.canEvolve('Slime'), isFalse);
      expect(progress.evolve('Slime'), isNull);
      expect(progress.isUnlocked('Slime'), isTrue);
    });

    test('cannot evolve without enough gems', () {
      final cost = GameBalance.evolutionCost(CreatureRarity.uncommon);
      final progress = _owning(
        'Slime',
        level: GameBalance.maxHeroLevel,
        gems: cost - 1,
      );
      expect(progress.canEvolve('Slime'), isFalse);
      expect(progress.evolve('Slime'), isNull);
    });

    test('cannot evolve a creature that is not owned', () {
      final progress = PlayerProgress(
        gems: 99999,
        unlockedHeroes: const {},
        heroProgress: const {},
      );
      expect(progress.canEvolve('Slime'), isFalse);
    });

    test('terminal forms cannot evolve', () {
      final progress = _owning(
        'Roi Slime',
        level: GameBalance.maxHeroLevel,
        gems: 99999,
      );
      expect(progress.evolutionCostOf('Roi Slime'), isNull);
      expect(progress.canEvolve('Roi Slime'), isFalse);
    });

    test('cost scales with the target tier', () {
      // Slime (1★) → Gros Slime (2★/uncommon).
      expect(
        _owning('Slime', level: 1, gems: 0).evolutionCostOf('Slime'),
        GameBalance.evolutionCost(CreatureRarity.uncommon),
      );
      // Mage (3★) → Archmage (4★/epic).
      expect(
        _owning('Mage', level: 1, gems: 0).evolutionCostOf('Mage'),
        GameBalance.evolutionCost(CreatureRarity.epic),
      );
    });
  });
}
