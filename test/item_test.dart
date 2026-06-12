import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/items.dart';
import 'package:flutter_testing_shit/src/data/skills.dart';
import 'package:flutter_testing_shit/src/game/battle_controller.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/models/enums.dart';
import 'package:flutter_testing_shit/src/models/fighter.dart';
import 'package:flutter_testing_shit/src/models/item.dart';

Fighter hero(String name, {double hp = 30, double atk = 5, double def = 3}) {
  return Fighter(
    name: name,
    maxHp: hp,
    attackPower: atk,
    baseDefence: def,
    isHero: true,
  );
}

Fighter mob(String name, {double hp = 20, int value = 10}) {
  return Fighter(
    name: name,
    maxHp: hp,
    attackPower: 2,
    baseDefence: 0,
    value: value,
  );
}

BattleController controller(List<Fighter> heroes) {
  return BattleController(heroes: heroes, seedString: 'items-test');
}

void main() {
  group('Item catalog', () {
    test('ids are unique and lookup works', () {
      final ids = itemCatalog.map((item) => item.id).toSet();
      expect(ids.length, itemCatalog.length);
      for (final item in itemCatalog) {
        expect(itemById(item.id), same(item));
      }
    });

    test('every mob category has a boss item', () {
      for (final category in MobCategory.values) {
        final item = bossItemFor(category);
        expect(item, isNotNull, reason: 'missing boss item for $category');
        expect(item!.rarity, ItemRarity.boss);
        expect(item.isRelic, isTrue);
      }
    });

    test('each standard rarity tier offers all five item kinds', () {
      for (final rarity in [
        ItemRarity.common,
        ItemRarity.uncommon,
        ItemRarity.legendary,
      ]) {
        final pool = itemsOfRarity(rarity);
        expect(pool.length, 5, reason: 'pool of $rarity');
        expect(pool.map((i) => i.slot).toSet(), ItemSlot.values.toSet());
      }
    });
  });

  group('Equip and replace', () {
    test('equipping bakes stat bonuses into the hero', () {
      final battle = controller([hero('A')]);
      final target = battle.heroes.members.first;
      final baseHp = target.maxHp;
      final baseDef = target.baseDefence;

      battle.equipItem(target, itemById('chest_common')!);
      battle.equipItem(target, itemById('helmet_uncommon')!);

      expect(target.maxHp, baseHp + 6);
      expect(target.hp, target.maxHp);
      expect(target.baseDefence, baseDef + 5);
      expect(target.equipment[ItemSlot.chest], 'chest_common');
      expect(target.equipment[ItemSlot.helmet], 'helmet_uncommon');
    });

    test('replacing a slot removes old bonuses and sells the old item', () {
      final battle = controller([hero('A')]);
      final target = battle.heroes.members.first;
      final baseDef = target.baseDefence;

      battle.equipItem(target, itemById('helmet_common')!);
      final goldBefore = battle.gold;
      battle.equipItem(target, itemById('helmet_legendary')!);

      expect(target.baseDefence, baseDef + 11);
      expect(target.equipment[ItemSlot.helmet], 'helmet_legendary');
      expect(battle.gold, goldBefore + itemSellValue(ItemRarity.common));
    });

    test('relics stack without replacing', () {
      final battle = controller([hero('A')]);
      final target = battle.heroes.members.first;

      battle.equipItem(target, itemById('relic_fang')!);
      battle.equipItem(target, itemById('relic_fang')!);

      expect(target.relics, ['relic_fang', 'relic_fang']);
      expect(target.onHitEffects.length, 2);
    });
  });

  group('Derived item effects', () {
    test('extra attack chance sums across items and respects the cap', () {
      final holder = hero('A');
      holder.equipment[ItemSlot.weapon] = 'weapon_legendary'; // .40
      holder.relics.add('boss_bandits'); // +.20
      expect(holder.extraAttackChance, closeTo(.60, 1e-9));

      holder.relics.addAll(['boss_bandits', 'boss_bandits']); // > cap
      expect(
        holder.extraAttackChance,
        closeTo(GameBalance.extraAttackChanceCap, 1e-9),
      );
    });

    test('lifesteal heals the attacker on hit', () {
      final battle = controller([hero('A', atk: 10)]);
      final attacker = battle.heroes.members.first;
      attacker.relics.add('relic_vampire'); // 20% lifesteal
      attacker.hp = attacker.maxHp / 2;
      final hpBefore = attacker.hp;

      battle.basicAttack(attacker, mob('Dummy', hp: 100));

      expect(attacker.hp, greaterThan(hpBefore));
    });

    test('area skills trigger the same item procs as basic attacks', () {
      final battle = controller([hero('A', atk: 10)]);
      final attacker = battle.heroes.members.first;
      attacker.relics.add('relic_vampire'); // 20% lifesteal
      attacker.hp = attacker.maxHp / 2;
      final hpBefore = attacker.hp;
      final targets = [mob('M1', hp: 100), mob('M2', hp: 100)];

      nukeSkill().apply(battle, attacker, targets);

      // Nuke deals 3x attack to every target; lifesteal heals on each hit.
      expect(attacker.hp, greaterThan(hpBefore));
      expect(targets.every((target) => target.hp < 100), isTrue);
    });
  });

  group('Drops and assignment', () {
    test('boss kill queues its category item in manual mode', () {
      final battle = controller([hero('A')]);
      final boss = mob('Boss', value: 100)..isBoss = true;

      battle.rollItemDrop(boss);

      expect(battle.pendingItemDrops, hasLength(1));
      expect(
        battle.pendingItemDrops.first.def.id,
        'boss_${battle.waveInfo.category.name}',
      );
    });

    test('auto mode assigns to the least-equipped hero', () {
      final battle = controller([hero('A'), hero('B')]);
      final a = battle.heroes.members[0];
      final b = battle.heroes.members[1];
      battle.equipItem(a, itemById('relic_fang')!);
      battle.autoAttackEnabled = true;

      final boss = mob('Boss', value: 100)..isBoss = true;
      battle.rollItemDrop(boss);

      expect(battle.pendingItemDrops, isEmpty);
      expect(b.relics, ['boss_${battle.waveInfo.category.name}']);
    });

    test('auto mode sells a slot item nobody benefits from', () {
      final battle = controller([hero('A')]);
      final a = battle.heroes.members.first;
      battle.equipItem(a, itemById('helmet_legendary')!);
      battle.autoAttackEnabled = true;
      final goldBefore = battle.gold;

      battle.autoAssignItem(itemById('helmet_common')!);

      expect(a.equipment[ItemSlot.helmet], 'helmet_legendary');
      expect(battle.gold, goldBefore + itemSellValue(ItemRarity.common));
    });

    test('manual resolution can give or sell', () {
      final battle = controller([hero('A')]);
      final a = battle.heroes.members.first;
      final boss = mob('Boss', value: 100)..isBoss = true;
      battle.rollItemDrop(boss);
      final pending = battle.pendingItemDrops.first;

      battle.resolvePendingItemDrop(pending, hero: a);

      expect(battle.pendingItemDrops, isEmpty);
      expect(a.relics, isNotEmpty);
    });

    test('a mob killed by damage over time still grants its rewards', () {
      final battle = controller([hero('A')]);
      final victim = mob('Bleeder', value: 30);
      final goldBefore = battle.gold;

      battle.rewardDotKill(victim);

      expect(battle.gold, goldBefore + 30 * GameBalance.goldPerMobValue);
    });
  });

  group('Combined proc chance', () {
    test('matches 1 - product of miss chances', () {
      expect(combinedProcChance([.25, .25]), closeTo(.4375, 1e-9));
      expect(combinedProcChance([.5]), closeTo(.5, 1e-9));
      expect(combinedProcChance([]), 0);
      expect(combinedProcChance([1.0, .3]), closeTo(1.0, 1e-9));
    });
  });

  group('Serialization', () {
    test('equipment and relics survive a JSON round trip', () {
      final original = hero('A');
      original.equipment[ItemSlot.helmet] = 'helmet_uncommon';
      original.equipment[ItemSlot.weapon] = 'weapon_common';
      original.relics.addAll(['relic_fang', 'boss_giants']);

      final restored = Fighter.fromJson(original.toJson());

      expect(restored.equipment, original.equipment);
      expect(restored.relics, original.relics);
    });

    test('fighter copy carries items', () {
      final original = hero('A');
      original.equipment[ItemSlot.chest] = 'chest_legendary';
      original.relics.add('relic_venom');

      final copy = original.copy();

      expect(copy.equipment, original.equipment);
      expect(copy.relics, original.relics);
    });
  });
}
