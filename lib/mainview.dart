import 'package:flutter/material.dart';
import 'package:xenodate/swipe.dart';
import 'package:xenodate/matches.dart';
import 'package:xenodate/filter.dart';

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
  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  ValueNotifier<Selector> selectorNotifier = ValueNotifier<Selector>(Selector.swipe);

  @override
  void initState() {
    super.initState();
    selectorNotifier.addListener(_updateView);
  }

  @override
  void dispose() {
    selectorNotifier.removeListener(_updateView);
    selectorNotifier.dispose();
    super.dispose();
  }

  void _updateView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.network(
          'logo/Xenodate-logo.png', // Replace with your logo URL
        ),
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
      drawer: Drawer(
       child: ListView(
         padding: EdgeInsets.zero,
         children: [
           ListTile(
             title: const Text('Xenodate'),
             onTap: () {} ,
           ),
           ListTile(
             title: Text('Characters'),
             onTap: () {} ,
           ),
           ListTile(
             title: Text('Settings'),
             onTap: () {} ,
           ),
           ListTile(
             title: Text('Cash Shop (Coming Soon!)'),
             onTap: () {},
           ),
         ],
       ),
      ),
      body: Column(
        children: [
          NavButtons(selectorNotifier: selectorNotifier),
          Expanded(
            child: _buildView(),
          ),
        ],
      ),
    );
  }

  Widget _buildView() {
    switch (selectorNotifier.value) {
      case Selector.filter:
        return Filter();
      case Selector.swipe:
        return Swipe();
      case Selector.matches:
        return XenoMatches();
      default:
        return Swipe();
    }
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainView(),
    );
  }
}
