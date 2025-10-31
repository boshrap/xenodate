import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xenodate/models/match.dart'; // Your Match model
import 'package:xenodate/services/matchesserv.dart'; // Import your MatchService
import 'package:xenodate/services/xenoprofserv.dart'; // Import your XenoprofileService
import 'package:xenodate/xenoprofile.dart';
import 'package:xenodate/services/charserv.dart'; // Import CharacterService

import 'chatscreen3.dart';

class XenoMatches extends StatefulWidget {
  @override
  _XenoMatchesState createState() => _XenoMatchesState();
}

class _XenoMatchesState extends State<XenoMatches> {
  // No longer need _allMatches or _displayedMatches here,
  // as data will come from the StreamProvider or a StreamBuilder.

  // --- Helper functions to get data not directly in Match model ---
  // These would ideally fetch data from another service or local cache
  // based on characterId or xenoProfileId.
  Future<String> _getCharacterName(Match match, BuildContext context) async {
    final xenoprofileService = Provider.of<XenoprofileService>(context, listen: false);
    final xenoprofile = await xenoprofileService.getXenoprofileById(match.xenoProfileId);

    if (xenoprofile != null) {
      return "${xenoprofile.name} ${xenoprofile.surname}";
    } else {
      String profileIdSnippet = match.xenoProfileId;
      if (match.xenoProfileId.length > 6) {
        profileIdSnippet = match.xenoProfileId.substring(0, 6) + "...";
      }
      return "Character (ID: $profileIdSnippet)";
    }
  }

  String _getCharacterPhotoUrl(Match match, BuildContext context) {
    // Replace with actual logic to get photo URL
    // This could be fetched from a UserProfile service or Character service
    // For example: Provider.of<UserProfileService>(context, listen: false).getProfile(match.xenoProfileId).photoUrl;
    return 'https://via.placeholder.com/150/92c952'; // Placeholder
  }

  int _getDaysAgo(DateTime dateTime) {
    return DateTime.now().difference(dateTime).inDays;
  }

  // --- Event Handlers ---
  void _handleUnmatchTap(BuildContext context, Match match) async {
    final matchService = Provider.of<MatchService>(context, listen: false);
    try {
      // You might want to show a confirmation dialog first
      await matchService.setMatchUnmatched(match.id, true);
      // Optionally, show a success message
      // Note: This line needs to be updated to await _getCharacterName
      final characterName = await _getCharacterName(match, context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$characterName unmatched.')),
      );
    } catch (e) {
      print("Error unmatching: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unmatch. Please try again.')),
      );
    }
  }

  void _handleProfileTap(BuildContext context, Match match) {
    print("Profile tapped for match ID: ${match.id}. Character ID: ${match.characterId}");
    // Navigate to a profile screen, passing characterId or xenoProfileId
    Navigator.push(context, MaterialPageRoute(builder: (context) => XenoprofileDisplayPage(xenoprofileId: match.xenoProfileId)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to profile for ${match.xenoProfileId}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the MatchService and CharacterService
    final matchService = Provider.of<MatchService>(context, listen: false);
    final characterService = Provider.of<CharacterService>(context); // Listen to changes

    final String? selectedCharacterId = characterService.selectedCharacterId;

    if (selectedCharacterId == null) {
      return Center(child: Text('Please select a character to view matches.'));
    }

    return StreamBuilder<List<Match>>(
      // Listen to the stream of matches from the service
      // You can pass a characterId here if you want to filter by character
      stream: matchService.getMatchesStream(characterId: selectedCharacterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("Error in matches stream: ${snapshot.error}");
          return Center(child: Text('Error loading matches: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No active matches found.'));
        }

        // Filter out matches that are hidden or unmatched on the client-side,
        // though ideally, this filtering is also done in the Firestore query if possible.
        final displayedMatches = snapshot.data!
            .where((match) => !match.unmatched && !match.hidden)
            .toList();

        if (displayedMatches.isEmpty) {
          return Center(
            child: Text('No visible matches found for the selected character.'),
          );
        }

        return ListView.builder(
          itemCount: displayedMatches.length,
          itemBuilder: (context, index) {
            final match = displayedMatches[index];
            final characterPhotoUrl = _getCharacterPhotoUrl(match, context);
            final daysAgo = _getDaysAgo(match.matchedAt);

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            characterPhotoUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            semanticLabel: 'Character photo', // Updated semantic label
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _handleUnmatchTap(context, match),
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset( // Use Image.asset for local assets
                                'assets/ico/del.png',
                                width: 25,
                                height: 25,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.delete, size: 20, color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FutureBuilder<String>(
                            future: _getCharacterName(match, context),
                            builder: (context, nameSnapshot) {
                              if (nameSnapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (nameSnapshot.hasError) {
                                return Text('Error: ${nameSnapshot.error}');
                              } else {
                                return Text(
                                  nameSnapshot.data ?? 'Unknown Character',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                );
                              }
                            },
                          ),
                          SizedBox(height: 4),
                          Text('You matched $daysAgo ${daysAgo == 1 ? "day" : "days"} ago.'),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _handleProfileTap(context, match),
                                icon: const Icon(Icons.person),
                                tooltip: 'View Profile',
                              ),
                              IconButton(
                                onPressed: () {
                                  if (match.chatId == null) {
                                    // Handle case where chatId is not yet created
                                    // You might want to create the chat session here
                                    // or navigate to a screen that initiates it.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Chat not available yet for this match.')),
                                    );
                                    print("Chat ID is null for match: ${match.id}");
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AIChatScreen(
                                        // The chatId from the match object should be the definitive ID for the chat session.
                                        chatId: match.chatId!,
                                        characterId: match.characterId,
                                        xenoprofileId: match.xenoProfileId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.message),
                                tooltip: 'Open Chat',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
