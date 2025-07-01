import 'package:flutter/material.dart';

class SportPage extends StatelessWidget {
  final Function(String) onSelected;
  final String? selectedValue;

  SportPage({required this.onSelected, this.selectedValue});

  final List<String> sports = [
    'Figure skating',
    'Basketball',
    'Soccer',
    'Track & Field',
    'Gymnastics',
    'Dance',
    'Tennis',
    'Volleyball',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is your main sport?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          ...sports.map((sport) =>
              RadioListTile<String>(
                title: Text(sport, style: TextStyle(fontSize: 18)),
                value: sport,
                groupValue: selectedValue,
                onChanged: (value) => onSelected(value!),
              ),
          ).toList(),
        ],
      ),
    );
  }
}