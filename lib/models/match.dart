class Match {
  final String id; // Unique identifier for the match itself
  final String characterId; // ID of the user's character involved in the match
  final String xenoProfileId; // This should correspond to Xenoprofile.uid
  final DateTime matchedAt;
  final bool hidden;
  final bool unmatched;

  Match({
    required this.id,
    required this.characterId,
    required this.xenoProfileId, // This ID links to a Xenoprofile
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
      'hidden': hidden,
      'unmatched': unmatched,
    };
  }
}
