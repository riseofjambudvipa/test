import 'package:flutter/material.dart';
import '../../../../../../app/theme.dart';

class ColorPickerRow extends StatefulWidget {
  final String label;
  final String currentHex;
  final ValueChanged<String> onColorSelected;

  const ColorPickerRow({
    super.key,
    required this.label,
    required this.currentHex,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerRow> createState() => _ColorPickerRowState();
}

class _ColorPickerRowState extends State<ColorPickerRow> {
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    final cleanHex = widget.currentHex.replaceAll('#', '').toUpperCase();
    _hexController = TextEditingController(text: cleanHex);
  }

  @override
  void didUpdateWidget(covariant ColorPickerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentHex != widget.currentHex) {
      final cleanHex = widget.currentHex.replaceAll('#', '').toUpperCase();
      if (_hexController.text != cleanHex) {
        _hexController.text = cleanHex;
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> colorPresets = [
      '#f97316', // Orange
      '#06b6d4', // Cyan
      '#22c55e', // Green
      '#a855f7', // Purple
      '#ef4444', // Red
      '#ec4899', // Pink
      '#eab308', // Yellow
      '#ffffff', // White
      '#000000', // Black
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: TextStyle(fontSize: 13, color: AppTheme.secondaryText)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _parseHex(widget.currentHex),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 85,
                height: 28,
                child: TextField(
                  controller: _hexController,
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.primaryText),
                  decoration: InputDecoration(
                    prefixText: '#',
                    prefixStyle: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.secondaryText),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    filled: true,
                    fillColor: AppTheme.cardBg,
                    border: AppTheme.defaultBorder(radius: 4),
                    focusedBorder: AppTheme.focusedBorder(radius: 4),
                    isDense: true,
                    hintText: 'RRGGBB',
                    hintStyle: TextStyle(fontSize: 10, color: AppTheme.mutedText),
                  ),
                  onSubmitted: (val) {
                    final cleanVal = val.trim().replaceAll('#', '');
                    if (cleanVal.length == 6) {
                      try {
                        Color(int.parse('FF$cleanVal', radix: 16));
                        widget.onColorSelected('#$cleanVal');
                      } catch (_) {}
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: colorPresets.map((hex) {
                      final isSelected = hex.toLowerCase() == widget.currentHex.toLowerCase();
                      return GestureDetector(
                        onTap: () => widget.onColorSelected(hex),
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: _parseHex(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
