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
  final List<String>? interests; // Keep this as List<String> for filter input
  final String? lookingFor;

  const FilterCriteria({
    this.minAge,
    this.maxAge,
    this.gender,
    this.species,
    this.location,
    this.interests,
    this.lookingFor,
  });

  factory FilterCriteria.empty() {
    return FilterCriteria(
      minAge: null,
      maxAge: null,
      species: null,
      interests: null,
    );
  }

  bool get isNotEmpty {
    return minAge != null ||
        maxAge != null ||
        (species != null && species!.isNotEmpty) ||
        (interests != null && interests!.isNotEmpty);
  }

  bool matches(Xenoprofile profile) {
    if (profile.earthage == null) {
      if (minAge != null || maxAge != null) {
        return false;
      }
    } else {
      if (minAge != null && profile.earthage! < minAge!) {
        return false;
      }
      if (maxAge != null && profile.earthage! > maxAge!) {
        return false;
      }
    }
    if (species != null && species!.isNotEmpty && profile.species.toLowerCase() != species!.toLowerCase()) {
      return false;
    }

// --- MODIFIED INTERESTS CHECK ---
    if (interests != null && interests!.isNotEmpty) {
      if (profile.interests.isEmpty) { // If profile has no interests, it can't match.
        return false;
      }

      // Convert profile interests to lowercase for case-insensitive comparison
      List<String> profileInterestsLowercase = profile.interests.map((e) => e.toLowerCase()).toList();

      bool interestMatch = false;
      for (String filterInterest in interests!) { // Iterate through the filter's list of interests
        if (profileInterestsLowercase.contains(filterInterest.toLowerCase())) {
          interestMatch = true;
          break; // Found a match, no need to check further
        }
      }
      if (!interestMatch) {
        return false; // No common interest found
      }
    }
    // --- END OF MODIFIED INTERESTS CHECK ---


    return true;
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

  @override
  String toString() {
    return 'FilterCriteria(minAge: $minAge, maxAge: $maxAge, gender: $gender, species: $species, location: $location, interests: $interests, lookingFor: $lookingFor)';
  }

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
              listEquals(interests, other.interests) && // Keep listEquals here as FilterCriteria.interests is still a List
              lookingFor == other.lookingFor;

  @override
  int get hashCode =>
      minAge.hashCode ^
      maxAge.hashCode ^
      gender.hashCode ^
      species.hashCode ^
      location.hashCode ^
      interests.hashCode ^ // Keep .hashCode for List here
      lookingFor.hashCode;
}
