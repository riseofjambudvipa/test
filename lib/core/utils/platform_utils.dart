import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
bool get isWeb => kIsWeb;

bool get isLinuxSandboxed =>
    !kIsWeb &&
    Platform.isLinux &&
    (Platform.environment.containsKey('FLATPAK_ID') ||
        Platform.environment.containsKey('SNAP_NAME') ||
        Platform.environment.containsKey('APPIMAGE'));
