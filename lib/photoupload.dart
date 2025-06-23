import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xenodate/mainview.dart';
import 'dart:io';

class PhotoUpload extends StatefulWidget {
  const PhotoUpload({super.key});

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image thumbnail
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 50),
            ),
            const SizedBox(height: 20),

            // Upload Photo Button
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Upload Photo'),
            ),
            const SizedBox(height: 20),

            // Row with right-aligned button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MainView()),
                    );
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row with 2 evenly spaced buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MainView()),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}