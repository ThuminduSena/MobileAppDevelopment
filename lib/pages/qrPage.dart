import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyQRPage extends StatelessWidget {
  const MyQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.black,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white70),
          ),
        ),
        child: const Scaffold(
          body: Center(
            child: Text('Please sign in to view your QR code'),
          ),
        ),
      );
    }

    final darkTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );

    return Theme(
      data: darkTheme,
      child: Scaffold(
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
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.4),
                ),
                child: QrImageView(
                  data: user.uid,
                  version: QrVersions.auto,
                  size: 250.0,
                  gapless: true,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.blueAccent,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.white,
                  ),
                  errorStateBuilder: (context, error) => const Center(
                    child: Text(
                      'Error generating QR code',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Scan this QR code to chat with me",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
