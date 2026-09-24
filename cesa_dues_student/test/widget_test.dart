import 'package:flutter_test/flutter_test.dart';
import 'package:cesa_dues_student/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CesaDuesStudentApp());
    expect(find.text('CESA DUES'), findsOneWidget);
  });
}
