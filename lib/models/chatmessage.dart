enum MessageSender { userCharacter, aiPersona }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final String characterId;
  final String xenoProfileId;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.characterId,
    required this.xenoProfileId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: MessageSender.values.firstWhere(
            (e) => e.toString().split('.').last == json['sender'],
        orElse: () => MessageSender.userCharacter, // Default fallback
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      characterId: json['characterId'] as String,
      xenoProfileId: json['xenoProfileId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'characterId': characterId,
      'xenoProfileId': xenoProfileId,
    };
  }
}