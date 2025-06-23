import 'package:flutter/material.dart';
import 'package:xenodate/tac.dart';
import 'package:xenodate/chat.dart';
import 'package:xenodate/matches.dart';

void main() {
  runApp(const XenoDate());
}

const String appTitle ="XenoDate: Meet your intergalactic match!";

class XenoDate extends StatelessWidget {
  const XenoDate ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XenoDate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const XDLogin(title: appTitle),
    );
  }
}

// Init
class XDLogin extends StatelessWidget {
  const XDLogin ({super.key, required String title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Image.network('logo/Xenodate-logo.png'),
        Image.network('Foto/xenid_0000_01.png'),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Terms()),
              );
            },
            child: Text ('Create Character')),
        ElevatedButton(
            onPressed: null,
            child: Text ('Sign in with Google')),
        ElevatedButton(
            onPressed: null,
            child: Text('Sign in with Apple')),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => XenoChat()),
              );
            },
            child: Text('Quick Chat with Nella')),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => XenoMatches()),
              );
            },
            child: Text('Go to Matches'))
      ],
    );
  }
}


