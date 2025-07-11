import 'package:flutter/material.dart';
import 'package:xenodate/createacct.dart';
import 'package:xenodate/newchar.dart'; // Assuming this is your next screen after login
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        print('Firebase user signed in successfully: ${userCredential.user?.uid}');

        setState(() {
          _isLoading = false;
        });

        // Navigate to the next screen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NewChar()), // Or your home screen
        );

      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
          if (e.code == 'user-not-found') {
            _errorMessage = 'No user found for that email.';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'Wrong password provided for that user.';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'The email address is not valid.';
          } else {
            _errorMessage = 'An error occurred. Please try again.';
          }
          print('Firebase Auth Error: ${e.message}');
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
          print('Generic Error: $e');
        });
      }
    }
  }

  void _navigateToCreateAccount() {
    // Assuming 'CreateAcct' is the route name for your create account page
    // If you are not using named routes, you can use:
    // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAcct()));
    // For this example, let's assume you might want to replace the current page
    // or simply push it. I'll use push for now so the user can go back.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateAcct()), // Make sure CreateAcct is imported
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.network(
          'logo/Xenodate-logo.png', // Make sure this path is correct or use an AssetImage
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return Text('Xenodate'); // Fallback text
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Sign in to continue.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              Text('Email', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              SizedBox(height: 20),

              Text('Password', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: _validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: _isLoading
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : Text('Sign In'),
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _navigateToCreateAccount,
                child: Text('Don\'t have an account? Create One'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// You will also need to import your CreateAcct page if you want the navigation to work
// At the top of this file, add:
// import 'package:xenodate/createacct.dart'; // Or the correct path to your CreateAcct file
