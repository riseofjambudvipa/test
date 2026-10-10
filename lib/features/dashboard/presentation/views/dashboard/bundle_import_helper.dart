import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/database/schemas/project.dart';
import '../../controllers/dashboard_controller.dart';

/// Handles picking and importing a .capstudio or .json project bundle on the Dashboard.
Future<void> pickAndImportProjectBundle(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['capstudio', 'json'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    Project? imported;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);
      final dynamic decoded = json.decode(content);
      imported = await ref.read(dashboardProvider.notifier).importProjectBundle(rawJson: decoded);
    } else {
      final path = file.path;
      if (path == null) throw Exception('File path missing');
      imported = await ref.read(dashboardProvider.notifier).importProjectBundle(filePath: path);
    }

    if (imported != null && context.mounted) {
      await context.push('/editor/${imported.projectId}');
    }
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to import project bundle: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }
}
