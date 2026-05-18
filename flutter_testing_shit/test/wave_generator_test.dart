import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/game/wave_generator.dart';
import 'package:flutter_testing_shit/src/models/enums.dart';

void main() {
  group('ThemedWaveGenerator', () {
    test('keeps waves inside the current theme and decrements remaining waves', () {
      final generator = ThemedWaveGenerator(Random(1))
        ..currentCategory = MobCategory.bandits
        ..wavesRemainingInTheme = 3;

      final wave = generator.generate(20);

      expect(wave.category, MobCategory.bandits);
      expect(wave.finalWaveInTheme, isFalse);
      expect(generator.wavesRemainingInTheme, 2);
      expect(wave.team.members, isNotEmpty);
      expect(wave.team.members.every((mob) => !mob.isBoss), isTrue);
      expect(wave.team.members.length, lessThanOrEqualTo(GameBalance.maxWaveSize));
    });

    test('final theme wave can include a boss and marks the wave as final', () {
      final generator = ThemedWaveGenerator(Random(1))
        ..currentCategory = MobCategory.monsters
        ..wavesRemainingInTheme = 1;

      final wave = generator.generate(1000);

      expect(wave.category, MobCategory.monsters);
      expect(wave.finalWaveInTheme, isTrue);
      expect(generator.wavesRemainingInTheme, 0);
      expect(wave.team.members.any((mob) => mob.isBoss), isTrue);
      expect(wave.team.members.length, lessThanOrEqualTo(GameBalance.maxWaveSize));
    });

    test('starts a new theme when no waves remain', () {
      final generator = ThemedWaveGenerator(Random(2));

      final wave = generator.generate(5);

      expect(generator.currentCategory, isNotNull);
      expect(wave.category, generator.currentCategory);
      expect(generator.wavesRemainingInTheme, GameBalance.waveThemeLength - 1);
    });
  });
}
