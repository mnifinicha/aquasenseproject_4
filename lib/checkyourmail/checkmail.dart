import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckMailScreen extends StatelessWidget {
  final String? email;

  const CheckMailScreen({
    super.key,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Content - Center aligned
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Email Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 50,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Check your mail',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'We have sent a password recover\ninstructions to your email.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Open Email App Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          debugPrint('Open email app');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003D7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Open email app',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skip Button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: Text(
                        "Skip, I'll confirm later",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
