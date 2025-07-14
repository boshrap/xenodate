// lib/swipeview.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading JSON
import 'package:xenodate/models/xenoprofile.dart';
import 'package:xenodate/models/filter.dart';
import 'package:xenodate/filterview.dart'; // Your FilterView

class SwipeView extends StatefulWidget {
  const SwipeView({Key? key, required ValueNotifier<List<Xenoprofile>> profilesNotifier}) : super(key: key);

  @override
  _SwipeViewState createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> {
  List<Xenoprofile> _allProfiles = [];
  List<Xenoprofile> _filteredProfiles = [];
  ValueNotifier<FilterCriteria> _filterCriteriaNotifier =
  ValueNotifier(FilterCriteria.empty());
  bool _isLoading = true;
  int _currentIndex = 0; // For swiping

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _filterCriteriaNotifier.addListener(_applyFiltersToList);
  }

  @override
  void dispose() {
    _filterCriteriaNotifier.removeListener(_applyFiltersToList);
    _filterCriteriaNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final String response =
      await rootBundle.loadString('assets/profiles/xenopersonas_DATA.json');
      final List<dynamic> data = json.decode(response) as List<dynamic>;
      _allProfiles = data.map((jsonItem) => Xenoprofile.fromJson(jsonItem as Map<String, dynamic>)).toList();
      _applyFiltersToList(); // Apply initial (empty) filters
    } catch (e) {
      print("Error loading profiles: $e");
      // Handle error, e.g., show a message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersToList() {
    final criteria = _filterCriteriaNotifier.value;
    setState(() {
      _filteredProfiles = _allProfiles.where((profile) {
        // Age filter
        if (profile.earthage == null) {
          // If minAge or maxAge is specified in criteria, a profile with no age doesn't match
          if (criteria.minAge != null || criteria.maxAge != null) {
            return false;
          }
        } else {
          // Only perform comparisons if profile.earthage is not null
          if (criteria.minAge != null && profile.earthage! < criteria.minAge!) return false;
          if (criteria.maxAge != null && profile.earthage! > criteria.maxAge!) return false;
        }

        // Gender filter
        if (criteria.gender != null && profile.gender.toLowerCase() != criteria.gender!.toLowerCase()) return false;

        // Species filter
        if (criteria.species != null && profile.species.toLowerCase() != criteria.species!.toLowerCase()) return false;

        // Location filter
        if (criteria.location != null && profile.location.toLowerCase() != criteria.location!.toLowerCase()) return false;

        // Looking For filter
        if (criteria.lookingFor != null && profile.lookingfor.toLowerCase() != criteria.lookingFor!.toLowerCase()) return false;

        // Interests filter (match any selected interest)
        if (criteria.interests != null && criteria.interests!.isNotEmpty) {
          bool interestMatch = false;
          for (String interest in criteria.interests!) {
            if (profile.interests.any((profileInterest) => profileInterest.toLowerCase() == interest.toLowerCase())) {
              interestMatch = true;
              break;
            }
          }
          if (!interestMatch) return false;
        }
        return true;
      }).toList();
      _currentIndex = 0; // Reset swipe index when filters change
    });
  }

  void _handleApplyFilters(FilterCriteria newCriteria) {
    _filterCriteriaNotifier.value = newCriteria;
    Navigator.of(context).pop(); // Close the filter view if it's a modal
  }

  void _openFilterView() {
    // You can show FilterView as a modal bottom sheet, a dialog, or a new route
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for full-screen height
      builder: (context) {
        return FractionallySizedBox( // Allows the sheet to take most of the screen
          heightFactor: 0.85, // Adjust as needed
          child: Filter(
            filterCriteriaNotifier: _filterCriteriaNotifier, // Pass the existing notifier
            onApplyFilters: _handleApplyFilters,
            // --- Pass dynamic options if you derived them ---
            // availableGenders: _availableGenders,
            // availableSpecies: _availableSpecies,
            // etc.
          ),
        );
      },
    );
  }

  // --- Swipe and Button Actions ---
  void _onSwipeLeft() { // "No" action
    print("Profile disliked (or swiped left): ${_filteredProfiles.isNotEmpty && _currentIndex < _filteredProfiles.length ? _filteredProfiles[_currentIndex].name : 'N/A'}");
    setState(() {
      if (_currentIndex < _filteredProfiles.length - 1) {
        _currentIndex++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No more profiles matching your criteria!')),
        );
      }
    });
  }

  void _onSwipeRight() { // "Yes" action
    print("Profile liked (or swiped right): ${_filteredProfiles.isNotEmpty && _currentIndex < _filteredProfiles.length ? _filteredProfiles[_currentIndex].name : 'N/A'}");
    setState(() {
      if (_currentIndex < _filteredProfiles.length - 1) {
        _currentIndex++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No more profiles matching your criteria!')),
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Your Xeno-Match'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _openFilterView,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredProfiles.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _allProfiles.isEmpty
                ? 'Could not load profiles. Check your connection or the data file.'
                : 'No profiles match your current filters. Try adjusting them!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      )
          : Column( // Use a Column to stack the card and buttons
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded( // Make the ProfileCard take available space
            child: Center( // Center the card within the Expanded area
              child: (_currentIndex < _filteredProfiles.length)
                  ? GestureDetector( // Simple GestureDetector for swipe
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < 0) {
                    _onSwipeLeft(); // Swiped left
                  } else if (details.primaryVelocity! > 0) {
                    _onSwipeRight(); // Swiped right
                  }
                },
                child: ProfileCard(profile: _filteredProfiles[_currentIndex]),
              )
                  : Padding( // Message when all profiles are swiped through
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "You've seen all profiles for now!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
          // Show buttons only if there's a card currently visible
          if (_filteredProfiles.isNotEmpty && _currentIndex < _filteredProfiles.length)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _onSwipeLeft, // "No" action
                    icon: Icon(Icons.close, size: 28),
                    label: Text('No', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onSwipeRight, // "Yes" action
                    icon: Icon(Icons.favorite, size: 28, color: Colors.pinkAccent), // Using favorite for "Yes"
                    label: Text('Yes', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Optional: Add a small spacer if there are no more profiles but buttons were just hidden
          if (_filteredProfiles.isNotEmpty && _currentIndex >= _filteredProfiles.length)
            SizedBox(height: 80), // Placeholder for button area height
        ],
      ),
    );
  }
}

// --- Basic Profile Card Widget (Example) ---
class ProfileCard extends StatelessWidget {
  final Xenoprofile profile;

  const ProfileCard({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjust margin
      elevation: 5.0,
      clipBehavior: Clip.antiAlias, // To ensure rounded corners clip the image
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: SingleChildScrollView( // Make card content scrollable if it overflows
        child: Padding(
          padding: const EdgeInsets.all(1.0), // No padding for the card itself, image will fill
          child: Column(
            // mainAxisSize: MainAxisSize.min, // Can remove if using SingleChildScrollView and Expanded
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch
            children: <Widget>[
              if (profile.imageUrl.isNotEmpty)
                ClipRRect( // Clip the image to have rounded top corners
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
                  child: Image.asset(
                    profile.imageUrl,
                    height: 300, // Increased height
                    width: double.infinity,
                    fit: BoxFit.cover, // Cover ensures the image fills the bounds
                    errorBuilder: (context, error, stackTrace) {
                      return Container( // Placeholder container
                        height: 300,
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image, size: 100, color: Colors.grey[600]),
                      );
                    },
                  ),
                )
              else // Placeholder if no image URL
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
                  ),
                  child: Icon(Icons.person_outline, size: 150, color: Colors.grey[400]),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0), // Padding for the text content
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${profile.name}, ${profile.earthage ?? 'N/A'}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.public, size: 18, color: Colors.grey[700]),
                        SizedBox(width: 6),
                        Text('Species: ${profile.species}', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[700]),
                        SizedBox(width: 6),
                        Text('Location: ${profile.location}', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.search, size: 18, color: Colors.grey[700]),
                        SizedBox(width: 6),
                        Text('Looking for: ${profile.lookingfor}', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('Interests:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Wrap( // Use Wrap for interests if they can be many
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: profile.interests.map((interest) => Chip(label: Text(interest))).toList(),
                    ),
                    SizedBox(height: 12),
                    Text('Bio:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(profile.bio, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
