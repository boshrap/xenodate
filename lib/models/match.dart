import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id; // Unique identifier for the match itself
  final String characterId; // ID of the user's character involved in the match
  final String xenoProfileId; // This should correspond to Xenoprofile.uid
  final String chatId;
  final DateTime matchedAt;
  final bool hidden;
  final bool unmatched;

  Match({
    required this.id,
    required this.characterId,
    required this.xenoProfileId, // This ID links to a Xenoprofile
    required this.chatId,
    required this.matchedAt,
    this.hidden = false,
    this.unmatched = false,
  });



  factory Match.fromJson(Map<String, dynamic> json) {
    // Validate incoming JSON data (New in Dart 3 - using pattern matching)
    // This helps ensure the JSON has the expected structure before trying to access fields.
    // For more complex validation, you might want to create a more detailed pattern.
    if (json
    case {
    'id': String id,
    'characterId': String characterId,
    'xenoProfileId': String xenoProfileId,
    'matchedAt': String matchedAtString
    }) {
      return Match(
        id: id,
        characterId: characterId,
        xenoProfileId: xenoProfileId,
        matchedAt: DateTime.parse(matchedAtString),
        chatId: json['chatId'] as String,
        hidden: json['hidden'] as bool? ?? false,
        unmatched: json['unmatched'] as bool? ?? false,
      );
    } else {
      // Handle cases where the JSON doesn't match the expected structure.
      // You could throw an error, return a default Match object, or handle it differently.
      throw FormatException('Invalid JSON for Match: $json');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'xenoProfileId': xenoProfileId,
      'matchedAt': matchedAt.toIso8601String(),
      'chatId': chatId,
      'hidden': hidden,
      'unmatched': unmatched,
    };
  }

  // Factory constructor to create a Match from a Firestore DocumentSnapshot
  factory Match.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    if (data == null) {
      // It's crucial to handle the case where data might be null,
      // though Firestore queries with converters usually expect data.
      // Depending on your logic, you might throw an error or return a default/empty Match.
      // For now, let's assume data is always present if the document exists.
      throw StateError("Missing data for Match snapshot: ${snapshot.id}");
    }

    return Match(
      id: snapshot.id,
      characterId: data['characterId'] as String,
      xenoProfileId: data['xenoProfileId'] as String,
      // Ensure 'matchedAt' is stored as a Timestamp in Firestore
      matchedAt: (data['matchedAt'] as Timestamp).toDate(),
      chatId: data['chatId'] as String,
      unmatched: data['unmatched'] as bool? ?? false,
      hidden: data['hidden'] as bool? ?? false,
      // Add other fields here, ensuring type safety and handling potential nulls
    );
  }

  // Method to convert a Match instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'characterId': characterId,
      'xenoProfileId': xenoProfileId,
      'matchedAt': Timestamp.fromDate(matchedAt), // Store as Timestamp
      if (chatId != null) 'chatId': chatId,
      'unmatched': unmatched,
      'hidden': hidden,
      // Add other fields
    };
  }
}


