import 'package:flutter/material.dart';
import 'package:xenodate/swipelimit.dart';

// Swipe Class
class Swipe extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                Image.network(
                  'Foto/xenid_0000_01.png', // Replace with your image URL
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