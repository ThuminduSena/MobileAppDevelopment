import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'model.dart';
import 'chatDetailPage.dart';

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

      final friendId = scanData.code; // The scanned userId
      final currentUserId = _auth.currentUser!.uid;

      if (friendId == null || friendId == currentUserId) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Invalid QR code")));
        Navigator.pop(context);
        return;
      }

      // Check if chat already exists between the two users
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

      // If chat doesn't exist, create it
      if (chat == null) {
        final chatId = _firestore.collection('chats').doc().id;
        chat = Chat(
          id: chatId,
          name: "Chat with Friend",
          participants: [currentUserId, friendId],
        );

        await _firestore.collection('chats').doc(chatId).set({
          'id': chatId,
          'name': "Chat with Friend",
          'participants': [currentUserId, friendId],
          'createdBy': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      // Navigate to chat detail page
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
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }
}
