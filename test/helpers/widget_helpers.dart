import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/l10n/app_localizations.dart';

Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Size size = const Size(1280, 800),
  ProviderContainer? container,
}) async {
  // Set screen size for responsive design testing
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    container != null
        ? UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: child,
              ),
            ),
          )
        : ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: child,
              ),
            ),
          ),
  );
}
