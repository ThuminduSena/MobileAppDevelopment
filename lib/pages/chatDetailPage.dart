import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'model.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
        backgroundColor: const Color(0xFF2575FC),
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs
                    .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _auth.currentUser!.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: const Color(0xFF2575FC),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
