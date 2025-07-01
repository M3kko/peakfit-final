import 'package:flutter/material.dart';

class InjuriesPage extends StatelessWidget {
  final Function(List<String>) onSelected;
  final List<String>? selectedValue;

  InjuriesPage({required this.onSelected, this.selectedValue});

  final List<String> injuries = [
    'No current injuries',
    'Knee issues',
    'Ankle issues',
    'Back issues',
    'Shoulder issues',
    'Wrist issues',
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
            'Do you have any injuries or physical limitations?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Select all that apply',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 30),
          ...injuries.map((injury) =>
              CheckboxListTile(
                title: Text(injury, style: TextStyle(fontSize: 18)),
                value: selected.contains(injury),
                onChanged: (bool? value) {
                  List<String> newSelected = List.from(selected);
                  if (value == true) {
                    newSelected.add(injury);
                  } else {
                    newSelected.remove(injury);
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