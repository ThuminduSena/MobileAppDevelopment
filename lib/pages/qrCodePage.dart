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

class _QRScanPageState extends State<QRScanPage> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool scanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        scanned = false; // reset when app comes back
      });
    }
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (scanned) return;
      scanned = true;

      final friendId = scanData.code;
      final currentUser = _auth.currentUser!;
      final currentUserId = currentUser.uid;

      if (friendId == null || friendId == currentUserId) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid QR code")));
        Navigator.pop(context);
        return;
      }

      try {
        // Fetch friend's name
        final friendDoc = await _firestore
            .collection('users')
            .doc(friendId)
            .get();

        if (!friendDoc.exists) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("User not found")));
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
          final data = doc.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants'] ?? []);
          if (participants.contains(friendId) && participants.length == 2) {
            chat = Chat.fromMap(data);
            break;
          }
        }

        // If chat doesn’t exist, create it
        if (chat == null) {
          final chatId = _firestore.collection('chats').doc().id;

          final Map<String, String> namesMap = {
            currentUserId:
                currentUser.displayName ?? "Me", // Your ID maps to your name
            friendId: friendName, // Friend's ID maps to their name
          };

          await _firestore.collection('chats').doc(chatId).set({
            'id': chatId,
            'participants': [currentUserId, friendId],
            'names': namesMap,
            'createdBy': currentUserId,
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessageAt': FieldValue.serverTimestamp(),
          });

          final createdChat = await _firestore
              .collection('chats')
              .doc(chatId)
              .get();
          final data = createdChat.data()!;

          chat = Chat(
            id: data['id'],
            participants: List<String>.from(data['participants']),
            names: data['names'] != null
                ? Map<String, String>.from(data['names'])
                : null,
            createdBy: data['createdBy'],
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
          );
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat!)),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }
}
