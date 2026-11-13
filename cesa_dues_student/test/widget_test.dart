import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:cesa_dues_student/app/theme/app_colors.dart';
import 'package:cesa_dues_student/app/theme/app_theme.dart';

void main() {
  test('brand constants describe ACES (UENR Computer Engineering)', () {
    expect(AppConstants.appName, 'ACES DUES');
    expect(AppConstants.organizationName, 'ACES');
    expect(AppConstants.associationFullName, 'Association of Computer Engineering Students');
    expect(AppConstants.universityShort, 'UENR');
    expect(AppConstants.receiptPrefix, 'ACES');
    expect(AppConstants.departmentNameUpper, AppConstants.departmentName.toUpperCase());
  });

  testWidgets('theme renders the brand header in ACES navy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: Text(AppConstants.appName))),
      ),
    );
    expect(find.text('ACES DUES'), findsOneWidget);
    expect(AppTheme.lightTheme.colorScheme.primary, AppColors.primary);
    expect(AppColors.primary, const Color(0xFF0A2A52));
  });
}
