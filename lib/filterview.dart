// lib/filterview.dart
import 'package:flutter/material.dart';
// Assuming Profile model might be used for context, but not directly in this file for filter logic
import 'package:xenodate/models/xenoprofile.dart';
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
  // Use _currentFilters to hold the state of the filters being edited in this view.
  late FilterCriteria _currentFilters;

  // Available options
  final List<String> _availableGenders = ['Any', 'Male', 'Female', 'Neutral'];
  final List<String> _availableInterests = [
    'Academic', 'Adaptation', 'Adventure', 'Arts', 'Communication', 'Craft',
    'Creative', 'Culture', 'Education', 'Entertainment', 'Fitness', 'Hobby',
    'Intellectual', 'Lifestyle', 'Personal', 'Professional', 'Recreation',
    'Science', 'Social', 'Spiritual', 'Technology'
  ];
  final List<String> _availableSpecies = [
    'Any', 'Human', 'Keplian', 'Matobun',
    'Kirtaki', 'Aviman', 'Teagardener'
  ];
  final List<String> _availableLocations = [
    'Any', 'Earth', 'Moon & NECs', 'Mars & FECs', 'Keplia', 'Matobo',
    'Kir-Tak',
  ];
  final List<String> _availableLookingFor = ['Any', 'Conversation', 'Friendship', 'Romance'];


  @override
  void initState() {
    super.initState();
    // Initialize _currentFilters with the value from the notifier.
    // This ensures that when the filter view is opened, it reflects the currently applied filters.
    _currentFilters = widget.filterCriteriaNotifier.value;
    // _currentCriteria was uninitialized and likely not needed if _currentFilters is maintained.
  }

  // This method is not explicitly called in your current setup,
  // but if it were, it should use _currentFilters.
  // The "Apply Filters" button's onPressed directly calls widget.onApplyFilters.
  // void _apply() {
  //   widget.onApplyFilters(_currentFilters);
  // }

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
              child: Text(value.toString()),
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
              (_currentFilters.maxAge ?? 100).toDouble(), // Assuming 100 was a placeholder, adjusting to 500 like divisions
            ),
            min: 18,
            max: 500, // Max age consistent with divisions
            divisions: 482, // (500 - 18)
            labels: RangeLabels(
              _currentFilters.minAge?.toString() ?? '18',
              _currentFilters.maxAge?.toString() ?? '500',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                // Determine if the range is effectively "Any"
                bool isAnyAge = values.start.round() == 18 && values.end.round() == 500;
                _currentFilters = _currentFilters.copyWith(
                  minAge: isAnyAge ? null : values.start.round(),
                  maxAge: isAnyAge ? null : values.end.round(),
                  clearMinAge: isAnyAge, // Explicitly set clear flags
                  clearMaxAge: isAnyAge,  // Explicitly set clear flags
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

          // --- Looking For Filter ---
          _buildDropdownFilter<String>(
            label: 'Looking For',
            currentValue: _currentFilters.lookingFor ?? 'Any',
            items: _availableLookingFor,
            onChanged: (String? newValue) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(
                  lookingFor: newValue == 'Any' ? null : newValue,
                  clearLookingFor: newValue == 'Any',
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
                    // Make a mutable copy of the current interests, or an empty list if null
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
                // When "Apply Filters" is pressed, pass the _currentFilters
                // (which have been updated by the UI elements)
                // back to the parent widget (MainView).
                widget.onApplyFilters(_currentFilters);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Filters applied! Current: ${_currentFilters.toString()}')),
                  );
                }
              },
              child: Text('Apply Filters'),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  // Reset _currentFilters to an empty state
                  _currentFilters = FilterCriteria.empty();
                });
                // Apply the empty filters immediately
                widget.onApplyFilters(FilterCriteria.empty());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Filters cleared!')),
                  );
                }
              },
              child: Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
