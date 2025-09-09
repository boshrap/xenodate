import 'package:flutter/material.dart';
import 'package:xenodate/swipeview.dart';
import 'package:xenodate/matches.dart';
import 'package:xenodate/menudrawer.dart';
import 'package:xenodate/models/xenoprofile.dart';
import 'package:xenodate/models/filter.dart';
import 'package:xenodate/services/xenoprofserv.dart';


// MODIFIED: Removed Selector.filter
enum Selector { swipe, matches }

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
        // MODIFIED: Adjusted for removed filter
        widget.selectorNotifier.value == Selector.swipe,
        widget.selectorNotifier.value == Selector.matches,
      ],
      onPressed: (int index) {
        setState(() {
          // MODIFIED: Adjusted for removed filter
          widget.selectorNotifier.value = Selector.values[index];
        });
      },
      // MODIFIED: Removed Filter button
      children: const <Widget>[
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
  // MODIFIED: Default to swipe if filter is removed
  ValueNotifier<Selector> selectorNotifier = ValueNotifier<Selector>(Selector.swipe);

  final ValueNotifier<List<Xenoprofile>> _allProfilesNotifier = ValueNotifier<List<Xenoprofile>>([]);
  final ValueNotifier<List<Xenoprofile>> _filteredProfilesNotifier = ValueNotifier<List<Xenoprofile>>([]);
  final ValueNotifier<FilterCriteria> _filterCriteriaNotifier = ValueNotifier<FilterCriteria>(FilterCriteria.empty());
  final XenoprofileService _xenoprofileService = XenoprofileService();

  // If you still need to apply filters, keep this. Otherwise, remove it.
  void _updateFilters(FilterCriteria newFilters) {
    _filterCriteriaNotifier.value = newFilters;
  }

  // late final Filter _filterView; // REMOVED
  late final SwipeViewWithMatching _swipeView;
  late final XenoMatches _xenoMatchesView;

  @override
  void initState() {
    super.initState();
    selectorNotifier.addListener(_onSelectorChanged);

    // _filterView = Filter( // REMOVED
    //   filterCriteriaNotifier: _filterCriteriaNotifier,
    //   onApplyFilters: _applyFilters,
    // );
    _swipeView = SwipeViewWithMatching(profilesNotifier: _filteredProfilesNotifier, userId: '',);
    _xenoMatchesView = XenoMatches();

    _fetchAndSetProfiles();
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

  Future<void> _fetchAndSetProfiles() async {
    // Use the service to get profiles
    List<Xenoprofile> loadedProfiles =
    await _xenoprofileService.getAllXenoprofiles();
    _allProfilesNotifier.value = loadedProfiles;
    _applyFilters(_filterCriteriaNotifier.value); // Apply initial filters
  }


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
    // MODIFIED: Adjusted for removed filter
    switch (selectorNotifier.value) {
      case Selector.swipe:
        return 0; // Swipe is now the first item
      case Selector.matches:
        return 1; // Matches is now the second item
      default:
        return 0; // Default to swipe
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
          'logo/Xenodate-logo.png',
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.error_outline);
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
              // MODIFIED: Removed _filterView
              children: <Widget>[
                // _filterView, // REMOVED
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
      title: 'Xenodate',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
