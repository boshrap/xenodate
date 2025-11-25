import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

// The schema you provided.
const worldBuildingTemplate = [
  {
    'scope': 'location',
    'location': '',
    'category': 'world',
    'subcategory': [
      'Name for World',
      'Planet Details',
      'Geology',
      'Atmosphere',
      'Satellites',
      'Orbital Mechanics'
    ],
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'regions',
    'subcategory': ['biomes', 'zones', 'borders', 'states'],
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'Oceans',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'continents',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'sub-continents',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'local features',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'local location',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'common flora',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'common fauna',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'Local Sapients',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'Global Organizations',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'Businesses',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'Local Politics',
    'subcategory': '',
    'content': '',
  },
  {
    'scope': 'location',
    'location': '',
    'category': 'Regional History',
    'subcategory': '',
    'content': '',
  },
];

class WorldBuildingForm extends StatefulWidget {
  const WorldBuildingForm({super.key});

  @override
  State<WorldBuildingForm> createState() => _WorldBuildingFormState();
}

class _WorldBuildingFormState extends State<WorldBuildingForm> {
  // Controllers and state variables to manage form input
  String? _selectedLocation;
  String? _selectedCategory;
  String? _selectedSubcategory;
  final _contentController = TextEditingController();
  bool _isLoading = false;


  // Lists to populate the dropdowns
  // Using the locations from your genui.dart context
  final List<String> _locations = const [
    'Keplia', 'Matobu', 'Savaa', 'Novumera', 'Vespera', 'Essoveria',
    'Twileria', 'Toivoa', 'Lyria', 'Biszaria', 'Teagarden'
  ];
  late final List<String> _categories;
  List<String> _currentSubcategories = [];

  @override
  void initState() {
    super.initState();
    // Populate the categories list from the schema when the widget is first created.
    // Using a Set handles duplicates automatically.
    _categories = worldBuildingTemplate
        .map((template) => template['category'] as String)
        .toSet()
        .toList();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the tree
    _contentController.dispose();
    super.dispose();
  }

  /// This method is called when the Category dropdown value changes.
  /// It finds the corresponding subcategories in the schema and updates the UI.
  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;

    setState(() {
      _selectedCategory = newCategory;
      // Reset subcategory selection whenever the category changes
      _selectedSubcategory = null;
      _currentSubcategories = [];

      // Find the template entry for the selected category
      final selectedTemplate = worldBuildingTemplate.firstWhere(
        (template) => template['category'] == newCategory,
        orElse: () => <String, Object>{}, // Return an empty map if not found
      );

      if (selectedTemplate.isNotEmpty) {
        final subcategoryData = selectedTemplate['subcategory'];
        // Check if the subcategory data is a non-empty list
        if (subcategoryData is List && subcategoryData.isNotEmpty) {
          // If it is, update our state variable to show the subcategory dropdown
          _currentSubcategories = List<String>.from(subcategoryData);
        }
      }
    });
  }

  Future<void> _submitForm() async {
  if (_selectedLocation == null || _selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a location and category.')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Get a reference to the callable function.
    final worldBuilder =
        FirebaseFunctions.instance.httpsCallable('worldBuilder');

    // Create the request data payload.
    final data = {
      'location': _selectedLocation,
      'category': _selectedCategory,
      'subcategory': _selectedSubcategory,
      'content': _contentController.text,
    };

    // Call the function and await the result.
    final result = await worldBuilder.call(data);
    final output = result.data; // The JSON array returned by the flow

    // For now, just print the result and show a success message.
    // You could navigate to a new screen to display the results,
    // or update the state of this widget.
    print('Flow Result: $output');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('World data generated successfully!')),
    );
  } on FirebaseFunctionsException catch (e) {
    print('Firebase Functions Exception: ${e.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}')),
    );
  } catch (e) {
    print('An unexpected error occurred: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An unexpected error occurred.')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Building Entry'),
      ),
      // Use SingleChildScrollView to prevent overflow on smaller screens
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Location Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  hint: const Text('Select Location'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLocation = newValue;
                    });
                  },
                  items:
                      _locations.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Select Category'),
                  onChanged: _onCategoryChanged,
                  items:
                      _categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Subcategory Dropdown (Conditional)
                // This widget is only built if there are subcategories for the selected category
                if (_currentSubcategories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedSubcategory,
                    hint: const Text('Select Subcategory'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubcategory = newValue;
                      });
                    },
                    items: _currentSubcategories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      border: OutlineInputBorder(),
                    ),
                  ),

                // Add spacing below the subcategory dropdown if it is visible
                if (_currentSubcategories.isNotEmpty)
                  const SizedBox(height: 24),

                // 4. Content Text Field
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    hintText: 'Enter the details here...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true, // Good for multi-line fields
                  ),
                  maxLines: 6, // Makes it a text area
                  minLines: 3,
                ),
                const SizedBox(height: 32),

                // 5. Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Entry'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
