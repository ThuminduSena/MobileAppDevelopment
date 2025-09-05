import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatDetailPage.dart';
import 'model.dart';

class MyQRPage extends StatefulWidget {
  const MyQRPage({super.key});

  @override
  State<MyQRPage> createState() => _MyQRPageState();
}

class _MyQRPageState extends State<MyQRPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _lastOpenedChatId;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your QR code'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My QR Code"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final latestChatDoc = snapshot.data!.docs.first;
            final latestChatId = latestChatDoc.id;

            // Only trigger if it's a new chat we haven’t opened yet
            if (_lastOpenedChatId != latestChatId) {
              _lastOpenedChatId = latestChatId;

              final chat = Chat.fromMap(
                latestChatDoc.data() as Map<String, dynamic>,
              );

              // Navigate to the chat after a short delay (avoid build conflicts)
              Future.microtask(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailPage(chat: chat),
                  ),
                );
              });
            }
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: user.uid,
                    version: QrVersions.auto,
                    size: 250.0,
                    gapless: true,
                    errorStateBuilder: (context, error) => const Center(
                      child: Text('Error generating QR code'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Scan this QR code to chat with me",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
