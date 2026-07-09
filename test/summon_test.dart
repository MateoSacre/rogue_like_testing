import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/creatures.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/models/creature_rarity.dart';
import 'package:flutter_testing_shit/src/progression/player_progress.dart';
import 'package:flutter_testing_shit/src/progression/summon.dart';

/// Total XP a creature has accumulated, including XP already spent on levels.
int _xpEquivalent(HeroProgress p) {
  var total = p.xp;
  for (var l = 1; l < p.level; l++) {
    total += GameBalance.xpForLevel(l);
  }
  return total;
}

PlayerProgress _withGems(int gems, {Set<String> unlocked = const {}}) {
  return PlayerProgress(
    gems: gems,
    unlockedHeroes: unlocked,
    heroProgress: {for (final id in unlocked) id: HeroProgress()},
  );
}

void main() {
  group('Rarity rolls', () {
    test('only ever roll populated, positively-weighted tiers', () {
      final random = Random(7);
      for (var i = 0; i < 2000; i++) {
        final rarity = rollSummonRarity(random);
        expect(GameBalance.summonWeight(rarity), greaterThan(0));
        expect(creaturesByRarity(rarity), isNotEmpty);
        expect(rarity, isNot(CreatureRarity.legendary)); // evolution-only
      }
    });
  });

  group('Single summon', () {
    test('spends gems and unlocks a new creature', () {
      final progress = _withGems(GameBalance.summonCostSingle);
      final result = progress.summonSingle(Random(1));

      expect(result, isNotNull);
      expect(result!.isNew, isTrue);
      expect(result.xpGained, 0);
      expect(progress.gems, 0);
      expect(progress.isUnlocked(result.creatureId), isTrue);
      expect(creatureById(result.creatureId), isNotNull);
    });

    test('cannot summon without enough gems (no state change)', () {
      final progress = _withGems(GameBalance.summonCostSingle - 1);
      expect(progress.summonSingle(Random(1)), isNull);
      expect(progress.gems, GameBalance.summonCostSingle - 1);
      expect(progress.unlockedHeroes, isEmpty);
    });

    test('a duplicate grants fixed XP instead of a new unlock', () {
      final allIds = creatureCatalog.map((c) => c.id).toSet();
      final progress = _withGems(GameBalance.summonCostSingle, unlocked: allIds);

      final result = progress.summonSingle(Random(3))!;
      expect(result.isNew, isFalse);
      expect(result.xpGained, GameBalance.summonDuplicateXp);
      expect(
        _xpEquivalent(progress.heroProgress[result.creatureId]!),
        GameBalance.summonDuplicateXp,
      );
    });

    test('a duplicate at max level grants no XP', () {
      final allIds = creatureCatalog.map((c) => c.id).toSet();
      final progress = PlayerProgress(
        gems: GameBalance.summonCostSingle,
        unlockedHeroes: allIds,
        heroProgress: {
          for (final id in allIds)
            id: HeroProgress(level: GameBalance.maxHeroLevel),
        },
      );

      final result = progress.summonSingle(Random(5))!;
      expect(result.isNew, isFalse);
      expect(result.xpGained, 0);
    });

    test('duplicate XP is conserved across level-ups (no XP lost)', () {
      final allIds = creatureCatalog.map((c) => c.id).toSet();
      const draws = 8;
      final progress = _withGems(
        GameBalance.summonCostSingle * draws,
        unlocked: allIds,
      );
      final random = Random(11);
      for (var i = 0; i < draws; i++) {
        progress.summonSingle(random);
      }
      final totalXp = progress.heroProgress.values.fold<int>(
        0,
        (sum, p) => sum + _xpEquivalent(p),
      );
      expect(totalXp, draws * GameBalance.summonDuplicateXp);
    });
  });

  group('Ten-pull', () {
    test('spends gems, returns ten results, guarantees an epic-or-better', () {
      for (final seed in [1, 2, 3, 42, 99]) {
        final progress = _withGems(GameBalance.summonCostTen);
        final results = progress.summonTen(Random(seed));
        expect(results, hasLength(GameBalance.summonBatchSize));
        expect(progress.gems, 0);
        expect(
          results.any((r) => r.rarity.stars >= CreatureRarity.epic.stars),
          isTrue,
          reason: 'pity failed for seed $seed',
        );
      }
    });

    test('cannot ten-pull without enough gems (no state change)', () {
      final progress = _withGems(GameBalance.summonCostTen - 1);
      expect(progress.summonTen(Random(1)), isEmpty);
      expect(progress.gems, GameBalance.summonCostTen - 1);
      expect(progress.unlockedHeroes, isEmpty);
    });
  });
}
