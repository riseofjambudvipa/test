import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/widgets/app_snackbar.dart';

void main() {
  testWidgets('AppSnackBar shows success snackbar with icon and message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppSnackBar.success(context, 'Saved successfully!'),
              child: const Text('Show SnackBar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show SnackBar'));
    await tester.pumpAndSettle();

    expect(find.text('Saved successfully!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('AppSnackBar shows error snackbar with icon and message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppSnackBar.error(context, 'Export failed!'),
              child: const Text('Show Error'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Error'));
    await tester.pumpAndSettle();

    expect(find.text('Export failed!'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
