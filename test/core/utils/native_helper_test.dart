import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/utils/native_helper.dart';
import 'package:capstudio/core/utils/native_helper_real.dart' as native_real;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeHelper and Architecture Tests', () {
    test('getCpuArchitecture returns a valid architecture string', () {
      final arch = native_real.getCpuArchitecture();
      expect(arch, isNotEmpty);
    });

    test('isAppleSilicon returns boolean and handles override correctly', () {
      final original = native_real.isAppleSilicon();
      expect(original, isA<bool>());

      // Test override
      native_real.setAppleSiliconForTesting(true);
      expect(native_real.isAppleSilicon(), isTrue);

      native_real.setAppleSiliconForTesting(false);
      expect(native_real.isAppleSilicon(), isFalse);

      // Reset
      native_real.setAppleSiliconForTesting(null);
    });

    test('SystemHardwareInfo defaults and properties', () {
      const info = SystemHardwareInfo(
        ramGB: 16.0,
        cpuCores: 8,
        gpuInfo: 'Apple Silicon (Metal)',
        hasGpu: true,
        isAppleSilicon: true,
        cpuArchitecture: 'macos_arm64',
      );

      expect(info.ramGB, 16.0);
      expect(info.cpuCores, 8);
      expect(info.gpuInfo, 'Apple Silicon (Metal)');
      expect(info.hasGpu, isTrue);
      expect(info.isAppleSilicon, isTrue);
      expect(info.cpuArchitecture, 'macos_arm64');
    });

    test('detectSystemHardware returns populated SystemHardwareInfo', () async {
      final info = await detectSystemHardware();
      expect(info.ramGB, greaterThan(0));
      expect(info.cpuCores, greaterThan(0));
      expect(info.gpuInfo, isNotEmpty);
      expect(info.cpuArchitecture, isNotEmpty);
      expect(info.isAppleSilicon, isA<bool>());
    });
  });
}
