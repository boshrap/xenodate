import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xenodate/sigininview.dart';
import 'firebase_options.dart';
import 'package:xenodate/mainview.dart';
import 'package:xenodate/tac.dart';
import 'package:xenodate/services/charserv.dart';
import 'package:xenodate/services/matchesserv.dart';
import 'package:provider/provider.dart';// Keep if used by MainView or SignInView
import 'package:xenodate/services/xenoprofserv.dart';
import 'package:xenodate/chatscreen2.dart'; // Keep if used by MainView or SignInView
import 'package:firebase_ai/firebase_ai.dart';
import 'package:xenodate/worldbuildingform.dart';

// --- NEW IMPORTS FOR EMULATOR SETTINGS ---
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
// ------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CharacterService>( // Explicitly provide the type
          create: (_) => CharacterService(),
        ),
        ChangeNotifierProvider(create: (_) => MatchService(),
        ),
        ChangeNotifierProvider<XenoprofileService>(create: (_) => XenoprofileService(),
        ),// Add// Add other providers here if needed
      ],
      child: XenoDateApp(), // Assuming XenoDateApp is your main app widget
    ),
  ); // Renamed to avoid conflict
}

const String appTitle ="XenoDate: Meet your intergalactic match!";

class XenoDateApp extends StatelessWidget { // Renamed from XenoDate
  const XenoDateApp ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XenoDate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthWrapper(), // Start with AuthWrapper
      // Define routes if you need to navigate by name elsewhere
      routes: {
        '/main': (context) => const MainView(),
        '/signin': (context) => const SignInView(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            print("AuthWrapper - User is null, showing XDLogin");
            return XDLogin(key: ValueKey("XDLoginView"), title: appTitle);
          }
          print("AuthWrapper - User is not null, showing MainView");
          return MainView(key: ValueKey("MainView"));
        }
        // Show a loading spinner or some other placeholder while checking auth state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}


// Your original XDLogin, now serves as an entry point if not logged in
class XDLogin extends StatelessWidget {
  const XDLogin ({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    // It's better to build a Scaffold here if this is a full screen
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding( // Added padding for better layout
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons stretch
          children: <Widget>[
            // Consider using Image.asset if images are local
            // Image.network('logo/Xenodate-logo.png'),
            // Image.network('Foto/xenid_0000_01.png'),
            // For local assets, add them to your pubspec.yaml and use Image.asset:
            Image.network('logo/Xenodate-logo.png'), // Example path
            SizedBox(height: 20),
            // Image.asset('assets/Foto/xenid_0000_01.png', height: 150), // Example path
            // SizedBox(height: 30),

            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Terms()), // Ensure Terms() is defined
                  );
                },
                child: Text ('Create Character / View Terms')),
            ElevatedButton(
                onPressed: () {
                  // TODO: Implement Google Sign In
                  print("Sign in with Google - Not Implemented");
                },
                child: Text ('Sign in with Google')),
            ElevatedButton(
                onPressed: () {
                  // TODO: Implement Apple Sign In
                  print("Sign in with Apple - Not Implemented");
                },
                child: Text('Sign in with Apple')),
            ElevatedButton(
                onPressed: () {
                  // Navigate to the SignInView for email/password
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInView()),
                  );
                },
                child: Text('Sign in with Email')),
            // ElevatedButton(
            //     onPressed: () {
            //       // This Quick Chat might be a feature for logged-in users,
            //       // or a guest chat. If for logged-in users, it should be in MainView.
            //       // Navigator.push(
            //       //   context,
            //       //   MaterialPageRoute(builder: (context) => XenoChat()), // Ensure XenoChat() is defined
            //       // );
            //        print("Quick Chat button pressed");
            //     },
            //     child: Text('Quick Chat')),

            // New Button for AIChatScreen
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AIChatScreen()),
                );
              },
              child: const Text('Chat with AI'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorldBuildingForm()),
                );
              },
              child: const Text('World Building Form'),
            ),
          ],
        ),
      ),
    );
  }
}