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

class _SwipeViewWithMatchingState extends State<SwipeViewWithMatching> with TickerProviderStateMixin {
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

  // Animation variables for swipe
  late AnimationController _animationController;
  late Animation<Offset> _cardAnimation;
  double _dragX = 0.0;
  double _dragY = 0.0;
  double _rotation = 0.0;
  double _rotationAngle = 0.0;


  @override
  void initState() {
    super.initState();
    _characterService = Provider.of<CharacterService>(context, listen: false);
    _xenoprofileService = Provider.of<XenoprofileService>(context, listen: false);
    _characterService.addListener(_onCharacterServiceChange);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    )
      ..addListener(() {
        setState(() {
          _dragX = _cardAnimation.value.dx;
          _dragY = _cardAnimation.value.dy;
          _rotation = _cardAnimation.value.dx * _rotationAngle; // Adjust rotation based on drag
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Animation finished, reset for next card if it was a swipe out
          if (_dragX.abs() > 100) { // Arbitrary threshold for a full swipe
            _moveToNextProfile();
            _resetCardPosition();
          } else {
            _resetCardPosition(); // Snap back if not fully swiped
          }
        }
      });

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
    _animationController.dispose(); // Dispose the animation controller
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

      if (_filteredProfiles.isNotEmpty && _currentUserCharacter != null) {
        List<Xenoprofile> tempProfiles = List.from(_filteredProfiles);
        List<Xenoprofile> newShuffledProfiles = [];
        Random random = Random();

        while (tempProfiles.isNotEmpty) {
          double totalWeight = 0.0;
          for (Xenoprofile p in tempProfiles) {
            totalWeight += (_compatibilityScores[p.id] ?? 0.0) + 0.1; // Add a base weight to ensure all profiles have a chance
          }

          double randValue = random.nextDouble() * totalWeight;
          double currentWeightSum = 0.0;
          int selectedIndex = -1;

          for (int i = 0; i < tempProfiles.length; i++) {
            currentWeightSum += (_compatibilityScores[tempProfiles[i].id] ?? 0.0) + 0.1;
            if (currentWeightSum >= randValue) {
              selectedIndex = i;
              break;
            }
          }
          
          if (selectedIndex == -1 && tempProfiles.isNotEmpty) {
            selectedIndex = random.nextInt(tempProfiles.length); // Fallback to random if weighted selection fails
          } else if (selectedIndex == -1 && tempProfiles.isEmpty) {
            break;
          }

          Xenoprofile selectedProfile = tempProfiles[selectedIndex];
          newShuffledProfiles.add(selectedProfile);
          tempProfiles.removeAt(selectedIndex);
        }
        _filteredProfiles = newShuffledProfiles;
        print("Profiles weighted randomly shuffled after filtering.");
      } else if (_filteredProfiles.isNotEmpty && _currentUserCharacter == null) {
        // If no user character, compatibility scores are not relevant for sorting.
        // Still apply a simple shuffle for randomness.
        _filteredProfiles.shuffle(Random());
        print("Profiles shuffled randomly (no user character for compatibility).");
      }


      _currentIndex = 0; // Reset index to the start of the shuffled list
      _resetCardPosition(); // Reset card position when filters are applied
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

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
      // Calculate rotation based on horizontal drag
      final screenWidth = MediaQuery.of(context).size.width;
      _rotation = (_dragX / screenWidth * 0.5); // Adjust multiplier for desired rotation
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final swipeThreshold = screenWidth * 0.4; // 40% of screen width

    if (_dragX.abs() > swipeThreshold) {
      // Determine if it's a left or right swipe
      if (_dragX < 0) {
        _performSwipeAnimation(Alignment.bottomLeft, () => _onSwipeLeft());
      } else {
        _performSwipeAnimation(Alignment.bottomRight, () => _onSwipeRight());
      }
    } else {
      // Snap back to original position
      _resetCardPosition();
    }
  }

  void _performSwipeAnimation(Alignment endAlignment, VoidCallback onComplete) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    _cardAnimation = Tween<Offset>(
      begin: Offset(_dragX, _dragY),
      end: Offset(
        endAlignment.x * 2 * screenWidth, // Swipe far off screen
        endAlignment.y * 2 * screenHeight, // Swipe far off screen
      ),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward().then((_) {
      onComplete();
      _resetCardPosition(animate: false); // Reset immediately without animation after swipe completes
    });
  }


  void _resetCardPosition({bool animate = true}) {
    if (animate) {
      _cardAnimation = Tween<Offset>(
        begin: Offset(_dragX, _dragY),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
      _animationController.forward(from: 0.0);
    } else {
      setState(() {
        _dragX = 0.0;
        _dragY = 0.0;
        _rotation = 0.0;
      });
    }
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
        _resetCardPosition(animate: false); // Immediately reset for the new card
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
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Stack(
                  children: [
                    // Next card (optional, for subtle peek)
                    if (_currentIndex + 1 < _filteredProfiles.length)
                      Align(
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scale: 0.9, // Make next card slightly smaller
                          child: ProfileCard(
                            profile: _filteredProfiles[_currentIndex + 1],
                            compatibilityScore: _compatibilityScores[_filteredProfiles[_currentIndex + 1].id] ?? 0.0,
                          ),
                        ),
                      ),
                    // Current card with transformations
                    Transform.translate(
                      offset: Offset(_dragX, _dragY),
                      child: Transform.rotate(
                        angle: _rotation,
                        child: ProfileCard(
                          profile: _filteredProfiles[_currentIndex],
                          compatibilityScore: _compatibilityScores[_filteredProfiles[_currentIndex].id] ?? 0.0,
                        ),
                      ),
                    ),
                    // "LIKE" overlay
                    if (_dragX > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(50.0),
                          child: Opacity(
                            opacity: min(1.0, _dragX / 100), // Fade in based on drag
                            child: Transform.rotate(
                              angle: -pi / 12, // Slight rotation for "LIKE"
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green, width: 5),
                                  borderRadius: BorderRadius.circular(10), // Optional: add some border radius
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Optional: add padding inside the border
                                child: Text(
                                  'LIKE',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // "PASS" overlay
                    if (_dragX < 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(50.0),
                          child: Opacity(
                            opacity: min(1.0, _dragX.abs() / 100), // Fade in based on drag
                            child: Transform.rotate(
                              angle: pi / 12, // Slight rotation for "PASS"
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red, width: 5),
                                  borderRadius: BorderRadius.circular(10), // Optional: add some border radius
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Optional: add padding inside the border
                                child: Text(
                                  'PASS',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                    onPressed: () => _performSwipeAnimation(Alignment.bottomLeft, () => _onSwipeLeft()),
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
                    onPressed: () => _performSwipeAnimation(Alignment.bottomRight, () => _onSwipeRight()),
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