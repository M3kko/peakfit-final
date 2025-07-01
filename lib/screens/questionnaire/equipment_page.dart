import 'package:flutter/material.dart';

class EquipmentPage extends StatelessWidget {
  final Function(List<String>) onSelected;
  final List<String>? selectedValue;

  EquipmentPage({required this.onSelected, this.selectedValue});

  final List<String> equipment = [
    'None (bodyweight only)',
    'Jump rope',
    'Resistance bands',
    'Dumbbells',
    'Plyometric box',
    'Balance board',
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
            'What equipment do you have available?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Select all that apply',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 30),
          ...equipment.map((item) =>
              CheckboxListTile(
                title: Text(item, style: TextStyle(fontSize: 18)),
                value: selected.contains(item),
                onChanged: (bool? value) {
                  List<String> newSelected = List.from(selected);
                  if (value == true) {
                    newSelected.add(item);
                  } else {
                    newSelected.remove(item);
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