import 'package:flutter/material.dart';
import 'package:xenodate/chat.dart';

class XenoMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Image.network(
                    'Foto/xenid_0000_01.png',
                    width: 120,
                    height: 120,
                    semanticLabel: 'Xeno photo',
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        // Handle badge tap here
                        // e.g., show a dialog or navigate to a new screen
                      },
                      child: Container(
                        child: Image.network('ico/del.png', width: 25, height: 25,)
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Nella "Nel"'),
                    Text('You matched XX days ago.'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(onPressed: null, icon: const Icon(Icons.person)),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => XenoChat()),
                            );
                          },
                          icon: const Icon(Icons.message),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}