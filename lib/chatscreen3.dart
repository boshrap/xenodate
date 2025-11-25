import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xenodate/services/charserv.dart';
import 'package:xenodate/services/xenoprofserv.dart';


class AIChatScreen extends StatefulWidget {
  final String chatId;
  final String characterId;
  final String xenoprofileId;

  const AIChatScreen({
    super.key,
    required this.chatId,
    required this.characterId,
    required this.xenoprofileId,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();

  List<Map<String, dynamic>> _messages = [];

  String? _characterName;
  String? _xenoprofileDisplayName;
  bool _isLoadingNames = true;
  late XenoprofileService _xenoprofileService;
  late CharacterService _characterService;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      _loadMessagesFromFirestore();
    } else {
      _isLoadingNames = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _xenoprofileService =
        Provider.of<XenoprofileService>(context, listen: false);
    _characterService = Provider.of<CharacterService>(context, listen: false);
    _fetchNames();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchNames() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNames = true;
    });
    try {
      final selectedCharacter =
          await _characterService.getSelectedCharacter(widget.characterId);
      _characterName = selectedCharacter?.name ?? "User";

      final xenoprofile =
          await _xenoprofileService.getXenoprofileById(widget.xenoprofileId);
      _xenoprofileDisplayName =
          xenoprofile != null ? "${xenoprofile.name} ${xenoprofile.surname}" : "Bot";
    } catch (e) {
      print("Error fetching names: $e");
      _characterName = "User (Error)";
      _xenoprofileDisplayName = "Bot (Error)";
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNames = false;
        });
      }
    }
  }

  CollectionReference _getChatMessagesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');
  }

  void _loadMessagesFromFirestore() {
    final user = _auth.currentUser;
    if (user == null) return;

    _getChatMessagesCollection(user.uid)
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _messages =
            snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    });
  }

  Future<void> _sendMessageToFlow(String text) async {
    final currentUserAuth = _auth.currentUser;
    if (currentUserAuth == null || text.trim().isEmpty) return;

    final userDisplayName = _characterName ?? "You";

    // Removed direct addition of user message to _messages
    // await _saveMessageToFirestore(currentUserAuth.uid, text, "user");


    try {
      final response = await FirebaseFunctions.instance
          .httpsCallable('chatbot')
          .call(<String, dynamic>{
        'xenoprofileId': widget.xenoprofileId,
        'userMessage': text,
        'userId': currentUserAuth.uid,
        'chatId': widget.chatId,
        'characterId': widget.characterId,
        'characterName': _characterName,
      });

      final responseData = response.data as Map<String, dynamic>?;

      if (responseData != null) {
        final aiReply = responseData['reply'] as String?;

        if (aiReply != null && aiReply.isNotEmpty) {
        } else {
          print("Flow returned an empty or null reply.");
          _showErrorDialog("The bot didn't have anything to say.");
        }
      } else {
        print('Genkit flow returned null data.');
        _showErrorDialog("Failed to get a valid response from the bot.");
      }
    } on FirebaseFunctionsException catch (e) {
      print(
          'FirebaseFunctionsException when calling Genkit flow: ${e.code} - ${e.message}');
      _showErrorDialog("Error calling bot: ${e.message}");
    } catch (e) {
      print('Exception when calling Genkit flow: $e');
      _showErrorDialog("An error occurred while contacting the bot: $e");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle =
        _isLoadingNames ? 'Loading...' : (_xenoprofileDisplayName ?? "Bot");

    if (_auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle, style: GoogleFonts.poppins())));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $appBarTitle', style: GoogleFonts.poppins()),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final bool isUserMsg =
                        message['role'] == "user";

                    return _buildMessageBubble(
                      isUserMsg,
                      message['text'] as String? ?? '...',
                      (message['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      message['senderName'] as String,
                    );
                  },
                ),
              ),
              _buildMessageInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isUserMessage, String messageText,
      DateTime timestamp, String senderDisplayName) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMessage
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text( // Always display sender name
                senderDisplayName,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, 
                    color: isUserMessage ? Colors.white70 : Colors.blue.shade800),
              ),
            Text(messageText,
                style: GoogleFonts.poppins(
                    color: isUserMessage ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour}:${timestamp.minute}',
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isUserMessage ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputArea() {
    final hintName = _xenoprofileDisplayName ?? "Bot";

    void handleSend() {
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        _sendMessageToFlow(text);
        _textController.clear();
      }
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration( // Added decoration for shading
        color: Colors.grey.shade100, 
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Message $hintName...',
                hintStyle: GoogleFonts.poppins(),
                border: InputBorder.none, // Remove default TextField border
              ),
              style: GoogleFonts.poppins(),
              onSubmitted: (_) => handleSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: handleSend,
          ),
        ],
      ),
    );
  }
}