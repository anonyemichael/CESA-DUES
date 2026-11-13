import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'package:cesa_dues_admin/app/theme/app_colors.dart';
import 'package:cesa_dues_admin/app/theme/app_theme.dart';

void main() {
  testWidgets('admin theme renders the ACES brand title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(appBar: AppBar(title: const Text('${AppConstants.appName} Admin'))),
      ),
    );
    expect(find.text('ACES DUES Admin'), findsOneWidget);
    expect(AppTheme.lightTheme.colorScheme.primary, AppColors.primary);
  });
}
