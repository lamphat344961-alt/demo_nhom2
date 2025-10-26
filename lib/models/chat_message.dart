enum MessageType { user, ai, system, error }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime time;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.type,
    required this.time,
    this.isTyping = false,
  });

  bool get isUser => type == MessageType.user;
  bool get isAI => type == MessageType.ai;
  bool get isError => type == MessageType.error;

  ChatMessage copyWith({
    String? text,
    MessageType? type,
    DateTime? time,
    bool? isTyping,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      type: type ?? this.type,
      time: time ?? this.time,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
