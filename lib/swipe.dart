import 'package:flutter/material.dart';
import 'package:xenodate/swipelimit.dart';

// Swipe Class
class Swipe extends StatefulWidget {
  @override
  _SwipeState createState() => _SwipeState();
}

class _SwipeState extends State<Swipe> {
  final List<String> cardImages = [
    'Foto/xenid_0000_01.png',
    'Foto/xenid_0000_02.png',
    'Foto/xenid_0000_03.png',
    'Foto/xenid_0000_04.png',
    'Foto/xenid_0000_05.png',
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Dismissible(
            key: Key(cardImages[_currentIndex]),
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                // Handle "Nope" action
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NoMatches()),
                );
              } else {
                // Handle "Yep" action
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SwipeLimit()),
                );
              }
              setState(() {
                _currentIndex = (_currentIndex + 1) % cardImages.length;
              });
            },
            child: Card(
              child: Column(
                children: [
                  Image.network(
                    cardImages[_currentIndex],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nella "Nel"'),
                            Text('Keplian'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.info),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NoMatches()),
                  );
                },
                child: Text('Nope'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SwipeLimit()),
                  );
                },
                child: Text('YEP'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}