import 'dart:math';

import '../data/items.dart';
import '../data/mobs.dart';
import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/item.dart';
import '../models/mob_template.dart';
import '../models/team.dart';
import '../models/wave_info.dart';
import 'game_balance.dart';

class ThemedWaveGenerator {
  ThemedWaveGenerator(this.random);

  final Random random;
  MobCategory? currentCategory;
  int wavesRemainingInTheme = 0;

  WaveInfo generate(int totalValue) {
    if (wavesRemainingInTheme == 0) {
      currentCategory =
          MobCategory.values[random.nextInt(MobCategory.values.length)];
      wavesRemainingInTheme = GameBalance.waveThemeLength;
    }

    final category = currentCategory!;
    final isFinal = wavesRemainingInTheme == 1;
    // totalValue tracks the wave number, which also drives enemy stat scaling.
    final waveNumber = totalValue;
    final wave = <Fighter>[];
    var remainingValue = totalValue;
    var remainingSlots = GameBalance.maxWaveSize;

    if (isFinal) {
      final hardMob = _selectMob(remainingValue, category, bossesAllowed: true);
      if (hardMob != null) {
        wave.add(_spawn(hardMob, waveNumber));
        remainingValue -= hardMob.value;
        remainingSlots--;
      }
    }

    while (remainingValue > 0 && remainingSlots > 0) {
      final mob = _selectMob(remainingValue, category, bossesAllowed: false);
      if (mob == null) break;
      wave.add(_spawn(mob, waveNumber));
      remainingValue -= mob.value;
      remainingSlots--;
    }

    wavesRemainingInTheme--;
    return WaveInfo(
      team: Team('Wave', wave),
      category: category,
      finalWaveInTheme: isFinal,
    );
  }

  /// Builds a mob, applies the wave's power scaling and (past a threshold)
  /// equips wave-scaled offensive relics.
  Fighter _spawn(MobTemplate template, int waveNumber) {
    final fighter = template.build(template.name, random);
    final scale = GameBalance.waveStatScale(waveNumber);
    if (scale != 1) {
      fighter
        ..maxHp = fighter.maxHp * scale
        ..attackPower = fighter.attackPower * scale
        ..baseDefence = fighter.baseDefence * scale
        ..hp = fighter.maxHp;
    }
    _equipEnemyItems(fighter, waveNumber);
    return fighter;
  }

  /// Picks the relic rarity enemies carry at [wave] (richer the further in).
  ItemRarity _enemyRelicRarity(int wave) {
    final over = wave - GameBalance.enemyItemStartWave;
    if (over >= 120) return ItemRarity.legendary;
    if (over >= 50) return ItemRarity.uncommon;
    return ItemRarity.common;
  }

  /// Offensive relics only (so enemies threaten with the same procs heroes use).
  List<ItemDef> _enemyRelicPool(ItemRarity rarity) {
    return itemsOfRarity(rarity)
        .where(
          (item) =>
              item.isRelic &&
              (item.lifesteal > 0 ||
                  item.onHit != null ||
                  item.extraAttackChance > 0 ||
                  item.critChanceBonus > 0),
        )
        .toList();
  }

  void _equipEnemyItems(Fighter fighter, int wave) {
    final count = GameBalance.enemyRelicCount(wave);
    if (count == 0) return;
    final pool = _enemyRelicPool(_enemyRelicRarity(wave));
    if (pool.isEmpty) return;
    for (var i = 0; i < count; i++) {
      final def = pool[random.nextInt(pool.length)];
      fighter.relics.add(def.id);
      fighter
        ..maxHp += def.hpBonus
        ..attackPower += def.atkBonus
        ..baseDefence += def.defBonus;
    }
    fighter.hp = fighter.maxHp;
  }

  MobTemplate? _selectMob(
    int remainingValue,
    MobCategory category, {
    required bool bossesAllowed,
  }) {
    final minimumTargetValue = remainingValue / 4;
    final candidates = mobRoster
        .where((mob) => mob.category == category)
        .where((mob) => mob.value <= remainingValue)
        .where((mob) => bossesAllowed || !mob.isBoss)
        .toList();
    if (candidates.isEmpty) return null;

    final window = candidates
        .where((mob) => mob.value >= minimumTargetValue)
        .toList();
    final pool = window.isEmpty ? candidates : window;
    return pool[random.nextInt(pool.length)];
  }
}
