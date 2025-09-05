import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String name;
  final List<String> participants;

  Chat({
    required this.id,
    required this.name,
    required this.participants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'createdAt': DateTime.now(),
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      name: map['name'],
      participants: List<String>.from(map['participants'] ?? []),
    );
  }
}

class Message {
  final String text;
  final DateTime timestamp;
  final String senderId;

  Message({
    required this.text,
    required this.timestamp,
    required this.senderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'timestamp': timestamp,
      'senderId': senderId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'],
      timestamp: map['timestamp'] is DateTime
          ? map['timestamp']
          : (map['timestamp'] as Timestamp).toDate(),
      senderId: map['senderId'],
    );
  }
}
