// lib/filter.dart
import 'package:flutter/material.dart';
import 'package:xenodate/models/profile.dart'; // Assuming Profile model
import 'package:xenodate/models/filter.dart'; // Import your FilterCriteria model

class Filter extends StatefulWidget {
  final ValueNotifier<FilterCriteria> filterCriteriaNotifier;
  final Function(FilterCriteria) onApplyFilters;

  const Filter({
    Key? key,
    required this.filterCriteriaNotifier,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  late FilterCriteria _currentFilters;

  // Available options
  final List<String> _availableGenders = ['Any', 'Male', 'Female', 'Non-binary']; // Corrected 'Femal'
  final List<String> _availableInterests = [
    'Conquering galaxies', 'Tea', 'Space pilot', 'Martial arts', 'Quantum physics',
    'Knitting nebulae', 'Heroism', 'Justice', 'Shiny boots', 'Astronomy',
    'Ancient languages', 'Exploring ruins'
  ];
  final List<String> _availableSpecies = [
    'Any', 'Earthian', 'Novuman', 'Farrman', 'Merkind', 'Mammalkind',
    'Snakekind', 'Featherfolk', 'Jellykind'
  ];
  final List<String> _availableLocations = [
    'Any', 'Earth', 'Moon & NECs', 'Mars & FECs', 'Keplia', 'Matobu',
    'Kir-Tak', 'Teagardgen'
  ];

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filterCriteriaNotifier.value;
  }

  // Helper method to build DropdownButtonFormField to reduce repetition
  Widget _buildDropdownFilter<T>({
    required String label,
    required T? currentValue,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:'),
        DropdownButtonFormField<T>(
          value: currentValue,
          items: items.map((T value) {
            return DropdownMenuItem<T>(
              value: value,
              child: Text(value.toString()), // Assuming T can be converted to string meaningfully
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
        SizedBox(height: 20),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Filter Profiles', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 20),

          // --- Age Range Example ---
          Text('Age Range: ${_currentFilters.minAge ?? 'Any'} - ${_currentFilters.maxAge ?? 'Any'}'),
          RangeSlider(
            values: RangeValues(
              (_currentFilters.minAge ?? 18).toDouble(),
              (_currentFilters.maxAge ?? 100).toDouble(),
            ),
            min: 18,
            max: 500,
            divisions: 482,
            labels: RangeLabels(
              _currentFilters.minAge?.toString() ?? '18',
              _currentFilters.maxAge?.toString() ?? '500',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(
                  minAge: values.start.round() == 18 && values.end.round() == 500 ? null : values.start.round(),
                  maxAge: values.start.round() == 18 && values.end.round() == 500 ? null : values.end.round(),
                  clearMinAge: values.start.round() == 18 && values.end.round() == 500,
                  clearMaxAge: values.start.round() == 18 && values.end.round() == 500,
                );
              });
            },
          ),
          SizedBox(height: 20),

          // --- Gender Filter ---
          _buildDropdownFilter<String>(
            label: 'Gender',
            currentValue: _currentFilters.gender ?? 'Any',
            items: _availableGenders,
            onChanged: (String? newValue) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(
                  gender: newValue == 'Any' ? null : newValue,
                  clearGender: newValue == 'Any',
                );
              });
            },
          ),

          // --- Species Filter ---
          _buildDropdownFilter<String>(
            label: 'Species',
            currentValue: _currentFilters.species ?? 'Any',
            items: _availableSpecies,
            onChanged: (String? newValue) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(
                  species: newValue == 'Any' ? null : newValue,
                  clearSpecies: newValue == 'Any',
                );
              });
            },
          ),

          // --- Location Filter ---
          _buildDropdownFilter<String>(
            label: 'Location',
            currentValue: _currentFilters.location ?? 'Any',
            items: _availableLocations,
            onChanged: (String? newValue) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(
                  location: newValue == 'Any' ? null : newValue,
                  clearLocation: newValue == 'Any',
                );
              });
            },
          ),

          // --- Interests Example (Multi-select Chips) ---
          Text('Interests:'),
          Wrap(
            spacing: 8.0,
            children: _availableInterests.map((interest) {
              final isSelected = _currentFilters.interests?.contains(interest) ?? false;
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    List<String> currentSelectedInterests = List.from(_currentFilters.interests ?? []);
                    if (selected) {
                      if (!currentSelectedInterests.contains(interest)) {
                        currentSelectedInterests.add(interest);
                      }
                    } else {
                      currentSelectedInterests.remove(interest);
                    }
                    _currentFilters = _currentFilters.copyWith(
                      interests: currentSelectedInterests.isEmpty ? null : currentSelectedInterests,
                      clearInterests: currentSelectedInterests.isEmpty,
                    );
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 30),

          // --- Apply Button ---
          Center(
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilters(_currentFilters);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Filters applied! Current: ${_currentFilters.toString()}')), // Added toString for debug
                );
              },
              child: Text('Apply Filters'),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _currentFilters = FilterCriteria.empty();
                });
                widget.onApplyFilters(FilterCriteria.empty());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Filters cleared!')),
                );
              },
              child: Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
