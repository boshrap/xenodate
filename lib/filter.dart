import 'package:flutter/material.dart';

class Filter extends StatefulWidget {
  const Filter({Key? key}) : super(key: key);

  @override
  State<Filter> createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  // Define variables to keep track of selected values
  String _selectedSpecies = '';
  String _selectedGender = '';
  String _selectedLocation = '';

  // List of species
  final List<String> _species = [
    'Earthian',
    'Novuman',
    'Matouban',
    'Aviman',
    'Visyenynen',
    'Teagarderer',
    'Far-Verser',
  ];

  // List of genders
  final List<String> _genders = ['Male', 'Female', 'Non-Binary'];

  // List of locations
  final List<String> _locations = [
    'Moon & Near Earth Colonies',
    'Mars & Colonies',
    'Keplia (Kepler System)',
    'Matobu (Andromeda System)',
    'Kaah-Hiiz (Trappist System)',
    'Planet Teagarden (Teagarden System)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Species'),
            ..._species.map((species) {
              return SelectableButton(
                text: species,
                isSelected: _selectedSpecies == species,
                onPressed: () {
                  setState(() {
                    _selectedSpecies = species;
                  });
                },
              );
            }).toList(),
            const Divider(),
            const Text('Gender'),
            ..._genders.map((gender) {
              return SelectableButton(
                text: gender,
                isSelected: _selectedGender == gender,
                onPressed: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                },
              );
            }).toList(),
            const Divider(),
            const Text('Location'),
            ..._locations.map((location) {
              return SelectableButton(
                text: location,
                isSelected: _selectedLocation == location,
                onPressed: () {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// Custom SelectableButton widget
class SelectableButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const SelectableButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected? Colors.blue : Colors.grey,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}