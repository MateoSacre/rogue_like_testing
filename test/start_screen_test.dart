import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/l10n/app_language.dart';
import 'package:flutter_testing_shit/src/l10n/app_localizations.dart';
import 'package:flutter_testing_shit/src/persistence/save_service.dart';
import 'package:flutter_testing_shit/src/progression/player_progress.dart';
import 'package:flutter_testing_shit/src/settings/game_settings.dart';
import 'package:flutter_testing_shit/src/start/start_screen.dart';

PlayerProgress _progressWith(Set<String> unlocked) {
  return PlayerProgress(
    gems: 0,
    unlockedHeroes: unlocked,
    heroProgress: {for (final id in unlocked) id: HeroProgress()},
  );
}

Widget _host(PlayerProgress progress) {
  return MaterialApp(
    builder: (context, child) => AppLocalizations(
      language: AppLanguage.fr,
      child: child ?? const SizedBox.shrink(),
    ),
    home: StartScreen(
      settings: const GameSettings(),
      progress: progress,
      battleJson: null,
      onSettingsChanged: (_) {},
      onProgressChanged: (_) {},
      onBattleSaved: (_) {},
      onResetProgress: () async {},
    ),
  );
}

void main() {
  setUpAll(() {
    SaveService.directoryOverride = Directory.systemTemp.createTempSync(
      'roguelite_start_screen_test_',
    );
  });

  tearDownAll(() {
    try {
      SaveService.directoryOverride?.deleteSync(recursive: true);
    } catch (_) {}
    SaveService.directoryOverride = null;
  });

  testWidgets('run team is capped at the max even with more unlocked', (
    tester,
  ) async {
    // Eight unlocked creatures, but the team caps at GameBalance.maxTeamSize.
    final progress = _progressWith({
      'Paladin',
      'Warrior',
      'Artificier',
      'Archer',
      'Priest',
      'Mage',
      'Slime',
      'Cutpurse',
    });
    await tester.pumpWidget(_host(progress));
    await tester.pumpAndSettle();

    // Default selection is capped: "6/6 héros sélectionnés".
    expect(
      find.text('${GameBalance.maxTeamSize}/${GameBalance.maxTeamSize} '
          'héros sélectionnés'),
      findsOneWidget,
    );

    // An over-cap creature's chip is disabled, so tapping it adds nothing.
    final overCapChip = find.text('Gluant Niv 1');
    expect(overCapChip, findsOneWidget);
    await tester.tap(overCapChip);
    await tester.pumpAndSettle();

    expect(
      find.text('${GameBalance.maxTeamSize}/${GameBalance.maxTeamSize} '
          'héros sélectionnés'),
      findsOneWidget,
    );
  });

  testWidgets('first summon is the free starter choice', (tester) async {
    await tester.pumpWidget(_host(PlayerProgress.initial()));
    await tester.pumpAndSettle();

    // No hero unlocked yet → the run tab prompts the free first choice.
    expect(find.text('Choisis ton premier héros gratuitement'), findsOneWidget);
  });
}
