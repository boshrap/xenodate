import 'package:xenodate/models/profile.dart'; // Import your Profile model


class FilterCriteria {
  final int? minAge;
  final int? maxAge;
  final String? gender;
  final List<String>? interests;
  // Add other filter options

  FilterCriteria({
    this.minAge,
    this.maxAge,
    this.gender,
    this.interests,
  });

  // Method to check if a profile matches the criteria
  bool matches(Profile profile) {
    if (minAge != null && profile.age < minAge!) return false;
    if (maxAge != null && profile.age > maxAge!) return false;
    if (gender != null && gender!.isNotEmpty && profile.gender.toLowerCase() != gender!.toLowerCase()) return false;
    if (interests != null && interests!.isNotEmpty) {
      if (!interests!.any((interest) => profile.interests.contains(interest))) {
        return false;
      }
    }
    return true;
  }

  // Optional: A way to represent an empty/default filter
  static FilterCriteria empty() => FilterCriteria();

  // Optional: A way to check if any filter is applied
  bool get isNotEmpty => minAge != null || maxAge != null || (gender != null && gender!.isNotEmpty) || (interests != null && interests!.isNotEmpty);
}