import 'package:flutter/material.dart';
import 'package:xenodate/main.dart';
import 'package:xenodate/makeacct.dart';

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
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.network(
          'logo/Xenodate-logo.png',
          height: 40,
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
            Text('Terms and Conditions'),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Your long terms and conditions text goes here...',
                  style: TextStyle(color: Colors.grey[600]),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateAcct()),
                    );
                  },
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
