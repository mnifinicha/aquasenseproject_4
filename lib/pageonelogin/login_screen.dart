import 'package:flutter/material.dart';
//import 'package:flutter_svg/flutter_svg.dart';

// ✅ Firebase Auth / Google Sign-In
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ไปหน้า Address หลังล็อกอินสำเร็จ
//import '../address/address.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /*void _goNext() {
    Navigator.pushReplacementNamed(
      context,
      '/email-password',
      arguments: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      },
    );
  }*/
  void _goNext() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _goToResetPassword() {
    Navigator.pushNamed(context, '/reset-password');
  }

  // ---------- Auth actions ----------
  Future<void> _loginWithEmail() async {
    //final email = _emailController.text.trim();
    var email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _toast('Please fill email & password');
      return;
    }
    if (email.contains(' ')) {
      _toast('Email should not contain spaces');
      return;
    }

    final invalidEmail =
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) ||
            RegExp(r'[ก-๙]').hasMatch(email) ||
            RegExp(r'[!#$%^&*(),?":{}|<>]').hasMatch(email);

    if (invalidEmail) {
      _toast('Please enter a valid email address');
      return;
    }

    if (email.contains(RegExp(r'[A-Z]'))) {
      email = email.toLowerCase(); // แปลงเป็นตัวเล็ก
      _toast('Email has been converted to lowercase automatically');
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      _goNext();
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Login failed');
    } catch (_) {
      _toast('Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _toast('Enter your email first');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('Password reset link sent to your email');
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Cannot send reset email');
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _loading = false);
          return;
        }
        final googleAuth = await googleUser!.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      _goNext();
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Google sign-in failed');
    } catch (_) {
      _toast('Google sign-in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- UI (ของเดิม) ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB8D4F1), Color(0xFF1B4F91)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'AquaSense',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4F91),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Fill out the information below in order to\naccess your account.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle:
                                    const TextStyle(color: Colors.black38),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle:
                                    const TextStyle(color: Colors.black38),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.black38,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ✅ เชื่อม Firebase: email/password
                            ElevatedButton(
                              onPressed: _loading ? null : _loginWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4F91),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            Align(
                              alignment:
                                  Alignment.centerRight, // ✅ ชิดขวาแน่นอน
                              child:
                                  // ✅ เชื่อม Firebase: reset password
                                  TextButton(
                                onPressed: _loading ? null : _goToResetPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            const Text(
                              'Or sign in with',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // ✅ เชื่อม Firebase: Google sign-in
                            /* OutlinedButton.icon(
                              onPressed: _loading ? null : _loginWithGoogle,
                              icon: SvgPicture.asset(
                                'assets/icons/google.svg',
                                width: 22,
                                height: 22,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.black12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),*/

                            OutlinedButton.icon(
                              onPressed: _loading ? null : _loginWithGoogle,
                              icon: const FaIcon(
                                FontAwesomeIcons.google,
                                color: Color.fromARGB(255, 10, 10, 10),
                                size: 17,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.black12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  child: const Text(
                                    'Sign Up here',
                                    style: TextStyle(
                                      color: Color(0xFF1B4F91),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
