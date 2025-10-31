import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Reset password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content ตรงกลาง
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Card Container
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Title
                              const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Description
                              Text(
                                'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Email address',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF1B4F91),
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF6C63FF),
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Send Link Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      // String email = _emailController.text;
                                      // debugPrint('Send reset link to: $email');
                                      final email =
                                          _emailController.text.trim();
                                      try {
                                        // ✅ เรียกใช้ Firebase เพื่อส่งลิงก์รีเซ็ตรหัสผ่านจริง
                                        await FirebaseAuth.instance
                                            .sendPasswordResetEmail(
                                                email: email);

                                        // Show success dialog
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(32),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .mark_email_read_rounded,
                                                      color: Colors.green,
                                                      size: 48,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  const Text(
                                                    'Check Your Email',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'We have sent a password reset link to',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    email,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1B4F91),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF1B4F91),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 14),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        elevation: 0,
                                                      ),
                                                      child: const Text(
                                                        'Got it!',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        String message;
                                        switch (e.code) {
                                          case 'user-not-found':
                                            message =
                                                'ไม่พบบัญชีนี้ในระบบ กรุณาตรวจสอบอีเมลอีกครั้ง';
                                            break;
                                          case 'invalid-email':
                                            message = 'รูปแบบอีเมลไม่ถูกต้อง';
                                            break;
                                          default:
                                            message =
                                                'ไม่สามารถส่งอีเมลได้: ${e.message}';
                                        }

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(message)));
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B4F91),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    shadowColor: const Color(0xFF1B4F91)
                                        .withOpacity(0.3),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Send Link',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // SizedBox(width: 8),
                                      // Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Back to login
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Back to Login',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
