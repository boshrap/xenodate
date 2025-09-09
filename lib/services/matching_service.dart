import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:xenodate/models/character.dart';
import 'package:xenodate/models/xenoprofile.dart';
import 'package:xenodate/models/match.dart';
import 'dart:math';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add FirebaseAuth instance

  // Helper function to get the user-specific matches collection
  CollectionReference _getMatchesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('matches');
  }


  // Generate a unique chat ID for a new match
  String _generateChatId() {
    return _firestore.collection('chats').doc().id;
  }

  // Calculate compatibility score between a character and xenoprofile
  double calculateCompatibilityScore(Character character, Xenoprofile xenoprofile) {
    double score = 0.0;
    double maxScore = 0.0;

    // Age compatibility (weight: 20%)
    if (character.age != null && xenoprofile.earthage != null) {
      int ageDiff = (character.age! - xenoprofile.earthage!).abs();
      double ageScore = ageDiff <= 5 ? 1.0 :
      ageDiff <= 10 ? 0.7 :
      ageDiff <= 15 ? 0.4 : 0.1;
      score += ageScore * 0.2;
    }
    maxScore += 0.2;

    // Gender compatibility (weight: 15%)
    if (character.lookingFor != null && xenoprofile.gender.isNotEmpty) {
      if (character.lookingFor!.toLowerCase() == xenoprofile.gender.toLowerCase() ||
          character.lookingFor!.toLowerCase() == 'any') {
        score += 0.15;
      }
    }
    maxScore += 0.15;

    // Species compatibility (weight: 10%)
    if (character.species != null && xenoprofile.species.isNotEmpty) {
      if (character.species!.toLowerCase() == xenoprofile.species.toLowerCase()) {
        score += 0.1;
      }
    }
    maxScore += 0.1;

    // Bio/personality compatibility (weight: 25%)
    if (character.biography != null && xenoprofile.biography.isNotEmpty) {
      double bioScore = _calculateTextSimilarity(character.biography!, xenoprofile.biography);
      score += bioScore * 0.25;
    }
    maxScore += 0.25;

    // Interests compatibility (weight: 30%)
    if (character.biography != null && xenoprofile.interests.isNotEmpty) {
      double interestsScore = _calculateInterestsCompatibility(character.biography!, xenoprofile.interests as List<String>);
      score += interestsScore * 0.3;
    }
    maxScore += 0.3;

    // Normalize score to 0-1 range
    return maxScore > 0 ? score / maxScore : 0.0;
  }

  // Calculate text similarity using simple keyword matching
  double _calculateTextSimilarity(String text1, String text2) {
    List<String> words1 = text1.toLowerCase().split(RegExp(r'\W+'));
    List<String> words2 = text2.toLowerCase().split(RegExp(r'\W+'));

    // Remove common words
    List<String> commonWords = ['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'can', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'her', 'its', 'our', 'their'];

    words1 = words1.where((word) => word.length > 2 && !commonWords.contains(word)).toList();
    words2 = words2.where((word) => word.length > 2 && !commonWords.contains(word)).toList();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    int commonWordsCount = 0;
    for (String word in words1) {
      if (words2.contains(word)) {
        commonWordsCount++;
      }
    }

    return commonWordsCount / max(words1.length, words2.length);
  }

  // Calculate interests compatibility
  double _calculateInterestsCompatibility(String biography, List<String> interests) {
    String bioLower = biography.toLowerCase();
    int matchingInterests = 0;

    for (String interest in interests) {
      if (bioLower.contains(interest.toLowerCase())) {
        matchingInterests++;
      }
    }

    return interests.isEmpty ? 0.0 : matchingInterests / interests.length;
  }

  // Create a match between character and xenoprofile
  Future<Match?> createMatch(Character character, Xenoprofile xenoprofile) async { // Removed userId parameter
    try {
      // Get the current user from Firebase Auth
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('Error creating match: No user is currently signed in.');
        return null; // Or throw an exception
      }

      final String userId = currentUser.uid; // Use the UID of the logged-in user

      final matchesCollection = _getMatchesCollection(userId);
      // Check if match already exists
      QuerySnapshot existingMatch = await matchesCollection
          .where('characterId', isEqualTo: character.id)
          .where('xenoProfileId', isEqualTo: xenoprofile.id)
          .limit(1)
          .get();

      if (existingMatch.docs.isNotEmpty) {
        print('Match already exists between ${character.name} and ${xenoprofile.name}');
        return null;
      }

      // Generate unique match ID and chat ID
      String matchId = matchesCollection.doc().id;
      String chatId = _generateChatId();

      // Create new match
      Match newMatch = Match(
        id: matchId,
        characterId: character.id,
        xenoProfileId: xenoprofile.id,
        chatId: chatId,
        matchedAt: DateTime.now(),
        hidden: false,
        unmatched: false,
      );



      // Save to Firestore
      await matchesCollection.doc(matchId).set(newMatch.toFirestore());

      print('Match created successfully: ${character.name} ↔ ${xenoprofile.name}');
      print('Chat ID: $chatId');
      return newMatch;

    } catch (e) {
      print('Error creating match: $e');
      return null;
    }
  }

  // Get all matches for a character
  // The userId here should be the user who owns the character.
  Future<List<Match>> getMatchesForCharacter(String characterId) async { // Removed userId parameter
    try {
      // Get the current user from Firebase Auth
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('Error fetching matches: No user is currently signed in.');
        return []; // Or throw an exception
      }
      final String userId = currentUser.uid;


      final matchesCollection = _getMatchesCollection(userId);
      QuerySnapshot snapshot = await matchesCollection
          .where('characterId', isEqualTo: characterId)
          .where('unmatched', isEqualTo: false)
          .orderBy('matchedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Match.fromJson(data);
      }).toList();

    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }

  // Check if two profiles are compatible based on minimum threshold
  bool areCompatible(Character character, Xenoprofile xenoprofile, {double threshold = 0.3}) {
    return calculateCompatibilityScore(character, xenoprofile) >= threshold;
  }

  // Get character by ID (you'll need to implement this based on your data structure)
  Future<Character?> getCharacterById(String characterId) async {
    try {
      // This assumes characters are in a top-level collection.
      // Adjust if characters are also under a user document.
      DocumentSnapshot doc = await _firestore.collection('characters').doc(characterId).get();
      if (doc.exists) {
        return Character.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, doc);
      }
      return null;
    } catch (e) {
      print('Error fetching character: $e');
      return null;
    }
  }

  // Remove/unmatch a match
  Future<bool> unmatchProfiles(String matchId) async { // Removed userId parameter
    try {
      // Get the current user from Firebase Auth
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('Error unmatching profiles: No user is currently signed in.');
        return false; // Or throw an exception
      }
      final String userId = currentUser.uid;

      final matchesCollection = _getMatchesCollection(userId);
      await matchesCollection.doc(matchId).update({'unmatched': true});
      print('Match unmatched successfully');
      return true;
    } catch (e) {
      print('Error unmatching profiles: $e');
      return false;
    }
  }

  // Hide a match
  Future<bool> hideMatch(String matchId) async { // Removed userId parameter
    try {
      // Get the current user from Firebase Auth
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('Error hiding match: No user is currently signed in.');
        return false; // Or throw an exception
      }
      final String userId = currentUser.uid;

      final matchesCollection = _getMatchesCollection(userId);
      await matchesCollection.doc(matchId).update({'hidden': true});
      print('Match hidden successfully');
      return true;
    } catch (e) {
      print('Error hiding match: $e');
      return false;
    }
  }
}