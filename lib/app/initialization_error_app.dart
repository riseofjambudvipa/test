import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'theme.dart';

class InitializationErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;
  final VoidCallback? onRetry;

  const InitializationErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CapStudio — Startup Failure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Builder(
          builder: (context) {
            return Stack(
              children: [
                // Glowing Ambient background gradients
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: GlowingBackgroundPainter(
                        primaryGlow: Colors.redAccent,
                        secondaryGlow: AppTheme.accentOrange,
                        devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 650),
                      padding: const EdgeInsets.all(32.0),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.cardBg.withValues(alpha: 0.55),
                        borderRadius: 16,
                        borderOpacity: 0.1,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Alert Icon
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.gpp_bad_rounded,
                              size: 64,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Heading
                          Text(
                            'Failed to Start CapStudio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Description
                          Text(
                            'A critical error occurred while initializing application resources. This might be caused by database corruption, missing file system permissions, or unsupported system configurations.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryText,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Error details box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ERROR DETAILS',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                                      tooltip: 'Copy full log & stack trace',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: 'Error: $error\n\nStack Trace:\n$stackTrace'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Error log copied to clipboard.'),
                                            backgroundColor: Color(0xFF1E1E24),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error,
                                  style: const TextStyle(
                                    fontFamily: 'Consolas',
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'STACK TRACE',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 150),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      stackTrace,
                                      style: TextStyle(
                                        fontFamily: 'Consolas',
                                        fontSize: 11,
                                        color: AppTheme.mutedText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (onRetry != null) ...[
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentOrange,
                                    foregroundColor: Colors.white,
                                    shadowColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                                    elevation: 6,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: onRetry,
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  label: const Text(
                                    'RETRY STARTUP',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              if (!kIsWeb) ...[
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    if (Platform.isAndroid || Platform.isIOS) {
                                      SystemNavigator.pop();
                                    } else {
                                      exit(0);
                                    }
                                  },
                                  icon: const Icon(Icons.power_settings_new_rounded, size: 20),
                                  label: const Text(
                                    'EXIT',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
