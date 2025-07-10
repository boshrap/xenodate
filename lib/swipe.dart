import 'package:flutter/material.dart';
import 'package:xenodate/models/profile.dart'; // Import your Profile model
// Remove these imports if NoMatches and SwipeLimit are not used elsewhere in this file
// or if the intention is to completely remove navigation from this widget.
// import 'package:xenodate/swipelimit.dart';
// import 'package:xenodate/nomatches.dart'; // Assuming you have a NoMatches class for a different purpose

class Swipe extends StatefulWidget {
  final ValueNotifier<List<Profile>> profilesNotifier;

  const Swipe({Key? key, required this.profilesNotifier}) : super(key: key);

  @override
  _SwipeState createState() => _SwipeState();
}

class _SwipeState extends State<Swipe> {
  // Current index for the card being displayed from the filtered list
  int _currentCardIndex = 0;
  // To keep track of which profiles from the current filtered list have been dismissed
  final Set<String> _dismissedProfileIds = {};


  @override
  void initState() {
    super.initState();
    // Listen to profile changes to reset index if the list fundamentally changes (e.g., new filter applied)
    widget.profilesNotifier.addListener(_onProfilesChanged);
  }

  @override
  void dispose() {
    widget.profilesNotifier.removeListener(_onProfilesChanged);
    super.dispose();
  }

  void _onProfilesChanged() {
    // When the list of profiles changes (e.g., due to filtering),
    // reset the current card index and dismissed set.
    setState(() {
      _currentCardIndex = 0;
      _dismissedProfileIds.clear();
    });
  }

  // Helper function to advance to the next card
  void _showNextCard(String dismissedProfileId) {
    setState(() {
      _dismissedProfileIds.add(dismissedProfileId);
      _currentCardIndex++;
    });
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Profile>>(
      valueListenable: widget.profilesNotifier,
      builder: (context, profiles, child) {
        // Filter out already dismissed profiles from the current list
        final displayableProfiles = profiles.where((p) => !_dismissedProfileIds.contains(p.id)).toList();

        if (displayableProfiles.isEmpty) {
          if (profiles.isNotEmpty && _dismissedProfileIds.length == profiles.length) {
            // All profiles from the current filter have been swiped
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "You've swiped through all available profiles for this filter. Try changing your filters or check back later!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }
          // No profiles match the current filter criteria
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No profiles match your current filters. Try adjusting them in the Filter tab!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        // Get the current profile to display based on _currentCardIndex
        // relative to the start of the displayableProfiles list.
        // This logic simplifies as we're always taking the first of the remaining displayableProfiles.
        final currentProfile = displayableProfiles.first;


        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded( // Ensure Dismissible takes available space
                child: Dismissible(
                  key: Key(currentProfile.id), // Unique key for each profile
                  onDismissed: (direction) {
                    print("Card for ${currentProfile.name} dismissed with direction: $direction");
                    // Here you would typically handle the swipe action (e.g., like, dislike)
                    // For now, it just advances to the next card.
                    _showNextCard(currentProfile.id);
                  },
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.check_circle_outline, color: Colors.white, size: 36),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.cancel_outlined, color: Colors.white, size: 36),
                  ),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    clipBehavior: Clip.antiAlias, // Important for rounded corners on Image
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Make card wrap content
                      children: [
                        Expanded( // Image takes up available vertical space
                          child: currentProfile.imageUrl.isNotEmpty
                              ? (currentProfile.imageUrl.startsWith('assets/')
                              ? Image.asset(
                            currentProfile.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.broken_image, size: 50), Text('Could not load image')]));
                            },
                          )
                              : Image.network(
                            currentProfile.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 50), Text('Could not load image')]));
                            },
                          ))
                              : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person, size: 100, color: Colors.grey[400]), Text('No image available')])),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(currentProfile.name, style: Theme.of(context).textTheme.headlineSmall),
                                    SizedBox(height: 4),
                                    Text('${currentProfile.gender}, Age: ${currentProfile.age}', style: Theme.of(context).textTheme.titleMedium),
                                    if (currentProfile.bio.isNotEmpty) ...[
                                      SizedBox(height: 4),
                                      Text(currentProfile.bio, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ]
                                  ],
                                ),
                              ),
                              IconButton( // Example: Info button
                                icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                                onPressed: () {
                                  // TODO: Show profile details modal/page
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(currentProfile.name),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: <Widget>[
                                            if (currentProfile.imageUrl.isNotEmpty)
                                              Image.network(currentProfile.imageUrl, errorBuilder: (c,e,s) => SizedBox.shrink()),
                                            Text('Age: ${currentProfile.age}'),
                                            Text('Gender: ${currentProfile.gender}'),
                                            Text('Interests: ${currentProfile.interests.join(", ")}'),
                                            SizedBox(height: 8),
                                            Text('Bio: ${currentProfile.bio}'),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Close'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20), // Spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      print("Nope button pressed for ${currentProfile.name}");
                      _showNextCard(currentProfile.id); // Simulate a "nope" swipe
                    },
                    icon: Icon(Icons.close),
                    label: Text('Nope'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      print("YEP button pressed for ${currentProfile.name}");
                      _showNextCard(currentProfile.id); // Simulate a "yep" swipe
                    },
                    icon: Icon(Icons.favorite),
                    label: Text('YEP'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
