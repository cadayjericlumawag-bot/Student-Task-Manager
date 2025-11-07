import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DurationPickerDialog extends StatefulWidget {
  const DurationPickerDialog({super.key});

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  int _hours = 0;
  int _minutes = 30;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Focus Mode Duration', style: GoogleFonts.poppins()),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NumberPicker(
            value: _hours,
            label: 'Hours',
            onChanged: (value) => setState(() => _hours = value),
            min: 0,
            max: 12,
          ),
          const SizedBox(width: 16),
          _NumberPicker(
            value: _minutes,
            label: 'Minutes',
            onChanged: (value) => setState(() => _minutes = value),
            min: 0,
            max: 59,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            Duration(hours: _hours, minutes: _minutes),
          ),
          child: Text('Set', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final int value;
  final String label;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const _NumberPicker({
    required this.value,
    required this.label,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: GoogleFonts.poppins(fontSize: 24),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text(label, style: GoogleFonts.poppins()),
      ],
    );
  }
}
