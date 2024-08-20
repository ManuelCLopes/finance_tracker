import 'package:flutter/material.dart';

class BackupFrequencySelector extends StatelessWidget {
  final String? selectedFrequency;
  final void Function(String? frequency) onFrequencySelected;
  final VoidCallback onUnschedule;

  BackupFrequencySelector({
    required this.selectedFrequency,
    required this.onFrequencySelected,
    required this.onUnschedule,
  });

  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Backup Frequency', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            children: _frequencies.map((frequency) {
              bool isSelected = frequency == selectedFrequency;
              return ChoiceChip(
                label: Text(frequency),
                selected: isSelected,
                onSelected: (selected) {
                  onFrequencySelected(selected ? frequency : null);
                  Navigator.pop(context);
                },
                selectedColor: Theme.of(context).primaryColor, // The color when selected
                backgroundColor: Colors.grey[200], // The color when not selected
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black, // Text color changes based on selection
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Optionally make text bold when selected
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Custom rounded shape if needed
                  side: BorderSide(
                    color: Theme.of(context).primaryColor, // Outline color when not selected
                    width: 1.0, // Thickness of the outline
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (selectedFrequency != null)
            ElevatedButton(
              onPressed: () {
                onUnschedule();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Unschedule Backup'),
            ),
        ],
      ),
    );
  }
}
