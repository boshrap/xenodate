import 'package:flutter/material.dart';

class SettingDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          TextButton
            (onPressed: () {},
              child: const Text('Characters')),
          TextButton
            (onPressed: () {},
              child: const Text('Settings')),
          TextButton
            (onPressed: () {},
              child: const Text('Cash Shop')),
        ]
      ),
    );
  }
}
