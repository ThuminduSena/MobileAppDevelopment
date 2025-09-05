class Chat {
  final String id;
  final String name;

  Chat({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(id: map['id'], name: map['name']);
  }
}

class Message {
  final String text;
  final DateTime timestamp;
  final String senderId;

  Message({required this.text, required this.timestamp, required this.senderId});

  Map<String, dynamic> toMap() {
    return {'text': text, 'timestamp': timestamp.toIso8601String(), 'senderId': senderId};
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'],
      timestamp: DateTime.parse(map['timestamp']),
      senderId: map['senderId'],
    );
  }
}
