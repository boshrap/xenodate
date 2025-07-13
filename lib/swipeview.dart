// lib/swipeview.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading JSON
import 'package:xenodate/models/xenoprofile.dart';
import 'package:xenodate/models/filter.dart';
import 'package:xenodate/filterview.dart';

class SwipeView extends StatefulWidget {
  // 1. Add the profilesNotifier parameter
  final ValueNotifier<List<Xenoprofile>> profilesNotifier;
  final ValueNotifier<FilterCriteria> filterCriteriaNotifier; // Keep this if filters are managed here
  final Function(FilterCriteria) onApplyFilters; // Keep this

  const SwipeView({
    Key? key,
    required this.profilesNotifier, // Make it required
    required this.filterCriteriaNotifier,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _SwipeViewState createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> {
  // 2. Remove _allProfiles and _filteredProfiles if they are now managed by profilesNotifier
  // List<Xenoprofile> _allProfiles = [];
  // List<Xenoprofile> _filteredProfiles = []; // This will now come from widget.profilesNotifier.value

  bool _isLoading = true; // Still useful for initial load if SwipeView handles it
  int _currentIndex = 0;

  // --- Dynamic options (can remain if SwipeView still loads initial data) ---
  List<String> _availableGenders = ['Any', 'Male', 'Female', 'Non-binary'];
  List<String> _availableInterests = [/* ... */];
  List<String> _availableSpecies = [/* ... */];
  List<String> _availableLocations = [/* ... */];
  List<String> _availableLookingFor = ['Any', 'Conversation', 'Friendship', 'Romance'];

  @override
  void initState() {
    super.initState();
    // 3. Listen to the passed-in profilesNotifier
    widget.profilesNotifier.addListener(_onProfilesChanged);

    // If SwipeView is still responsible for the initial load and filtering,
    // keep this. Otherwise, the parent widget should handle loading.
    _loadAndFilterProfiles(); // Potentially rename or restructure this

    widget.filterCriteriaNotifier.addListener(_applyFiltersToList); // Keep if filtering is here
  }

  @override
  void dispose() {
    widget.profilesNotifier.removeListener(_onProfilesChanged);
    widget.filterCriteriaNotifier.removeListener(_applyFiltersToList);
    // widget.filterCriteriaNotifier.dispose(); // Dispose this in the parent if passed in
    super.dispose();
  }

  // 4. Listener for external profile changes
  void _onProfilesChanged() {
    if (mounted) { // Ensure the widget is still in the tree
      setState(() {
        _currentIndex = 0; // Reset index when profiles change externally
        // Potentially update _isLoading if the notifier indicates loading state
      });
    }
  }

  // Option A: SwipeView still loads initial data and applies filters
  // (Potentially simpler if filter logic is tightly coupled)
  List<Xenoprofile> _internalAllProfiles = []; // For storing the raw loaded data

  Future<void> _loadAndFilterProfiles() async {
    setState(() { _isLoading = true; });
    try {
      final String response = await rootBundle.loadString('assets/profiles/xenopersonas_DATA.json');
      final List<dynamic> data = json.decode(response) as List<dynamic>;
      _internalAllProfiles = data.map((jsonItem) => Xenoprofile.fromJson(jsonItem as Map<String, dynamic>)).toList();
      _applyFiltersToList(); // This will update widget.profilesNotifier.value
    } catch (e) {
      print("Error loading profiles: $e");
      widget.profilesNotifier.value = []; // Update notifier on error
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _applyFiltersToList() {
    final criteria = widget.filterCriteriaNotifier.value;
    final filtered = _internalAllProfiles.where((profile) {
      // ... your existing filter logic ...
      if (criteria.minAge != null && profile.earthage < criteria.minAge!) return false;
      if (criteria.maxAge != null && profile.earthage > criteria.maxAge!) return false;
      if (criteria.gender != null && criteria.gender != 'Any' && profile.gender.toLowerCase() != criteria.gender!.toLowerCase()) return false;
      if (criteria.species != null && criteria.species != 'Any' && profile.species.toLowerCase() != criteria.species!.toLowerCase()) return false;
      if (criteria.location != null && criteria.location != 'Any' && profile.location.toLowerCase() != criteria.location!.toLowerCase()) return false;
      if (criteria.lookingFor != null && criteria.lookingFor != 'Any' && profile.lookingfor.toLowerCase() != criteria.lookingFor!.toLowerCase()) return false;
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

    // 5. Update the external notifier with the filtered list
    widget.profilesNotifier.value = filtered;
    // setState will be called by _onProfilesChanged if this listener is still active
    // or if you need to reset _currentIndex directly here.
    if (mounted) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }


  // This method is called by FilterView
  void _handleApplyFilters(FilterCriteria newCriteria) {
    // This will trigger _applyFiltersToList via the listener
    widget.onApplyFilters(newCriteria); // Propagate to parent if needed, or handle here
    // widget.filterCriteriaNotifier.value = newCriteria;
    // Navigator.of(context).pop(); // Keep if FilterView is modal
  }


  void _openFilterView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Filter( // Assuming FilterView's name is Filter
            filterCriteriaNotifier: widget.filterCriteriaNotifier, // Pass the one from the parent
            onApplyFilters: (newCriteria) { // This is FilterView's callback
              widget.filterCriteriaNotifier.value = newCriteria; // Update the shared notifier
              Navigator.of(context).pop(); // Close modal
              // _applyFiltersToList will be called by the listener on filterCriteriaNotifier
            },
            // availableGenders: _availableGenders, // Pass these if still needed
            // availableSpecies: _availableSpecies,
          ),
        );
      },
    );
  }

  void _onSwipeLeft() {
    setState(() {
      // 6. Use widget.profilesNotifier.value for length check
      if (_currentIndex < widget.profilesNotifier.value.length - 1) {
        _currentIndex++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No more profiles matching your criteria!')),
        );
      }
    });
  }

  void _onSwipeRight() {
    setState(() {
      // 6. Use widget.profilesNotifier.value for length check
      if (_currentIndex < widget.profilesNotifier.value.length - 1) {
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
    // 7. Use ValueListenableBuilder to react to profilesNotifier changes
    return ValueListenableBuilder<List<Xenoprofile>>(
      valueListenable: widget.profilesNotifier,
      builder: (context, currentProfiles, child) {
        // currentProfiles is the live list from profilesNotifier

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
          body: _isLoading // Check loading state for the initial load
              ? Center(child: CircularProgressIndicator())
              : currentProfiles.isEmpty // Use currentProfiles from the builder
              ? Center(
            child: Text(
              _internalAllProfiles.isEmpty && _isLoading == false // Check if initial load failed
                  ? 'Could not load profiles. Check connection or data.'
                  : 'No profiles match filters. Adjust them!',
              textAlign: TextAlign.center,
            ),
          )
              : GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) _onSwipeLeft();
              else if (details.primaryVelocity! > 0) _onSwipeRight();
            },
            // Use currentProfiles from the builder
            child: ProfileCard(profile: currentProfiles[_currentIndex]),
          ),
        );
      },
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
      margin: EdgeInsets.all(16.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (profile.imageUrl.isNotEmpty)
              Center(
                child: Image.asset(
                  profile.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.person, size: 100);
                  },
                ),
              ),
            SizedBox(height: 16),
            Text('${profile.name}, ${profile.earthage}', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 8),
            Text('Species: ${profile.species}'),
            Text('Location: ${profile.location}'),
            Text('Looking for: ${profile.lookingfor}'),
            SizedBox(height: 8),
            Text('Interests: ${profile.interests.join(', ')}'),
            SizedBox(height: 8),
            Text('Bio: ${profile.bio}', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
