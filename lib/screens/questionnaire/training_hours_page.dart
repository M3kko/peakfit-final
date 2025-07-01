import 'package:flutter/material.dart';

class TrainingHoursPage extends StatelessWidget {
  final Function(String) onSelected;
  final String? selectedValue;

  TrainingHoursPage({required this.onSelected, this.selectedValue});

  final List<String> trainingHours = [
    '1-5 hours',
    '6-10 hours',
    '11-15 hours',
    '16-20 hours',
    '20+ hours',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many hours do you spend training/practicing your sport per week?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          ...trainingHours.map((hours) =>
              RadioListTile<String>(
                title: Text(hours, style: TextStyle(fontSize: 18)),
                value: hours,
                groupValue: selectedValue,
                onChanged: (value) => onSelected(value!),
              ),
          ).toList(),
        ],
      ),
    );
  }
}