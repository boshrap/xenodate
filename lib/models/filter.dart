// lib/models/filter.dart
import 'package:flutter/foundation.dart';
import 'package:xenodate/models/xenoprofile.dart';

@immutable
class FilterCriteria {
  final int? minAge;
  final int? maxAge;
  final String? gender;
  final String? species;
  final String? location;
  final List<String>? interests;
  final String? lookingFor; // Make sure this is present

  const FilterCriteria({
    this.minAge,
    this.maxAge,
    this.gender,
    this.species,
    this.location,
    this.interests,
    this.lookingFor,
  });

  // Factory constructor for an "empty" or default state
  factory FilterCriteria.empty() {
    return FilterCriteria(
      minAge: null,
      maxAge: null,
      species: null,
      interests: null,
    );
  }

  // --- ADD THIS GETTER ---
  bool get isNotEmpty {
    // Returns true if any of the filter criteria are set
    return minAge != null ||
        maxAge != null ||
        (species != null && species!.isNotEmpty) ||
        (interests != null && interests!.isNotEmpty);
    // Add checks for other properties you might have
  }

  // --- ADD THIS METHOD ---
  bool matches(Xenoprofile profile) {
    // If a criterion is null or empty, it means "don't filter by this"
    // So, we only check if the criterion IS set AND the profile doesn't match.

    if (profile.earthage == null) {
      // If this filter has an age constraint, a profile with no age doesn't match
      if (minAge != null || maxAge != null) {
        return false;
      }
    } else {
      // profile.earthage is not null here
      if (minAge != null && profile.earthage! < minAge!) { // Use ! after null check
        return false;
      }
      if (maxAge != null && profile.earthage! > maxAge!) { // Use ! after null check
        return false;
      }
    }
    if (species != null && species!.isNotEmpty && profile.species.toLowerCase() != species!.toLowerCase()) {
      return false;
    }
    if (interests != null && interests!.isNotEmpty) {
      // Check if the profile has at least one of the specified interests
      bool interestMatch = false;
      for (String interest in interests!) {
        if (profile.interests.map((i) => i.toLowerCase()).contains(interest.toLowerCase())) {
          interestMatch = true;
          break;
        }
      }
      if (!interestMatch) {
        return false;
      }
    }
    // Add checks for other properties

    return true; // If all checks pass, the profile matches
  }

  FilterCriteria copyWith({
    int? minAge,
    int? maxAge,
    String? gender,
    String? species,
    String? location,
    List<String>? interests,
    String? lookingFor,
    bool clearMinAge = false,
    bool clearMaxAge = false,
    bool clearGender = false,
    bool clearSpecies = false,
    bool clearLocation = false,
    bool clearInterests = false,
    bool clearLookingFor = false,
  }) {
    return FilterCriteria(
      minAge: clearMinAge ? null : minAge ?? this.minAge,
      maxAge: clearMaxAge ? null : maxAge ?? this.maxAge,
      gender: clearGender ? null : gender ?? this.gender,
      species: clearSpecies ? null : species ?? this.species,
      location: clearLocation ? null : location ?? this.location,
      interests: clearInterests ? null : interests ?? this.interests,
      lookingFor: clearLookingFor ? null : lookingFor ?? this.lookingFor,
    );
  }

  // Optional: For debugging and the SnackBar message
  @override
  String toString() {
    return 'FilterCriteria(minAge: $minAge, maxAge: $maxAge, gender: $gender, species: $species, location: $location, interests: $interests, lookingFor: $lookingFor)';
  }

  // Optional: For equality checking if needed
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FilterCriteria &&
              runtimeType == other.runtimeType &&
              minAge == other.minAge &&
              maxAge == other.maxAge &&
              gender == other.gender &&
              species == other.species &&
              location == other.location &&
              listEquals(interests, other.interests) &&
              lookingFor == other.lookingFor;

  @override
  int get hashCode =>
      minAge.hashCode ^
      maxAge.hashCode ^
      gender.hashCode ^
      species.hashCode ^
      location.hashCode ^
      interests.hashCode ^
      lookingFor.hashCode;
}
