import 'dart:convert'; // For jsonDecode
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:xenodate/models/xenoprofile.dart'; // Adjust the path as necessary

Future<List<Xenoprofile>> loadXenoprofiles() async {
  try {
    // 1. Load the JSON string from the asset file
    final String jsonString = await rootBundle.loadString('assets/profiles/xenopersonas_DATA.json');

    // 2. Decode the JSON string
    //    This assumes your xenopersonas_data.json is a list of profiles
    //    e.g., [ { "name": "...", ... }, { "name": "...", ... } ]
    final dynamic jsonData = jsonDecode(jsonString);

    if (jsonData is List) {
      // 3. Map each JSON object in the list to a Xenoprofile object
      List<Xenoprofile> profiles = jsonData
          .map((profileJson) => Xenoprofile.fromJson(profileJson as Map<String, dynamic>))
          .toList();
      return profiles;
    } else if (jsonData is Map<String, dynamic>) {
      // If the JSON is a single profile object, not a list
      return [Xenoprofile.fromJson(jsonData)];
    } else {
      print('Error: JSON data is not in the expected format (List or Map).');
      return [];
    }
  } catch (e) {
    print('Error loading or parsing xenoprofiles: $e');
    return []; // Return an empty list or handle the error appropriately
  }
}

// Example usage:
void main() async {
  List<Xenoprofile> profiles = await loadXenoprofiles();
  for (var profile in profiles) {
    print('Loaded profile: ${profile.name}');
  }
}