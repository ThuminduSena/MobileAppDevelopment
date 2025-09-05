import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatDetailPage.dart';
import 'model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _createNewChat() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Chat"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter name"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final chatId = _firestore.collection('chats').doc().id;
                await _firestore.collection('chats').doc(chatId).set({
                  'id': chatId,
                  'name': controller.text,
                  'participants': [
                    _auth.currentUser!.uid,
                  ], // Only current user initially
                  'createdBy': _auth.currentUser!.uid,
                  'createdAt': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat App"),
        backgroundColor: const Color(0xFF2575FC),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: _auth.currentUser!.uid)
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final chatDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = Chat.fromMap(
                chatDocs[index].data() as Map<String, dynamic>,
              );
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    chat.name[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  chat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(chat: chat),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        backgroundColor: const Color(0xFF2575FC),
        child: const Icon(Icons.chat),
      ),
    );
  }
}
