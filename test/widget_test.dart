import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/app.dart';
import 'package:flutter_testing_shit/src/persistence/save_service.dart';

void main() {
  // Keep tests away from the real player save (and from path_provider,
  // which has no platform implementation in widget tests).
  setUpAll(() {
    SaveService.directoryOverride = Directory.systemTemp.createTempSync(
      'roguelite_widget_test_',
    );
  });

  tearDownAll(() {
    // No flush here: writes started inside the widget-test FakeAsync zone can
    // never complete once the test body ends, so awaiting them would hang.
    // Deletion is best effort — the OS cleans the temp dir anyway.
    try {
      SaveService.directoryOverride?.deleteSync(recursive: true);
    } catch (_) {}
    SaveService.directoryOverride = null;
  });

  testWidgets('game screen smoke test', (WidgetTester tester) async {
    // loadSave() performs real async file IO, so run the initial pump inside
    // runAsync and give it a moment to resolve before asserting.
    await tester.runAsync(() async {
      await tester.pumpWidget(const RogueLiteApp());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Default language is French. Two tabs: Partie (run) + Invocation (summon,
    // which replaced the old buy-heroes shop).
    expect(find.text('RogueLite'), findsOneWidget);
    expect(find.text('Partie'), findsOneWidget);
    expect(find.text('Invocation'), findsOneWidget);
  });
}
