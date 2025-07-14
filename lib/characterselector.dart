import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user
import 'package:xenodate/models/character.dart'; // Assuming your package name is 'xenodate'

class MyCharactersPage extends StatefulWidget {
  const MyCharactersPage({Key? key}) : super(key: key);

  @override
  State<MyCharactersPage> createState() => _MyCharactersPageState();
}

class _MyCharactersPageState extends State<MyCharactersPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<List<Character>>? _charactersStream;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _charactersStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('characters')
          .orderBy('createdAt', descending: true) // Optional: order by creation time
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => Character.fromFirestore(doc,snapshot))
          .toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Characters")),
        body: const Center(
          child: Text("Please log in to see your characters."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Characters"),
        // You could add an action to create a new character
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.add),
        //     onPressed: () {
        //       Navigator.push(context, MaterialPageRoute(builder: (context) => NewChar()));
        //     },
        //   ),
        // ],
      ),
      body: StreamBuilder<List<Character>>(
        stream: _charactersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching characters: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("You haven't created any characters yet."),
            );
          }

          List<Character> characters = snapshot.data!;

          // Using ListView.builder for efficient list rendering
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              return CharacterCard(character: characters[index]);
            },
          );

          // --- Alternative: GridView ---
          // return GridView.builder(
          //   padding: const EdgeInsets.all(8.0),
          //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //     crossAxisCount: 2, // Or 3, depending on your design
          //     childAspectRatio: 0.75, // Adjust as needed
          //     crossAxisSpacing: 8.0,
          //     mainAxisSpacing: 8.0,
          //   ),
          //   itemCount: characters.length,
          //   itemBuilder: (context, index) {
          //     return CharacterCard(character: characters[index]);
          //   },
          // );
        },
      ),
    );
  }
}

// Widget to display a single character in a card format
class CharacterCard extends StatelessWidget {
  final Character character;

  const CharacterCard({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell( // To make the card tappable for future navigation to a detail screen
        onTap: () {
          // TODO: Navigate to a character detail page if needed
          // Navigator.push(context, MaterialPageRoute(builder: (context) => CharacterDetailPage(characterId: character.id)));
          print("Tapped on ${character.name}");
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // You would typically display an image here if available
              // AspectRatio(
              //   aspectRatio: 1, // Square image
              //   child: Container(
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(8.0),
              //       image: character.imageUrl != null
              //           ? DecorationImage(
              //               image: NetworkImage(character.imageUrl!),
              //               fit: BoxFit.cover,
              //             )
              //           : const DecorationImage( // Placeholder
              //               image: AssetImage('assets/placeholder_character.png'), // Add a placeholder
              //               fit: BoxFit.cover,
              //             ),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 10),
              Text(
                character.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (character.species != null)
                Text(
                  "Species: ${character.species}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (character.age != null)
                Text(
                  "Age: ${character.age}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (character.gender != null)
                Text(
                  "Gender: ${character.gender}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              if (character.biography != null && character.biography!.isNotEmpty)
                Text(
                  character.biography!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3, // Show a snippet of the bio
                  overflow: TextOverflow.ellipsis,
                ),
              // Add more fields as needed (e.g., Looking for)
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     IconButton(icon: Icon(Icons.edit), onPressed: () { /* TODO: Edit action */ }),
              //     IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () { /* TODO: Delete action */ }),
              //   ],
              // )
            ],
          ),
        ),
      ),
    );
  }
}
