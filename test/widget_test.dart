import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/app.dart';

void main() {
  testWidgets('game screen smoke test', (WidgetTester tester) async {
    // loadSave() performs real async file IO, so run the initial pump inside
    // runAsync and give it a moment to resolve before asserting.
    await tester.runAsync(() async {
      await tester.pumpWidget(const RogueLiteApp());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Default language is French.
    expect(find.text('RogueLite'), findsOneWidget);
    expect(find.text('Partie'), findsOneWidget);
    expect(find.text('Héros'), findsOneWidget);
    expect(find.text('Niveaux'), findsOneWidget);
  });
}
