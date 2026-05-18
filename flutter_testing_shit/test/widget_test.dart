import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/app.dart';

void main() {
  testWidgets('game screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RogueLiteApp());

    expect(find.text('Heroes'), findsOneWidget);
    expect(find.text('Enemies'), findsOneWidget);
    expect(find.text('Battle log'), findsOneWidget);
  });
}
