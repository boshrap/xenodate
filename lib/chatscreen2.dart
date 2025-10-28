import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Import Firebase Functions
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
  final MatchService _matchService = MatchService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance; // Initialize Firebase Functions

  String? _selectedBot;
  List<String> _availableBots = [];
  bool _isLoadingBots = true;
  bool _isBotReplying = false; // To show a typing indicator for the bot

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
        _availableBots = ['Error: Not Logged In'];
        _selectedBot = null;
      });
      return;
    }

    _matchesSubscription?.cancel();
    _matchesSubscription = _matchService.getMatchesStream().listen(
          (matches) {
        if (!mounted) return;

        final botNames = matches
            .map((match) => match.xenoProfileId)
            .where((name) => name != null)
            .cast<String>()
            .toSet()
            .toList();

        setState(() {
          if (botNames.isNotEmpty) {
            _availableBots = botNames;
            if (_selectedBot == null || !_availableBots.contains(_selectedBot)) {
              _selectedBot = _availableBots.first;
            }
          } else {
            _availableBots = ['No Matches Found'];
            _selectedBot = null;
          }
          _isLoadingBots = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        print("Error loading matched bots: $error");
        setState(() {
          _availableBots = ['Error Loading Bots'];
          _selectedBot = null;
          _isLoadingBots = false;
        });
      },
    );
  }

  String get _chatId {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");
    final sanitizedBotName = _selectedBot?.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return '${userId}_bot_$sanitizedBotName';
  }

  CollectionReference<Map<String, dynamic>> get _chatMessagesCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated for chat collection");
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(_chatId)
        .collection('messages');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _matchesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isBotReplying) return;
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
    final currentBotId = _selectedBot!;
    _messageController.clear();
    _scrollToBottom();

    setState(() {
      _isBotReplying = true;
    });

    // 1. Add user message to Firestore
    final userMessageRef = await _chatMessagesCollection.add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(), // Use server timestamp for consistency
      'isUser': true,
      'senderName': user.displayName ?? 'User',
      'botType': currentBotId,
    });

    // 2. Prepare data for the Cloud Function
    try {
      // Fetch recent history to provide context to the chatbot
      final historySnapshot = await _chatMessagesCollection
          .orderBy('timestamp', descending: true)
          .limit(10) // Limit the history to the last 10 messages for context
          .get();

      final history = historySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'role': (data['isUser'] as bool) ? 'user' : 'model',
          'text': data['message'] as String,
        };
      }).toList().reversed.toList(); // Reverse to maintain chronological order

      // 3. Call the 'chatbot' Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('chatbot');
      final response = await callable.call<Map<String, dynamic>>({
        'xenoprofileId': currentBotId,
        'userMessage': message,
        'history': history,
      });

      final botReply = response.data['reply'] as String?;

      if (botReply == null || botReply.isEmpty) {
        throw Exception("Bot returned an empty reply.");
      }

      // 4. Add bot's response to Firestore
      await _chatMessagesCollection.add({
        'message': botReply,
        'timestamp': FieldValue.serverTimestamp(),
        'isUser': false,
        'senderName': currentBotId,
        'botType': currentBotId,
      });

    } on FirebaseFunctionsException catch (e) {
      print('Cloud function failed: ${e.code} - ${e.message}');
      // Add an error message to the chat for the user
      await _chatMessagesCollection.add({
        'message': 'Sorry, I had trouble responding. Please try again. (Error: ${e.message})',
        'timestamp': FieldValue.serverTimestamp(),
        'isUser': false,
        'senderName': currentBotId,
        'botType': currentBotId,
      });
    } catch (e) {
      print('An unexpected error occurred: $e');
      await _chatMessagesCollection.add({
        'message': 'Sorry, an unexpected error occurred. Please check your connection and try again.',
        'timestamp': FieldValue.serverTimestamp(),
        'isUser': false,
        'senderName': currentBotId,
        'botType': currentBotId,
      });
    } finally {
      setState(() {
        _isBotReplying = false;
      });
      _scrollToBottom();
    }
  }

  // _generateBotResponse method is no longer needed as the cloud function handles it.
  // String _generateBotResponse(String message) { ... } // You can remove this.

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
          if (_isBotReplying)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$_selectedBot is typing...',
                    style: GoogleFonts.poppins(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Message $_selectedBot...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            // Disable button while bot is replying
            onPressed: _isBotReplying ? null : _sendMessage,
          ),
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

    bool hasActualBots = _availableBots.isNotEmpty &&
        !_availableBots.contains('No Matches Found') &&
        !_availableBots.contains('Error Loading Bots') &&
        !_availableBots.contains('Error: Not Logged In');

    if (!hasActualBots || _selectedBot == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          _availableBots.isNotEmpty ? _availableBots.first : "No Characters",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: DropdownButton<String>(
        value: _selectedBot,
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
            .where((botName) =>
        botName != 'No Matches Found' &&
            botName != 'Error Loading Bots' &&
            botName != 'Error: Not Logged In')
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: GoogleFonts.poppins()), // Text color will be adapted by theme
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final isUserMessage = messageData['isUser'] as bool;

            return Align(
              alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isUserMessage ? Theme.of(context).primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  messageData['message'] ?? '',
                  style: TextStyle(
                    color: isUserMessage ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
