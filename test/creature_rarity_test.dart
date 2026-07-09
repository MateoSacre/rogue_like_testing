import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/heroes.dart';
import 'package:flutter_testing_shit/src/data/mobs.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/models/creature_rarity.dart';
import 'package:flutter_testing_shit/src/models/fighter.dart';

void main() {
  group('CreatureRarity', () {
    test('stars run 1..6 and fromStars is the inverse (clamped)', () {
      expect(CreatureRarity.common.stars, 1);
      expect(CreatureRarity.mythic.stars, 6);
      expect(CreatureRarity.fromStars(3), CreatureRarity.rare);
      expect(CreatureRarity.fromStars(0), CreatureRarity.common);
      expect(CreatureRarity.fromStars(99), CreatureRarity.mythic);
    });
  });

  group('Rarity stat budget', () {
    test('anchors match the design (1★≈100/10/4 … 6★≈900/90/36)', () {
      const w = StatWeights();
      expect(GameBalance.creatureHp(CreatureRarity.common, w), closeTo(100, 1e-9));
      expect(GameBalance.creatureAttack(CreatureRarity.common, w), closeTo(10, 1e-9));
      expect(GameBalance.creatureDefence(CreatureRarity.common, w), closeTo(4, 1e-9));

      expect(GameBalance.creatureHp(CreatureRarity.mythic, w), closeTo(900, 1e-9));
      expect(GameBalance.creatureAttack(CreatureRarity.mythic, w), closeTo(90, 1e-9));
      expect(GameBalance.creatureDefence(CreatureRarity.mythic, w), closeTo(36, 1e-9));
    });

    test('HP anchor is linear across the six tiers', () {
      // rare (3★) sits exactly two fifths of the way from 100 to 900.
      expect(GameBalance.rarityHpAnchor(CreatureRarity.rare), closeTo(420, 1e-9));
      expect(GameBalance.rarityHpAnchor(CreatureRarity.epic), closeTo(580, 1e-9));
    });

    test('weights scale each stat independently', () {
      const tank = StatWeights(hp: 1.5, atk: 0.5, def: 2);
      final anchor = GameBalance.rarityHpAnchor(CreatureRarity.rare); // 420
      expect(
        GameBalance.creatureHp(CreatureRarity.rare, tank),
        closeTo(anchor * 1.5, 1e-9),
      );
      expect(
        GameBalance.creatureAttack(CreatureRarity.rare, tank),
        closeTo(anchor * GameBalance.rarityAtkRatio * 0.5, 1e-9),
      );
      expect(
        GameBalance.creatureDefence(CreatureRarity.rare, tank),
        closeTo(anchor * GameBalance.rarityDefRatio * 2, 1e-9),
      );
    });

    test('value increases monotonically with rarity', () {
      var previous = -1;
      for (final rarity in CreatureRarity.values) {
        final value = GameBalance.rarityValue(rarity);
        expect(value, greaterThan(previous));
        previous = value;
      }
    });
  });

  group('Bestiary rarities', () {
    test('each category has one mythic boss and non-boss rarities span '
        'exactly common→epic (incl. evolution forms)', () {
      final byCategory = <Object, List<dynamic>>{};
      for (final mob in mobRoster) {
        byCategory.putIfAbsent(mob.category, () => []).add(mob);
      }
      for (final mobs in byCategory.values) {
        final bosses = mobs.where((m) => m.isBoss).toList();
        final regulars = mobs.where((m) => !m.isBoss).toList();
        expect(bosses, hasLength(1));
        expect(bosses.single.rarity, CreatureRarity.mythic);
        expect(
          regulars.map((m) => m.rarity).toSet(),
          {
            CreatureRarity.common,
            CreatureRarity.uncommon,
            CreatureRarity.rare,
            CreatureRarity.epic,
          },
        );
      }
    });

    test('mob templates derive their stats from rarity and weights', () {
      final slime = mobRoster.firstWhere((m) => m.name == 'Slime');
      expect(slime.rarity, CreatureRarity.common);
      expect(
        slime.hp,
        closeTo(GameBalance.creatureHp(slime.rarity, slime.weights), 1e-9),
      );
      final built = slime.build('Slime', Random(1));
      expect(built.rarity, CreatureRarity.common);
      expect(built.maxHp, closeTo(slime.hp, 1e-9));
      expect(built.value, GameBalance.rarityValue(CreatureRarity.common));
    });
  });

  group('Heroes', () {
    test('the six classic heroes are summonable at 3★ (rare)', () {
      final team = buildBaseTeam();
      expect(team, hasLength(6));
      expect(team.every((h) => h.rarity == CreatureRarity.rare), isTrue);
      expect(team.every((h) => h.isHero), isTrue);
    });
  });

  group('Fighter rarity persistence', () {
    test('rarity survives a JSON round trip and a copy', () {
      final fighter = Fighter(
        name: 'Slime',
        maxHp: 100,
        attackPower: 10,
        baseDefence: 4,
        rarity: CreatureRarity.common,
      );
      expect(Fighter.fromJson(fighter.toJson()).rarity, CreatureRarity.common);
      expect(fighter.copy().rarity, CreatureRarity.common);
    });

    test('a missing rarity decodes to null', () {
      final fighter = Fighter(
        name: 'Anon',
        maxHp: 10,
        attackPower: 1,
        baseDefence: 0,
      );
      expect(fighter.rarity, isNull);
      expect(Fighter.fromJson(fighter.toJson()).rarity, isNull);
    });
  });
}
