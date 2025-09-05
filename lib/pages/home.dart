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

  /// Create a new chat manually by entering a friend's UID
  void _createNewChat() async {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "New Chat",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter your friend's UID",
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final friendId = controller.text.trim();
              final currentUserId = _auth.currentUser!.uid;

              if (friendId.isEmpty || friendId == currentUserId) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid UID")),
                );
                return;
              }

              // Fetch user details
              final currentUserDoc =
                  await _firestore.collection('users').doc(currentUserId).get();
              final friendDoc =
                  await _firestore.collection('users').doc(friendId).get();

              if (!friendDoc.exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Friend not found")),
                );
                return;
              }

              final chatId = _firestore.collection('chats').doc().id;
              final now = DateTime.now();

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
            child: const Text(
              "Create",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the display name for chat (friend's name)
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
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        title: const Text(
          "Chit Chat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: const Color(0xFF1E1E1E),
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
            return const Center(
              child: Text(
                "No chats yet",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white54),
              ),
            );
          }

          final chats = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Chat.fromMap(data);
          }).toList();

          chats.sort((a, b) {
            final aTime =
                a.toMap()['lastMessageAt'] as Timestamp? ?? Timestamp(0, 0);
            final bTime =
                b.toMap()['lastMessageAt'] as Timestamp? ?? Timestamp(0, 0);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatName = _getChatName(chat);

              return Card(
                color: const Color(0xFF1E1E1E),
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      chatName.isNotEmpty ? chatName[0].toUpperCase() : "?",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    chatName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
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
                        return const Text(
                          "No messages yet",
                          style: TextStyle(color: Colors.white54),
                        );
                      }
                      final lastMsgData = msgSnapshot.data!.docs.first.data()
                          as Map<String, dynamic>;
                      return Text(
                        lastMsgData['text'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      );
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.white54, size: 24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(chat: chat),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "scanQrFab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScanPage()),
              );
            },
            backgroundColor: const Color(0xFF2C2C2C),
            child: const Icon(Icons.qr_code_scanner, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "myQrFab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyQRPage()),
              );
            },
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.qr_code, size: 28, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
