import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/app.dart';

void main() {
  testWidgets('game screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RogueLiteApp());

    expect(find.text('RogueLite'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Heros'), findsOneWidget);
    expect(find.text('Niveaux'), findsOneWidget);
  });
}
