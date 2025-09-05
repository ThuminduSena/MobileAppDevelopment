import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatDetailPage.dart';
import 'model.dart';
import 'qrCodePage.dart';

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
          decoration: const InputDecoration(hintText: "Enter chat name"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final chatId = _firestore.collection('chats').doc().id;
                final now = DateTime.now();

                await _firestore.collection('chats').doc(chatId).set({
                  'id': chatId,
                  'name': controller.text,
                  'participants': [_auth.currentUser!.uid],
                  'createdBy': _auth.currentUser!.uid,
                  'createdAt': now,
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
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          final chatDocs = snapshot.data!.docs;

          // Convert documents to Chat objects
          final chats = chatDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Chat.fromMap(data);
          }).toList();

          // Sort locally by createdAt
          chats.sort((a, b) {
            final aTime = a.toMap()['createdAt'] as DateTime? ?? DateTime(1970);
            final bTime = b.toMap()['createdAt'] as DateTime? ?? DateTime(1970);
            return bTime.compareTo(aTime); // descending
          });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

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
                subtitle: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(chat.id)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, msgSnapshot) {
                    if (!msgSnapshot.hasData ||
                        msgSnapshot.data!.docs.isEmpty) {
                      return const Text("No messages yet");
                    }
                    final lastMsgData =
                        msgSnapshot.data!.docs.first.data()
                            as Map<String, dynamic>;
                    return Text(
                      lastMsgData['text'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _createNewChat,
      //   backgroundColor: const Color(0xFF2575FC),
      //   child: const Icon(Icons.chat),
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRScanPage()),
          );
        },
        backgroundColor: const Color(0xFF2575FC),
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
