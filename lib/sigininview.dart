// lib/signin_view.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xenodate/createacct.dart';
// You might not need to explicitly navigate here if AuthWrapper handles it
import 'package:xenodate/mainview.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key}); // This is correct and allows const instantiation

  @override
  _SignInViewState createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _errorMessage = null;
        });
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // After successful sign-in, AuthWrapper will handle showing MainView.
        // We need to pop SignInView from the navigation stack.
        // Check if the widget is still in the tree (mounted) before calling Navigator.
        if (mounted) { // Best practice: Check if the widget is still mounted
          Navigator.of(context).pop(); // Removes the current route (SignInView) from the top of the navigation stack.
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
        print('Failed to sign in: ${e.code} - ${e.message}');
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
        print('Sign in error: $e');
      }
    }
  }

  // Example Sign Up Method (you'd likely move this to a separate SignUpView)
  Future<void> _signUpWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _errorMessage = null;
        });
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // User created, AuthWrapper will navigate
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
        print('Failed to sign up: ${e.code} - ${e.message}');
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred during sign up.';
        });
        print('Sign up error: $e');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In to Xenodate")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Welcome to Xenodate", style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _signInWithEmailAndPassword,
                  child: Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 40) // Full width
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateAcct()), // Assuming CreateAccountView is the widget in createacct.dart
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                )

                // Add Google Sign-In or other providers if needed
              ],
            ),
          ),
        ),
      ),
    );
  }
}
