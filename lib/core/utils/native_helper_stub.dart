// lib/core/utils/native_helper_stub.dart
import 'dart:async';
import 'native_helper.dart';

bool isWindowsVcRuntimeInstalled() => true;

Future<bool> cpuSupportsAvx() async => false;

Future<double> getAvailableDiskSpaceMB(String path) async => -1.0;

Future<SystemHardwareInfo> detectSystemHardware() async {
  return const SystemHardwareInfo(
    ramGB: 4.0,
    cpuCores: 2,
    gpuInfo: 'Not available (Web/Stub)',
    hasGpu: false,
  );
}
