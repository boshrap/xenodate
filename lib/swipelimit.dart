import 'package:flutter/material.dart';
import 'package:xenodate/matches.dart';

class NoMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.network(
          'logo/Xenodate-logo.png', // Replace with your logo URL
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Filters'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Swipe'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => XenoMatches()),
                    );
                  },
                  child: Text('Matches'),
                ),
              ],
            ),
            Container(
              child: Image.network('ico/errorMin.png'),
            ),
            const Column(
              children: [
                const Text('No Matches Found!'),
                ElevatedButton(
                    onPressed: null,
                    child: Text('Change Filters'),
                )
              ],

            )
          ],
        ),
      ),
    );
  }
}

class SwipeLimit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.network(
          'logo/Xenodate-logo.png', // Replace with your logo URL
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Filters'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Swipe'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Matches'),
                ),
              ],
            ),
            Container(
              child: Image.network('ico/errorMin.png'),
            ),
            const Column(
              children: [
                const Text('Swipe Limit Reached!'),
                const Text('Your XenoDevice has exhausted it\'s supply of swipes. Your swipes will recharge at the end of the week. Chat with your matches in the meantime!'),

              ],

            )
          ],
        ),
      ),
    );
  }
}