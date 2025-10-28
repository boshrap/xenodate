import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:xenodate/services/charserv.dart';
import 'package:xenodate/services/xenoprofserv.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  String? _characterName;
  String? _xenoprofileDisplayName;
  bool _isLoadingNames = true;
  late XenoprofileService _xenoprofileService;
  late CharacterService _characterService;

  String? _conversationId; // This will now be loaded/saved
  bool _isLoadingConversationId = true; // New loading state

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _isLoadingNames = false;
        _isLoadingConversationId = false; // Set this too
      });
      return;
    }

    print("Chat ID: ${widget.chatId}");
    print("Character ID: ${widget.characterId}");
    print("Xenoprofile ID: ${widget.xenoprofileId}");

    // Load or create the conversation ID before loading messages
    _loadOrCreateConversationId().then((_) {
      _loadMessagesFromFirestore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _xenoprofileService = Provider.of<XenoprofileService>(context, listen: false);
    _characterService = Provider.of<CharacterService>(context, listen: false);
    _fetchNames();
  }

  // --- NEW FUNCTION: Load or Create Conversation ID ---
  Future<void> _loadOrCreateConversationId() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingConversationId = false;
        });
      }
      return;
    }

    try {
      // Reference to the chat document itself to store its associated conversation ID
      final chatDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(widget.chatId);

      final chatDoc = await chatDocRef.get();

      if (chatDoc.exists && chatDoc.data() != null && chatDoc.data()!['conversationId'] != null) {
        _conversationId = chatDoc.data()!['conversationId'] as String;
        print("Loaded existing Conversation ID: $_conversationId");
      } else {
        // Generate a new ID if it doesn't exist, and save it to the chat document
        _conversationId = const Uuid().v4();
        await chatDocRef.set(
          {'conversationId': _conversationId},
          SetOptions(merge: true), // Merge to avoid overwriting other chat document data
        );
        print("Generated and saved new Conversation ID: $_conversationId");
      }
    } catch (e) {
      print("Error loading/creating conversation ID: $e");
      // Fallback: Generate a temporary ID, but this won't persist
      _conversationId = const Uuid().v4();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConversationId = false;
        });
      }
    }
  }
  // --- END NEW FUNCTION ---

  Future<void> _fetchNames() async {
    setState(() {
      _isLoadingNames = true;
    });
    try {
      final selectedCharacter = await _characterService.getSelectedCharacter(widget.characterId);
      if (selectedCharacter != null) {
        _characterName = selectedCharacter.name;
      } else {
        _characterName = "User";
      }

      final xenoprofile = await _xenoprofileService.getXenoprofileById(widget.xenoprofileId);
      if (xenoprofile != null) {
        _xenoprofileDisplayName = "${xenoprofile.name} ${xenoprofile.surname}";
      } else {
        _xenoprofileDisplayName = "Bot";
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
    if (user == null || _conversationId == null) return; // Wait for conversationId

    // You might want to filter these messages by conversationId if a chat document
    // could contain messages from multiple "logical" conversations over time,
    // though typically the chatId itself implies a unique conversation.
    _getChatMessagesCollection(user.uid)
        .where('conversationId', isEqualTo: _conversationId) // Add this filter
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
      senderDisplayName = _characterName ?? "User";
      senderIdValue = widget.characterId;
      receiverIdValue = widget.xenoprofileId;
    } else {
      senderDisplayName = _xenoprofileDisplayName ?? "Bot";
      senderIdValue = widget.xenoprofileId;
      receiverIdValue = widget.characterId;
    }

    await _getChatMessagesCollection(chatDocumentOwnerUserId).add({
      'text': text,
      'isUser': isUserMessage,
      'senderName': senderDisplayName,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': senderIdValue,
      'receiverId': receiverIdValue,
      'conversationId': _conversationId, // Still save for local display context
    });
  }


  Future<void> _sendMessageToFlow(String text) async {
    final currentUserAuth = _auth.currentUser;
    // Ensure _conversationId is loaded before sending
    if (currentUserAuth == null || text.trim().isEmpty || _conversationId == null) return;

    final userDisplayName = _characterName ?? "You";

    final localUserMessage = {
      'text': text,
      'isUser': true,
      'timestamp': Timestamp.now(),
      'senderName': userDisplayName,
      'senderId': widget.characterId,
      'receiverId': widget.xenoprofileId,
      'conversationId': _conversationId,
    };
    if (mounted) {
      setState(() {
        _messages.add(localUserMessage);
      });
    }

    await _saveMessageToFirestore(currentUserAuth.uid, text, true);

    try {
      FirebaseFunctions functions = FirebaseFunctions.instance;
      final HttpsCallable callable = functions.httpsCallable('chatbot');

      final response = await callable.call(<String, dynamic>{
        'xenoprofileId': widget.xenoprofileId,
        'userMessage': text,
        'conversationId': _conversationId,
      });

      final responseData = response.data as Map<String, dynamic>?;

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
            'conversationId': _conversationId,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAuth = _auth.currentUser;

    String appBarTitle;
    if (_isLoadingNames || _isLoadingConversationId) { // Check new loading state
      appBarTitle = 'Loading...';
    } else {
      appBarTitle = _xenoprofileDisplayName ?? "Bot";
    }

    if (currentUserAuth == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle, style: GoogleFonts.poppins())),
        body: const Center(child: Text('Please sign in to chat.')),
      );
    }

    // Show a loading indicator until conversationId is ready
    if (_isLoadingConversationId) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading Chat...', style: GoogleFonts.poppins())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $appBarTitle', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bool isUserMsg = message['senderId'] == widget.characterId;

                return _buildMessageBubble(
                  isUserMsg,
                  message['text'] as String,
                  (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  message['senderName'] as String,
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
            if (!isUserMessage)
              Text(
                senderDisplayName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
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
    final hintName = _xenoprofileDisplayName ?? "Bot";
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                  hintText: 'Message $hintName...',
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
