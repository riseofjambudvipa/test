import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/utils/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.capstudio.ai/permissions');

  group('PermissionService Tests', () {
    test('requestStoragePermission returns true immediately on non-Android platforms', () async {
      // On the test host (Linux/macOS/Windows), Platform.isAndroid is false.
      // mockIsAndroid is null so the real platform value is used.
      final result = await PermissionService.requestStoragePermission();
      expect(result, isTrue);
    });

    test('requestStoragePermission invokes channel when mockIsAndroid is true', () async {
      PermissionService.mockIsAndroid = true;
      addTearDown(() {
        PermissionService.mockIsAndroid = null;
      });

      bool channelCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          channelCalled = true;
          expect(methodCall.method, 'requestStoragePermission');
          return true; // Simulate user granting permission
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final result = await PermissionService.requestStoragePermission();
      expect(result, isTrue);
      expect(channelCalled, isTrue); // Channel MUST have been invoked
    });

    test('requestStoragePermission returns false when channel returns false (permission denied)', () async {
      PermissionService.mockIsAndroid = true;
      addTearDown(() {
        PermissionService.mockIsAndroid = null;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async => false, // User denied
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final result = await PermissionService.requestStoragePermission();
      expect(result, isFalse);
    });

    test('requestStoragePermission fails open (returns true) when channel throws', () async {
      PermissionService.mockIsAndroid = true;
      addTearDown(() {
        PermissionService.mockIsAndroid = null;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async => throw PlatformException(code: 'UNAVAILABLE'),
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      // Should catch the exception and return true (fail-open)
      final result = await PermissionService.requestStoragePermission();
      expect(result, isTrue);
    });
  });
}
