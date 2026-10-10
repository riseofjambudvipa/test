import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/widgets/app_section_header.dart';

void main() {
  testWidgets('AppSectionHeader renders title and icon correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSectionHeader(
            title: 'Test Section',
            icon: Icons.settings,
            showAccentBar: true,
          ),
        ),
      ),
    );

    expect(find.text('Test Section'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('AppSectionHeader renders trailing widget if provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSectionHeader(
            title: 'Header with Trailing',
            trailing: Text('TrailingAction'),
          ),
        ),
      ),
    );

    expect(find.text('Header with Trailing'), findsOneWidget);
    expect(find.text('TrailingAction'), findsOneWidget);
  });
}
