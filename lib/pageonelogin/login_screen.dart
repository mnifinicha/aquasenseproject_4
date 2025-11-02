import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _googleBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color ?? Colors.black87,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _goToResetPassword() {
    if (!mounted) return;
    Navigator.pushNamed(context, '/reset-password');
  }

  Future<void> _ensureFirestoreProfile(User user) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'email': user.email ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Created Firestore profile for ${user.email}');
      } else {
        debugPrint('ℹ️ Firestore profile exists for ${user.email}');
      }
    } catch (e) {
      debugPrint('⚠️ Firestore error: $e');
    }
  }

  // ================== EMAIL/PASS ==================
  Future<void> _loginWithEmail() async {
    if (_loading) return;

    String email = _emailController.text.trim();
    final String pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _toast('Please fill email & password', color: Colors.red);
      return;
    }

    if (email.contains(' ')) {
      _toast('Email should not contain spaces', color: Colors.red);
      return;
    }

    final invalidEmail =
        !RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) ||
            RegExp(r'[ก-๙]').hasMatch(email) ||
            RegExp(r'[!#$%^&*(),?":{}|<>]').hasMatch(email);

    if (invalidEmail) {
      _toast('Please enter a valid email address', color: Colors.red);
      return;
    }

    if (email.contains(RegExp(r'[A-Z]'))) {
      email = email.toLowerCase();
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);

      final user = cred.user;
      if (user == null) {
        _toast('Login failed', color: Colors.red);
        return;
      }

      await _ensureFirestoreProfile(user);
      _goNext();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _toast('This email has not been registered yet.', color: Colors.red);
          break;
        case 'wrong-password':
          _toast('Wrong password.', color: Colors.red);
          break;
        case 'user-disabled':
          _toast('This account has been disabled.', color: Colors.red);
          break;
        case 'too-many-requests':
          _toast('Too many attempts. Try again later.', color: Colors.red);
          break;
        case 'network-request-failed':
          _toast('No internet connection.', color: Colors.red);
          break;
        default:
          _toast('Login failed: ${e.message}', color: Colors.red);
      }
    } catch (e) {
      _toast('Unexpected error: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================== GOOGLE (ไม่เช็คอะไรเลย - เข้าตรงๆ) ==================
  Future<void> _loginWithGoogle() async {
    if (_loading || _googleBusy) return;

    setState(() {
      _loading = true;
      _googleBusy = true;
    });

    try {
      UserCredential cred;

      if (kIsWeb) {
        // บนเว็บ
        cred =
            await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        // บนมือถือ
        final googleUser = await GoogleSignIn().signIn();

        if (googleUser == null) {
          _toast('Google sign-in cancelled.');
          return;
        }

        final googleAuth = await googleUser.authentication;

        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          _toast('Failed to get authentication tokens', color: Colors.red);
          return;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        cred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = cred.user;

      if (user == null || user.email == null) {
        _toast('Google sign-in failed', color: Colors.red);
        await _signOutGoogle();
        return;
      }

      // ✅✅✅ เข้าเลย ไม่เช็คอะไร
      _toast('Welcome ${user.email}!', color: Colors.green);
      await _ensureFirestoreProfile(user);
      _goNext();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') {
        _toast('Sign-in popup was closed');
      } else if (e.code == 'network-request-failed') {
        _toast('No internet connection', color: Colors.red);
      } else {
        _toast('Google sign-in failed: ${e.message}', color: Colors.red);
      }
      await _signOutGoogle();
    } catch (e) {
      _toast('Unexpected error: $e', color: Colors.red);
      await _signOutGoogle();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _googleBusy = false;
        });
      }
    }
  }

  Future<void> _signOutGoogle() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
  }

  // ================== UI ==================
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

                            // Email
                            TextField(
                              controller: _emailController,
                              enabled: !_loading,
                              decoration: InputDecoration(
                                hintText: 'Email',
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

                            // Password
                            TextField(
                              controller: _passwordController,
                              enabled: !_loading,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Password',
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
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          setState(() => _obscurePassword =
                                              !_obscurePassword);
                                        },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: _loading ? null : _loginWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4F91),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor:
                                    const Color(0xFF1B4F91).withOpacity(0.6),
                              ),
                              child: Text(
                                _loading && !_googleBusy
                                    ? 'Please wait...'
                                    : 'Log In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _goToResetPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.black54,
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

                            OutlinedButton.icon(
                              onPressed: (_loading || _googleBusy)
                                  ? null
                                  : _loginWithGoogle,
                              icon: FaIcon(
                                FontAwesomeIcons.google,
                                color: (_loading || _googleBusy)
                                    ? Colors.grey
                                    : Colors.black,
                                size: 17,
                              ),
                              label: Text(
                                (_loading && _googleBusy)
                                    ? 'Connecting...'
                                    : 'Continue with Google',
                                style: TextStyle(
                                  color: (_loading || _googleBusy)
                                      ? Colors.grey
                                      : Colors.black87,
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
                                disabledBackgroundColor: Colors.grey[100],
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
                                  onTap: _loading
                                      ? null
                                      : () {
                                          Navigator.pushNamed(
                                              context, '/signup');
                                        },
                                  child: Text(
                                    'Sign Up here',
                                    style: TextStyle(
                                      color: _loading
                                          ? Colors.grey
                                          : const Color(0xFF1B4F91),
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
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
