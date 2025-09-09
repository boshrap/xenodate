import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Add this import
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider

// Assuming these are your service files - adjust paths as needed
import 'package:xenodate/services/charserv.dart';
import 'package:xenodate/services/xenoprofserv.dart';
import 'dart:async';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:http/http.dart' as http; // HTTP package

class AIChatScreen extends StatefulWidget {
  final String chatId;
  final String characterId;
  final String xenoprofileId;

  const AIChatScreen({
    Key? key,
    required this.chatId,
    required this.characterId,
    required this.xenoprofileId,
  }) : super(key: key);

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _messages = [];

  // State variables for fetched names
  String? _characterName; // USER's Name
  String? _xenoprofileDisplayName; // BOT's Name
  bool _isLoadingNames = true;
  late XenoprofileService _xenoprofileService;
  late CharacterService _characterService;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      // Handle user not logged in
      setState(() {
        _isLoadingNames = false;
      });
      return;
    }

    print("Chat ID: ${widget.chatId}");
    print("Character ID: ${widget.characterId}");
    print("Xenoprofile ID: ${widget.xenoprofileId}");

    _loadMessagesFromFirestore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _xenoprofileService = Provider.of<XenoprofileService>(context, listen: false);
    _characterService = Provider.of<CharacterService>(context, listen: false);
    _fetchNames();
  }

  Future<void> _fetchNames() async {
    setState(() {
      _isLoadingNames = true;
    });
    try {
      // Fetch USER's name using characterId
      // Assuming _characterService.getCharacterName exists and takes characterId
      // This might be fetching the user's profile name based on widget.characterId
      final _characterName = await _characterService.getSelectedCharacter(widget.characterId);
      if (_characterName != null) {
        _xenoprofileDisplayName = "User"; // Fallback for Bot's name
      }

      // Fetch BOT's name using xenoprofileId
      final xenoprofile = await _xenoprofileService.getXenoprofileById(widget.xenoprofileId);
      if (xenoprofile != null) {
        _xenoprofileDisplayName = "${xenoprofile.name} ${xenoprofile.surname}";
      } else {
        _xenoprofileDisplayName = "Bot"; // Fallback for Bot's name
      }

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

  void _loadMessagesFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _getChatMessagesCollection(user.uid)
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _messages = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    });
  }

  Future<void> _saveMessageToFirestore(
      String chatDocumentOwnerUserId, String text, bool isUserMessage) async {
    String senderDisplayName;
    String senderIdValue;
    String receiverIdValue;

    if (isUserMessage) {
      // Current user is sending the message
      senderDisplayName = _characterName ?? "User"; // USER's name
      senderIdValue = widget.characterId;           // USER's ID
      receiverIdValue = widget.xenoprofileId;       // BOT's ID
    } else {
      // Bot is sending the message
      senderDisplayName = _xenoprofileDisplayName ?? "Bot"; // BOT's name
      senderIdValue = widget.xenoprofileId;                 // BOT's ID
      receiverIdValue = widget.characterId;                 // USER's ID (the recipient)
    }

    await _getChatMessagesCollection(chatDocumentOwnerUserId).add({
      'text': text,
      'isUser': isUserMessage,
      'senderName': senderDisplayName,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': senderIdValue,
      'receiverId': receiverIdValue,
    });
  }


  Future<void> _sendMessageToFlow(String text) async {
    final currentUserAuth = _auth.currentUser;
    if (currentUserAuth == null || text.trim().isEmpty) return;

    final userDisplayName = _characterName ?? "You";

    final localUserMessage = {
      'text': text,
      'isUser': true,
      'timestamp': Timestamp.now(),
      'senderName': userDisplayName,
      'senderId': widget.characterId,
      'receiverId': widget.xenoprofileId,
    };
    if (mounted) {
      setState(() {
        _messages.add(localUserMessage);
      });
    }

    await _saveMessageToFirestore(currentUserAuth.uid, text, true);

    // Prepare recent messages for history
    const int historyLength = 5; // Or configurable
    final List<Map<String, String>> messageHistoryForFlow = _messages
        .take(historyLength) // Take last N messages
        .map((msg) => {
      'role': (msg['isUser'] as bool? ?? false) ? 'user' : 'model',
      'text': msg['text'] as String? ?? '',
    })
        .toList();

    // --- CALL GENKIT FLOW ---
    try {
      // Get an instance of Firebase Functions
      FirebaseFunctions functions = FirebaseFunctions.instance;
      // If your function is in a specific region, specify it:
      // FirebaseFunctions functions = FirebaseFunctions.instanceFor(region: 'your-region');

      // Prepare the data to send to the function
      final HttpsCallable callable = functions.httpsCallable('chatbot'); // 'chatbot' is the name of your deployed Genkit flow

      final response = await callable.call(<String, dynamic>{
        'xenoprofileId': widget.xenoprofileId,
        'userMessage': text,
        'history': messageHistoryForFlow, // Add history to the call
      });

      final responseData = response.data as Map<String, dynamic>?; // The 'data' field contains the function's response

      if (responseData != null) {
        final aiReply = responseData['reply'] as String?;

        if (aiReply != null && aiReply.isNotEmpty) {
          final aiSenderName = _xenoprofileDisplayName ?? "Bot";

          final localAiMessage = {
            'text': aiReply,
            'isUser': false,
            'timestamp': Timestamp.now(),
            'senderName': aiSenderName,
            'senderId': widget.xenoprofileId,
            'receiverId': widget.characterId,
          };
          if (mounted) {
            setState(() {
              _messages.add(localAiMessage);
            });
          }
          await _saveMessageToFirestore(currentUserAuth.uid, aiReply, false);
        } else {
          print("Flow returned an empty or null reply.");
          _showErrorDialog("The bot didn't have anything to say.");
        }
      } else {
        print('Genkit flow returned null data.');
        _showErrorDialog("Failed to get a valid response from the bot.");
      }
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException when calling Genkit flow: ${e.code} - ${e.message}');
      _showErrorDialog("Error calling bot: ${e.message}");
    } catch (e) {
      print('Exception when calling Genkit flow: $e');
      _showErrorDialog("An error occurred while contacting the bot: $e");
    }
  }

  // Helper to show an error dialog (optional)
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }


  @override
  void dispose() {
    // any listeners or controllers should be disposed here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAuth = _auth.currentUser; // Logged-in user

    // AppBar title should be the BOT's name
    String appBarTitle;
    if (_isLoadingNames) {
      appBarTitle = 'Loading...';
    } else {
      appBarTitle = _xenoprofileDisplayName ?? "Bot"; // BOT's name
    }

    if (currentUserAuth == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle, style: GoogleFonts.poppins())),
        body: const Center(child: Text('Please sign in to chat.')),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $appBarTitle', style: GoogleFonts.poppins()), // Chat with BOT
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bool isUserMsg = message['senderId'] == widget.characterId;
                // Alternatively, use message['isUser'] if it's reliably set based on senderId logic during save/load

                return _buildMessageBubble(
                  isUserMsg, // True if the sender is the USER (characterId)
                  message['text'] as String,
                  (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  message['senderName'] as String, // This will be _characterName for user, _xenoprofileDisplayName for bot
                );
              },
            ),
          ),
          _buildMessageInputArea((text) {
            print("Send: $text to Bot: ${_xenoprofileDisplayName ?? widget.xenoprofileId} (as Character: ${_characterName ?? widget.characterId})");
            _sendMessageToFlow(text);
          }),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isUserMessage, String messageText, DateTime timestamp, String senderDisplayName) {
    // isUserMessage is true if it's from the current user (characterId)
    // senderDisplayName will be the name of who sent it (_characterName for user, _xenoprofileDisplayName for bot)
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMessage ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Show sender's name only for the OTHER party (the Bot)
            if (!isUserMessage)
              Text(
                senderDisplayName, // This will be the BOT's name (_xenoprofileDisplayName)
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
            // If it IS a user message, and you want to show the user's name (e.g. in a group chat)
            // you could add:
            // if (isUserMessage) Text(senderDisplayName, style: ... ),
            // But for a 1-on-1 chat, it's often omitted for the user's own messages.

            Text(messageText, style: GoogleFonts.poppins(color: isUserMessage ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour}:${timestamp.minute}',
              style: GoogleFonts.poppins(fontSize: 10, color: isUserMessage ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputArea(void Function(String) onSend) {
    final TextEditingController controller = TextEditingController();
    // Hint text should refer to the BOT
    final hintName = _xenoprofileDisplayName ?? "Bot";
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                  hintText: 'Message $hintName...', // Message the BOT
                  hintStyle: GoogleFonts.poppins()),
              style: GoogleFonts.poppins(),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  onSend(text.trim());
                  controller.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onSend(text);
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}