import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/heroes.dart';
import 'package:flutter_testing_shit/src/game/game_screen.dart';
import 'package:flutter_testing_shit/src/l10n/app_language.dart';
import 'package:flutter_testing_shit/src/l10n/app_localizations.dart';
import 'package:flutter_testing_shit/src/progression/player_progress.dart';
import 'package:flutter_testing_shit/src/settings/game_settings.dart';

Widget _host(GameSettings settings) {
  return MaterialApp(
    home: AppLocalizations(
      language: settings.language,
      child: GameScreen(
        settings: settings,
        progress: PlayerProgress.initial(),
        initialHeroes: buildBaseTeam(),
        onSettingsChanged: (_) {},
        onProgressChanged: (_) {},
        onBattleSaved: (_) {},
        onResetProgress: () async {},
      ),
    ),
  );
}

void main() {
  testWidgets('GameScreen builds in FR + dev mode (compact layout)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const GameSettings(devMode: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Action du héros'), findsOneWidget);
    expect(find.text('Attaque'), findsWidgets);
    // Dev tools panel present (compact label).
    expect(find.text('Dev'), findsWidgets);
  });

  testWidgets('GameScreen builds in EN, shows localized panels', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const GameSettings(language: AppLanguage.en)));
    await tester.pumpAndSettle();

    expect(find.text('Hero action'), findsOneWidget);
    // Team panel titles are translated.
    expect(find.text('Heroes'), findsOneWidget);
    expect(find.text('Enemies'), findsOneWidget);
  });

  testWidgets('wide layout + dev mode renders full cards without overflow', (
    tester,
  ) async {
    // Worst case for the fixed-height fighter cards: wide layout (full,
    // non-compact cards) plus the extra dev-mode "AI" line. Previously this
    // overflowed; the FittedBox scale-down must now absorb it. pumpAndSettle
    // throws on any RenderFlex overflow, so reaching the asserts means no
    // overflow occurred.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(const GameSettings(language: AppLanguage.en, devMode: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Heroes'), findsOneWidget);
  });
}
