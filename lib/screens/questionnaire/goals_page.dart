import 'package:flutter/material.dart';

class GoalsPage extends StatelessWidget {
  final Function(List<String>) onSelected;
  final List<String>? selectedValue;

  GoalsPage({required this.onSelected, this.selectedValue});

  final List<String> goals = [
    'Increase vertical jump',
    'Improve agility/speed',
    'Build sport-specific strength',
    'Enhance flexibility/mobility',
    'Improve endurance/stamina',
    'Develop power/explosiveness',
  ];

  @override
  Widget build(BuildContext context) {
    List<String> selected = selectedValue ?? [];

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your training goals?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Select all that apply',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 30),
          ...goals.map((goal) =>
              CheckboxListTile(
                title: Text(goal, style: TextStyle(fontSize: 18)),
                value: selected.contains(goal),
                onChanged: (bool? value) {
                  List<String> newSelected = List.from(selected);
                  if (value == true) {
                    newSelected.add(goal);
                  } else {
                    newSelected.remove(goal);
                  }
                  onSelected(newSelected);
                },
              ),
          ).toList(),
        ],
      ),
    );
  }
}