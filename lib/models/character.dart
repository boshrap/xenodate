// Firestore Data Model
// lib/models/character.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Character {
  final String id;
  final String? uid; // Add this line
  final String name;
  final String? species;
  final int? age;
  final String? gender;
  final String? lookingFor; // Example of another field
  final String? biography;  // Example of another field
  final Timestamp? createdAt; // If you are using it for ordering

  Character({
    required this.id,
    this.uid, // Add this line
    required this.name,
    this.species,
    this.age,
    this.gender,
    this.lookingFor,
    this.biography,
    this.createdAt,
  });

  Character copyWith({
    String? id,
    String? uid,
    String? name,
    String? species,
    int? age,
    String? gender,
    String? lookingFor,
    String? biography,
    Timestamp? createdAt,
  }) {
    return Character(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      species: species ?? this.species,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      biography: biography ?? this.biography,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Character.fromJson(Map<String, dynamic> json, String id) {
    return Character(
      id: json['id'] as String,
      uid: json['uid'],
      name: json['name'],
      species: json['species'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      lookingFor: json['lookingFor'] as String?,
      biography: json['biography'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // You should also include other fields in JSON here
      // For example:
      if (uid != null) 'uid': uid,
      if (species != null) 'species': species,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (lookingFor != null) 'lookingFor': lookingFor,
      if (biography != null) 'biography': biography,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }


  // Factory constructor to create a Character from a Firestore document
  factory Character.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, snapshot) {
    final data = snapshot.data();
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
