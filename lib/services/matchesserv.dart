//lib/services/matchesserv.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xenodate/models/match.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For ChangeNotifier


class MatchService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Firestore Collection Path ---
  // Matches will be stored under a subcollection of the user.
  // This structure assumes you want to store matches per user.
  // If matches are global or per character, adjust the path accordingly.
  CollectionReference<Match> _userMatchesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('matches')
        .withConverter<Match>(
      fromFirestore: Match.fromFirestore, // Updated to use your fromFirestore
      toFirestore: (Match match, _) => match.toFirestore(),
    );
  }

  // --- Get Matches ---
  /// Fetches a stream of matches for the current user.
  /// Optionally, you can filter by characterId.
  Stream<List<Match>> getMatchesStream({String? characterId}) {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]); // Or handle as an error
    }

    Query<Match> query = _userMatchesCollection(currentUser.uid)
        .orderBy('matchedAt', descending: true);

    if (characterId != null) {
      query = query.where('characterId', isEqualTo: characterId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // --- Get a Single Match by ID ---
  Future<Match?> getMatchById(String matchId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final docSnapshot = await _userMatchesCollection(currentUser.uid).doc(matchId).get();
      return docSnapshot.data();
    } catch (e) {
      print("Error fetching match by ID: $e");
      return null;
    }
  }


  // --- Create a New Match ---
  /// Adds a new match to Firestore.
  /// The `Match` object should have its `id` field potentially handled
  /// by Firestore if you're using auto-generated IDs, or set manually.
  Future<String?> addMatch(Match match) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated to add a match.');
    }

    try {
      // If your Match object's 'id' is meant to be the Firestore document ID,
      // and you want Firestore to auto-generate it, you can do:
      // DocumentReference<Match> docRef = await _userMatchesCollection(currentUser.uid).add(match);
      // return docRef.id;

      // If you are setting the Match 'id' manually (e.g., from your Match object)
      // and want to use that as the document ID:
      if (match.id.isEmpty) { // Or some other check if ID should be auto-generated
        throw Exception('Match ID cannot be empty if setting manually.');
      }
      await _userMatchesCollection(currentUser.uid).doc(match.id).set(match);
      notifyListeners(); // If you have UI that needs to react to new matches
      return match.id;
    } catch (e) {
      print("Error adding match: $e");
      return null;
    }
  }

  // --- Update an Existing Match ---
  /// Updates specific fields of an existing match.
  /// `matchId` is the ID of the document in Firestore.
  /// `data` is a map of fields to update.
  Future<void> updateMatch(String matchId, Map<String, dynamic> data) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated to update a match.');
    }

    try {
      // Ensure 'matchedAt' is converted to Timestamp if present in data
      if (data.containsKey('matchedAt') && data['matchedAt'] is DateTime) {
        data['matchedAt'] = Timestamp.fromDate(data['matchedAt']);
      }
      await _userMatchesCollection(currentUser.uid).doc(matchId).update(data);
      notifyListeners(); // If UI needs to react to updates
    } catch (e) {
      print("Error updating match: $e");
      // Handle error appropriately
    }
  }

  // --- Specific Update Operations (Example: Hiding/Unmatching) ---
  Future<void> setMatchHidden(String matchId, bool hidden) async {
    await updateMatch(matchId, {'hidden': hidden});
  }

  Future<void> setMatchUnmatched(String matchId, bool unmatched) async {
    await updateMatch(matchId, {'unmatched': unmatched});
    // You might also want to handle related logic here, e.g., deleting a chat
  }


  // --- Delete a Match ---
  Future<void> deleteMatch(String matchId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated to delete a match.');
    }

    try {
      await _userMatchesCollection(currentUser.uid).doc(matchId).delete();
      notifyListeners(); // If UI needs to react
    } catch (e) {
      print("Error deleting match: $e");
      // Handle error appropriately
    }
  }
}
