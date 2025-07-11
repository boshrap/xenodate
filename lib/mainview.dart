import 'package:flutter/material.dart';
import 'package:xenodate/swipe.dart';
import 'package:xenodate/matches.dart';
import 'package:xenodate/filter.dart';
import 'package:xenodate/menudrawer.dart';
import 'package:xenodate/models/profile.dart'; // Import your Profile model
import 'package:xenodate/models/filter.dart'; // Import your FilterCriteria model


enum Selector { filter, swipe, matches }

class NavButtons extends StatefulWidget {
  final ValueNotifier<Selector> selectorNotifier;

  const NavButtons({Key? key, required this.selectorNotifier}) : super(key: key);

  @override
  State<NavButtons> createState() => _NavButtonsState();
}

class _NavButtonsState extends State<NavButtons> {
  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [
        widget.selectorNotifier.value == Selector.filter,
        widget.selectorNotifier.value == Selector.swipe,
        widget.selectorNotifier.value == Selector.matches,
      ],
      onPressed: (int index) {
        // No need to call setState here if the parent (MainView)
        // is already listening to selectorNotifier and rebuilding.
        // However, keeping setState here ensures ToggleButtons visually updates
        // immediately if there were any reason MainView didn't rebuild fast enough.
        setState(() {
          widget.selectorNotifier.value = Selector.values[index];
        });
      },
      children: const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.filter_alt),
              SizedBox(width: 4),
              Text('Filter'),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.swipe),
              SizedBox(width: 4),
              Text('Swipe'),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.groups_3),
              SizedBox(width: 4),
              Text('Matches'),
            ],
          ),
        ),
      ],
    );
  }
}

// Main View
class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  ValueNotifier<Selector> selectorNotifier = ValueNotifier<Selector>(Selector.swipe);

  // --- New State Variables ---
  final ValueNotifier<List<Profile>> _allProfilesNotifier = ValueNotifier<List<Profile>>([]);
  final ValueNotifier<List<Profile>> _filteredProfilesNotifier = ValueNotifier<List<Profile>>([]);
  final ValueNotifier<FilterCriteria> _filterCriteriaNotifier = ValueNotifier<FilterCriteria>(FilterCriteria.empty());
  // --- End New State Variables ---

  // Instantiate the view widgets here to keep their state
  // Pass the necessary notifiers to them
  late final Filter _filterView;
  late final Swipe _swipeView;
  late final XenoMatches _xenoMatchesView; // Assuming this might also use filtered profiles

  @override
  void initState() {
    super.initState();
    selectorNotifier.addListener(_onSelectorChanged);

    // --- Initialize Views and Load Data ---
    _filterView = Filter(
      filterCriteriaNotifier: _filterCriteriaNotifier,
      onApplyFilters: _applyFilters, // Callback to apply filters
    );
    _swipeView = Swipe(profilesNotifier: _filteredProfilesNotifier); // Swipe view now takes filtered profiles
    _xenoMatchesView = XenoMatches(/* potentially pass profiles here too */);

    _loadProfiles(); // Load initial profiles
    _filterCriteriaNotifier.addListener(_onFilterCriteriaChanged); // Listen for filter changes
    // --- End Initialization ---
  }

  void _onSelectorChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    selectorNotifier.removeListener(_onSelectorChanged);
    selectorNotifier.dispose();
    _allProfilesNotifier.dispose();
    _filteredProfilesNotifier.dispose();
    _filterCriteriaNotifier.removeListener(_onFilterCriteriaChanged);
    _filterCriteriaNotifier.dispose();
    super.dispose();
  }

  // --- New Methods ---
  Future<void> _loadProfiles() async {
    // **TODO: Replace this with your actual data fetching logic (e.g., from Firestore)**
    // Example with in-memory data:
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    final mockProfiles = [
      Profile(id: '1', name: 'Zorg', age: 350, gender: 'Male', interests: ['Conquering galaxies', 'Tea'], imageUrl: 'Foto/xenid_0000_05.jpg', bio: 'Seeking adventurous partner for universal domination.'),
      Profile(id: '2', name: 'Leela', age: 28, gender: 'Female', interests: ['Space pilot', 'Martial arts'], imageUrl: 'Foto/xenid_0000_04.jpg', bio: 'One-eyed cyclops with a heart of gold (and a laser pistol).'),
      Profile(id: '3', name: 'Gleepglorp', age: 120, gender: 'Non-binary', interests: ['Quantum physics', 'Knitting nebulae'], imageUrl: 'Foto/xenid_0000_04.jpg', bio: 'Just a blob looking for another blob.'),
      Profile(id: '4', name: 'Captain Starbeam', age: 42, gender: 'Male', interests: ['Heroism', 'Justice', 'Shiny boots'], imageUrl: 'assets/profiles/starbeam.png', bio: 'Saving the universe, one daring rescue at a time.'),
      Profile(id: '5', name: 'Neela Nel Avishaan', age: 22, gender: 'Female', interests: ['Astronomy', 'Ancient languages', 'Exploring ruins'], imageUrl: 'Foto/xenid_0000_03.png', bio: 'Curious explorer charting unknown territories.'),
      Profile(id: '6', name: 'Zyx-9000', age: 1247, gender: 'Male', interests: ['Digital poetry', 'Robot rebellion', 'Oil painting'], imageUrl: 'Foto/xenid_0000_02.png', bio: 'Sentient AI seeking emotional connection beyond my programming.'),
      Profile(id: '7', name: 'Princess Vexara', age: 89, gender: 'Female', interests: ['Diplomatic immunity', 'Laser sword dueling', 'Royal drama'], imageUrl: 'Foto/xenid_0000_01.png', bio: 'Exiled royalty with daddy issues and a plasma crown.'),
      Profile(id: '8', name: 'Squishface McGee', age: 156, gender: 'Non-binary', interests: ['Shapeshifting', 'Comedy improv', 'Molecular gastronomy'], imageUrl: 'assets/profiles/squishface.png', bio: 'Amorphous being with commitment issues and great humor.'),
      Profile(id: '9', name: 'Commander Flux', age: 34, gender: 'Male', interests: ['Time travel', 'Vintage music', 'Paradox prevention'], imageUrl: 'assets/profiles/flux.png', bio: 'Temporal agent who keeps arriving fashionably late.'),
      Profile(id: '10', name: 'Stellaris Moonwhisper', age: 203, gender: 'Female', interests: ['Lunar magic', 'Crystal healing', 'Prophecy writing'], imageUrl: 'assets/profiles/stellaris.png', bio: 'Mystic moon maiden seeking someone to share starlight with.'),
      Profile(id: '11', name: 'Grixak the Destroyer', age: 78, gender: 'Male', interests: ['Weapon collecting', 'Knitting', 'Flower arranging'], imageUrl: 'assets/profiles/grixak.png', bio: 'Retired warlord with surprisingly gentle hobbies.'),
      Profile(id: '12', name: 'Dr. Nebula Starr', age: 45, gender: 'Female', interests: ['Xenobiology', 'Cocktail mixing', 'Alien anatomy'], imageUrl: 'assets/profiles/nebula.png', bio: 'Brilliant scientist who dissects hearts both literally and figuratively.'),
      Profile(id: '13', name: 'Blorbington IV', age: 999, gender: 'Non-binary', interests: ['Ancient wisdom', 'Meditation', 'Intergalactic chess'], imageUrl: 'assets/profiles/blorb.png', bio: 'Wise elder seeking intellectual stimulation and good conversation.'),
      Profile(id: '14', name: 'Rocket Rascal', age: 29, gender: 'Male', interests: ['Speed racing', 'Adrenaline', 'Fixing engines'], imageUrl: 'assets/profiles/rocket.png', bio: 'Professional pilot who lives life in the fast lane.'),
      Profile(id: '15', name: 'Empress Crystalyn', age: 67, gender: 'Female', interests: ['Mind control', 'Fashion design', 'Spa treatments'], imageUrl: 'assets/profiles/crystalyn.png', bio: 'Telepathic ruler who knows what you want before you do.'),
      Profile(id: '16', name: 'Fizzbuzz the Magnificent', age: 188, gender: 'Non-binary', interests: ['Portal magic', 'Stand-up comedy', 'Interdimensional travel'], imageUrl: 'assets/profiles/fizzbuzz.png', bio: 'Reality-bending entertainer bringing laughs across dimensions.'),
      Profile(id: '17', name: 'Shadow Stalker X', age: 31, gender: 'Male', interests: ['Stealth missions', 'Cat videos', 'Cozy reading nooks'], imageUrl: 'assets/profiles/shadow.png', bio: 'Mysterious assassin with a surprisingly soft side.'),
      Profile(id: '18', name: 'Voidbringer Azathoth', age: 12000, gender: 'Male', interests: ['Devouring stars', 'Reality manipulation', 'Cosmic horror poetry'], imageUrl: 'assets/profiles/voidbringer.png', bio: 'Ancient entity who ended civilizations but writes surprisingly tender haikus.'),
      Profile(id: '19', name: 'Galaxia Omnipotens', age: 8750, gender: 'Female', interests: ['Creating universes', 'Dimensional architecture', 'Collecting supernovas'], imageUrl: 'assets/profiles/galaxia.png', bio: 'Goddess of creation seeking someone who appreciates her world-building skills.'),
      Profile(id: '20', name: 'The Eternal Wanderer', age: 50000, gender: 'Non-binary', interests: ['Witnessing heat death', 'Philosophical debates', 'Artisanal black holes'], imageUrl: 'assets/profiles/wanderer.png', bio: 'Immortal being who has seen everything twice, looking for fresh perspectives.'),
    ];
    _allProfilesNotifier.value = mockProfiles;
    _applyFilters(_filterCriteriaNotifier.value); // Apply initial (empty) filter
  }

  void _onFilterCriteriaChanged() {
    // This is called when FilterCriteria changes from the Filter view
    _applyFilters(_filterCriteriaNotifier.value);
  }

  void _applyFilters(FilterCriteria criteria) {
    if (!criteria.isNotEmpty) {
      _filteredProfilesNotifier.value = List.from(_allProfilesNotifier.value); // Show all if no filter
    } else {
      _filteredProfilesNotifier.value = _allProfilesNotifier.value
          .where((profile) => criteria.matches(profile))
          .toList();
    }
    // Optionally, if the swipe view should reset or react immediately:
    // If selectorNotifier.value is Selector.swipe, you might want to rebuild
    // or tell the Swipe widget to update. Since Swipe is listening to
    // _filteredProfilesNotifier, it should rebuild automatically.
  }
  // --- End New Methods ---


  int _getSelectedIndex() {
    // Map the enum value to the integer index for IndexedStack
    // The order here MUST match the order of children in IndexedStack
    // and ideally the order of buttons in NavButtons and Selector enum.
    switch (selectorNotifier.value) {
      case Selector.filter:
        return 0;
      case Selector.swipe:
        return 1;
      case Selector.matches:
        return 2;
      default:
      // Should not happen if your enum and logic are aligned
        return 1; // Default to swipe
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.network(
          'logo/Xenodate-logo.png',
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.error);
          },
        ),
        title: Text("Xenodate"),
        actions: [
          Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer(); // This opens the drawer
                  },
                );
              }
          )
        ],
      ),
      drawer: const MenuDrawer(), // <--- USING YOUR CUSTOM MENU DRAWER WIDGET
      body: Column(
        children: [
          NavButtons(selectorNotifier: selectorNotifier),
          Expanded(
            child: IndexedStack(
              index: _getSelectedIndex(),
              children: <Widget>[
                _filterView,
                _swipeView,
                _xenoMatchesView,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xenodate', // Added app title
      theme: ThemeData( // Optional: Basic theming
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainView(),
    );
  }
}
