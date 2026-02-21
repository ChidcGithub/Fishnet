import 'package:flutter_test/flutter_test.dart';
import 'package:fishnet/main.dart';

void main() {
  testWidgets('Fishnet app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FishnetApp());
    expect(find.text('Fishnet'), findsOneWidget);
  });
}
