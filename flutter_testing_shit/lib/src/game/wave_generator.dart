import 'dart:math';

import '../data/mobs.dart';
import '../models/enums.dart';
import '../models/fighter.dart';
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
    final wave = <Fighter>[];
    var remainingValue = totalValue;
    var remainingSlots = GameBalance.maxWaveSize;
    var index = 1;

    if (isFinal) {
      final hardMob = _selectMob(remainingValue, category, bossesAllowed: true);
      if (hardMob != null) {
        wave.add(hardMob.build('$index-${hardMob.name}', random));
        remainingValue -= hardMob.value;
        remainingSlots--;
        index++;
      }
    }

    while (remainingValue > 0 && remainingSlots > 0) {
      final mob = _selectMob(remainingValue, category, bossesAllowed: false);
      if (mob == null) break;
      wave.add(mob.build('$index-${mob.name}', random));
      remainingValue -= mob.value;
      remainingSlots--;
      index++;
    }

    wavesRemainingInTheme--;
    return WaveInfo(
      team: Team('Wave', wave),
      category: category,
      finalWaveInTheme: isFinal,
    );
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
