import 'package:flutter/material.dart';
import 'package:xenodate/updaacct.dart';
import 'package:xenodate/characterselector.dart';
import 'package:xenodate/signin.dart';
import 'package:xenodate/main.dart'; // Or the correct path to your main.dart
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

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
              MaterialPageRoute(builder: (context) => const MyCharactersPage()), // Changed this line
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
        TextButton(
          onPressed: () {
            // Show a confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Close the dialog
                      },
                    ),
                    TextButton(
                      child: const Text('Log Out'),
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                        Navigator.of(dialogContext).pop(); // Close the dialog first
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                        } catch (e) {
                          print('Error signing out: $e');
                          Navigator.of(dialogContext).pop(); // Close the dialog even if there's an error
                          // Optionally, show an error message to the user
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error logging out. Please try again.')),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: const Text('Log Out'),
        ),
      ],
    );
  }
}
