import 'package:flutter/material.dart';

class AgePage extends StatelessWidget {
  final Function(String) onSelected;
  final String? selectedValue;

  AgePage({required this.onSelected, this.selectedValue});

  final List<String> ageRanges = [
    'Under 13',
    '13-17',
    '18-24',
    '25-34',
    '35-44',
    '45+',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is your age?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          ...ageRanges.map((age) =>
              RadioListTile<String>(
                title: Text(age, style: TextStyle(fontSize: 18)),
                value: age,
                groupValue: selectedValue,
                onChanged: (value) => onSelected(value!),
              ),
          ).toList(),
        ],
      ),
    );
  }
}