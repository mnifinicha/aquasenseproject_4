/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// เปลี่ยน path ให้ตรงโปรเจ็กต์
import '../addbuoy/addbuoy.dart';
import '../edit_buoy_address_screen.dart';

class BuoyManagementScreen extends StatefulWidget {
  const BuoyManagementScreen({Key? key}) : super(key: key);

  @override
  State<BuoyManagementScreen> createState() => _BuoyManagementScreenState();
}

class _BuoyManagementScreenState extends State<BuoyManagementScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getBuoysStream() {
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('buoy_registry')
        .where('uid', isEqualTo: user!.uid)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  void _editBuoy(String buoyId, Map<String, dynamic> installAddress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBuoyAddressScreen(
          buoyCode: buoyId,
          currentAddress: installAddress,
        ),
      ),
    );
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) return 'No address';

    final line1 = address['line1'] ?? '';
    final subdistrict = address['subdistrict'] ?? '';
    final district = address['district'] ?? '';
    final province = address['province'] ?? '';
    final postalCode = address['postal_code'] ?? '';

    return '$line1\n$subdistrict, $district,\n$province $postalCode';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: const Text(
            'Buoy Management',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Buoy Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Your Buoys',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Review your added buoys before proceeding to the home screen.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getBuoysStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.waves,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีทุ่นในระบบ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'กดปุ่ม "Add Another Buoy" เพื่อเพิ่มทุ่น',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final buoys = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: buoys.length,
                    itemBuilder: (context, index) {
                      final doc = buoys[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final buoyId = data['buoy_id'] ?? doc.id;
                      final installAddress =
                          data['install_address'] as Map<String, dynamic>?;
                      final createdAt = data['created_at'] as Timestamp?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      buoyId,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xFF007BFF)),
                                    onPressed: () {
                                      _editBuoy(buoyId, installAddress ?? {});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatAddress(installAddress),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Added ${_getTimeAgo(createdAt)}",
                                style: const TextStyle(
                                  color: Color(0xFF007BFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddBuoyScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: Color(0xFF003366)),
                      label: const Text(
                        'Add Another Buoy',
                        style: TextStyle(
                          color: Color(0xFF003366),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                            color: Color(0xFF003366), width: 1.5),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text(
                        'Go to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// เปลี่ยน path ให้ตรงโปรเจ็กต์ของเธอ
import '../addbuoy/addbuoy.dart';
import '../edit_buoy_address_screen.dart';
import '../dashboard/dashboard.dart'; // ✅ เพิ่มอันนี้ เพื่อจะกดไปหน้า Dashboard

class BuoyManagementScreen extends StatefulWidget {
  const BuoyManagementScreen({Key? key}) : super(key: key);

  @override
  State<BuoyManagementScreen> createState() => _BuoyManagementScreenState();
}

class _BuoyManagementScreenState extends State<BuoyManagementScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // ดึงข้อมูลทุ่นของ user นี้
  Stream<QuerySnapshot> _getBuoysStream() {
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('buoy_registry')
        .where('uid', isEqualTo: user!.uid)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  // เปิดหน้าแก้ไขที่อยู่ทุ่น
  void _editBuoy(String buoyId, Map<String, dynamic> installAddress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBuoyAddressScreen(
          buoyCode: buoyId,
          currentAddress: installAddress,
        ),
      ),
    );
  }

  // แปลงเวลา
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // ฟอร์แมตที่อยู่ทุ่น
  String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) return 'No address';

    final line1 = address['line1'] ?? '';
    final subdistrict = address['subdistrict'] ?? '';
    final district = address['district'] ?? '';
    final province = address['province'] ?? '';
    final postalCode = address['postal_code'] ?? '';

    return '$line1\n$subdistrict, $district,\n$province $postalCode';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: const Text(
            'Buoy Management',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Buoy Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Your Buoys',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Review your added buoys before proceeding to the home screen.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // ---------- รายการทุ่น ----------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getBuoysStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.waves,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีทุ่นในระบบ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'กดปุ่ม "Add Another Buoy" เพื่อเพิ่มทุ่น',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final buoys = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: buoys.length,
                    itemBuilder: (context, index) {
                      final doc = buoys[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final buoyId = data['buoy_id'] ?? doc.id;
                      final installAddress =
                          data['install_address'] as Map<String, dynamic>?;
                      //final createdAt = data['created_at'] as Timestamp?;
                      final createdOrUpdatedAt = (data['updated_at'] ??
                          data['created_at']) as Timestamp?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // แถวบนสุด (ชื่อทุ่น + ปุ่มแก้ไข)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      buoyId,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF007BFF),
                                    ),
                                    onPressed: () {
                                      _editBuoy(buoyId, installAddress ?? {});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // ที่อยู่
                              Text(
                                _formatAddress(installAddress),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // เวลา
                              /*Text(
                                "Added ${_getTimeAgo(createdAt)}",*/
                              Text(
                                "Added ${_getTimeAgo(createdOrUpdatedAt)}",
                                style: const TextStyle(
                                  color: Color(0xFF007BFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ---------- ปุ่มล่าง ----------
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ปุ่มเพิ่มทุ่น
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddBuoyScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: Color(0xFF003366)),
                      label: const Text(
                        'Add Another Buoy',
                        style: TextStyle(
                          color: Color(0xFF003366),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                            color: Color(0xFF003366), width: 1.5),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // ✅ ปุ่ม Go to Home → ไป DashboardScreen
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // ไปหน้า Dashboard แล้วล้างสแต็กเก่าออก
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                          (route) => false,
                        );
                        // ถ้าเธอตั้ง route name ไว้เป็น '/dashboard' ก็ใช้แบบนี้แทนได้
                        // Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                      },
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text(
                        'Go to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
