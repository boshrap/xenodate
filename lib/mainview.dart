import 'package:flutter/material.dart';
import 'package:xenodate/swipeview.dart';
import 'package:xenodate/data_utils.dart';
import 'package:xenodate/matches.dart';
import 'package:xenodate/filterview.dart';
import 'package:xenodate/menudrawer.dart';
import 'package:xenodate/models/xenoprofile.dart'; // Import your Profile model
import 'package:xenodate/models/filter.dart';    // Import your FilterCriteria model


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
  MainViewState createState() => MainViewState();
}

class MainViewState extends State<MainView> {
  ValueNotifier<Selector> selectorNotifier = ValueNotifier<Selector>(Selector.swipe);

  final ValueNotifier<List<Xenoprofile>> _allProfilesNotifier = ValueNotifier<List<Xenoprofile>>([]);
  final ValueNotifier<List<Xenoprofile>> _filteredProfilesNotifier = ValueNotifier<List<Xenoprofile>>([]);
  final ValueNotifier<FilterCriteria> _filterCriteriaNotifier = ValueNotifier<FilterCriteria>(FilterCriteria.empty());

  late final Filter _filterView;
  late final SwipeView _swipeView;
  late final XenoMatches _xenoMatchesView;

  @override
  void initState() {
    super.initState();
    selectorNotifier.addListener(_onSelectorChanged);

    _filterView = Filter(
      filterCriteriaNotifier: _filterCriteriaNotifier,
      onApplyFilters: _applyFilters,
    );
    _swipeView = SwipeView(profilesNotifier: _filteredProfilesNotifier);
    _xenoMatchesView = XenoMatches();

    _fetchAndSetProfiles(); // Changed from _loadProfiles to _fetchAndSetProfiles
    _filterCriteriaNotifier.addListener(_onFilterCriteriaChanged);
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

  // --- MODIFIED METHOD to load from JSON ---
  Future<void> _fetchAndSetProfiles() async {
    // Show a loading indicator if you want (optional)
    // For example, you could add a ValueNotifier<bool> _isLoadingNotifier

    List<Xenoprofile> loadedProfiles = await loadXenoprofiles(); // Call the JSON loading function
    _allProfilesNotifier.value = loadedProfiles;
    _applyFilters(_filterCriteriaNotifier.value); // Apply initial (empty) filter

    // Hide loading indicator (if you added one)
  }
  // --- END MODIFIED METHOD ---

  void _onFilterCriteriaChanged() {
    _applyFilters(_filterCriteriaNotifier.value);
  }

  void _applyFilters(FilterCriteria criteria) {
    if (!criteria.isNotEmpty) {
      _filteredProfilesNotifier.value = List.from(_allProfilesNotifier.value);
    } else {
      _filteredProfilesNotifier.value = _allProfilesNotifier.value
          .where((profile) => criteria.matches(profile))
          .toList();
    }
  }

  int _getSelectedIndex() {
    switch (selectorNotifier.value) {
      case Selector.filter:
        return 0;
      case Selector.swipe:
        return 1;
      case Selector.matches:
        return 2;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.network(
          'logo/Xenodate-logo.png', // Consider adding this to your assets for offline use
          errorBuilder: (context, error, stackTrace) {
            // Placeholder if logo fails to load (e.g., local asset instead)
            return Icon(Icons.error_outline); // Or Image.asset('assets/logo/Xenodate-logo.png')
          },
        ),
        title: Text("Xenodate"),
        actions: [
          Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              }
          )
        ],
      ),
      drawer: const MenuDrawer(),
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

// Ensure MyApp and main() are still present if this is your main app file
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xenodate',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainView(),
      debugShowCheckedModeBanner: false, // Optional: remove debug banner
    );
  }
}
