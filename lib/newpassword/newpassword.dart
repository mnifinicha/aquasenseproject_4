import 'package:flutter/material.dart';

class Address extends StatelessWidget {
  const Address({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // รับข้อมูลที่ส่งมาจากหน้า Login
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String email = args?['email'] ?? '';
    final String password = args?['password'] ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB8D4F1), Color(0xFF1B4F91)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email: $email',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Password: $password',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
