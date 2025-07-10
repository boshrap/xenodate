// lib/models/profile.dart (create this file)
class Profile {
  final String id; // Unique identifier
  final String name;
  final int age;
  final String gender;
  final List<String> interests;
  final String imageUrl;
  final String bio;
  // Add other relevant fields like location, occupation, etc.

  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.interests,
    required this.imageUrl,
    required this.bio,
  });

  // Optional: Factory constructor for creating a Profile from a Map (e.g., from Firestore)
  factory Profile.fromMap(Map<String, dynamic> data, String documentId) {
    return Profile(
      id: documentId,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      bio: data['bio'] ?? '',
    );
  }

  // Optional: Method to convert a Profile to a Map (e.g., for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'interests': interests,
      'imageUrl': imageUrl,
      'bio': bio,
    };
  }
}