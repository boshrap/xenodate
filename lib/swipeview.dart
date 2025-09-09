// lib/swipeview_with_matching.dart
import 'dart:convert';
import 'dart:math'; // Import for Random
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xenodate/models/xenoprofile.dart';
import 'package:xenodate/models/character.dart';
import 'package:xenodate/models/filter.dart';
import 'package:xenodate/filterview.dart';
import 'package:xenodate/profilecard.dart';
import 'package:xenodate/services/matching_service.dart';
import 'package:xenodate/services/charserv.dart';
import 'package:xenodate/services/xenoprofserv.dart';
import 'package:xenodate/characterselector.dart';

class SwipeViewWithMatching extends StatefulWidget {
  final String userId;

  const SwipeViewWithMatching({Key? key, required this.userId, required ValueNotifier<List<Xenoprofile>> profilesNotifier}) : super(key: key);

  @override
  _SwipeViewWithMatchingState createState() => _SwipeViewWithMatchingState();
}

class _SwipeViewWithMatchingState extends State<SwipeViewWithMatching> {
  List<Xenoprofile> _allProfiles = [];
  List<Xenoprofile> _filteredProfiles = [];
  ValueNotifier<FilterCriteria> _filterCriteriaNotifier = ValueNotifier(FilterCriteria.empty());

  final MatchingService _matchingService = MatchingService();

  Character? _currentUserCharacter;
  bool _isLoading = true;
  int _currentIndex = 0;

  Map<String, double> _compatibilityScores = {};

  late CharacterService _characterService;
  late XenoprofileService _xenoprofileService;


  @override
  void initState() {
    super.initState();
    _characterService = Provider.of<CharacterService>(context, listen: false);
    _xenoprofileService = Provider.of<XenoprofileService>(context, listen: false);
    _characterService.addListener(_onCharacterServiceChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
    _filterCriteriaNotifier.addListener(_applyFiltersToList);
  }

  @override
  void dispose() {
    _filterCriteriaNotifier.removeListener(_applyFiltersToList);
    _filterCriteriaNotifier.dispose();
    _characterService.removeListener(_onCharacterServiceChange);
    super.dispose();
  }

  void _onCharacterServiceChange() {
    print("CharacterService changed, re-initializing data for SwipeView");
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUserCharacter = await _characterService.getSelectedCharacter(widget.userId);

      if (_currentUserCharacter == null) {
        if (mounted) {
          // It seems noChar2NewChar is a custom function you have.
          // Make sure it handles navigation or UI changes appropriately.
          // await noChar2NewChar(context);
          print("No character selected, prompting for creation/selection.");
          if (mounted) {
            setState(() { _isLoading = false; });
          }
        }
        return;
      }

      await _loadProfiles();

    } catch (e) {
      print("Error initializing data: $e");
      if (mounted) _showErrorDialog("Failed to load data. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProfiles() async {
    try {
      _allProfiles = await _xenoprofileService.getAllXenoprofiles();

      if (_currentUserCharacter == null) {
        print("Current user character is null in _loadProfiles. This should ideally be handled before calling _loadProfiles or lead to a state where no profiles are shown.");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _filteredProfiles = []; // Ensure filtered profiles are empty
          });
        }
        return;
      }

      _calculateCompatibilityScores();
      _applyFiltersToList();
    } catch (e) {
      print("Error loading profiles from service: $e");
      if (mounted) _showErrorDialog("Failed to load profiles. Please check your connection.");
      // Re-throwing or handling appropriately
    }
  }

  void _calculateCompatibilityScores() {
    if (_currentUserCharacter == null) return;

    _compatibilityScores.clear();
    for (Xenoprofile profile in _allProfiles) {
      double score = _matchingService.calculateCompatibilityScore(_currentUserCharacter!, profile);
      _compatibilityScores[profile.id] = score;
    }
  }

  void _applyFiltersToList() {
    final criteria = _filterCriteriaNotifier.value;
    setState(() {
      _filteredProfiles = _allProfiles.where((profile) {
        if (profile.earthage == null) {
          if (criteria.minAge != null || criteria.maxAge != null) {
            return false;
          }
        } else {
          if (criteria.minAge != null && profile.earthage! < criteria.minAge!) return false;
          if (criteria.maxAge != null && profile.earthage! > criteria.maxAge!) return false;
        }

        if (criteria.gender != null && profile.gender.toLowerCase() != criteria.gender!.toLowerCase()) return false;
        if (criteria.species != null && profile.species.toLowerCase() != criteria.species!.toLowerCase()) return false;
        if (criteria.location != null && profile.location.toLowerCase() != criteria.location!.toLowerCase()) return false;
        if (criteria.lookingFor != null && profile.lookingfor.toLowerCase() != criteria.lookingFor!.toLowerCase()) return false;

        if (criteria.interests != null && criteria.interests!.isNotEmpty) {
          bool interestMatch = false;
          List<String> profileInterests = profile.interests.map((interest) => interest.toLowerCase()).toList();
          for (String filterInterest in criteria.interests!) {
            if (profileInterests.contains(filterInterest.toLowerCase())) {
              interestMatch = true;
              break;
            }
          }
          if (!interestMatch) return false;
        }
        return true;
      }).toList();

      // Sort by compatibility score (highest first)
      if (_currentUserCharacter != null) {
        _filteredProfiles.sort((a, b) {
          double scoreA = _compatibilityScores[a.id] ?? 0.0;
          double scoreB = _compatibilityScores[b.id] ?? 0.0;
          return scoreB.compareTo(scoreA); // Highest score first
        });
      }

      // Shuffle the filtered and sorted list
      if (_filteredProfiles.isNotEmpty) {
        _filteredProfiles.shuffle(Random()); // Use dart:math's Random
        print("Profiles shuffled after filtering/sorting.");
      }

      _currentIndex = 0; // Reset index to the start of the shuffled list
    });
  }

  void _handleApplyFilters(FilterCriteria newCriteria) {
    _filterCriteriaNotifier.value = newCriteria; // This will trigger _applyFiltersToList
    Navigator.of(context).pop();
  }

  void _openFilterView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Filter(
            filterCriteriaNotifier: _filterCriteriaNotifier,
            onApplyFilters: _handleApplyFilters,
          ),
        );
      },
    );
  }

  void _onSwipeLeft() async {
    if (_currentIndex >= _filteredProfiles.length) return;
    final currentProfile = _filteredProfiles[_currentIndex];
    print("Profile disliked: ${currentProfile.name}");
    _moveToNextProfile();
  }

  void _onSwipeRight() async {
    if (_currentIndex >= _filteredProfiles.length || _currentUserCharacter == null) return;

    final currentProfile = _filteredProfiles[_currentIndex];
    print("Profile liked: ${currentProfile.name}");

    bool isCompatible = _matchingService.areCompatible(_currentUserCharacter!, currentProfile);

    if (isCompatible) {
      final match = await _matchingService.createMatch(_currentUserCharacter!, currentProfile );
      if (match != null) {
        _showMatchCreatedDialog(currentProfile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create match. You may have already matched.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not quite compatible, but your interest has been noted!')),
      );
    }
    _moveToNextProfile();
  }

  void _moveToNextProfile() {
    setState(() {
      if (_currentIndex < _filteredProfiles.length - 1) {
        _currentIndex++;
      } else {
        // Optionally, inform the user they've reached the end of the shuffled list for the current filters
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No more profiles matching your criteria for now!')),
        );
        // Consider what should happen here: maybe disable swipe buttons or show a different message.
        // For now, it will just show the "You've seen all profiles for now!" message from the build method.
      }
    });
  }

  void _showMatchCreatedDialog(Xenoprofile profile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('It\'s a Match!'),
          content: Text('You and ${profile.name} are compatible! Check your matches.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Great!'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Placeholder for your noChar2NewChar function if it's not defined elsewhere
  // or needs specific handling in this context.
  Future<void> noChar2NewChar(BuildContext context) async {
    // This is a placeholder. Implement your actual navigation or dialog logic here.
    print("noChar2NewChar called - user needs to create/select a character.");
    // Example: You might navigate to a character creation screen
    // Navigator.of(context).push(MaterialPageRoute(builder: (_) => YourCharacterCreationScreen()));
    // For now, just show a dialog to indicate action is needed.
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Character Required'),
            content: Text('Please create or select a character to start viewing profiles.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Potentially navigate to character management screen
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_currentUserCharacter != null ? "Profiles for ${_currentUserCharacter!.name}" : "XenoDate"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _currentUserCharacter != null ? _openFilterView : null, // Disable if no character
            tooltip: _currentUserCharacter != null ? "Open Filters" : "Select a character to enable filters",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentUserCharacter == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Please select or create a character profile to start matching.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to character selection/creation page
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyCharactersPage()));
                print("Navigate to character selection/creation");
                // You'll need to implement the actual navigation
                // For now, triggering a re-check which might call noChar2NewChar
                _initializeData();
              },
              child: Text('Select/Create Character'),
            )
          ],
        ),
      )
          : _filteredProfiles.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _filterCriteriaNotifier.value == FilterCriteria.empty() && _allProfiles.isNotEmpty
                ? 'No profiles available right now. Check back later!' // General case if allProfiles exist but initial filter yields none (before user interaction)
                : 'No profiles match your current filters. Try adjusting them or broaden your search!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: (_currentIndex < _filteredProfiles.length)
                  ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < 0) {
                    _onSwipeLeft();
                  } else if (details.primaryVelocity! > 0) {
                    _onSwipeRight();
                  }
                },
                child: ProfileCard(
                  profile: _filteredProfiles[_currentIndex],
                  compatibilityScore: _compatibilityScores[_filteredProfiles[_currentIndex].id] ?? 0.0,
                ),
              )
                  : Padding( // This is shown when _currentIndex >= _filteredProfiles.length
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "You've seen all available profiles for the current criteria!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
          if (_filteredProfiles.isNotEmpty && _currentIndex < _filteredProfiles.length)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _onSwipeLeft,
                    icon: Icon(Icons.close, size: 28),
                    label: Text('Pass', style: TextStyle(fontSize: 18)),
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
                    onPressed: _onSwipeRight,
                    icon: Icon(Icons.favorite, size: 28, color: Colors.pinkAccent),
                    label: Text('Like', style: TextStyle(fontSize: 18)),
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
        ],
      ),
    );
  }
}
