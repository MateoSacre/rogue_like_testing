import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/game/battle_controller.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/models/enums.dart';
import 'package:flutter_testing_shit/src/models/fighter.dart';
import 'package:flutter_testing_shit/src/models/status_effect.dart';
import 'package:flutter_testing_shit/src/models/team.dart';
import 'package:flutter_testing_shit/src/models/wave_info.dart';
import 'package:flutter_testing_shit/src/settings/game_settings.dart';

void main() {
  group('BattleController', () {
    test('computeAttackDamage respects defence and minimum damage', () {
      final battle = BattleController();
      final attacker = Fighter(
        name: 'Attacker',
        maxHp: 10,
        attackPower: 4,
        baseDefence: 0,
      );
      final defender = Fighter(
        name: 'Defender',
        maxHp: 10,
        attackPower: 1,
        baseDefence: 100,
      );

      expect(battle.computeAttackDamage(attacker, defender), GameBalance.minimumDamage);
      expect(battle.computeDamagePreview(attacker, defender), GameBalance.minimumDamage);
      defender.takeDamage(9.5);
      expect(battle.computeDamagePreview(attacker, defender), .5);
    });

    test('turn start recurrent effects deal damage and expire', () {
      final battle = BattleController();
      final fighter = Fighter(
        name: 'Target',
        maxHp: 20,
        attackPower: 1,
        baseDefence: 1,
      )..effects.add(
          StatusEffect(
            name: 'Poison',
            kind: EffectKind.recurrent,
            duration: 1,
            damage: 4,
          ),
        );

      battle.applyEffectsOnTurnStart(fighter);

      expect(fighter.hp, 16);
      expect(fighter.effects, isEmpty);
      expect(battle.log.first, 'Poison hits Target for 4');
    });

    test('removeBuffs decrements buff duration and removes expired buffs', () {
      final battle = BattleController();
      final protected = Fighter(
        name: 'Protected',
        maxHp: 20,
        attackPower: 1,
        baseDefence: 1,
      )..effects.add(
          StatusEffect(
            name: 'Protect',
            kind: EffectKind.buff,
            duration: 1,
            defenceBonus: 10,
          ),
        );

      battle.removeBuffs(Team('Team', [protected]));

      expect(protected.effects, isEmpty);
      expect(protected.defence, 1);
    });

    test('gaining XP levels up and scales every stat degressively', () {
      final battle = BattleController();
      final hero = Fighter(
        name: 'Hero',
        maxHp: 100,
        attackPower: 10,
        baseDefence: 10,
        isHero: true,
      );

      battle.gainXp(hero, GameBalance.xpForLevel(1));

      expect(hero.level, 2);
      final multiplier = 1 + GameBalance.statBonusForLevel(2);
      expect(hero.maxHp, closeTo(100 * multiplier, 1e-6));
      expect(hero.attackPower, closeTo(10 * multiplier, 1e-6));
      expect(hero.baseDefence, closeTo(10 * multiplier, 1e-6));
      expect(hero.hp, hero.maxHp); // full heal on level up
    });

    test('level is capped at the maximum', () {
      final battle = BattleController();
      final hero = Fighter(
        name: 'Hero',
        maxHp: 100,
        attackPower: 10,
        baseDefence: 10,
        isHero: true,
      );

      battle.gainXp(hero, 100000000);

      expect(hero.level, GameBalance.maxHeroLevel);
      expect(hero.xp, 0);
    });

    test('potions validate merchant, stock, gold and injury constraints', () {
      final battle = BattleController();
      final hero = battle.heroes.members.first;
      battle.merchantAvailable = true;
      battle.gold = GameBalance.singlePotionCost;
      hero.takeDamage(10);

      expect(battle.buySinglePotion(hero), isTrue);
      expect(battle.gold, 0);
      expect(battle.healingPotionStock, 0);
      expect(hero.hp, hero.maxHp);

      expect(battle.buySinglePotion(hero), isFalse);

      hero.takeDamage(10);
      battle.healingPotionStock = 1;
      expect(battle.useHealingPotion(hero), isTrue);
      expect(battle.healingPotionStock, 0);
    });

    test('toJson and fromJson preserve battle progress', () {
      final battle = BattleController();
      battle
        ..gold = 123
        ..gems = 4
        ..healingPotionStock = 2
        ..teamPotionStock = 1
        ..specialPotionStock = 3
        ..merchantAvailable = true;
      battle.heroes.members.first
        ..takeDamage(5)
        ..xp = 12
        ..level = 2;
      battle.addLog('custom log');

      final restored = BattleController.fromJson(battle.toJson());

      expect(restored.gold, 123);
      expect(restored.gems, 4);
      expect(restored.healingPotionStock, 2);
      expect(restored.teamPotionStock, 1);
      expect(restored.specialPotionStock, 3);
      expect(restored.merchantAvailable, isTrue);
      expect(restored.heroes.members.first.hp, battle.heroes.members.first.hp);
      expect(restored.heroes.members.first.level, 2);
      expect(restored.heroes.members.first.xp, 12);
      expect(restored.log.first, 'custom log');
    });

    test('loadFromJson falls back to a generated wave when saved mobs are empty outside merchant', () {
      final battle = BattleController.fromJson({
        'category': MobCategory.monsters.name,
        'merchantAvailable': false,
        'heroes': <Map<String, Object?>>[],
        'mobs': <Map<String, Object?>>[],
      });

      expect(battle.heroes.members, isNotEmpty);
      expect(battle.mobs.members, isNotEmpty);
      expect(battle.merchantAvailable, isFalse);
    });

    test('addLog keeps most recent entries under the configured limit', () {
      final battle = BattleController();

      for (var i = 0; i < GameBalance.maxLogEntries + 5; i++) {
        battle.addLog('entry $i');
      }

      expect(battle.log, hasLength(GameBalance.maxLogEntries));
      expect(battle.log.first, 'entry ${GameBalance.maxLogEntries + 4}');
      expect(battle.log.last, 'entry 5');
    });

    test('resolveManualTargets handles implicit target types', () {
      final battle = BattleController();
      final hero = battle.heroes.members.first;
      final lowHpMob = Fighter(
        name: 'Low',
        maxHp: 10,
        attackPower: 1,
        baseDefence: 1,
      )..takeDamage(8);
      final highHpMob = Fighter(
        name: 'High',
        maxHp: 20,
        attackPower: 1,
        baseDefence: 1,
      );
      battle.waveInfo = WaveInfo(
        team: Team('Wave', [lowHpMob, highHpMob]),
        category: MobCategory.monsters,
        finalWaveInTheme: false,
      );

      final skill = hero.skill!;
      skill.fullyRecharge();
      battle
        ..selectedHero = hero
        ..actionMode = ActionMode.skill;

      expect(battle.targetsForSelectedAction(), [hero]);
      expect(battle.resolveManualTargets(hero, skill), [hero]);
    });

    test('manual attack without target uses auto target choice', () async {
      final battle = BattleController();
      final hero = battle.heroes.members.first..attackPower = 10;
      final lowHpMob = Fighter(
        name: 'Low',
        maxHp: 4,
        attackPower: 1,
        baseDefence: 0,
      );
      final highHpMob = Fighter(
        name: 'High',
        maxHp: 8,
        attackPower: 1,
        baseDefence: 0,
      );
      battle.waveInfo = WaveInfo(
        team: Team('Wave', [lowHpMob, highHpMob]),
        category: MobCategory.monsters,
        finalWaveInTheme: false,
      );
      battle
        ..selectedHero = hero
        ..selectedTarget = null
        ..actionMode = ActionMode.attack;

      expect(battle.canAct, isTrue);

      await battle.performSelectedAction(pause: () async {}, notify: () {});

      expect(highHpMob.hp, lessThan(highHpMob.maxHp));
      expect(lowHpMob.hp, lowHpMob.maxHp);
    });

    test('enemy target tap toggles selection', () {
      final battle = BattleController();
      final hero = battle.heroes.members.first;
      final mob = battle.mobs.alive.first;
      battle
        ..selectedHero = hero
        ..actionMode = ActionMode.attack;

      battle.toggleEnemyTarget(mob);
      expect(battle.selectedTarget, mob);

      battle.toggleEnemyTarget(mob);
      expect(battle.selectedTarget, isNull);
    });

    test('dev currency cheats only work in dev mode', () {
      final battle = BattleController();

      battle.devAddGold();
      battle.devAddGems();
      expect(battle.gold, 0);
      expect(battle.gems, 0);

      battle.devMode = true;
      battle.devAddGold();
      battle.devAddGems();

      expect(battle.gold, 9999);
      expect(battle.gems, 999);
    });

    test('dev effect cheat can apply effects to heroes and enemies', () {
      final battle = BattleController()..devMode = true;
      final hero = battle.heroes.members.first;
      final mob = battle.mobs.members.first;
      final effect = StatusEffect(
        name: 'Heavy poison',
        kind: EffectKind.recurrent,
        duration: 5,
        damage: 10,
      );

      battle.devApplyEffect(hero, effect);
      battle.devApplyEffect(mob, effect);

      expect(hero.effects.single.name, 'Heavy poison');
      expect(mob.effects.single.damage, 10);
    });

    test('dev merchant cheat opens the merchant without auto attack', () {
      final battle = BattleController()
        ..devMode = true
        ..autoAttackEnabled = true
        ..resumeAutoAttackAfterMerchant = true;

      battle.devOpenMerchant();

      expect(battle.merchantAvailable, isTrue);
      expect(battle.autoAttackEnabled, isFalse);
      expect(battle.resumeAutoAttackAfterMerchant, isFalse);
      expect(battle.selectedHero, isNull);
    });

    test('dev auto restart setting round trips through json', () {
      final settings = const GameSettings(
        devMode: true,
        devAutoRestartOnDefeat: true,
      );

      final restored = GameSettings.fromJson(settings.toJson());

      expect(restored.devMode, isTrue);
      expect(restored.devAutoRestartOnDefeat, isTrue);
    });
  });
}
