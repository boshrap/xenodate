// lib/filter.dart
import 'package:flutter/material.dart';
import 'package:xenodate/models/profile.dart'; // Assuming Profile model
import 'package:xenodate/models/filter.dart'; // Import your FilterCriteria model

class Filter extends StatefulWidget {
  final ValueNotifier<FilterCriteria> filterCriteriaNotifier; // To receive current and update
  final Function(FilterCriteria) onApplyFilters; // Callback to MainView

  const Filter({
    Key? key,
    required this.filterCriteriaNotifier,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  // Local state to hold temporary filter changes before applying
  late FilterCriteria _currentFilters;

  // Example available options (you might fetch these from somewhere or define them)
  final List<String> _availableGenders = ['Any', 'Male', 'Female', 'Non-binary'];
  final List<String> _availableInterests = ['Conquering galaxies', 'Tea', 'Space pilot', 'Martial arts', 'Quantum physics', 'Knitting nebulae', 'Heroism', 'Justice', 'Shiny boots', 'Astronomy', 'Ancient languages', 'Exploring ruins'];


  @override
  void initState() {
    super.initState();
    // Initialize local state with the current global filters
    _currentFilters = widget.filterCriteriaNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // In case filters take up space
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
              (_currentFilters.minAge ?? 18).toDouble(), // Default min age
              (_currentFilters.maxAge ?? 100).toDouble(), // Default max age
            ),
            min: 18,
            max: 500, // Max age for aliens!
            divisions: 482,
            labels: RangeLabels(
              _currentFilters.minAge?.toString() ?? '18',
              _currentFilters.maxAge?.toString() ?? '500',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _currentFilters = FilterCriteria(
                  minAge: values.start.round() == 18 && values.end.round() == 500 ? null : values.start.round(), // Null if default range
                  maxAge: values.start.round() == 18 && values.end.round() == 500 ? null : values.end.round(),
                  gender: _currentFilters.gender,
                  interests: _currentFilters.interests,
                );
              });
            },
          ),
          SizedBox(height: 20),

          // --- Gender Example ---
          Text('Gender:'),
          DropdownButtonFormField<String>(
            value: _currentFilters.gender ?? 'Any',
            items: _availableGenders.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _currentFilters = FilterCriteria(
                  minAge: _currentFilters.minAge,
                  maxAge: _currentFilters.maxAge,
                  gender: newValue == 'Any' ? null : newValue, // Null if 'Any'
                  interests: _currentFilters.interests,
                );
              });
            },
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          SizedBox(height: 20),

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
                      currentSelectedInterests.add(interest);
                    } else {
                      currentSelectedInterests.remove(interest);
                    }
                    _currentFilters = FilterCriteria(
                      minAge: _currentFilters.minAge,
                      maxAge: _currentFilters.maxAge,
                      gender: _currentFilters.gender,
                      interests: currentSelectedInterests.isEmpty ? null : currentSelectedInterests,
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
                // Update the global filter criteria in MainView
                widget.onApplyFilters(_currentFilters);
                // widget.filterCriteriaNotifier.value = _currentFilters; // Alternative

                // Optional: Give feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Filters applied!')),
                );

                // Optional: Switch back to swipe view?
                // Provider.of<ValueNotifier<Selector>>(context, listen: false).value = Selector.swipe;
              },
              child: Text('Apply Filters'),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _currentFilters = FilterCriteria.empty(); // Reset local state
                });
                widget.onApplyFilters(FilterCriteria.empty()); // Apply empty filter
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
