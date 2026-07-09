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
import 'package:flutter_testing_shit/src/widgets/creature_tile.dart';

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

  Finder tileNamed(String name) =>
      find.byWidgetPredicate((w) => w is CreatureTile && w.name == name);

  // A tall surface so every team card / creature tile is mounted without
  // needing to scroll the list into view first.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('start screen shows 5 empty team slots to build from', (
    tester,
  ) async {
    useTallSurface(tester);
    final progress = _progressWith({'Paladin', 'Warrior', 'Slime'});
    await tester.pumpWidget(_host(progress));
    await tester.pumpAndSettle();

    // Five team-preset cards, none seeded (this progress bypassed
    // claimStarterHero, which is the only thing that seeds slot 0).
    for (var i = 1; i <= GameBalance.teamSlotCount; i++) {
      expect(find.text('Équipe $i'), findsOneWidget);
    }
    expect(find.text('Aucun héros sélectionné'), findsNWidgets(5));
  });

  testWidgets(
    'team editor toggles selection and ignores taps past the cap',
    (tester) async {
      useTallSurface(tester);
      // Eight unlocked creatures, so the roster cap (6) is the binding
      // constraint, not how many are available to pick from.
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

      // Open team 1's editor.
      await tester.tap(find.text('Équipe 1'));
      await tester.pumpAndSettle();

      // All 8 unlocked creatures are offered, starting unselected.
      const names = [
        'Paladin',
        'Guerrier',
        'Artificier',
        'Archer',
        'Prêtre',
        'Mage',
        'Gluant',
        'Coupe-bourse',
      ];
      for (final name in names) {
        expect(tileNamed(name), findsOneWidget);
      }
      expect(find.text('0/6 héros sélectionnés'), findsOneWidget);

      // Select the first 6 — each tap should grow the count by one.
      const firstSix = [
        'Paladin',
        'Guerrier',
        'Artificier',
        'Archer',
        'Prêtre',
        'Mage',
      ];
      for (var i = 0; i < firstSix.length; i++) {
        await tester.tap(tileNamed(firstSix[i]));
        await tester.pumpAndSettle();
        expect(find.text('${i + 1}/6 héros sélectionnés'), findsOneWidget);
      }

      // A 7th tap (roster is full) changes nothing.
      await tester.tap(tileNamed('Gluant'));
      await tester.pumpAndSettle();
      expect(find.text('6/6 héros sélectionnés'), findsOneWidget);

      // Tapping an already-selected creature deselects it.
      await tester.tap(tileNamed('Paladin'));
      await tester.pumpAndSettle();
      expect(find.text('5/6 héros sélectionnés'), findsOneWidget);

      // Now that there's room again, the earlier no-op tap succeeds.
      await tester.tap(tileNamed('Gluant'));
      await tester.pumpAndSettle();
      expect(find.text('6/6 héros sélectionnés'), findsOneWidget);

      // Back on the start screen, team 1's card reflects the edited roster.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${GameBalance.maxTeamSize}/${GameBalance.maxTeamSize} '
          'héros sélectionnés',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('first summon is the free starter choice', (tester) async {
    await tester.pumpWidget(_host(PlayerProgress.initial()));
    await tester.pumpAndSettle();

    // No hero unlocked yet → the run tab prompts the free first choice.
    expect(find.text('Choisis ton premier héros gratuitement'), findsOneWidget);
  });
}
