// lib/services/xenoprofserv.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xenodate/models/xenoprofile.dart'; // Make sure this path is correct


class XenoprofileService extends ChangeNotifier{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _profilesCollection =
  FirebaseFirestore.instance.collection('xenoprofiles'); // Or your collection name

  // Cache for profiles to reduce Firestore reads
  final Map<String, Xenoprofile> _profileCache = {};

  // Fetches all Xenoprofiles from Firestore
  Future<List<Xenoprofile>> getAllXenoprofiles() async {
    try {
      QuerySnapshot querySnapshot = await _profilesCollection.get();
      List<Xenoprofile> profiles = [];
      for (var doc in querySnapshot.docs) {
        if (doc.data() != null) {
          // This line relies on the Xenoprofile.fromJson factory
          final profile = Xenoprofile.fromJson(doc.data() as Map<String, dynamic>);
          _profileCache[doc.id] = profile; // Cache the profile
          profiles.add(profile);
          // Consider if you really need to notifyListeners() here for every single profile
          // It might be better to notify once after the loop if the list itself is what widgets observe.
        }
      }
      if (profiles.isNotEmpty) {
        notifyListeners(); // Notify after all profiles are fetched and cache is updated
      }
      return profiles;

    } catch (e) {
      print("Error fetching all Xenoprofiles: $e");
      return []; // Return empty list on error
    }
  }

  // Fetches a single Xenoprofile by UID
  // Tries to get from cache first, then Firestore
  Future<Xenoprofile?> getXenoprofileById(String id) async {
    if (id.isEmpty) {
      print("getXenoprofileByID called with empty ID."); // More informative message
      return null;
    }

    if (_profileCache.containsKey(id)) {
      return _profileCache[id];
    }

    try {
      DocumentSnapshot doc = await _profilesCollection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        // This line relies on the Xenoprofile.fromJson factory
        final profile = Xenoprofile.fromJson(doc.data() as Map<String, dynamic>);
        _profileCache[id] = profile; // Cache the profile
        // notifyListeners(); // Usually not needed for a single profile fetch unless a specific widget listens for this ID
        return profile;
      }
      print("Xenoprofile with ID $id not found.");
      return null;
    } catch (e) {
      print("Error fetching Xenoprofile for UID $id: $e");
      return null;
    }
  }

  // Optional: Pre-fetch multiple profiles if you have a list of UIDs
  Future<void> prefetchProfiles(List<String> uids) async {
    final List<String> uidsToFetch = uids.where((uid) => !_profileCache.containsKey(uid) && uid.isNotEmpty).toList();
    if (uidsToFetch.isEmpty) return;

    try {
      if (uidsToFetch.length <= 30) { // Firestore 'in' query limit
        final querySnapshot = await _profilesCollection
            .where(FieldPath.documentId, whereIn: uidsToFetch)
            .get();

        bool cacheUpdated = false;
        for (var doc in querySnapshot.docs) {
          if (doc.data() != null) {
            // This line relies on the Xenoprofile.fromJson factory
            final profile = Xenoprofile.fromJson(doc.data() as Map<String, dynamic>);
            _profileCache[doc.id] = profile;
            cacheUpdated = true;
          }
        }
        if (cacheUpdated) {
          notifyListeners(); // Notify if the cache was updated
        }
      } else {
        // Fallback to individual fetches or implement batching for larger lists
        // Consider the performance implications for very large lists
        for (String uid in uidsToFetch) {
          await getXenoprofileById(uid); // This will fetch and cache (and potentially notify individually if getXenoprofileById does)
        }
        // If getXenoprofileById doesn't notify, and you want a single notification after batch fetching:
        // notifyListeners();
      }
    } catch (e) {
      print("Error pre-fetching Xenoprofiles: $e");
    }
  }

  // You might also want methods to add or update Xenoprofiles
  Future<void> addXenoprofile(Xenoprofile profile) async {
    try {
      // Use profile.id as the document ID if it's meant to be client-generated and unique
      // Otherwise, let Firestore generate an ID by using .add()
      await _profilesCollection.doc(profile.id).set(profile.toJson());
      _profileCache[profile.id] = profile; // Update cache
      notifyListeners();
    } catch (e) {
      print("Error adding Xenoprofile: $e");
    }
  }

  Future<void> updateXenoprofile(Xenoprofile profile) async {
    try {
      await _profilesCollection.doc(profile.id).update(profile.toJson());
      _profileCache[profile.id] = profile; // Update cache
      notifyListeners();
    } catch (e) {
      print("Error updating Xenoprofile for UID ${profile.id}: $e");
    }
  }

  Future<void> deleteXenoprofile(String id) async {
    try {
      await _profilesCollection.doc(id).delete();
      _profileCache.remove(id); // Remove from cache
      notifyListeners();
    } catch (e) {
      print("Error deleting Xenoprofile for UID $id: $e");
    }
  }
}
