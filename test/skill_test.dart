import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/skills.dart';
import 'package:flutter_testing_shit/src/models/battle_actions.dart';
import 'package:flutter_testing_shit/src/models/enums.dart';
import 'package:flutter_testing_shit/src/models/fighter.dart';

class FakeBattle implements BattleActions {
  final List<String> logs = [];
  final List<String> attacks = [];

  @override
  void addLog(String message) {
    logs.add(message);
  }

  @override
  void basicAttack(Fighter attacker, Fighter target, {double modifier = 1}) {
    attacks.add('${attacker.name}->${target.name} x$modifier');
    target.takeDamage(attacker.attackPower * modifier);
  }

  @override
  double computeDamagePreview(
    Fighter attacker,
    Fighter target, {
    double modifier = 1,
  }) {
    return attacker.attackPower * modifier;
  }

  @override
  double skillDamage(Fighter attacker, Fighter target, double amount) {
    return target.takeDamage(amount);
  }
}

void main() {
  group('Skill cooldowns', () {
    test('readiness, cooldown start and recharge respect charge bars', () {
      final skill = powerSlashSkill()..chargeBars = 2;

      expect(skill.maxCharge, 6);
      expect(skill.isReady, isFalse);

      skill.fullyRecharge();
      expect(skill.charge, 6);
      expect(skill.isReady, isTrue);

      skill.startCooldown();
      expect(skill.charge, 3);
      expect(skill.isReady, isTrue);

      skill.startCooldown();
      expect(skill.charge, 0);
      expect(skill.isReady, isFalse);

      for (var i = 0; i < 10; i++) {
        skill.tickCooldown();
      }
      expect(skill.charge, 6);
    });
  });

  group('Buff engine', () {
    test('attack and crit buffs feed the fighter getters; no stacking', () {
      final battle = FakeBattle();
      final caster = Fighter(name: 'Chief', maxHp: 20, attackPower: 5, baseDefence: 2);
      final ally = Fighter(name: 'Grunt', maxHp: 20, attackPower: 8, baseDefence: 3);
      final skill = buffSkill(
        name: 'War Cry',
        description: '+4 ATK, +15% crit',
        attackBonus: 4,
        critChanceBonus: .15,
      );

      skill.apply(battle, caster, [ally]);
      skill.apply(battle, caster, [ally]); // duplicate is ignored

      expect(ally.effects.where((e) => e.name == 'War Cry'), hasLength(1));
      expect(ally.attack, 12); // 8 base + 4 buff
      expect(ally.critChance, closeTo(0.25, 1e-9)); // 0.10 base + 0.15
    });

    test('base crit chance applies with no buffs or items', () {
      final hero = Fighter(name: 'A', maxHp: 10, attackPower: 5, baseDefence: 1);
      expect(hero.attack, 5);
      expect(hero.critChance, closeTo(0.10, 1e-9));
    });
  });

  group('Skill effects', () {
    test('protect adds a single defence buff', () {
      final battle = FakeBattle();
      final caster = Fighter(
        name: 'Paladin',
        maxHp: 25,
        attackPower: 3,
        baseDefence: 7,
      );
      final target = Fighter(
        name: 'Hero',
        maxHp: 20,
        attackPower: 5,
        baseDefence: 5,
      );
      final skill = protectSkill();

      skill.apply(battle, caster, [target]);
      skill.apply(battle, caster, [target]);

      expect(target.effects.where((effect) => effect.name == 'Protect'), hasLength(1));
      expect(target.defence, 25); // base 5 + Protect +20
      expect(battle.logs, ['Paladin protects Hero']);
    });

    test('poison arrow attacks and does not stack duplicate poison', () {
      final battle = FakeBattle();
      final caster = Fighter(
        name: 'Archer',
        maxHp: 15,
        attackPower: 5,
        baseDefence: 5,
      );
      final target = Fighter(
        name: 'Ogre',
        maxHp: 30,
        attackPower: 8,
        baseDefence: 2,
      );
      final skill = poisonArrowSkill();

      skill.apply(battle, caster, [target]);
      skill.apply(battle, caster, [target]);

      expect(battle.attacks, ['Archer->Ogre x1.0', 'Archer->Ogre x1.0']);
      expect(target.effects.where((effect) => effect.name == 'Poison Arrow'), hasLength(1));
      expect(target.effects.single.kind, EffectKind.recurrent);
    });

    test('magic healing restores twenty percent of target max HP', () {
      final battle = FakeBattle();
      final caster = Fighter(
        name: 'Priest',
        maxHp: 15,
        attackPower: 2,
        baseDefence: 3,
      );
      final target = Fighter(
        name: 'Paladin',
        maxHp: 30,
        attackPower: 3,
        baseDefence: 7,
      )..takeDamage(20);

      magicHealingSkill().apply(battle, caster, [target]);

      expect(target.hp, 16);
      expect(battle.logs.single, 'Priest heals Paladin for 6 hp');
    });
  });
}
