import 'package:flutter/material.dart';
import 'package:xenodate/chat.dart'; // Assuming this is your chat screen
import 'package:xenodate/models/match.dart'; // Your Match model

class XenoMatches extends StatefulWidget {
  @override
  _XenoMatchesState createState() => _XenoMatchesState();
}

class _XenoMatchesState extends State<XenoMatches> {
  // Sample list of matches - replace with your actual data source and fetching logic
  final List<Match> _allMatches = [
    // Example Match objects - replace with your actual data
    // Match(
    //   id: '1',
    //   characterId: 'char123',
    //   xenoProfileId: 'xenoProfile789',
    //   matchedAt: DateTime.now().subtract(Duration(days: 2)),
    //   // photoUrl and name are not in the Match model, you'll need to fetch
    //   // these separately based on characterId or xenoProfileId
    // ),
    // Match(
    //   id: '2',
    //   characterId: 'char456',
    //   xenoProfileId: 'xenoProfileABC',
    //   matchedAt: DateTime.now().subtract(Duration(days: 5)),
    //   hidden: true,
    // ),
  ];

  late List<Match> _displayedMatches;

  @override
  void initState() {
    super.initState();
    // In a real app, you would fetch _allMatches from a database or API here
    _filterMatches();
  }

  void _filterMatches() {
    setState(() {
      _displayedMatches = _allMatches
          .where((match) => !match.unmatched && !match.hidden)
          .toList();
    });
  }

  // --- Helper functions to get data not directly in Match model ---
  // You'll need to implement these based on how you fetch character/profile details

  // Placeholder to get the character's name
  // In a real app, this would likely involve looking up the characterId
  // in another data source (e.g., a map, a database, an API call)
  String _getCharacterName(Match match) {
    // Replace with actual logic to get name based on match.characterId or match.xenoProfileId
    return "Character Name (ID: ${match.characterId})"; // Placeholder
  }

  // Placeholder to get the character's photo URL
  String _getCharacterPhotoUrl(Match match) {
    // Replace with actual logic to get photo URL
    // This could be a static map, or fetched from a server
    // For example, if you have a map of characterId to photoUrl:
    // return characterPhotos[match.characterId] ?? 'https://via.placeholder.com/100';
    return 'https://via.placeholder.com/150/92c952'; // Placeholder
  }

  int _getDaysAgo(DateTime dateTime) {
    return DateTime.now().difference(dateTime).inDays;
  }

  // --- Event Handlers ---

  void _handleBadgeTap(Match match) {
    print("Badge tapped for match ID: ${match.id}");
    // Example: Mark as unmatched and refilter
    // setState(() {
    //   // Find the match in the original list and update its state
    //   final index = _allMatches.indexWhere((m) => m.id == match.id);
    //   if (index != -1) {
    //     _allMatches[index] = Match(
    //       id: _allMatches[index].id,
    //       characterId: _allMatches[index].characterId,
    //       xenoProfileId: _allMatches[index].xenoProfileId,
    //       matchedAt: _allMatches[index].matchedAt,
    //       hidden: _allMatches[index].hidden,
    //       unmatched: true, // Set unmatched to true
    //     );
    //     _filterMatches(); // Re-filter the displayed list
    //   }
    // });
    // Or call an API to unmatch
  }

  void _handleProfileTap(Match match) {
    print("Profile tapped for match ID: ${match.id}. Character ID: ${match.characterId}");
    // Navigate to a profile screen, passing characterId or xenoProfileId
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(characterId: match.characterId)));
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedMatches.isEmpty) {
      return Center(
        child: Text('No active matches found.'),
      );
    }

    return ListView.builder(
      itemCount: _displayedMatches.length,
      itemBuilder: (context, index) {
        final match = _displayedMatches[index];
        final characterName = _getCharacterName(match); // Get name
        final characterPhotoUrl = _getCharacterPhotoUrl(match); // Get photo URL
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
                        characterPhotoUrl, // Use fetched photo URL
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        semanticLabel: '$characterName photo',
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
                        onTap: () => _handleBadgeTap(match),
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Image.network( // Consider using an Icon for local assets
                            'assets/ico/del.png', // Ensure this path is correct and asset is in pubspec.yaml
                            width: 25,
                            height: 25,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.delete, size: 20, color: Colors.red), // Fallback icon
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
                      Text(
                        characterName, // Use fetched name
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('You matched $daysAgo ${daysAgo == 1 ? "day" : "days"} ago.'),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _handleProfileTap(match),
                            icon: const Icon(Icons.person),
                            tooltip: 'View Profile',
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    matchId: match.id, // Assuming 'match.id' is the correct ID for the chat
                                    // You need to determine what 'userCharacter' and 'aiPersona' should be.
                                    // These likely come from your 'match' object or other state in your application.
                                    // For example, if 'match' contains information about both participants:
                                    userCharacterId: match.characterId, // Or whatever represents the user's character in the match
                                    aiPersonaId: match.xenoProfileId,
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
  }
}
