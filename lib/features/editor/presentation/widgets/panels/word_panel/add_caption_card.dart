import 'package:flutter/material.dart';
import '../../../../../../app/theme.dart';

/// Inline card with editable Start / End / Text fields for adding a caption at a
/// specific timestamp range. Used both inline in the empty-state view and inside the
/// Add Caption modal dialog.
class AddCaptionAtTimeCard extends StatefulWidget {
  const AddCaptionAtTimeCard({
    super.key,
    required this.currentTime,
    required this.maxDuration,
    required this.onAdd,
  });

  final double currentTime;
  final double maxDuration;
  final void Function(double start, double end, String text) onAdd;

  @override
  State<AddCaptionAtTimeCard> createState() => _AddCaptionAtTimeCardState();
}

class _AddCaptionAtTimeCardState extends State<AddCaptionAtTimeCard> {
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController(text: widget.currentTime.toStringAsFixed(2));
    _endCtrl = TextEditingController(text: (widget.currentTime + 2.0).clamp(0.0, widget.maxDuration).toStringAsFixed(2));
    _textCtrl = TextEditingController(text: 'New Caption');
  }

  @override
  void didUpdateWidget(covariant AddCaptionAtTimeCard old) {
    super.didUpdateWidget(old);
    if ((old.currentTime - widget.currentTime).abs() > 0.05) {
      _startCtrl.text = widget.currentTime.toStringAsFixed(2);
      _endCtrl.text = (widget.currentTime + 2.0).clamp(0.0, widget.maxDuration).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'ADD CAPTION AT CUSTOM TIME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryText,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startCtrl,
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Start (s)',
                    labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedText),
                    border: AppTheme.defaultBorder(),
                    focusedBorder: AppTheme.focusedBorder(),
                    filled: true,
                    fillColor: AppTheme.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _endCtrl,
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'End (s)',
                    labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedText),
                    border: AppTheme.defaultBorder(),
                    focusedBorder: AppTheme.focusedBorder(),
                    filled: true,
                    fillColor: AppTheme.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textCtrl,
            style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
            decoration: InputDecoration(
              labelText: 'Caption text',
              labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedText),
              border: AppTheme.defaultBorder(),
              focusedBorder: AppTheme.focusedBorder(),
              filled: true,
              fillColor: AppTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('ADD CAPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: AppTheme.onAccentText,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final start = double.tryParse(_startCtrl.text) ?? widget.currentTime;
                final end = double.tryParse(_endCtrl.text) ?? (start + 2.0);
                final text = _textCtrl.text.trim().isEmpty ? 'New Caption' : _textCtrl.text.trim();
                if (end <= start) return;
                widget.onAdd(start.clamp(0.0, widget.maxDuration), end.clamp(0.0, widget.maxDuration), text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
