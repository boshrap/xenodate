import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xenodate/models/character.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Assuming you use Provider for state management

import 'package:xenodate/characterselector.dart'; // Ensure this path is correct

class CharacterService extends ChangeNotifier{
  static const String _prefsKey = 'selectedCharacterId';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedCharacterId;

  // Initialize and restore saved character if exists
  Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedCharacterId = prefs.getString(_prefsKey);
  }

  String? get selectedCharacterId => _selectedCharacterId;


  Stream<List<Character>> getCharactersStream() {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      // Return an empty stream or a stream with an error if the user is not logged in.
      // For simplicity, returning an empty stream. You might want to handle this differently.
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('characters')
        .orderBy('createdAt', descending: true) // Optional: order by creation time
        .snapshots() // This returns a Stream<QuerySnapshot>
        .map((querySnapshot) {
      // querySnapshot is the Stream<QuerySnapshot>
      // We map this to a Stream<List<Character>>
      return querySnapshot.docs
          .map((doc) => Character.fromFirestore(doc, doc)) // Make sure your fromFirestore matches this
          .toList();
    });
  }

  Future<Character?> getSelectedCharacter(String userId) async {
    final User? user = _auth.currentUser;
    if (user == null || _selectedCharacterId == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('characters')
        .doc(_selectedCharacterId)
        .get();

    if (!doc.exists) return null;
    return Character.fromFirestore(doc, doc);
  }

  Future<void> switchCharacter(String characterId) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    _selectedCharacterId = characterId;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, characterId);
    notifyListeners(); // Notify listeners of the change
  }

  Future<void> addCharacter(Character character) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('characters')
        .doc(character.id);

    await docRef.set(character.toJson());

    // Optionally make this the selected character
    await switchCharacter(character.id);
  }

  Future<void> deleteCharacter(String characterId) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('characters')
        .doc(characterId)
        .delete();

    // If the deleted character was selected, clear the selection
    if (_selectedCharacterId == characterId) {
      _selectedCharacterId = null;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      notifyListeners(); // Notify listeners of the change
    }
  }

  Future<void> clearCharacterSelection() async {
    _selectedCharacterId = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners(); // Notify listeners of the change
  }
}

/// Checks for a selected character and shows a creation prompt if none exists.
///
/// This function should be called in a place where you have access to a [BuildContext],
/// typically within a widget's `initState` or `didChangeDependencies` method,
/// or in response to a user action.
///
/// It's recommended to call this after the `CharacterService` has been initialized.
Future<void> noChar2NewChar(BuildContext context) async {
  // Access your CharacterService instance.
  // This might be through Provider, a singleton, or another dependency injection method.
  // For this example, we'll assume it's available via Provider.
  final characterService = Provider.of<CharacterService>(context, listen: false);

  // 1. Check if there's a _selectedCharacterId
  if (characterService.selectedCharacterId == null) {
    // 2. If there isn't one, display a popup
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('No Character Selected'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Select or add a character to begin."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
                // 3. Clicking OK navigates the user to MyCharactersPage
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MyCharactersPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Example Usage (e.g., in your main screen's initState or after login):

//class HomeScreen extends StatefulWidget {
//  const HomeScreen({super.key});

//  @override
//  State<HomeScreen> createState() => _HomeScreenState();
//}

//class _HomeScreenState extends State<HomeScreen> {
//  @override
//  void initState() {
//    super.initState();
    // Ensure CharacterService is initialized before calling this.
    // You might do this in your main.dart or a loading screen.
//    WidgetsBinding.instance.addPostFrameCallback((_) {
      // It's often good practice to call this after the first frame is rendered
      // or when the CharacterService signals it has finished initializing.
//      final characterService = Provider.of<CharacterService>(context, listen: false);
//      characterService.initialize().then((_) {
        // Now that initialization is complete, check for the character.
//        noChar2NewChar(context);
//      });
//    });
//  }

//  @override
//  Widget build(BuildContext context) {
    // Your screen's UI
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Home'),
//      ),
//      body: const Center(
//        child: Text('Welcome!'),
//      ),
//    );
//  }
//}
