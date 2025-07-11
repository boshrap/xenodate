import 'package:flutter/material.dart';
import 'package:xenodate/photoupload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // If you have user authentication

class NewChar extends StatefulWidget {
  const NewChar({Key? key}) : super(key: key);

  @override
  State<NewChar> createState() => _NewCharState();
}

class _NewCharState extends State<NewChar> {
  // Controllers for TextFields
  final _nameController = TextEditingController();
  final _topicsController = TextEditingController();
  final _turnoffsController = TextEditingController();
  final _biographyController = TextEditingController();

  int sliderValue = 18;
  String? _selectedSpecies; // To store the selected species
  String? _selectedGender;
  String? _selectedLookingFor;

  // For simplicity, defining species options here. You might fetch these from a DB.
  final List<String> _speciesOptions = ["Human", "Klingon", "Vulcan"]; // Example options
  final List<String> _genderOptions = ["Male", "Female", "Other"];
  final List<String> _lookingForOptions = ["Friendship", "Dating", "Networking"];

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _nameController.dispose();
    _topicsController.dispose();
    _turnoffsController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _saveCharacter() async {
    // --- Get the current user (assuming you have Firebase Auth implemented) ---
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle the case where the user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You must be logged in to save a character.')),
      );
      return;
    }
    // --- ---

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name.')),
      );
      return;
    }
    if (_selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a species.')),
      );
      return;
    }
    // Add more validation as needed for other fields

    try {
      // Get a reference to the Firestore collection
      CollectionReference characters = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('characters');

      // Add a new document with a generated ID
      await characters.add({
        'name': _nameController.text,
        'species': _selectedSpecies,
        'age': sliderValue,
        'gender': _selectedGender,
        'lookingFor': _selectedLookingFor,
        'topics': _topicsController.text,
        'turnoffs': _turnoffsController.text,
        'biography': _biographyController.text,
        'createdAt': FieldValue.serverTimestamp(), // Optional: to know when it was created
        // 'userId': user.uid, // You can store the userId here too if your collection isn't nested
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Character saved successfully!')),
      );

      // Navigate to the next screen
      if (mounted) { // Check if the widget is still in the tree
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PhotoUpload()), // Assuming PhotoUpload takes a characterId or similar
        );
      }

    } catch (e) {
      print('Error saving character: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save character: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.network(
          'logo/Xenodate-logo.png', // Make sure this path is correct or use Image.asset
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Text("Xenodate"), // Fallback for image load error
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Text("Name")),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: "Enter character name")),
            const Divider(),
            const Center(child: Text("Species")),
            // --- Using DropdownButton for single selection or ToggleButtons for multiple ---
            // Example using Wrap with ChoiceChips for better UI
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: _speciesOptions.map((species) {
                return ChoiceChip(
                  label: Text(species),
                  selected: _selectedSpecies == species,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSpecies = selected ? species : null;
                    });
                  },
                );
              }).toList(),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Age: $sliderValue"),
              ],
            ),
            Slider(
              value: sliderValue.toDouble(),
              min: 18,
              max: 110,
              divisions: 92,
              label: sliderValue.toString(),
              onChanged: (value) {
                setState(() {
                  sliderValue = value.toInt();
                });
              },
            ),
            const Center(child: Text("Gender")),
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: _genderOptions.map((gender) {
                return ChoiceChip(
                  label: Text(gender),
                  selected: _selectedGender == gender,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGender = selected ? gender : null;
                    });
                  },
                );
              }).toList(),
            ),
            const Divider(),
            const Center(child: Text("Looking For")),
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: _lookingForOptions.map((lookingFor) {
                return ChoiceChip(
                  label: Text(lookingFor),
                  selected: _selectedLookingFor == lookingFor,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLookingFor = selected ? lookingFor : null;
                    });
                  },
                );
              }).toList(),
            ),
            const Divider(),
            const Center(child: Text("Topics")),
            TextField(controller: _topicsController, decoration: const InputDecoration(hintText: "e.g., Space travel, Philosophy")),
            const Center(child: Text("Turnoffs")),
            TextField(controller: _turnoffsController, decoration: const InputDecoration(hintText: "e.g., Loud chewing, Negativity")),
            const Center(child: Text("Biography")),
            TextField(controller: _biographyController, maxLines: 3, decoration: const InputDecoration(hintText: "Tell us about your character...")),
            const SizedBox(height: 20), // Added some spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _saveCharacter, // Call the save function
                  child: const Text("Save & Continue"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
