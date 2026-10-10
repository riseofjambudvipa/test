import 'package:flutter/material.dart';
import '../../../../../app/theme.dart';

class HoverableImportCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const HoverableImportCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<HoverableImportCard> createState() => _HoverableImportCardState();
}

class _HoverableImportCardState extends State<HoverableImportCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _iconAnimController;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileWidth = size.width < 600;
    final isSmallHeight = size.height < 500;
    final double effectiveHeight =
        isMobileWidth ? 84.0 : (isSmallHeight ? 90.0 : 160.0);
    final bool useRowLayout = effectiveHeight <= 100;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: GlassContainer(
            height: effectiveHeight,
            borderRadius: 16,
            borderOpacity: _isHovered ? 0.24 : 0.08,
            glowColor: AppTheme.accentOrange,
            glowOpacity: _isHovered ? 0.08 : 0.0,
            color: _isHovered
                ? AppTheme.cardBg.withValues(alpha: 0.6)
                : AppTheme.cardBg.withValues(alpha: 0.35),
            child: useRowLayout
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _iconAnimController,
                          builder: (context, child) {
                            final double offset = _isHovered
                                ? (_iconAnimController.value * -4.0)
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(0, offset),
                              child: Icon(
                                widget.icon,
                                size: 32,
                                color: _isHovered
                                    ? AppTheme.accentOrange
                                    : AppTheme.accentOrange
                                        .withValues(alpha: 0.8),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: _isHovered
                                      ? AppTheme.primaryText
                                      : AppTheme.primaryText
                                          .withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: _isHovered
                                          ? AppTheme.secondaryText
                                          : AppTheme.secondaryText
                                              .withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color:
                              AppTheme.secondaryText.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _iconAnimController,
                              builder: (context, child) {
                                final double offset = _isHovered
                                    ? (_iconAnimController.value * -6.0)
                                    : 0.0;
                                return Transform.translate(
                                  offset: Offset(0, offset),
                                  child: Icon(
                                    widget.icon,
                                    size: 44,
                                    color: _isHovered
                                        ? AppTheme.accentOrange
                                        : AppTheme.accentOrange
                                            .withValues(alpha: 0.8),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: _isHovered
                                      ? AppTheme.primaryText
                                      : AppTheme.primaryText
                                          .withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                widget.subtitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: 11,
                                      color: _isHovered
                                          ? AppTheme.secondaryText
                                          : AppTheme.secondaryText
                                              .withValues(alpha: 0.7),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
