import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/skills.dart';
import 'package:flutter_testing_shit/src/models/enums.dart';
import 'package:flutter_testing_shit/src/models/fighter.dart';
import 'package:flutter_testing_shit/src/models/status_effect.dart';

void main() {
  group('Fighter', () {
    test('damage and healing are clamped to valid HP bounds', () {
      final fighter = Fighter(
        name: 'Knight',
        maxHp: 20,
        attackPower: 4,
        baseDefence: 2,
      );

      expect(fighter.takeDamage(-5), 0);
      expect(fighter.hp, 20);

      expect(fighter.takeDamage(7), 7);
      expect(fighter.hp, 13);

      expect(fighter.heal(50), 7);
      expect(fighter.hp, 20);

      expect(fighter.takeDamage(25), 20);
      expect(fighter.hp, 0);
      expect(fighter.isAlive, isFalse);
      expect(fighter.heal(5), 0);
      expect(fighter.hp, 0);
    });

    test('defence includes active buff effects only', () {
      final fighter = Fighter(
        name: 'Guardian',
        maxHp: 20,
        attackPower: 4,
        baseDefence: 5,
      );

      fighter.effects.addAll([
        StatusEffect(
          name: 'Protect',
          kind: EffectKind.buff,
          duration: 2,
          defenceBonus: 10,
        ),
        StatusEffect(
          name: 'Poison',
          kind: EffectKind.recurrent,
          duration: 2,
          damage: 2,
        ),
      ]);

      expect(fighter.defence, 15);
      expect(fighter.statusLabel, 'Protect 2 | Poison 2');
    });

    test('json round trip restores combat stats, skill state and effects', () {
      final fighter = Fighter(
        name: 'Archer',
        maxHp: 18,
        attackPower: 6,
        baseDefence: 3,
        skill: poisonArrowSkill(),
        value: 4,
        isHero: true,
        aiType: AiType.killer,
      )
        ..hp = 9
        ..level = 3
        ..xp = 42;
      fighter.skill!
        ..chargeBars = 2
        ..charge = 5;
      fighter.effects.add(
        StatusEffect(
          name: 'Bleed',
          kind: EffectKind.recurrent,
          duration: 3,
          damage: 5,
        ),
      );

      final restored = Fighter.fromJson(fighter.toJson());

      expect(restored.name, 'Archer');
      expect(restored.hp, 9);
      expect(restored.maxHp, 18);
      expect(restored.attackPower, 6);
      expect(restored.baseDefence, 3);
      expect(restored.value, 4);
      expect(restored.isHero, isTrue);
      expect(restored.aiType, AiType.killer);
      expect(restored.level, 3);
      expect(restored.xp, 42);
      expect(restored.skill!.name, 'Poison Arrow');
      expect(restored.skill!.chargeBars, 2);
      expect(restored.skill!.charge, 5);
      expect(restored.effects.single.name, 'Bleed');
      expect(restored.effects.single.damage, 5);
    });

    test('copy creates an independent skill instance with equivalent charge', () {
      final original = Fighter(
        name: 'Hero',
        maxHp: 20,
        attackPower: 5,
        baseDefence: 5,
        skill: powerSlashSkill(),
      );
      original.skill!
        ..chargeBars = 2
        ..charge = 4;

      final copy = original.copy(renamed: 'Hero copy');

      expect(copy.name, 'Hero copy');
      expect(copy.skill, isNot(same(original.skill)));
      expect(copy.skill!.name, original.skill!.name);
      expect(copy.skill!.charge, 4);
      expect(copy.skill!.chargeBars, 2);
    });
  });
}
