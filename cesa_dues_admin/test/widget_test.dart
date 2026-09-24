import 'package:flutter_test/flutter_test.dart';
import 'package:cesa_dues_admin/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CesaDuesAdminApp());
    expect(find.text('CESA DUES Admin'), findsOneWidget);
  });
}
