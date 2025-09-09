import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

class DocumentUploadPage extends StatefulWidget {
  @override
  _DocumentUploadPageState createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    setState(() => _uploading = true);
    // Let user pick a text/pdf file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'pdf', 'doc'],
    );

    if (result != null && result.files.single.bytes != null) {      final bytes = result.files.single.bytes!;
      String content;
      if (result.files.single.extension == 'pdf') {
        // For simplicity: assume text extraction done client- or server-side
        content = base64Encode(bytes);
      } else {
        content = utf8.decode(bytes);
      }

      // Call cloud function to generate embedding
      final HttpsCallable embedCallable =
      _functions.httpsCallable('generateEmbedding');
      final embedResponse = await embedCallable.call(<String, dynamic>{
        'text': content,
      });
      List embedding = embedResponse.data['embedding'];

      // Generate document ID
      String docId = Uuid().v4();

      // Upload to Firestore
      await _firestore.collection('xenoworldbook').doc(docId).set({
        'id': docId,
        'content': content,
        'embedding': embedding,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Document for RAG')),
      body: Center(
        child: _uploading
            ? CircularProgressIndicator()
            : ElevatedButton(
          onPressed: _pickAndUpload,
          child: Text('Select & Upload Document'),
        ),
      ),
    );
  }
}
