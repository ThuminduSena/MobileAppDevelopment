import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatDetailPage.dart';
import 'model.dart';
import 'qrCodePage.dart';
import 'qrPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat with a name
  void _createNewChat() async {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Chat"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your friend's UID"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final friendId = controller.text.trim();
              final currentUserId = _auth.currentUser!.uid;

              if (friendId.isEmpty || friendId == currentUserId) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid UID")));
                return;
              }

              // Fetch current user's name
              final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
              final friendDoc = await _firestore.collection('users').doc(friendId).get();

              if (!friendDoc.exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Friend not found")));
                return;
              }

              final chatId = _firestore.collection('chats').doc().id;
              final now = DateTime.now();

              // Store names map
              final namesMap = {
                currentUserId: currentUserDoc.data()?['name'] ?? 'Me',
                friendId: friendDoc.data()?['name'] ?? 'Friend',
              };

              await _firestore.collection('chats').doc(chatId).set({
                'id': chatId,
                'participants': [currentUserId, friendId],
                'names': namesMap,
                'createdBy': currentUserId,
                'createdAt': now,
                'lastMessageAt': now,
              });

              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  String _getChatName(Chat chat) {
    final currentUserId = _auth.currentUser!.uid;
    String chatName = "Chat";

    if (chat.name != null) {
      chat.name!.forEach((uid, name) {
        if (uid != currentUserId) {
          chatName = name;
        }
      });
    }
    return chatName;
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
          final chats = chatDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Chat.fromMap(data);
          }).toList();

          chats.sort((a, b) {
            final aTime = a.toMap()['createdAt'] as DateTime? ?? DateTime(1970);
            final bTime = b.toMap()['createdAt'] as DateTime? ?? DateTime(1970);
            return bTime.compareTo(aTime); // descending
          });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatName = _getChatName(chat);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(chatName.isNotEmpty ? chatName[0] : "?",
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(chatName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(chat.id)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, msgSnapshot) {
                    if (!msgSnapshot.hasData || msgSnapshot.data!.docs.isEmpty) {
                      return const Text("No messages yet");
                    }
                    final lastMsgData =
                        msgSnapshot.data!.docs.first.data() as Map<String, dynamic>;
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _createNewChat, // New chat button
            backgroundColor: const Color(0xFF2575FC),
            child: const Icon(Icons.chat),
            heroTag: "chatFab",
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScanPage()),
              );
            },
            backgroundColor: const Color(0xFF2575FC),
            child: const Icon(Icons.qr_code_scanner),
            heroTag: "scanQrFab",
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyQRPage()),
              );
            },
            backgroundColor: const Color(0xFF2575FC),
            child: const Icon(Icons.qr_code),
            heroTag: "myQrFab",
          ),
        ],
      ),
    );
  }
}
