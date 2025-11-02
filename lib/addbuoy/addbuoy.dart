import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

// เปลี่ยน path ให้ตรงกับโปรเจกต์ของเธอ
import '../buoymana/Buoymanagement.dart';

class AddBuoyScreen extends StatefulWidget {
  final String? userAddress;

  const AddBuoyScreen({Key? key, this.userAddress}) : super(key: key);

  @override
  State<AddBuoyScreen> createState() => _AddBuoyScreenState();
}

class _AddBuoyScreenState extends State<AddBuoyScreen> {
  final TextEditingController _buoyCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  String _selectedAddressOption = 'profile';

  // เก็บ doc ที่ได้จาก verify เผื่อใช้ซ้ำ
  DocumentSnapshot<Map<String, dynamic>>? _verifiedDoc;

  @override
  void dispose() {
    _buoyCodeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 1) Verify รหัสทุ่น + ดักว่าใครเป็นเจ้าของแล้ว
  // ─────────────────────────────────────────────
  Future<void> _verifyBuoyCode() async {
    final code = _buoyCodeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('กรุณากรอกรหัสทุ่น');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('กรุณาเข้าสู่ระบบก่อน', color: Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('buoy_registry')
          .doc(code)
          .get();

      if (!doc.exists) {
        setState(() {
          _isVerified = false;
          _verifiedDoc = null;
        });
        _showSnackBar('ไม่พบรหัสทุ่นนี้ในระบบ', color: Colors.orange);
        return;
      }

      // เช็กเจ้าของเดิม
      final data = doc.data() ?? {};
      final ownerUid = data['owner_uid'] as String?;
      final ownerEmail = data['owner_email'] as String?;

      // ถ้ามีเจ้าของแล้ว และไม่ใช่คนที่ล็อกอินอยู่ → ไม่ให้ไปต่อ
      if (ownerUid != null && ownerUid.isNotEmpty && ownerUid != user.uid) {
        setState(() {
          _isVerified = false;
          _verifiedDoc = doc;
        });
        _showSnackBar(
          'ทุ่นนี้ถูกผูกกับผู้ใช้อื่นแล้ว ใช้ได้ 1 เมลต่อ 1 ทุ่นเท่านั้น',
          color: Colors.red,
        );
        return;
      }
      if (ownerUid == null &&
          ownerEmail != null &&
          ownerEmail.isNotEmpty &&
          user.email != null &&
          ownerEmail != user.email) {
        // กรณีเก่าที่ใช้แค่ owner_email
        setState(() {
          _isVerified = false;
          _verifiedDoc = doc;
        });
        _showSnackBar(
          'ทุ่นนี้ถูกผูกกับอีเมล $ownerEmail แล้ว',
          color: Colors.red,
        );
        return;
      }

      // มาถึงตรงนี้แปลว่า
      // - ยังไม่มีเจ้าของ
      // OR
      // - เจ้าของเดิม = คนนี้เอง (เข้ามาแก้ที่อยู่ก็ได้)
      setState(() {
        _isVerified = true;
        _verifiedDoc = doc;
      });
      _showSnackBar('ยืนยันรหัสทุ่นสำเร็จ');
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────
  // 2) Next → เลือกว่าจะใช้ที่อยู่จากโปรไฟล์ หรือกรอกใหม่
  // ─────────────────────────────────────────────
  Future<void> _handleNext() async {
    if (!_isVerified) {
      _showSnackBar('กรุณายืนยันรหัสทุ่นก่อน');
      return;
    }

    final buoyCode = _buoyCodeController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('กรุณาเข้าสู่ระบบก่อน', color: Colors.red);
      return;
    }

    // ถ้ากรอกใหม่ → ไปหน้ากรอกที่อยู่
    if (_selectedAddressOption == 'new') {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BuoyAddressInformationScreen(buoyCode: buoyCode),
        ),
      );
      if (!mounted) return;
      if (saved == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BuoyManagementScreen(),
          ),
        );
      }
      return;
    }

    // ถ้าใช้ที่อยู่จากโปรไฟล์
    try {
      final addr = await _getProfileAddressFromUsers();
      if (addr == null) {
        _showSnackBar('ไม่พบบันทึกที่อยู่ของผู้ใช้ใน users/{uid}',
            color: Colors.orange);
        return;
      }

      await _saveInstallAddressToRegistry(
        buoyCode: buoyCode,
        installAddress: addr,
      );

      _showSnackBar('บันทึกตำแหน่งทุ่นจากโปรไฟล์สำเร็จ', color: Colors.green);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BuoyManagementScreen(),
        ),
      );
    } catch (e) {
      _showSnackBar('บันทึกไม่สำเร็จ: $e', color: Colors.red);
    }
  }

  // ─────────────────────────────────────────────
  // 3) ดึงที่อยู่จาก users/{uid}
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> _getProfileAddressFromUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;

    final d = doc.data() ?? {};

    // เราเซฟจากหน้า Address ไว้แบบนี้: address, subdistrict, district, province, postal_code
    if ((d['address'] ?? '').toString().isEmpty ||
        (d['subdistrict'] ?? '').toString().isEmpty ||
        (d['district'] ?? '').toString().isEmpty ||
        (d['province'] ?? '').toString().isEmpty ||
        (d['postal_code'] ?? '').toString().isEmpty) {
      return null;
    }

    // ให้เก็บทั้ง address และ line1 ไว้เลย เผื่อหน้าที่แสดงดึงคนละชื่อ
    return {
      'address': d['address'],
      'subdistrict': d['subdistrict'],
      'district': d['district'],
      'province': d['province'],
      'postal_code': d['postal_code'],
      'label': 'ตำแหน่งทุ่น',
    };
  }

  // ─────────────────────────────────────────────
  // 4) เซฟลง buoy_registry/{buoyCode} แบบ “ล็อกเจ้าของ”
  // ─────────────────────────────────────────────
  Future<void> _saveInstallAddressToRegistry({
    required String buoyCode,
    required Map<String, dynamic> installAddress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No logged in user');
    }

    // อ่าน doc ปัจจุบันก่อน เผื่อมีเจ้าของแล้ว
    final docRef =
        FirebaseFirestore.instance.collection('buoy_registry').doc(buoyCode);
    final currentDoc = await docRef.get();
    final now = FieldValue.serverTimestamp();

    String? existingOwnerUid;
    String? existingOwnerEmail;
    if (currentDoc.exists) {
      final d = currentDoc.data() ?? {};
      existingOwnerUid = d['owner_uid'] as String?;
      existingOwnerEmail = d['owner_email'] as String?;
    }

    // ถ้ามีเจ้าของแล้ว และไม่ใช่เรา → หยุด
    if (existingOwnerUid != null &&
        existingOwnerUid.isNotEmpty &&
        existingOwnerUid != user.uid) {
      throw Exception('ทุ่นนี้มีเจ้าของแล้ว');
    }
    if (existingOwnerUid == null &&
        existingOwnerEmail != null &&
        existingOwnerEmail.isNotEmpty &&
        user.email != null &&
        existingOwnerEmail != user.email) {
      throw Exception('ทุ่นนี้มีเจ้าของแล้ว');
    }

    // เตรียม data ที่จะอัปเดต
    final dataToSet = <String, dynamic>{
      'buoy_id': buoyCode,
      'active': true,
      'install_address': installAddress,
      'updated_at': now,
      'uid':
          user.uid, // ← ใส่เพิ่ม เพื่อให้หน้า list ที่ query ด้วย uid ก็หาเจอ
    };

    // ถ้ายังไม่มีเจ้าของ → ตั้งคนนี้เป็นเจ้าของ
    if (existingOwnerUid == null && existingOwnerEmail == null) {
      dataToSet['owner_uid'] = user.uid;
      dataToSet['owner_email'] = user.email;
      dataToSet['created_at'] = now;
    }

    // อัปเดตที่ทุ่น
    await docRef.set(dataToSet, SetOptions(merge: true));

    // ผูกฝั่ง user → users/{uid}.buoys = [..., buoy_001]
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'buoys': FieldValue.arrayUnion([buoyCode]),
    }, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Buoy',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // กล่องกรอกรหัสทุ่น
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your buoy code to add it to your monitoring system.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _buoyCodeController,
                      decoration: InputDecoration(
                        labelText: 'Buoy code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyBuoyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Verify Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ถ้ายืนยันแล้ว
              if (_isVerified) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings buoy location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedAddressOption = 'profile'),
                        child: _buildOptionCard(
                          title: 'Use Address from Profile',
                          subtitle: 'Quick setup with saved location',
                          icon: Icons.person_pin_circle,
                          selected: _selectedAddressOption == 'profile',
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedAddressOption = 'new'),
                        child: _buildOptionCard(
                          title: 'Enter New Address',
                          subtitle: 'Set a different location for this buoy',
                          icon: Icons.add_location_alt,
                          selected: _selectedAddressOption == 'new',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF003366) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF003366) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF003366),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// หน้ากรอกที่อยู่ทุ่น (กรอกใหม่)
// ─────────────────────────────────────────────
class BuoyAddressInformationScreen extends StatefulWidget {
  final String buoyCode;
  const BuoyAddressInformationScreen({Key? key, required this.buoyCode})
      : super(key: key);

  @override
  State<BuoyAddressInformationScreen> createState() =>
      _BuoyAddressInformationScreenState();
}

class _BuoyAddressInformationScreenState
    extends State<BuoyAddressInformationScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  List<String> _provinces = [];
  List<String> _districts = [];
  List<String> _subdistricts = [];

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    final jsonStr =
        await rootBundle.loadString('assets/thai_data/provinces.json');
    final List data = jsonDecode(jsonStr);
    setState(() {
      _provinces = List<String>.from(data.map((e) => e['name_th']));
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.isEmpty ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedSubdistrict == null ||
        _postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')));
      return;
    }

    final installAddress = {
      'label': 'ตำแหน่งทุ่น',
      'address': _addressController.text.trim(),
      'line1': _addressController.text.trim(), // เก็บให้ตรงกับอีกหน้าด้วย
      'subdistrict': _selectedSubdistrict,
      'district': _selectedDistrict,
      'province': _selectedProvince,
      'postal_code': _postalCodeController.text.trim(),
    };

    try {
      final docRef = FirebaseFirestore.instance
          .collection('buoy_registry')
          .doc(widget.buoyCode);

      final doc = await docRef.get();
      final now = FieldValue.serverTimestamp();

      String? existingOwnerUid;
      String? existingOwnerEmail;
      if (doc.exists) {
        final d = doc.data() ?? {};
        existingOwnerUid = d['owner_uid'] as String?;
        existingOwnerEmail = d['owner_email'] as String?;
      }

      // ถ้ามีเจ้าของแล้วและไม่ใช่เรา → หยุด
      if (existingOwnerUid != null &&
          existingOwnerUid.isNotEmpty &&
          existingOwnerUid != user.uid) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ทุ่นนี้มีเจ้าของแล้ว ไม่สามารถแก้ที่อยู่ได้')));
        return;
      }
      if (existingOwnerUid == null &&
          existingOwnerEmail != null &&
          existingOwnerEmail.isNotEmpty &&
          user.email != null &&
          existingOwnerEmail != user.email) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ทุ่นนี้มีเจ้าของแล้ว ไม่สามารถแก้ที่อยู่ได้')));
        return;
      }

      final dataToSet = <String, dynamic>{
        'buoy_id': widget.buoyCode,
        'install_address': installAddress,
        'active': true,
        'updated_at': now,
        'uid': user.uid, // ← เพิ่มเหมือนหน้า add
      };

      if (existingOwnerUid == null && existingOwnerEmail == null) {
        dataToSet['owner_uid'] = user.uid;
        dataToSet['owner_email'] = user.email;
        dataToSet['created_at'] = now;
      }

      await docRef.set(dataToSet, SetOptions(merge: true));

      // ผูกฝั่ง user
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'buoys': FieldValue.arrayUnion([widget.buoyCode]),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('เพิ่มทุ่นสำเร็จ')));

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Address Information',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('Address'),
                  TextField(
                    controller: _addressController,
                    decoration: _inputStyle(Icons.home, '198/114 ม.1'),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Province'),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    items: _provinces
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedProvince = value;
                        _selectedDistrict = null;
                        _selectedSubdistrict = null;
                        _districts.clear();
                        _subdistricts.clear();
                        _postalCodeController.clear();
                      });

                      if (value == null) return;

                      final provJson = await rootBundle
                          .loadString('assets/thai_data/provinces.json');
                      final distJson = await rootBundle
                          .loadString('assets/thai_data/districts.json');
                      final List prov = jsonDecode(provJson);
                      final List dist = jsonDecode(distJson);
                      final provId =
                          prov.firstWhere((e) => e['name_th'] == value)['id'];
                      setState(() {
                        _districts = List<String>.from(dist
                            .where((e) => e['province_id'] == provId)
                            .map((e) => e['name_th']));
                      });
                    },
                    decoration:
                        _dropdownStyle(Icons.location_city, 'Select province'),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('District'),
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    items: _districts
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedDistrict = value;
                        _selectedSubdistrict = null;
                        _subdistricts.clear();
                        _postalCodeController.clear();
                      });
                      if (value == null) return;

                      final distJson = await rootBundle
                          .loadString('assets/thai_data/districts.json');
                      final subJson = await rootBundle
                          .loadString('assets/thai_data/sub_districts.json');
                      final List dist = jsonDecode(distJson);
                      final List subs = jsonDecode(subJson);
                      final distId =
                          dist.firstWhere((e) => e['name_th'] == value)['id'];

                      setState(() {
                        _subdistricts = List<String>.from(subs
                            .where((e) => e['district_id'] == distId)
                            .map((e) => e['name_th']));
                      });
                    },
                    decoration: _dropdownStyle(Icons.map, 'Select district'),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Subdistrict'),
                  DropdownButtonFormField<String>(
                    value: _selectedSubdistrict,
                    items: _subdistricts
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedSubdistrict = value;
                        _postalCodeController.clear();
                      });
                      if (value == null) return;

                      final distJson = await rootBundle
                          .loadString('assets/thai_data/districts.json');
                      final subJson = await rootBundle
                          .loadString('assets/thai_data/sub_districts.json');
                      final List dist = jsonDecode(distJson);
                      final List subs = jsonDecode(subJson);
                      final distId = dist.firstWhere(
                          (e) => e['name_th'] == _selectedDistrict)['id'];
                      final sub = subs.firstWhere((e) =>
                          e['district_id'] == distId && e['name_th'] == value);
                      setState(() {
                        _postalCodeController.text = sub['zip_code'].toString();
                      });
                    },
                    decoration:
                        _dropdownStyle(Icons.place, 'Select subdistrict'),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Postal Code'),
                  TextField(
                    controller: _postalCodeController,
                    readOnly: true,
                    decoration:
                        _inputStyle(Icons.mail, 'Postal code auto-filled'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(IconData icon, String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF003366)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      );

  InputDecoration _dropdownStyle(IconData icon, String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF003366)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      );

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
}
