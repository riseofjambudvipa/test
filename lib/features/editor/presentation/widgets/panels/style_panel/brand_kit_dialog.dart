import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/brand/brand_kit_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../controllers/editor_controller.dart';

/// Modal dialog allowing creators to manage their Brand Kits (Submagic & OpusClip parity),
/// apply custom colors & typography in 1-click, and export/import `.capbrand` packages.
class BrandKitDialog extends ConsumerStatefulWidget {
  const BrandKitDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const BrandKitDialog(),
    );
  }

  @override
  ConsumerState<BrandKitDialog> createState() => _BrandKitDialogState();
}

class _BrandKitDialogState extends ConsumerState<BrandKitDialog> {
  List<BrandKit> _brandKits = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final List<String> _availableFonts = [
    'Outfit',
    'Montserrat',
    'Space Grotesk',
    'Cinzel',
    'Anton',
    'Bebas Neue',
    'Poppins',
    'Inter',
    'Roboto',
  ];

  @override
  void initState() {
    super.initState();
    _loadBrandKits();
  }

  Future<void> _loadBrandKits() async {
    setState(() => _isLoading = true);
    try {
      final kits = await BrandKitService.instance.getBrandKits();
      if (mounted) {
        setState(() {
          _brandKits = kits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  List<BrandKit> get _filteredKits {
    if (_searchQuery.trim().isEmpty) return _brandKits;
    final q = _searchQuery.toLowerCase().trim();
    return _brandKits.where((k) {
      return k.name.toLowerCase().contains(q) ||
          k.handle.toLowerCase().contains(q) ||
          k.fontFamily.toLowerCase().contains(q);
    }).toList();
  }

  void _applyKit(BrandKit kit) {
    ref.read(editorProvider.notifier).applyBrandKit(
          primaryColor: kit.primaryColor,
          secondaryColor: kit.secondaryColor,
          accentColor: kit.accentColor,
          fontFamily: kit.fontFamily,
          templateId: kit.templateId,
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied "${kit.name}" brand kit styles!'),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportKit(BrandKit kit) async {
    try {
      final jsonStr = BrandKitService.instance.exportBrandKitJson(kit);
      final defaultName = '${kit.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}.capbrand';

      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final bytes = Uint8List.fromList(utf8.encode(jsonStr));
        final savePath = await FilePicker.saveFile(
          dialogTitle: 'Export Brand Kit (.capbrand)',
          fileName: defaultName,
          type: FileType.custom,
          allowedExtensions: ['capbrand', 'json'],
          bytes: bytes,
        );

        if (savePath != null) {
          final file = File(savePath);
          await file.writeAsString(jsonStr);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Exported brand kit to $savePath'),
                backgroundColor: AppTheme.accentGreen,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Brand kit export ready: $defaultName'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'BrandKitDialog', 'Failed to export brand kit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _importKit() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['capbrand', 'json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = await file.readAsBytes();
        final content = utf8.decode(fileBytes);

        final imported = BrandKitService.instance.importBrandKitJson(content);
        await BrandKitService.instance.saveBrandKit(imported);
        await _loadBrandKits();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported brand kit "${imported.name}"!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'BrandKitDialog', 'Failed to import brand kit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteKit(BrandKit kit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => PremiumBlurDialog(
        maxWidth: 360,
        glowColor: AppTheme.accentRed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Brand Kit?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "${kit.name}"? This action cannot be undone.',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.secondaryText)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: AppTheme.onAccentText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await BrandKitService.instance.deleteBrandKit(kit.id);
      await _loadBrandKits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${kit.name}" brand kit'),
            backgroundColor: AppTheme.accentOrange,
          ),
        );
      }
    }
  }

  void _showCreateEditDialog([BrandKit? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final handleCtrl = TextEditingController(text: existing?.handle ?? '');
    final primaryCtrl = TextEditingController(text: existing?.primaryColor ?? '#F97316');
    final secondaryCtrl = TextEditingController(text: existing?.secondaryColor ?? '#06B6D4');
    final accentCtrl = TextEditingController(text: existing?.accentColor ?? '#EC4899');
    String selectedFont = existing?.fontFamily ?? 'Outfit';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return PremiumBlurDialog(
            maxWidth: 440,
            glowColor: AppTheme.accentCyan,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Create Brand Kit' : 'Edit Brand Kit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Brand or Creator Name',
                    hintText: 'e.g. Acme Studio / My Brand',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: handleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Social Handle Tag',
                    hintText: 'e.g. @alexhormozi',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: primaryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Primary (Hex)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _parseHex(primaryCtrl.text, AppTheme.accentOrange),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: secondaryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Secondary (Hex)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _parseHex(secondaryCtrl.text, AppTheme.accentCyan),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: accentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Accent Highlight (Hex)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _parseHex(accentCtrl.text, AppTheme.accentPink),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedFont,
                  decoration: const InputDecoration(
                    labelText: 'Brand Typography Font',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppTheme.cardBg,
                  items: _availableFonts
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedFont = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: TextStyle(color: AppTheme.secondaryText)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: AppTheme.onAccentText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final kit = BrandKit(
                          id: existing?.id ?? 'kit_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          handle: handleCtrl.text.trim(),
                          primaryColor: primaryCtrl.text.trim(),
                          secondaryColor: secondaryCtrl.text.trim(),
                          accentColor: accentCtrl.text.trim(),
                          fontFamily: selectedFont,
                          templateId: existing?.templateId,
                        );

                        await BrandKitService.instance.saveBrandKit(kit);
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadBrandKits();
                      },
                      child: Text(existing == null ? 'Create' : 'Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassContainer(
        width: 680,
        height: 620,
        padding: const EdgeInsets.all(24),
        borderRadius: 16,
        borderOpacity: 0.15,
        color: AppTheme.cardBgElevated.withValues(alpha: 0.95),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: AppTheme.glassDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: 10,
                    borderOpacity: 0.25,
                  ),
                  child: Icon(Icons.verified_user_rounded, color: AppTheme.accentCyan, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BRAND KITS & CREATOR IDENTITIES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1-Click apply your custom colors, typography & logo styling to any video project',
                        style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppTheme.mutedText, size: 20),
                  splashRadius: 18,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Search brand kits by name, handle, or font...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.mutedText),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.dividerColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _importKit,
                  icon: const Icon(Icons.file_open_outlined, size: 15),
                  label: const Text('IMPORT .CAPBRAND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryText,
                    side: BorderSide(color: AppTheme.dividerColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreateEditDialog(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('NEW BRAND KIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: AppTheme.onAccentText,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
                  : _filteredKits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.branding_watermark_outlined, size: 40, color: AppTheme.mutedText),
                              const SizedBox(height: 10),
                              Text(
                                'No matching Brand Kits found',
                                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredKits.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final kit = _filteredKits[index];
                            return _buildBrandKitCard(kit);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandKitCard(BrandKit kit) {
    final pColor = _parseHex(kit.primaryColor, AppTheme.accentOrange);
    final sColor = _parseHex(kit.secondaryColor, AppTheme.accentCyan);
    final aColor = _parseHex(kit.accentColor, AppTheme.accentPink);

    return GlassContainer(
      borderRadius: 12,
      borderOpacity: 0.1,
      color: AppTheme.cardBg.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3-Color Swatch Strip
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(child: Container(color: pColor)),
                Expanded(child: Container(color: sColor)),
                Expanded(child: Container(color: aColor)),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      kit.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    if (kit.handle.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kit.handle,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentCyan,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.font_download_outlined, size: 12, color: AppTheme.mutedText),
                        const SizedBox(width: 4),
                        Text(
                          kit.fontFamily,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${kit.primaryColor} • ${kit.secondaryColor} • ${kit.accentColor}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.file_upload_outlined, size: 18, color: AppTheme.mutedText),
                tooltip: 'Export .capbrand',
                splashRadius: 16,
                onPressed: () => _exportKit(kit),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: AppTheme.mutedText),
                tooltip: 'Edit Brand Kit',
                splashRadius: 16,
                onPressed: () => _showCreateEditDialog(kit),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.accentRed.withValues(alpha: 0.8)),
                tooltip: 'Delete Brand Kit',
                splashRadius: 16,
                onPressed: () => _deleteKit(kit),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => _applyKit(kit),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                label: const Text('APPLY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
