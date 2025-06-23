import 'package:flutter/material.dart';
import 'package:xenodate/updaacct.dart';
import 'package:xenodate/updachar.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UpdaChar()),
            );
          },
          child: const Text('Characters'),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UpdateAcct()),
            );
          },
          child: const Text('Settings'),
        ),
        TextButton(
          onPressed: null, // Disable the button
          child: const Text('Cash Shop (Coming Soon!)'),
        ),
      ],
    );
  }
}