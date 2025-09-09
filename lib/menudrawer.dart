import 'package:flutter/material.dart';
import 'package:xenodate/updaacct.dart';
import 'package:xenodate/characterselector.dart';
import 'package:xenodate/signin.dart';
// import 'package:xenodate/main.dart'; // This import might not be necessary if you are navigating using named routes like '/'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xenodate/chatscreen2.dart'; // Assuming AIChatScreen is in this file
import 'package:xenodate/docingester.dart'; // Import the AdminPage class

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer( // Use Drawer widget as the root
      child: ListView( // Use ListView to allow for scrolling if content exceeds screen height
        padding: EdgeInsets.zero, // Remove default padding from ListView
        children: <Widget>[
          // You can add a DrawerHeader here for a more standard look and feel
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile( // Using ListTile for better semantics and tap handling
            leading: Icon(Icons.people_alt_outlined), // Optional: Add icons
            title: const Text('Characters'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyCharactersPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.chat_bubble_outline), // Optional: Add an icon
            title: const Text('AI Chat'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIChatScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateAcct()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.storefront_outlined),
            title: const Text('Cash Shop (Coming Soon!)'),
            onTap: null, // This will disable the ListTile
            enabled: false,
          ),
          ListTile( // Added Admin Only button
            leading: Icon(Icons.admin_panel_settings_outlined), // Optional: Add an icon
            title: const Text('Admin Only'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DocumentIngestionPage()), // Navigate to AdminPage
              );
            },
          ),
          const Divider(), // Optional: Add a visual separator
          ListTile(
            leading: Icon(Icons.logout_outlined),
            title: const Text('Log Out'),
            onTap: () {
              // Navigator.pop(context); // Close the drawer before showing dialog
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
                            Navigator.of(dialogContext).pop(); // Close the dialog
                            // Navigate to the root and remove all previous routes
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                          } catch (e) {
                            print('Error signing out: $e');
                            Navigator.of(dialogContext).pop(); // Close the dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error logging out. Please try again.')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
