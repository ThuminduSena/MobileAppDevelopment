import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyQRPage extends StatelessWidget {
  const MyQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Add null check for user
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
      body: Center(
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
                gapless: true, // Changed to true for better QR code appearance
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
      ),
    );
  }
}