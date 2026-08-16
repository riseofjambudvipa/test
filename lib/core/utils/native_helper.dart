// lib/core/utils/native_helper.dart
export 'native_helper_stub.dart'
    if (dart.library.io) 'native_helper_real.dart';

class SystemHardwareInfo {
  final double ramGB;
  final int cpuCores;
  final String gpuInfo;
  final bool hasGpu;

  const SystemHardwareInfo({
    required this.ramGB,
    required this.cpuCores,
    required this.gpuInfo,
    required this.hasGpu,
  });
}
