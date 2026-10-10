/// Status and progress models for binary downloads (FFmpeg, Whisper, models).
enum BinaryDownloadStatus { idle, downloading, extracting, verifying, complete, failed }

class BinaryDownloadProgress {
  final String toolId;
  final BinaryDownloadStatus status;
  final double downloadProgress; // 0.0 - 1.0
  final double extractProgress;  // 0.0 - 1.0
  final int bytesReceived;
  final int totalBytes;
  final double speedBytesPerSec;
  final Duration? eta;
  final String? error;

  const BinaryDownloadProgress({
    required this.toolId,
    required this.status,
    this.downloadProgress = 0.0,
    this.extractProgress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.eta,
    this.error,
  });

  double get overall => (downloadProgress * 0.7) + (extractProgress * 0.3);

  String get label => switch (status) {
    BinaryDownloadStatus.idle        => 'Ready to install',
    BinaryDownloadStatus.downloading => 'Downloading ${_fmt(bytesReceived)} / ${_fmt(totalBytes)}',
    BinaryDownloadStatus.extracting  => 'Extracting executables...',
    BinaryDownloadStatus.verifying   => 'Verifying installation...',
    BinaryDownloadStatus.complete    => 'Ready and active',
    BinaryDownloadStatus.failed      => 'Error: ${error ?? "Installation failed"}',
  };

  String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ManualInstallStep {
  final String title;
  final String command;

  const ManualInstallStep({required this.title, required this.command});
}

class ManualInstallRequiredException implements Exception {
  final String platform;
  final String toolId;
  final List<ManualInstallStep> steps;

  ManualInstallRequiredException({
    required this.platform,
    required this.toolId,
    required this.steps,
  });

  @override
  String toString() {
    return 'Manual installation required for $toolId on $platform.';
  }
}
