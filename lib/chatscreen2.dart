import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:xenodate/matches.dart';
import 'package:xenodate/services/matchesserv.dart';
import 'package:xenodate/models/match.dart';
import 'dart:async';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final MatchService _matchService = MatchService(); // Assuming your service class is named MatchService


  String? _selectedBot; // Can be null initially
  List<String> _availableBots = []; // Will be populated from matches
  bool _isLoadingBots = true; // To show a loading indicator

  // StreamSubscription for matches to manage disposal
  StreamSubscription<List<Match>>? _matchesSubscription;

  @override
  void initState() {
    super.initState();
    _loadMatchedBots();
  }

  void _loadMatchedBots() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoadingBots = false;
        _availableBots = ['Error: Not Logged In']; // Or an empty list
        _selectedBot = null; // Ensure selectedBot is null if no valid bots
      });
      return;
    }

    _matchesSubscription?.cancel();

    _matchesSubscription = _matchService.getMatchesStream().listen(
          (matches) {
        if (!mounted) return;

        // Get unique bot names
        final botNames = matches
            .map((match) => match.xenoProfileId)
            .where((name) => name != null)
            .cast<String>()
            .toSet() // Use a Set to automatically handle duplicates
            .toList(); // Convert back to List

        setState(() {
          if (botNames.isNotEmpty) {
            _availableBots = botNames;
            // If _selectedBot is no longer in the new list OR was null,
            // set it to the first available bot.
            if (_selectedBot == null || !_availableBots.contains(_selectedBot)) {
              _selectedBot = _availableBots.first;
            }
          } else {
            _availableBots = ['No Matches Found'];
            _selectedBot = null; // No bot can be selected
          }
          _isLoadingBots = false;
        });

        if (_selectedBot != null) {
          // Potentially refresh chat or other UI
        }
      },
      onError: (error) {
        if (!mounted) return;
        print("Error loading matched bots: $error");
        setState(() {
          _availableBots = ['Error Loading Bots'];
          _selectedBot = null; // No bot can be selected
          _isLoadingBots = false;
        });
      },
    );
  }

  String get _chatId {
    // Generates a unique chat ID for the current user and selected bot
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      // This should ideally not happen if the user is on this screen
      throw Exception("User not authenticated");
    }
    // Sanitize bot name to be a valid Firestore document ID
    final sanitizedBotName = _selectedBot?.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return '${userId}_bot_$sanitizedBotName';
  }

  CollectionReference<Map<String, dynamic>> get _chatMessagesCollection {
    final user = _auth.currentUser;
    if (user == null) {
      // This should ideally not happen if the user is on this screen
      // You might want to navigate the user away or show a permanent error
      throw Exception("User not authenticated for chat collection");
    }
    // Path: users/{userId}/chats/{chatId}/messages
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(_chatId) // Use the generated chatId
        .collection('messages');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _matchesSubscription?.cancel(); // Important: Cancel the stream subscription
    super.dispose();
  }


  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_selectedBot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a character to chat with.')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to send messages.')),
      );
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    final timestamp = DateTime.now();

    // Add user message to Firestore
    await _chatMessagesCollection.add({
      // 'userId': user.uid, // Not strictly needed here as it's part of the path
      'message': message,
      'timestamp': timestamp,
      'isUser': true,
      'senderName': user.displayName ?? 'User', // Optional: store sender's name
      'botType': _selectedBot, // Keep track of which bot this conversation is with
    });

    _scrollToBottom(); // Scroll after sending user message

    // Simulate bot response
    await Future.delayed(const Duration(seconds: 1));

    await _chatMessagesCollection.add({
      // 'userId': user.uid, // Bot messages are also under the user's chat
      'message': _generateBotResponse(message),
      'timestamp': DateTime.now(), // New timestamp for bot message
      'isUser': false,
      'senderName': _selectedBot,
      'botType': _selectedBot,
    });

    _scrollToBottom(); // Scroll after receiving bot message
  }

  String _generateBotResponse(String message) {
    if (_selectedBot == null) {
      return "Please select a character first.";
    }
    // You might want to have more dynamic bot responses based on the character
    // For now, it uses the selected bot's name.
    switch (_selectedBot) {
    // You'll need to update these cases or make them more dynamic
    // if the bot names are now coming from your matches.
    // For a simple approach, you can keep a default, or look up
    // specific responses if your `Match` object contains more info.
      case 'Tech Support': // Example, this might not be a matched character name anymore
        return "Thanks for your tech question about '$message'. I'm looking into it...";
      default:
        return "I, $_selectedBot, received your message: '$message'. How can I assist you further?";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {

      return Scaffold(
        appBar: AppBar(title: Text('AI Chatbot', style: GoogleFonts.poppins())),
        body: const Center(
            child: Text('Please sign in to use the chat.',
                style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chatbot', style: GoogleFonts.poppins()),
        actions: [
          _buildBotSelectionDropdown(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildChatMessages(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildBotSelectionDropdown() {
    if (_isLoadingBots) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }

    // Check for placeholder messages or empty list
    bool hasActualBots = _availableBots.isNotEmpty &&
        !_availableBots.contains('No Matches Found') &&
        !_availableBots.contains('Error Loading Bots') &&
        !_availableBots.contains('Error: Not Logged In');

    if (!hasActualBots || _selectedBot == null) {
      // Display a message if no actual bots are available or none is selected
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          _availableBots.isNotEmpty ? _availableBots.first : "No Characters", // Shows "No Matches Found" etc.
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    // At this point, _availableBots contains actual bot names and _selectedBot is one of them.
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: DropdownButton<String>(
        value: _selectedBot, // This should now always be a valid item
        dropdownColor: Colors.grey[800],
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        elevation: 16,
        style: GoogleFonts.poppins(color: Colors.white),
        underline: Container(height: 0),
        onChanged: (String? newValue) {
          if (newValue != null && newValue != _selectedBot) {
            setState(() {
              _selectedBot = newValue;
              _messageController.clear();
            });
          }
        },
        items: _availableBots
            .where((botName) => // Filter out placeholder messages from items
        botName != 'No Matches Found' &&
            botName != 'Error Loading Bots' &&
            botName != 'Error: Not Logged In')
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: GoogleFonts.poppins(color: Colors.black87)),
          );
        }).toList(),
      ),
    );
  }



  Widget _buildChatMessages() {
    if (_auth.currentUser == null) {
      return const Center(child: Text('Please sign in to chat'));
    }
    if (_selectedBot == null) {
      return Center(
        child: Text(
          _availableBots.contains('No Matches Found')
              ? 'No characters to chat with. Go find some matches!'
              : 'Please select a character to chat with.',
          style: GoogleFonts.poppins(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      // Stream from the user-specific chat messages subcollection
      stream: _chatMessagesCollection
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Error fetching messages: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Text(
              'Start chatting with $_selectedBot!',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          );
        }
        // Ensure scroll to bottom is called when messages are loaded/updated
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageDoc = messages[index];
            final messageData = messageDoc.data() as Map<String, dynamic>; // Cast to Map
            final isUser = messageData['isUser'] as bool;
            final msgText = messageData['message'] as String;
            final timestamp = (messageData['timestamp'] as Timestamp).toDate();
            // Use senderName for bot, or fallback for user if needed
            final senderName = messageData['senderName'] as String? ?? (isUser ? 'You' : _selectedBot);


            return _buildMessageBubble(isUser, msgText, timestamp, senderName!);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(bool isUser, String message, DateTime timestamp, String senderName) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser
                ? const Radius.circular(12)
                : const Radius.circular(0),
            bottomRight: isUser
                ? const Radius.circular(0)
                : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser) // Display bot name for bot messages
              Text(
                senderName, // Use the senderName (which will be the bot's name)
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800, // Or your preferred bot name color
                ),
              ),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(timestamp),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.poppins(),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
