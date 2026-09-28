class ChatMessage {
  final String sender;
  final String text;
  final String time;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] ?? 'Unknown',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
    );
  }

  Map<String, String> toJson() {
    return {
      'sender': sender,
      'text': text,
      'time': time,
    };
  }
}
