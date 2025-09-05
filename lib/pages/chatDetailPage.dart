import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'model.dart';
import 'package:intl/intl.dart';

class ChatDetailPage extends StatefulWidget {
  final Chat chat;
  const ChatDetailPage({required this.chat, super.key});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msg = Message(
      text: text,
      senderId: _auth.currentUser!.uid,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('chats')
        .doc(widget.chat.id)
        .collection('messages')
        .add(msg.toMap());

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser!.uid;
    String chatName = "Chat";

    // Pick other participant's name
    if (widget.chat.name != null) {
      widget.chat.name!.forEach((uid, name) {
        if (uid != currentUserId) {
          chatName = name;
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 👈 Dark background
      appBar: AppBar(
        title: Text(
          chatName,
          style: const TextStyle(
            color: Colors.white, // White title
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E), // Dark appbar
        elevation: 1,
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 This makes the back button white
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chat.id)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs
                    .map(
                      (doc) =>
                          Message.fromMap(doc.data() as Map<String, dynamic>),
                    )
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;
                    final time = DateFormat('hh:mm a').format(msg.timestamp);

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.grey[850],
                              content: Text("Copied: ${msg.text}"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF2575FC) // My message blue
                                : const Color(
                                    0xFF2C2C2C,
                                  ), // Friend msg dark gray
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : Colors.grey[200], // Softer for dark bg
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: const Color(0xFF1E1E1E), // Dark input area
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(
                        color: Colors.white, // Typed text white
                        fontSize: 16,
                      ),
                      cursorColor: Colors.white, // 👈 White cursor
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: const TextStyle(
                          color: Colors.white54, // Softer white hint
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C), // Dark gray bubble
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2575FC),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
