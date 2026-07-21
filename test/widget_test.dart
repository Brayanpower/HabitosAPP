import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitosApp());
    expect(find.byType(HabitosApp), findsOneWidget);
  });
}
