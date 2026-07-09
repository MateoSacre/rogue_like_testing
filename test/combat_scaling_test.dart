import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/items.dart';
import 'package:flutter_testing_shit/src/data/skills.dart';
import 'package:flutter_testing_shit/src/game/battle_controller.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/game/wave_generator.dart';
import 'package:flutter_testing_shit/src/models/enums.dart';
import 'package:flutter_testing_shit/src/models/fighter.dart';
import 'package:flutter_testing_shit/src/models/status_effect.dart';

Fighter _dummy({double hp = 100}) =>
    Fighter(name: 'T', maxHp: hp, attackPower: 10, baseDefence: 0);

void main() {
  group('Enemy wave scaling', () {
    test('multiplier is 1 at wave 1 and strictly grows', () {
      expect(GameBalance.waveStatScale(1), 1);
      expect(GameBalance.waveStatScale(50), greaterThan(1));
      expect(
        GameBalance.waveStatScale(200),
        greaterThan(GameBalance.waveStatScale(50)),
      );
    });

    test('spawned mobs are scaled up on late waves', () {
      final early = ThemedWaveGenerator(Random(1))
        ..currentCategory = MobCategory.monsters
        ..wavesRemainingInTheme = 3;
      final earlyWave = early.generate(1);

      final late = ThemedWaveGenerator(Random(1))
        ..currentCategory = MobCategory.monsters
        ..wavesRemainingInTheme = 3;
      final lateWave = late.generate(150);

      // Same seed/category: the late wave's mobs hit much harder (factor
      // depends on the tunable scaling rate; assert a clear, rate-agnostic gap).
      final earlyAtk = earlyWave.team.members.first.attackPower;
      final lateAtk = lateWave.team.members.first.attackPower;
      expect(lateAtk, greaterThan(earlyAtk * 2));
    });
  });

  group('Enemy items', () {
    test('relic count is zero before the threshold, then grows and caps', () {
      expect(GameBalance.enemyRelicCount(GameBalance.enemyItemStartWave - 1), 0);
      expect(GameBalance.enemyRelicCount(GameBalance.enemyItemStartWave), 1);
      expect(
        GameBalance.enemyRelicCount(100000),
        GameBalance.enemyMaxRelics,
      );
    });

    test('mobs carry relics past the threshold but not before', () {
      final early = ThemedWaveGenerator(Random(3))
        ..currentCategory = MobCategory.bandits
        ..wavesRemainingInTheme = 3;
      final earlyWave = early.generate(5);
      expect(
        earlyWave.team.members.every((m) => m.relics.isEmpty),
        isTrue,
      );

      final late = ThemedWaveGenerator(Random(3))
        ..currentCategory = MobCategory.bandits
        ..wavesRemainingInTheme = 3;
      final lateWave = late.generate(120);
      expect(lateWave.team.members.any((m) => m.relics.isNotEmpty), isTrue);
    });
  });

  group('Resistance relics', () {
    test('flat reduction trims each DoT tick', () {
      final fighter = _dummy()..relics.add('relic_poison_ward'); // -4 poison
      expect(fighter.dotFlatReduction(DotType.poison), 4);
      expect(fighter.dotFlatReduction(DotType.bleed), 0);

      final battle = BattleController();
      fighter.effects.add(
        StatusEffect(
          name: 'Poison',
          kind: EffectKind.recurrent,
          duration: 1,
          damage: 10,
          dotType: DotType.poison,
        ),
      );
      battle.applyEffectsOnTurnStart(fighter);
      expect(fighter.hp, fighter.maxHp - 6); // 10 - 4
    });

    test('full immunity negates the tick entirely', () {
      final fighter = _dummy()..relics.add('relic_poison_immunity');
      expect(fighter.dotNegateChance(DotType.poison), 1);

      final battle = BattleController();
      fighter.effects.add(
        StatusEffect(
          name: 'Poison',
          kind: EffectKind.recurrent,
          duration: 2,
          damage: 99,
          dotType: DotType.poison,
        ),
      );
      battle.applyEffectsOnTurnStart(fighter);
      expect(fighter.hp, fighter.maxHp); // no damage taken
      expect(battle.log.any((l) => l.contains('resists')), isTrue);
    });

    test('lifesteal resist reduces an attacker\'s drain', () {
      expect((_dummy()..relics.add('relic_grievous')).lifestealResist, .50);
      expect(
        (_dummy()..relics.add('relic_null_lifesteal')).lifestealResist,
        1,
      );
    });
  });

  group('Crit relics', () {
    test('crit relics raise the holder\'s crit chance', () {
      final fighter = _dummy()..relics.add('relic_crit_major'); // +18%
      expect(
        fighter.critChance,
        closeTo(GameBalance.baseCritChance + .18, 1e-9),
      );
    });
  });

  group('DoT scales with caster ATK', () {
    test('poison tick = 20% of the caster\'s (buffed) attack', () {
      final battle = BattleController();
      final caster = Fighter(
        name: 'C',
        maxHp: 100,
        attackPower: 50,
        baseDefence: 0,
      );
      final target = Fighter(
        name: 'T',
        maxHp: 100000,
        attackPower: 1,
        baseDefence: 0,
      );
      poisonArrowSkill().apply(battle, caster, [target]);
      final poison = target.effects.firstWhere((e) => e.name == 'Poison Arrow');
      expect(poison.damage, closeTo(50 * 0.20, 1e-9));
      expect(poison.dotType, DotType.poison);

      // An ATK buff feeds straight into the next application's tick.
      caster.effects.add(
        StatusEffect(
          name: 'Rage',
          kind: EffectKind.buff,
          duration: 3,
          attackBonus: 50,
        ),
      );
      final target2 = Fighter(
        name: 'T2',
        maxHp: 100000,
        attackPower: 1,
        baseDefence: 0,
      );
      poisonArrowSkill().apply(battle, caster, [target2]);
      final poison2 = target2.effects
          .firstWhere((e) => e.name == 'Poison Arrow');
      expect(poison2.damage, closeTo(100 * 0.20, 1e-9)); // attack now 100
    });

    test('on-hit relic tick = atkRatio × the attacker ATK', () {
      final fang = itemById('relic_fang')!; // bleed, atkRatio .10
      expect(fang.onHit!.tickDamage(200), closeTo(200 * 0.10, 1e-9));
    });
  });
}
