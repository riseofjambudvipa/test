import 'package:flutter/material.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../domain/community_presets_service.dart';
import '../../../../domain/style_templates.dart';

/// Interactive modal allowing creators to explore curated viral creator caption presets,
/// preview styles in real-time, 1-click install entire packs, or apply a style directly.
class CommunityPresetsDialog extends StatefulWidget {
  final ValueChanged<StyleTemplate> onApplyPreset;
  final VoidCallback onPacksUpdated;

  const CommunityPresetsDialog({
    super.key,
    required this.onApplyPreset,
    required this.onPacksUpdated,
  });

  @override
  State<CommunityPresetsDialog> createState() => _CommunityPresetsDialogState();
}

class _CommunityPresetsDialogState extends State<CommunityPresetsDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTag = 'All';
  final Set<String> _installedPackIds = {};
  final Set<String> _installingPackIds = {};
  bool _loading = true;

  final List<String> _availableTags = const [
    'All',
    'Trending',
    'YouTube',
    'Shorts',
    'Podcast',
    'TikTok',
    'Documentary',
    'Gaming',
  ];

  @override
  void initState() {
    super.initState();
    _checkInstalledPacks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkInstalledPacks() async {
    final service = CommunityPresetsService.instance;
    final installed = <String>{};
    for (final pack in service.packs) {
      if (await service.isPackInstalled(pack.id)) {
        installed.add(pack.id);
      }
    }
    if (mounted) {
      setState(() {
        _installedPackIds.addAll(installed);
        _loading = false;
      });
    }
  }

  Future<void> _installPack(CommunityPresetPack pack) async {
    setState(() => _installingPackIds.add(pack.id));
    final addedCount = await CommunityPresetsService.instance.installPack(pack);
    if (mounted) {
      setState(() {
        _installedPackIds.add(pack.id);
        _installingPackIds.remove(pack.id);
      });
      widget.onPacksUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Installed ${pack.title} ($addedCount presets added to My Presets)'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = CommunityPresetsService.instance;
    final filteredPacks = service.searchPacks(
      query: _searchController.text,
      tag: _selectedTag,
    );

    return PremiumBlurDialog(
      maxWidth: 680,
      glowColor: AppTheme.accentOrange,
      glowOpacity: 0.08,
      child: SizedBox(
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: AppTheme.glassDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.12),
                          borderRadius: 10,
                          borderOpacity: 0.2,
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: AppTheme.accentOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMMUNITY PRESET PACKS',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: AppTheme.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Curated viral creator caption styles. 1-click install to your library.',
                              style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.secondaryText, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
              decoration: InputDecoration(
                hintText: 'Search by creator, keyword or style...',
                hintStyle: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.secondaryText),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 16, color: AppTheme.mutedText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppTheme.cardBgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.borderGlass),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.borderGlass),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.accentOrange),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tag Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.accentOrange : AppTheme.secondaryText,
                      ),
                      selectedColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                      backgroundColor: AppTheme.cardBg,
                      side: BorderSide(
                        color: isSelected ? AppTheme.accentOrange : AppTheme.borderGlass,
                        width: isSelected ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        if (val) setState(() => _selectedTag = tag);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Packs List
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppTheme.accentOrange),
                      ),
                    )
                  : filteredPacks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 40, color: AppTheme.mutedText),
                              const SizedBox(height: 12),
                              Text(
                                'No preset packs found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing your search query or choosing another tag filter.',
                                style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredPacks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final pack = filteredPacks[index];
                            final isInstalled = _installedPackIds.contains(pack.id);
                            final isInstalling = _installingPackIds.contains(pack.id);

                            return _buildPackCard(pack, isInstalled, isInstalling);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackCard(CommunityPresetPack pack, bool isInstalled, bool isInstalling) {
    Color badgeColor = AppTheme.accentOrange;
    if (pack.badge == 'POPULAR') badgeColor = AppTheme.accentCyan;
    if (pack.badge == 'PRO') badgeColor = AppTheme.accentGreen;
    if (pack.badge == 'TRENDING') badgeColor = AppTheme.accentPink;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: 12,
        borderOpacity: 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pack Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          pack.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        if (pack.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: AppTheme.glassDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: 4,
                              borderOpacity: 0.2,
                            ),
                            child: Text(
                              pack.badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: badgeColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pack.creator} • ${(pack.downloads / 1000).toStringAsFixed(1)}k creators',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Install Button
              OutlinedButton.icon(
                onPressed: (isInstalled || isInstalling) ? null : () => _installPack(pack),
                icon: isInstalling
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentOrange),
                      )
                    : Icon(
                        isInstalled ? Icons.check_circle_rounded : Icons.download_rounded,
                        size: 14,
                        color: isInstalled ? AppTheme.accentGreen : AppTheme.accentOrange,
                      ),
                label: Text(
                  isInstalled ? 'INSTALLED' : 'INSTALL PACK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: isInstalled ? AppTheme.accentGreen : AppTheme.accentOrange,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isInstalled
                        ? AppTheme.accentGreen.withValues(alpha: 0.3)
                        : AppTheme.accentOrange.withValues(alpha: 0.3),
                  ),
                  backgroundColor: isInstalled
                      ? AppTheme.accentGreen.withValues(alpha: 0.08)
                      : AppTheme.accentOrange.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            pack.description,
            style: TextStyle(fontSize: 11, color: AppTheme.mutedText, height: 1.3),
          ),
          const SizedBox(height: 10),

          // Presets Preview Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pack.presets.map((preset) {
              return InkWell(
                onTap: () {
                  widget.onApplyPreset(preset);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppTheme.glassDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: 8,
                    borderOpacity: 0.1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _parseHexColor(preset.mainColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.touch_app_outlined, size: 12, color: AppTheme.mutedText),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
    } catch (_) {}
    return AppTheme.accentOrange;
  }
}
