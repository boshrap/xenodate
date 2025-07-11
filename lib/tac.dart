import 'package:flutter/material.dart';
import 'package:xenodate/main.dart'; // Assuming this is your main app entry point
import 'package:xenodate/createacct.dart';

class Terms extends StatefulWidget {
  @override
  _TermsState createState() => _TermsState();
}

class _TermsState extends State<Terms> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(), // Prevent selecting future dates
    );
    if (picked != null && picked != selectedDate) {
      // Age check
      DateTime today = DateTime.now();
      int age = today.year - picked.year;
      if (picked.month > today.month ||
          (picked.month == today.month && picked.day > today.day)) {
        age--;
      }

      if (age < 18) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Age Restriction'),
              content: Text('This app is for adults (18+) only.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          selectedDate = picked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate initial age for button enable/disable
    DateTime today = DateTime.now();
    int currentAge = today.year - selectedDate.year;
    if (selectedDate.month > today.month ||
        (selectedDate.month == today.month && selectedDate.day > today.day)) {
      currentAge--;
    }
    bool isAgeValid = currentAge >= 18;

    String termsAndConditionsText = """
1. Eligibility
You must be 18 years of age or older to use our services.

2. User Data
Data Retention: We may retain your messages and other user data to improve our service, prevent abuse, and comply with legal obligations.
Data Access and Deletion: You may request access to or deletion of your personal data. Please contact us at [email protected] with your request.
Data Security: We implement reasonable security measures to protect your data, but we cannot guarantee complete security.

3. User Conduct
You agree to use our service responsibly and respectfully.
You agree not to use our service for illegal or harmful purposes, including harassment, bullying, or hate speech.
You agree not to share personal information, such as phone numbers or addresses, with other users.

4. Modification of Service
We reserve the right to modify or discontinue our service at any time.

5. Limitation of Liability
We are not responsible for any damages or losses that may result from your use of our service.

6. Governing Law
These terms of service shall be governed by and construed in accordance with the laws of your location
""";

    return Scaffold(
      appBar: AppBar(
        title: Image.network( // Consider using Image.asset if the logo is local
          'logo/Xenodate-logo.png',
          height: 40,
          errorBuilder: (context, error, stackTrace) { // Handle potential network image loading errors
            return Text('Xenodate'); // Fallback text
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date of Birth'),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('Select Date'),
            ),
            Text("${selectedDate.toLocal()}".split(' ')[0]),
            Divider(),
            Text('Terms and Conditions', style: Theme.of(context).textTheme.titleLarge), // Added style for better visibility
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  termsAndConditionsText, // Use the variable here
                  style: TextStyle(color: Colors.grey[700]), // Slightly darker grey for better readability
                ),
              ),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Decline'),
                ),
                ElevatedButton(
                  onPressed: isAgeValid // Disable button if age is not valid
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateAcct()),
                    );
                  }
                      : null, // Setting onPressed to null disables the button
                  child: Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
