//firebase datamodel for xenoprofiles
import 'package:cloud_firestore/cloud_firestore.dart';


Future<Xenoprofile?> fetchProfile(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('xenoprofiles') // Changed collection name
        .doc(uid)
        .get();

    if (doc.exists) {
      return Xenoprofile.fromJson(doc.data()!);
    }
  } catch (e) {
    print("Error fetching profile: $e");
  }
  return null;
}

class Xenoprofile {
  final String uid; // Unique identifier
  final String name;
  final String surname;
  final int? earthage; // Changed to nullable int to match safe parsing
  final String gender;
  final List<String> interests;
  final String likes;
  final String dislikes;
  final String imageUrl;
  final String bio;
  final String species;
  final String subspecies;
  final String location;
  final String lookingfor;
  final String orientation;
  final String redflags;
  // Add other relevant fields like location, occupation, etc.

  Xenoprofile({
    required this.uid,
    required this.surname,
    required this.name,
    this.earthage, // earthage is now nullable
    required this.gender,
    required this.interests,
    required this.likes,
    required this.dislikes,
    required this.imageUrl,
    required this.bio,
    required this.species,
    required this.subspecies,
    required this.location,
    required this.lookingfor,
    required this.orientation,
    required this.redflags,
  });

  factory Xenoprofile.fromJson(Map<String, dynamic> json) => Xenoprofile(
    uid: json['uid'] as String,
    name: json['name'] as String,
    surname: json['surname'] as String,
    earthage: json['earthage'] as int?, // Safe parsing for nullable int
    gender: json['gender'] as String,
    interests: List<String>.from(json['interests'] as List<dynamic>),
    likes: json['likes'] as String,
    dislikes: json['dislikes'] as String,
    imageUrl: json['imageUrl'] as String,
    bio: json['bio'] as String,
    species: json['species'] as String,
    subspecies: json['subspecies'] as String,
    location: json['location'] as String,
    lookingfor: json['lookingfor'] as String,
    orientation: json['orientation'] as String,
    redflags: json['redflags'] as String,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'surname': surname,
    'earthage': earthage,
    'gender': gender,
    'interests': interests,
    'likes': likes,
    'dislikes': dislikes,
    'imageUrl': imageUrl,
    'bio': bio,
    'species': species,
    'subspecies': subspecies,
    'location': location,
    'lookingfor': lookingfor,
    'orientation': orientation,
    'redflags': redflags,
  };
}

// You can remove the old ChatbotProfile, BasicInfo, Name, Identity, Traits,
// Appearance, Anatomy, Psychology, Background, Personality, and Flags classes
// if Xenoprofile is replacing them. Otherwise, keep them if they are still needed.
