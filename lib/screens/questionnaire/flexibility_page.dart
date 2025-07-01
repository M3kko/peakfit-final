import 'package:flutter/material.dart';

class FlexibilityPage extends StatelessWidget {
  final Function(String) onSelected;
  final String? selectedValue;

  FlexibilityPage({required this.onSelected, this.selectedValue});

  final Map<String, String> flexibilityLevels = {
    'Beginner': 'Basic stretches, limited range of motion',
    'Intermediate': 'Can do some splits, good general flexibility',
    'Advanced': 'Full splits in all directions, exceptional flexibility',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is your flexibility level?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          ...flexibilityLevels.entries.map((entry) =>
              RadioListTile<String>(
                title: Text(entry.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                subtitle: Text(entry.value, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                value: entry.key,
                groupValue: selectedValue,
                onChanged: (value) => onSelected(value!),
              ),
          ).toList(),
        ],
      ),
    );
  }
}