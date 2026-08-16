// lib/core/utils/native_helper_real.dart
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';
import 'native_helper.dart';

bool isWindowsVcRuntimeInstalled() {
  if (!Platform.isWindows) return true;
  try {
    final systemRoot = Platform.environment['SystemRoot'] ?? 'C:\\Windows';
    final path1 = p.join(systemRoot, 'System32', 'vcruntime140.dll');
    final path2 = p.join(systemRoot, 'SysWOW64', 'vcruntime140.dll');
    final path1Ext = p.join(systemRoot, 'System32', 'vcruntime140_1.dll');
    final path2Ext = p.join(systemRoot, 'SysWOW64', 'vcruntime140_1.dll');

    final mainInstalled = File(path1).existsSync() || File(path2).existsSync();
    final extInstalled = File(path1Ext).existsSync() || File(path2Ext).existsSync();

    return mainInstalled && extInstalled;
  } catch (_) {
    return true; // Fail-open: return true if check fails due to permission/OS error.
  }
}

bool? _hasAvx;

Future<bool> cpuSupportsAvx() async {
  if (_hasAvx != null) return _hasAvx!;

  try {
    if (Platform.isWindows) {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final isProcessorFeaturePresent = kernel32.lookupFunction<
        Int32 Function(Int32 feature),
        int Function(int feature)
      >('IsProcessorFeaturePresent');
      // PF_AVX_INSTRUCTIONS_AVAILABLE = 38, PF_AVX2_INSTRUCTIONS_AVAILABLE = 40
      _hasAvx = isProcessorFeaturePresent(38) != 0 || isProcessorFeaturePresent(40) != 0;
    } else if (Platform.isLinux) {
      // Read /proc/cpuinfo flags asynchronously
      final file = File('/proc/cpuinfo');
      if (await file.exists()) {
        final cpuinfo = await file.readAsString();
        _hasAvx = cpuinfo.contains(' avx ') || cpuinfo.contains(' avx2 ');
      } else {
        _hasAvx = false;
      }
    } else if (Platform.isMacOS) {
      try {
        final libc = DynamicLibrary.process();
        final sysctlbyname = libc.lookupFunction<
          Int32 Function(
            Pointer<Utf8> name,
            Pointer<Int32> oldp,
            Pointer<IntPtr> oldlenp,
            Pointer<Void> newp,
            IntPtr newlen,
          ),
          int Function(
            Pointer<Utf8> name,
            Pointer<Int32> oldp,
            Pointer<IntPtr> oldlenp,
            Pointer<Void> newp,
            int newlen,
          )
        >('sysctlbyname');

        final namePtr = 'hw.optional.avx2'.toNativeUtf8();
        final valPtr = calloc<Int32>();
        final lenPtr = calloc<IntPtr>()..value = sizeOf<Int32>();

        try {
          final result = sysctlbyname(namePtr, valPtr, lenPtr, nullptr, 0);
          if (result == 0) {
            _hasAvx = valPtr.value != 0;
          } else {
            // Try avx1
            final namePtr1 = 'hw.optional.avx1'.toNativeUtf8();
            lenPtr.value = sizeOf<Int32>();
            try {
              final result1 = sysctlbyname(namePtr1, valPtr, lenPtr, nullptr, 0);
              if (result1 == 0) {
                _hasAvx = valPtr.value != 0;
              } else {
                _hasAvx = await _cpuSupportsAvxProcessFallback();
              }
            } finally {
              calloc.free(namePtr1);
            }
          }
        } finally {
          calloc.free(namePtr);
          calloc.free(valPtr);
          calloc.free(lenPtr);
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'AppDirs', 'FFI macOS AVX check failed: $e. Using process fallback.');
        _hasAvx = await _cpuSupportsAvxProcessFallback();
      }
    } else {
      _hasAvx = false; // Do not assume AVX on unknown platforms for safety
    }
  } catch (e) {
    LoggerService.instance.log(LogLevel.warning, 'AppDirs', 'AVX detection failed: $e. Defaulting to no-AVX build for safety.');
    _hasAvx = false; // Fail-safe: use the universally compatible build
  }

  return _hasAvx!;
}

Future<bool> _cpuSupportsAvxProcessFallback() async {
  try {
    final result = await Process.run('sysctl', ['-n', 'machdep.cpu.features'],
        stdoutEncoding: const SystemEncoding());
    return result.stdout.toString().toLowerCase().contains('avx');
  } catch (_) {
    return false;
  }
}

final Map<String, double> _cachedDiskSpaces = {};
final Map<String, DateTime> _diskSpaceCacheTimes = {};

Future<double> getAvailableDiskSpaceMB(String path) async {
  final now = DateTime.now();
  final cachedTime = _diskSpaceCacheTimes[path];
  if (cachedTime != null &&
      now.difference(cachedTime) < const Duration(seconds: 30)) {
    final cachedVal = _cachedDiskSpaces[path];
    if (cachedVal != null) {
      return cachedVal;
    }
  }

  double spaceMB = -1.0; // Sentinel value: -1.0 means check failed
  try {
    if (Platform.isWindows) {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final getDiskFreeSpace = kernel32.lookupFunction<
        Int32 Function(
          Pointer<Utf16> lpDirectoryName,
          Pointer<Uint64> lpFreeBytesAvailableToCaller,
          Pointer<Uint64> lpTotalNumberOfBytes,
          Pointer<Uint64> lpTotalNumberOfFreeBytes,
        ),
        int Function(
          Pointer<Utf16> lpDirectoryName,
          Pointer<Uint64> lpFreeBytesAvailableToCaller,
          Pointer<Uint64> lpTotalNumberOfBytes,
          Pointer<Uint64> lpTotalNumberOfFreeBytes,
        )
      >('GetDiskFreeSpaceExW');

      final pathPtr = path.toNativeUtf16();
      final freeBytesPtr = calloc<Uint64>();
      final totalBytesPtr = calloc<Uint64>();
      final totalFreeBytesPtr = calloc<Uint64>();

      try {
        final result = getDiskFreeSpace(
          pathPtr,
          freeBytesPtr,
          totalBytesPtr,
          totalFreeBytesPtr,
        );
        if (result != 0) {
          spaceMB = freeBytesPtr.value / (1024 * 1024);
        }
      } finally {
        calloc.free(pathPtr);
        calloc.free(freeBytesPtr);
        calloc.free(totalBytesPtr);
        calloc.free(totalFreeBytesPtr);
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      spaceMB = await _getAvailableDiskSpaceMBProcessFallback(path);
    }
  } catch (e) {
    LoggerService.instance.log(LogLevel.warning, 'AppDirs', 'Disk space check failed: $e');
  }

  _cachedDiskSpaces[path] = spaceMB;
  _diskSpaceCacheTimes[path] = now;
  return spaceMB;
}

Future<double> _getAvailableDiskSpaceMBProcessFallback(String path) async {
  try {
    final result = await Process.run('df', ['-k', path]);
    if (result.exitCode == 0) {
      final lines = result.stdout.toString().trim().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length > 3) {
          final kb = double.tryParse(parts[3]) ?? -1.0;
          if (kb >= 0) {
            return kb / 1024.0;
          }
        }
      }
    }
  } catch (_) {}
  return -1.0; // Sentinel value on failure
}

Future<SystemHardwareInfo> detectSystemHardware() async {
  double ramGB = 4.0;
  final int cpuCores = Platform.numberOfProcessors;
  String gpuInfo = 'None';
  bool hasGpu = false;

  try {
    if (Platform.isWindows) {
      final result = await Process.run('wmic', ['computersystem', 'get', 'TotalPhysicalMemory', '/value']);
      final match = RegExp(r'TotalPhysicalMemory=(\d+)').firstMatch(result.stdout.toString());
      if (match != null) {
        ramGB = double.parse(match.group(1)!) / (1024 * 1024 * 1024);
      }
    } else if (Platform.isMacOS) {
      final result = await Process.run('sysctl', ['hw.memsize']);
      final match = RegExp(r'hw.memsize:\s*(\d+)').firstMatch(result.stdout.toString());
      if (match != null) {
        ramGB = double.parse(match.group(1)!) / (1024 * 1024 * 1024);
      }
    } else if (Platform.isLinux) {
      final result = await Process.run('free', ['-b']);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length > 1) {
          ramGB = double.parse(parts[1]) / (1024 * 1024 * 1024);
        }
      }
    } else if (Platform.isAndroid) {
      try {
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          for (final line in lines) {
            if (line.startsWith('MemTotal:')) {
              final match = RegExp(r'MemTotal:\s*(\d+)\s*kB').firstMatch(line);
              if (match != null) {
                ramGB = double.parse(match.group(1)!) / (1024 * 1024);
                break;
              }
            }
          }
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'NativeHelper', 'Android RAM detection failed: $e');
      }
    }
  } catch (e) {
    LoggerService.instance.log(LogLevel.warning, 'NativeHelper', 'RAM detection failed: $e');
  }

  try {
    if (Platform.isWindows) {
      final result = await Process.run('wmic', ['path', 'win32_VideoController', 'get', 'name', '/value']);
      final lines = result.stdout.toString().split('\r\n');
      final names = <String>[];
      for (final line in lines) {
        if (line.trim().startsWith('Name=')) {
          final val = line.substring(5).trim();
          if (val.isNotEmpty) names.add(val);
        }
      }
      if (names.isNotEmpty) {
        gpuInfo = names.join(', ');
        hasGpu = gpuInfo.toLowerCase().contains('nvidia') ||
                 gpuInfo.toLowerCase().contains('amd') ||
                 gpuInfo.toLowerCase().contains('intel');
      }
    } else if (Platform.isMacOS) {
      gpuInfo = 'Apple Silicon (Metal)';
      hasGpu = true;
    } else if (Platform.isLinux) {
      final result = await Process.run('lspci', []);
      final lines = result.stdout.toString().split('\n');
      final gpuLines = lines.where((l) =>
          l.toLowerCase().contains('vga') ||
          l.toLowerCase().contains('3d') ||
          l.toLowerCase().contains('display'));
      if (gpuLines.isNotEmpty) {
        gpuInfo = gpuLines.map((l) {
          final parts = l.split(':');
          return parts.length > 2 ? parts[2].trim() : l.trim();
        }).join(', ');
        hasGpu = gpuInfo.toLowerCase().contains('nvidia') ||
                 gpuInfo.toLowerCase().contains('amd') ||
                 gpuInfo.toLowerCase().contains('intel');
      }
    }
  } catch (e) {
    LoggerService.instance.log(LogLevel.warning, 'NativeHelper', 'GPU detection failed: $e');
  }

  return SystemHardwareInfo(
    ramGB: ramGB,
    cpuCores: cpuCores,
    gpuInfo: gpuInfo,
    hasGpu: hasGpu,
  );
}
