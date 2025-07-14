// lib/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // Import for rootBundle
import 'dart:convert'; // Import for json.decode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xenodate/models/character.dart';
import 'package:xenodate/models/xenoProfile.dart';
import 'package:xenodate/models/chatmessage.dart';
import 'package:xenodate/models/match.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String userCharacterId;
  final String aiPersonaId;

  const ChatScreen({
    Key? key,
    required this.matchId,
    required this.userCharacterId,
    required this.aiPersonaId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _messagesRef;

  Character? _userCharacter;
  Xenoprofile? _aiPersona;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _messagesRef = _firestore.collection('chats').doc(widget.matchId).collection('messages');
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Fetch User Character (still from Firestore)
      DocumentSnapshot userCharDoc = await _firestore.collection('characters').doc(widget.userCharacterId).get();
      if (userCharDoc.exists) {
        _userCharacter = Character.fromFirestore(userCharDoc.data() as DocumentSnapshot<Map<String, dynamic>>, userCharDoc.id);
      } else {
        throw Exception("User character not found");
      }

      // Fetch AI Persona (Xenoprofile) from local JSON asset
      final String response = await rootBundle.loadString('assets/data/xenoprofiles.json'); // Adjust path as needed
      final List<dynamic> data = json.decode(response) as List<dynamic>;
      final aiPersonaData = data.firstWhere(
            (item) => item['uid'] == widget.aiPersonaId, // Assuming 'uid' is the ID field in your JSON
        orElse: () => null,
      );

      if (aiPersonaData != null) {
        // Assuming your Xenoprofile model has a fromJson that takes the data map and document ID.
        // If your JSON doesn't naturally have an 'id' field that matches widget.aiPersonaId for the fromJson second parameter,
        // you might need to adjust Xenoprofile.fromJson or pass widget.aiPersonaId directly.
        // For simplicity, if fromJson expects an ID and your JSON objects have a 'uid' field that serves as the ID:
        _aiPersona = Xenoprofile.fromJson(aiPersonaData as Map<String, dynamic>);
      } else {
        throw Exception("AI persona with ID ${widget.aiPersonaId} not found in local JSON");
      }

    } catch (e) {
      print("Error loading chat data: $e");
      setState(() {
        _errorMessage = "Failed to load chat data: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _userCharacter == null || _aiPersona == null) return;

    final userMessage = ChatMessage(
      id: _messagesRef.doc().id,
      text: text,
      sender: MessageSender.userCharacter,
      timestamp: DateTime.now(),
      characterId: _userCharacter!.id,
      xenoProfileId: _aiPersona!.uid, // Ensure Xenoprofile has a 'uid' or similar ID field
    );

    await _messagesRef.add(userMessage.toJson());
    _textController.clear();
    _getAIResponse(text);
  }

  void _getAIResponse(String userText) async {
    if (_userCharacter == null || _aiPersona == null) return;

    await Future.delayed(const Duration(seconds: 1));
    final aiResponseText = "This is a response from ${_aiPersona!.name}. You said: $userText";

    final aiMessage = ChatMessage(
      id: _messagesRef.doc().id,
      text: aiResponseText,
      sender: MessageSender.aiPersona,
      timestamp: DateTime.now(),
      characterId: _userCharacter!.id,
      xenoProfileId: _aiPersona!.uid,
    );

    await _messagesRef.add(aiMessage.toJson());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Chat...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (_aiPersona == null || _userCharacter == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Chat')),
          body: const Center(child: Text('Could not load participant details.'))
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${_aiPersona!.name}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesRef.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs.map((doc) {
                  return ChatMessage.fromJson(doc.data() as Map<String, dynamic>);
                }).toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUserMessage = message.sender == MessageSender.userCharacter;
                    return ListTile(
                      title: Align(
                        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isUserMessage ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(message.text),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
