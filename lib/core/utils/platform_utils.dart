import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
bool get isWeb => kIsWeb;

bool get isWindows => !kIsWeb && Platform.isWindows;
bool get isMacOS => !kIsWeb && Platform.isMacOS;
bool get isLinux => !kIsWeb && Platform.isLinux;
bool get isAndroid => !kIsWeb && Platform.isAndroid;
bool get isIOS => !kIsWeb && Platform.isIOS;

bool get isLinuxSandboxed =>
    !kIsWeb &&
    Platform.isLinux &&
    (Platform.environment.containsKey('FLATPAK_ID') ||
        Platform.environment.containsKey('SNAP_NAME') ||
        Platform.environment.containsKey('APPIMAGE'));
