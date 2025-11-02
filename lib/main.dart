import 'package:flutter/material.dart';
// ✅ Firebase init
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// หน้าที่อยากไปหลังล็อกอินสำเร็จ (Address)
import 'address/address.dart';

// หน้า Login ของโปรเจกต์นี้
//import 'pageonelogin/login_screen.dart';
import 'forgetpassword/pageone.dart';
import 'pagetwosignup/signup_screen.dart';
//import 'createaccount/createaccount.dart';
import 'sensorgraphs/sensorgraphs.dart';
import 'dashboard/dashboard.dart';
//import 'ml/ml.dart';
import 'addbuoy/addbuoy.dart';
//import 'newpassword/newpassword.dart';
//import 'buoymana/BuoyManagement.dart';
import 'pageonelogin/login_screen.dart';
import 'add_buoy_list_screen.dart';
import 'ml/ml.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AquaSenseApp());
}

class AquaSenseApp extends StatelessWidget {
  const AquaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5AA8)),
        useMaterial3: true,
      ),

      routes: {
        '/': (_) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/signup': (_) => const SignUpScreen(),
        //'/create-account': (_) => const CreateAccountScreen(),
        '/address': (_) => const AddressInformationScreen(),
        '/history': (context) => const SensorGraphsPage(),
        //'/address-info': (_) => const AddressInformationScreen(),
        '/add-buoy': (_) => const AddBuoyScreen(),
        '/add': (context) => const AddBuoyListScreen(),
        '/forecast': (context) => const WaterForecastPage(),
      },

      // initialRoute: '/',
      // ชั่วคราวให้เข้าหน้า Login เพื่อทดสอบการเชื่อม (เปลี่ยนกลับเป็น Address ได้)
      //home: const DashboardScreen(),
    );
  }
}
