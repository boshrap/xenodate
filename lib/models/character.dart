// lib/models/character.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Character {
  final String id;
  final String name;
  final String? species;
  final int? age;
  final String? gender;
  final String? lookingFor; // Example of another field
  final String? biography;  // Example of another field
  final Timestamp? createdAt; // If you are using it for ordering

  Character({
    required this.id,
    required this.name,
    this.species,
    this.age,
    this.gender,
    this.lookingFor,
    this.biography,
    this.createdAt,
  });

  // Factory constructor to create a Character from a Firestore document
  factory Character.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Missing data for Character ${doc.id}");
    }
    return Character(
      id: doc.id,
      name: data['name'] ?? 'N/A', // Provide a default or handle null appropriately
      species: data['species'] as String?,
      age: data['age'] as int?,
      gender: data['gender'] as String?,
      lookingFor: data['lookingFor'] as String?,
      biography: data['biography'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  // Optional: Method to convert Character instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (species != null) 'species': species,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (lookingFor != null) 'lookingFor': lookingFor,
      if (biography != null) 'biography': biography,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
