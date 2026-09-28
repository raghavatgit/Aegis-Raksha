import 'package:flutter_test/flutter_test.dart';
import 'package:raksha_emergency_mesh/main.dart';

void main() {
  testWidgets('Raksha app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title or main widget renders.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
