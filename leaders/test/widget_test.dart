import 'package:flutter_test/flutter_test.dart';
import 'package:leaders/main.dart';

void main() {
  testWidgets('app boots and shows the player banner', (tester) async {
    await tester.pumpWidget(const LeadersApp());
    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Rivière de recrutement'), findsOneWidget);
  });
}
