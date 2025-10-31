import 'package:flutter/material.dart';
//import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      // 1️⃣ เปิดหน้าล็อกอิน Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId:
            '395577249681-1ighk8r4ufomktraof9so3s1u9uut01c.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) return; // ถ้าผู้ใช้กดยกเลิก

      // 2️⃣ ดึง token ของผู้ใช้
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3️⃣ เอา token ไปแลก credential ของ Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4️⃣ ล็อกอินเข้า Firebase ด้วย credential นี้
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 5️⃣ สำเร็จ → ไปหน้า Address
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/address');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD6E7F7),
              Color(0xFF1B4F91),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const Text(
                    'AquaSense',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4F91),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Card
                  Container(
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'Fill out the information below to create\nyour new account.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Email Field
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password Field
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Button
                        // Sign Up Button
                        ElevatedButton(
                          onPressed: () async {
                            // 🔹 เพิ่มส่วนนี้: ตรวจสอบว่ากรอก Email หรือยัง
                            if (_emailController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your email'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return; // หยุดทำงานทันที
                            }

                            // 🔹 เพิ่มส่วนนี้: ตรวจสอบว่ากรอก Password หรือยัง
                            if (_passwordController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your password'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return; // หยุดทำงานทันที
                            }

                            // 🔹 ตรวจสอบว่า password ตรงกันไหม (เดิมมีอยู่แล้ว แต่ย้ายมาไว้หลังเช็คว่างก่อน)
                            if (_passwordController.text !=
                                _confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Passwords do not match!'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return; // หยุดทำงานทันที
                            }

                            // ลอง Sign Up กับ Firebase
                            try {
                              await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                              );

                              // 🔹 เปลี่ยน route จาก '/create-profile' เป็น '/create-account'
                              if (mounted) {
                                Navigator.pushReplacementNamed(
                                    context, '/address');
                              }
                            } on FirebaseAuthException catch (e) {
                              // 🔹 เพิ่มส่วนนี้: แปล error code เป็นข้อความไทยที่อ่านง่าย
                              String errorMessage = 'Sign up failed';

                              if (e.code == 'email-already-in-use') {
                                errorMessage =
                                    'This email is already registered';
                              } else if (e.code == 'weak-password') {
                                errorMessage = 'Password is too weak';
                              } else if (e.code == 'invalid-email') {
                                errorMessage = 'Invalid email format';
                              } else if (e.message != null) {
                                errorMessage = e.message!;
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F91),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        const Text(
                          'Or sign up with',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Google Button
                        /*OutlinedButton(
                          onPressed: () async {
                            try {
                              if (mounted) {
                                Navigator.pushReplacementNamed(
                                    context, '/create-account');
                              }
                            } catch (e) {
                              debugPrint('Google Sign Up Error: $e');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/google.svg',
                                width: 18,
                                height: 18,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),*/
                        // Google Button
                        /*OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              if (mounted) {
                                Navigator.pushReplacementNamed(
                                    context, '/create-account');
                              }
                            } catch (e) {
                              debugPrint('Google Sign Up Error: $e');
                            }
                          },*/
                        OutlinedButton.icon(
                          onPressed:
                              _signInWithGoogle, // ✅ เรียกฟังก์ชันที่เราเพิ่มไว้ด้านบน

                          icon: const FaIcon(
                            FontAwesomeIcons.google,
                            color: Color.fromARGB(255, 10, 10, 10),
                            size: 17, // ขนาดโลโก้ G
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Log In Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Log In here',
                                style: TextStyle(
                                  color: Color(0xFF1B4F91),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
