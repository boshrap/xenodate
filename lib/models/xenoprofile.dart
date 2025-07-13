class Xenoprofile {
  final String uid; // Unique identifier
  final String name;
  final String surname;
  final int earthage;
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
    required this.earthage,
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

// Factory constructor for creating a Profile from a Map (e.g., from a JSON file)
  factory Xenoprofile.fromJson(Map<String, dynamic> json) {
    return Xenoprofile(
      uid: json['uid'] as String? ?? '', // Handle potential null 'uid'
      name: json['name'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      earthage: json['earthage'] as int? ?? 0,
      gender: json['gender'] as String? ?? '',
      interests: List<String>.from(json['interests'] as List<dynamic>? ?? []),
      likes: json['likes'] as String? ?? '',        // Corrected key to lowercase
      dislikes: json['dislikes'] as String? ?? '',  // Corrected key to lowercase
      imageUrl: json['imageUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      species: json['species'] as String? ?? '',
      subspecies: json['subspecies'] as String? ?? '',
      location: json['location'] as String? ?? '',
      lookingfor: json['lookingfor'] as String? ?? '',
      orientation: json['orientation'] as String? ?? '', // Added orientation
      redflags: json['redflags'] as String? ?? '',    // Corrected key to lowercase
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // Added uid
      'name': name,
      'surname': surname,
      'earthage': earthage, // Corrected key from 'age' to 'earthage'
      'gender': gender,
      'interests': interests,
      'likes': likes,        // Corrected key to lowercase
      'dislikes': dislikes,  // Corrected key to lowercase
      'imageUrl': imageUrl,
      'bio': bio,
      'species': species,
      'subspecies': subspecies,
      'location': location,
      'lookingfor': lookingfor, // Added lookingfor
      'orientation': orientation,
      'redflags': redflags,    // Corrected key to lowercase
    };
    }}
