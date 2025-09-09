import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xenodate/models/character.dart';
import 'package:xenodate/services/charserv.dart'; // Your service
import 'package:provider/provider.dart'; // Make sure to import
import 'package:xenodate/newchar.dart';

class MyCharactersPage extends StatefulWidget {
  const MyCharactersPage({Key? key}) : super(key: key);

  @override
  State<MyCharactersPage> createState() => _MyCharactersPageState();
}

class _MyCharactersPageState extends State<MyCharactersPage> {
  final CharacterService _characterService = CharacterService();
  Stream<List<Character>>? _charactersStream;
  bool _showAddButton = true; // State to control FAB visibility

  @override
  void initState() {
    super.initState();
    _charactersStream = _characterService.getCharactersStream();
  }

  void _navigateToAddCharacterPage() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewChar()));
    print("Navigate to add character page");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigate to character creation (Not implemented yet)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
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
      ),
      body: StreamBuilder<List<Character>>(
        stream: _charactersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching characters: ${snapshot.error}");
            // It's good practice to hide the FAB on error too, or handle appropriately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _showAddButton = false;
                });
              }
            });
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Show button if no characters
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) { // Ensure the widget is still in the tree
                setState(() {
                  _showAddButton = true;
                });
              }
            });
            return const Center(
              child: Text("You haven't created any characters yet."),
            );
          }

          List<Character> characters = snapshot.data!;
          // Update FAB visibility based on character count
          // Use addPostFrameCallback to avoid calling setState during a build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Ensure the widget is still in the tree
              setState(() {
                _showAddButton = characters.length < 3;
              });
            }
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              return CharacterCard(character: characters[index]);
            },
          );
        },
      ),
      floatingActionButton: _showAddButton
          ? FloatingActionButton(
        onPressed: _navigateToAddCharacterPage,
        tooltip: 'Add Character',
        child: const Icon(Icons.add),
      )
          : null, // Hide FAB if not needed
    );
  }
}

// Widget to display a single character in a card format
class CharacterCard extends StatelessWidget {
  final Character character;

  const CharacterCard({Key? key, required this.character}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final characterService = Provider.of<CharacterService>(context, listen: false);
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell( // To make the card tappable for future navigation to a detail screen
        onTap: () async {
          try {
            if (character.id == null) {
              print("Character ID is null. Cannot switch character.");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error: Character ID is missing.")),
              );
              return;
            }
            await characterService.switchCharacter(character.id!);
            print("Switched to ${character.name}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Selected ${character.name}")),
            );
          } catch (e) {
            print("Error switching character: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error switching character: $e")),
            );
          }
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
              Row( // Wrap Title and Delete button in a Row
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items
                children: [
                  Expanded( // To ensure text still wraps and takes available space
                    child: Text(
                      character.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[700]), // Made delete icon more prominent
                    onPressed: () async {
                      // Confirmation dialog before deleting
                      final confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text('Are you sure you want to delete ${character.name}?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmDelete == true) {
                        try {
                          if (character.id == null) {
                            print("Character ID is null. Cannot delete character.");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error: Character ID is missing for deletion.")),
                            );
                            return;
                          }
                          await characterService.deleteCharacter(character.id!);
                          print("${character.name} deleted.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${character.name} has been deleted.")),
                          );
                        } catch (e) {
                          print("Error deleting character: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error deleting character: $e")),
                          );
                        }
                      }
                    },
                    tooltip: 'Delete Character',
                  ),
                ],
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
              //   ],
              // ) // Removed the old Row as delete is now at the top
            ],
          ),
        ),
      ),
    );
  }
}
