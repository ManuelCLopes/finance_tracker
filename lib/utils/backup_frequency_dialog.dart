import 'package:flutter/material.dart';
import '../services/app_localizations_service.dart'; 

class BackupFrequencyDialog extends StatelessWidget {
  final String? selectedFrequency;
  final void Function(String? frequency) onFrequencySelected;
  final VoidCallback onUnschedule;

  BackupFrequencyDialog({
    super.key,
    required this.selectedFrequency,
    required this.onFrequencySelected,
    required this.onUnschedule,
  });

  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.translate('select_backup_frequency') ?? 'Select Backup Frequency', 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: _frequencies.map((frequency) {
                bool isSelected = frequency == selectedFrequency;
                return ChoiceChip(
                  label: Text(
                    localizations?.translate(frequency.toLowerCase()) ?? frequency,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    onFrequencySelected(selected ? frequency : null);
                    Navigator.pop(context);
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (selectedFrequency != null)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    onUnschedule();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  ),
                  child: Text(localizations?.translate('unschedule_backup') ?? 'Unschedule Backup'), // Localized button text
                ),
              ),
          ],
        ),
      ),
    );
  }
}
