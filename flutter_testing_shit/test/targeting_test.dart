import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/skills.dart';
import 'package:flutter_testing_shit/src/game/targeting.dart';
import 'package:flutter_testing_shit/src/models/enums.dart';
import 'package:flutter_testing_shit/src/models/fighter.dart';
import 'package:flutter_testing_shit/src/models/status_effect.dart';
import 'package:flutter_testing_shit/src/models/team.dart';

Fighter fighter(
  String name, {
  double hp = 10,
  double attack = 3,
  double defence = 1,
  AiType aiType = AiType.dumb,
}) {
  return Fighter(
    name: name,
    maxHp: hp,
    attackPower: attack,
    baseDefence: defence,
    aiType: aiType,
  );
}

void main() {
  group('manualTargetsForSkill', () {
    test('returns the correct side for ally and enemy skills', () {
      final caster = fighter('Caster');
      final ally = fighter('Ally');
      final enemy = fighter('Enemy');
      final allies = Team('Allies', [caster, ally]);
      final enemies = Team('Enemies', [enemy]);

      expect(manualTargetsForSkill(caster, protectSkill(), allies, enemies), [caster, ally]);
      expect(manualTargetsForSkill(caster, powerSlashSkill(), allies, enemies), [enemy]);
    });
  });

  group('autoTargetsForSkill', () {
    test('ally lowest HP picks the weakest living ally', () {
      final caster = fighter('Priest');
      final healthy = fighter('Healthy', hp: 20);
      final wounded = fighter('Wounded', hp: 20)..takeDamage(15);
      final allies = Team('Allies', [caster, healthy, wounded]);

      expect(
        autoTargetsForSkill(caster, magicHealingSkill(), allies, Team('Enemies', [])),
        [wounded],
      );
    });

    test('enemy highest HP and multi-target skills select expected enemies', () {
      final caster = fighter('Mage');
      final low = fighter('Low', hp: 5);
      final high = fighter('High', hp: 30);
      final mid = fighter('Mid', hp: 15);
      final enemies = Team('Enemies', [low, high, mid]);

      expect(
        autoTargetsForSkill(caster, deepCutSkill(), Team('Allies', [caster]), enemies),
        [high],
      );
      expect(
        autoTargetsForSkill(caster, tripleBeamSkill(), Team('Allies', [caster]), enemies),
        [low, high, mid],
      );
    });
  });

  group('pickMobTargets', () {
    test('killer targets lowest health ratio first', () {
      final mob = fighter('Assassin', aiType: AiType.killer);
      final healthy = fighter('Healthy', hp: 20);
      final wounded = fighter('Wounded', hp: 20)..takeDamage(15);

      expect(pickMobTargets(mob, [healthy, wounded], 1), [wounded]);
    });

    test('damager targets lowest defence first', () {
      final mob = fighter('Striker', aiType: AiType.damager);
      final protected = fighter('Protected', defence: 8);
      final fragile = fighter('Fragile', defence: 1);

      expect(pickMobTargets(mob, [protected, fragile], 2), [fragile, protected]);
    });

    test('effect dealer prefers targets without recurrent effects', () {
      final mob = fighter('Poisoner', aiType: AiType.effectDealer);
      final clean = fighter('Clean');
      final poisoned = fighter('Poisoned')
        ..effects.add(
          StatusEffect(
            name: 'Poison',
            kind: EffectKind.recurrent,
            duration: 2,
          ),
        );

      expect(pickMobTargets(mob, [poisoned, clean], 1), [clean]);
    });

    test('effect stacker prefers targets with recurrent effects', () {
      final mob = fighter('Bleeder', aiType: AiType.effectStacker);
      final clean = fighter('Clean');
      final bleeding = fighter('Bleeding')
        ..effects.add(
          StatusEffect(
            name: 'Bleed',
            kind: EffectKind.recurrent,
            duration: 2,
          ),
        );

      expect(pickMobTargets(mob, [clean, bleeding], 1), [bleeding]);
    });
  });
}
