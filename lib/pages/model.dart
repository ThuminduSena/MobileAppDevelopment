import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final Map<String, String>? name;  // Add this field
  final String createdBy;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  Chat({
    required this.id,
    required this.participants,
    this.name,  // Add this to constructor
    required this.createdBy,
    required this.createdAt,
    required this.lastMessageAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'name': name,  // Add this to map
      'createdBy': createdBy,
      'createdAt': createdAt,
      'lastMessageAt': lastMessageAt,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      participants: List<String>.from(map['participants']),
      name: map['names'] != null ? Map<String, String>.from(map['names']) : null,  // Add this
      createdBy: map['createdBy'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastMessageAt: (map['lastMessageAt'] as Timestamp).toDate(),
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
