// JSON Data Model
import 'package:cloud_firestore/cloud_firestore.dart';


class Xenoprofile {
  final String id; // Unique identifier
  final String name;
  final String surname;
  final int? earthage; // Changed to nullable int to match safe parsing
  final String gender;
  final List<String> interests;
  final String likes;
  final String dislikes;
  final String imageUrl;
  final String biography;
  final String species;
  final String subspecies;
  final String location;
  final String lookingfor;
  final String orientation;
  final String redflags;
  // Add other relevant fields like location, occupation, etc.

  Xenoprofile({
    required this.id,
    required this.surname,
    required this.name,
    this.earthage, // earthage is now nullable
    required this.gender,
    required this.interests,
    required this.likes,
    required this.dislikes,
    required this.imageUrl,
    required this.biography,
    required this.species,
    required this.subspecies,
    required this.location,
    required this.lookingfor,
    required this.orientation,
    required this.redflags,
  });

  // Helper function to safely parse an int, handling potential Strings or nulls
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    // Optionally, log or handle unexpected types
    // print('Warning: Unexpected type for integer parsing: ${value.runtimeType}');
    return null;
  }

// Factory constructor for creating a Profile from a Map (e.g., from a JSON file)
  factory Xenoprofile.fromJson(Map<String, dynamic> json) {
    List<String> _parseInterests(dynamic value) {
      if (value is String) {
        return value.split(',').map((interest) => interest.trim()).toList();
      }
      // If it's somehow already a list (though unlikely if Firebase stores it as a string)
      else if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    return Xenoprofile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      earthage: _parseInt(json['earthage']),
      gender: json['gender'] as String? ?? '',
      interests: _parseInterests(json['interests']), // Parse string to List<String>
      likes: json['likes'] as String? ?? '',
      dislikes: json['dislikes'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      biography: json['biography'] as String? ?? '',
      species: json['species'] as String? ?? '',
      subspecies: json['subspecies'] as String? ?? '',
      location: json['location'] as String? ?? '',
      lookingfor: json['lookingfor'] as String? ?? '',
      orientation: json['orientation'] as String? ?? '',
      redflags: json['redflags'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'earthage': earthage,
      'gender': gender,
      'interests': interests.join(','), // Convert List<String> to a comma-separated String
      'likes': likes,
      'dislikes': dislikes,
      'imageUrl': imageUrl,
      'biography': biography,
      'species': species,
      'subspecies': subspecies,
      'location': location,
      'lookingfor': lookingfor,
      'orientation': orientation,
      'redflags': redflags,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'earthage': earthage,
      'gender': gender,
      'interests': interests.join(','), // Convert List<String> to a comma-separated String
      'likes': likes,
      'dislikes': dislikes,
      'imageUrl': imageUrl,
      'biography': biography,
      'species': species,
      'subspecies': subspecies,
      'location': location,
      'lookingfor': lookingfor,
      'orientation': orientation,
      'redflags': redflags,
    };
  }}
