import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatDetailPage.dart';
import 'model.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool scanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (scanned) return; // Prevent multiple scans
      scanned = true;

      final friendId = scanData.code;
      final currentUser = _auth.currentUser!;
      final currentUserId = currentUser.uid;

      if (friendId == null || friendId == currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid QR code")),
        );
        Navigator.pop(context);
        return;
      }

      final friendDoc = await _firestore.collection('users').doc(friendId).get();
      if (!friendDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found")),
        );
        Navigator.pop(context);
        return;
      }
      final friendName = friendDoc['name'] ?? "Friend";

      // Check if chat already exists
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      Chat? chat;
      for (var doc in chatQuery.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(friendId) && participants.length == 2) {
          chat = Chat.fromMap(data);
          break;
        }
      }

      // Create chat if not exists
      if (chat == null) {
        final chatId = _firestore.collection('chats').doc().id;
        final now = DateTime.now();
        chat = Chat(
          id: chatId,
          name: friendName,
          participants: [currentUserId, friendId],
          createdBy: currentUserId,
          createdAt: now,
          lastMessageAt: now,
        );

        await _firestore.collection('chats').doc(chatId).set({
          'id': chatId,
          'participants': [currentUserId, friendId],
          'name': {
            currentUserId: friendName,
            friendId: currentUser.displayName ?? "Me",
          },
          'createdBy': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat!)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        title: const Text(
          "Scan QR Code",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white), // White back button
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blueAccent,
              borderRadius: 12,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 250,
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Point the camera at a friend's QR code",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
