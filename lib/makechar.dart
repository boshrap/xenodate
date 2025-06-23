import 'package:flutter/material.dart';
import 'package:xenodate/photoupload.dart';


class NewChar extends StatefulWidget {
  const NewChar({Key? key}) : super(key: key);

  @override
  State<NewChar> createState() => _NewCharState();
}

class _NewCharState extends State<NewChar> {
  int sliderValue = 18;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Text("Name")),
            const TextField(),
            const Divider(),
            const Center(child: Text("Species")),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text("Button 1")),
                ElevatedButton(onPressed: () {}, child: const Text("Button 2")),
                ElevatedButton(onPressed: () {}, child: const Text("Button 3")),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Age: $sliderValue"),
              ],
            ),
            Slider(
              value: sliderValue.toDouble(),
              min: 18,
              max: 110,
              divisions: 92,
              label: sliderValue.toString(),
              onChanged: (value) {
                setState(() {
                  sliderValue = value.toInt();
                });
              },
            ),
            const Center(child: Text("Gender")),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text("Male")),
                ElevatedButton(onPressed: () {}, child: const Text("Female")),
                ElevatedButton(onPressed: () {}, child: const Text("Other")),
              ],
            ),
            const Divider(),
            const Center(child: Text("Looking For")),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text("Friendship")),
                ElevatedButton(onPressed: () {}, child: const Text("Dating")),
                ElevatedButton(onPressed: () {}, child: const Text("Networking")),
              ],
            ),
            const Divider(),
            const Center(child: Text("Topics")),
            const TextField(),
            const Center(child: Text("Turnoffs")),
            const TextField(),
            const Center(child: Text("Biography")),
            const TextField(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () {
                  Navigator.pop(context);
                }, child: const Text("Cancel")),
                ElevatedButton(onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PhotoUpload()),
                  );
                }, child: const Text("Save & Continue")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
