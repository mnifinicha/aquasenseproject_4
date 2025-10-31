/*import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AddBuoyScreen extends StatefulWidget {
  final String? userAddress; // ที่อยู่จาก profile

  const AddBuoyScreen({Key? key, this.userAddress}) : super(key: key);

  @override
  State<AddBuoyScreen> createState() => _AddBuoyScreenState();
}

class _AddBuoyScreenState extends State<AddBuoyScreen> {
  final TextEditingController _buoyCodeController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  bool _isLoading = false;
  bool _isVerified = false;
  String _selectedAddressOption = 'profile'; // 'profile' หรือ 'new'

  @override
  void dispose() {
    _buoyCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyBuoyCode() async {
    if (_buoyCodeController.text.isEmpty) {
      _showSnackBar('กรุณากรอกรหัสทุ่น');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot =
          await _database.child('buoys').child(_buoyCodeController.text).get();

      if (snapshot.exists) {
        setState(() {
          _isVerified = true;
          _isLoading = false;
        });
        _showSnackBar('ยืนยันรหัสทุ่นสำเร็จ');
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('ไม่พบรหัสทุ่นนี้ในระบบ');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleNext() {
    if (!_isVerified) {
      _showSnackBar('กรุณายืนยันรหัสทุ่นก่อน');
      return;
    }

    if (_selectedAddressOption == 'new') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuoyAddressInformationScreen(
            buoyCode: _buoyCodeController.text,
          ),
        ),
      );
    } else {
      _saveBuoyWithAddress(widget.userAddress);
    }
  }

  Future<void> _saveBuoyWithAddress(String? address) async {
    if (address == null || address.isEmpty) {
      _showSnackBar('ไม่พบที่อยู่ในโปรไฟล์');
      return;
    }

    try {
      await _database.child('user_buoys').push().set({
        'buoy_code': _buoyCodeController.text,
        'address': address,
        'timestamp': ServerValue.timestamp,
      });
      _showSnackBar('เพิ่มทุ่นสำเร็จ');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
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
              // ✅ Buoy Code Section
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
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
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

                      // ✅ เลือกใช้ที่อยู่เดิมหรือกรอกใหม่
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
                      if (_selectedAddressOption == 'profile' &&
                          widget.userAddress != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Color(0xFF003366), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.userAddress!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
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
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF003366).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
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
            child: Icon(icon,
                color: selected ? Colors.white : const Color(0xFF003366),
                size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600)),
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

// ✅ หน้ากรอกที่อยู่ใหม่พร้อม auto จังหวัด/อำเภอ/ตำบล/ไปรษณีย์
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
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
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
    final json = await rootBundle.loadString('assets/thai_data/provinces.json');
    final List data = jsonDecode(json);
    setState(
        () => _provinces = List<String>.from(data.map((e) => e['name_th'])));
  }

  Future<void> _saveAddress() async {
    if (_houseNumberController.text.isEmpty ||
        _villageController.text.isEmpty ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedSubdistrict == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
      return;
    }

    final DatabaseReference db = FirebaseDatabase.instance.ref();
    await db.child('user_buoys').push().set({
      'buoy_code': widget.buoyCode,
      'address':
          '${_houseNumberController.text}, ${_villageController.text}, $_selectedSubdistrict, $_selectedDistrict, $_selectedProvince ${_postalCodeController.text}',
      'timestamp': ServerValue.timestamp,
    });

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('เพิ่มทุ่นสำเร็จ')));
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Address Information',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildLabel('House Number'),
            TextField(
              controller: _houseNumberController,
              decoration: _inputStyle(Icons.home, 'Enter house number'),
            ),
            const SizedBox(height: 20),
            _buildLabel('Village / Soi / Street'),
            TextField(
              controller: _villageController,
              decoration: _inputStyle(Icons.signpost, 'Enter village or soi'),
            ),
            const SizedBox(height: 20),
            _buildLabel('Province'),
            DropdownButtonFormField(
              value: _selectedProvince,
              items: _provinces
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) async {
                _selectedProvince = v;
                _districts.clear();
                _subdistricts.clear();
                _postalCodeController.clear();
                final json = await rootBundle
                    .loadString('assets/thai_data/districts.json');
                final List data = jsonDecode(json);
                final provJson = await rootBundle
                    .loadString('assets/thai_data/provinces.json');
                final provData = jsonDecode(provJson);
                final id = provData.firstWhere((e) => e['name_th'] == v)['id'];
                setState(() => _districts = List<String>.from(data
                    .where((e) => e['province_id'] == id)
                    .map((e) => e['name_th'])));
              },
              decoration:
                  _dropdownStyle(Icons.location_city, 'Select province'),
            ),
            const SizedBox(height: 20),
            _buildLabel('District'),
            DropdownButtonFormField(
              value: _selectedDistrict,
              items: _districts
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) async {
                _selectedDistrict = v;
                _subdistricts.clear();
                final json = await rootBundle
                    .loadString('assets/thai_data/sub_districts.json');
                final List subs = jsonDecode(json);
                final distJson = await rootBundle
                    .loadString('assets/thai_data/districts.json');
                final List dist = jsonDecode(distJson);
                final id = dist.firstWhere((e) => e['name_th'] == v)['id'];
                setState(() => _subdistricts = List<String>.from(subs
                    .where((e) => e['district_id'] == id)
                    .map((e) => e['name_th'])));
              },
              decoration: _dropdownStyle(Icons.map, 'Select district'),
            ),
            const SizedBox(height: 20),
            _buildLabel('Subdistrict'),
            DropdownButtonFormField(
              value: _selectedSubdistrict,
              items: _subdistricts
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) async {
                _selectedSubdistrict = v;
                final subJson = await rootBundle
                    .loadString('assets/thai_data/sub_districts.json');
                final distJson = await rootBundle
                    .loadString('assets/thai_data/districts.json');
                final List subs = jsonDecode(subJson);
                final List dist = jsonDecode(distJson);
                final id = dist
                    .firstWhere((e) => e['name_th'] == _selectedDistrict)['id'];
                final sub = subs.firstWhere(
                    (e) => e['district_id'] == id && e['name_th'] == v);
                setState(() =>
                    _postalCodeController.text = sub['zip_code'].toString());
              },
              decoration: _dropdownStyle(Icons.place, 'Select subdistrict'),
            ),
            const SizedBox(height: 20),
            _buildLabel('Postal Code'),
            TextField(
              controller: _postalCodeController,
              readOnly: true,
              decoration: _inputStyle(Icons.mail, 'Postal code auto-filled'),
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
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('Save',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            )
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(IconData icon, String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF003366)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      );

  InputDecoration _dropdownStyle(IconData icon, String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF003366)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      );

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red))
            ],
          ),
        ),
      );
}*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ------------------------------------------------------------
/// AddBuoyScreen
/// - ยืนยันรหัสทุ่น
/// - ให้ผู้ใช้เลือก ใช้ที่อยู่จากโปรไฟล์ / กรอกใหม่
/// - ถ้าใช้ที่อยู่จากโปรไฟล์ → ดึงจาก users/{uid} แล้วเขียนลง buoy_registry/{buoy_code}
/// - ถ้าเลือกกรอกใหม่ → ไปหน้า BuoyAddressInformationScreen แล้วบันทึกลง buoy_registry/{buoy_code}
/// ------------------------------------------------------------
class AddBuoyScreen extends StatefulWidget {
  final String? userAddress; // (ไม่บังคับใช้แล้ว) ที่อยู่จากหน้าก่อน

  const AddBuoyScreen({Key? key, this.userAddress}) : super(key: key);

  @override
  State<AddBuoyScreen> createState() => _AddBuoyScreenState();
}

class _AddBuoyScreenState extends State<AddBuoyScreen> {
  final TextEditingController _buoyCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  String _selectedAddressOption = 'profile'; // 'profile' | 'new'

  @override
  void dispose() {
    _buoyCodeController.dispose();
    super.dispose();
  }

  // ✅ ตรวจว่ามีเอกสารทุ่นใน Firestore หรือไม่ (อนุโลมว่าผู้ผลิตสร้าง doc รอไว้)
  Future<void> _verifyBuoyCode() async {
    final code = _buoyCodeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('กรุณากรอกรหัสทุ่น');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('buoy_registry')
          .doc(code)
          .get();

      setState(() {
        _isVerified = doc.exists; // มีเอกสารถือว่า valid
        _isLoading = false;
      });

      if (_isVerified) {
        _showSnackBar('ยืนยันรหัสทุ่นสำเร็จ');
      } else {
        _showSnackBar('ไม่พบรหัสทุ่นนี้ในระบบ (buoy_registry/$code)');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleNext() async {
    if (!_isVerified) {
      _showSnackBar('กรุณายืนยันรหัสทุ่นก่อน');
      return;
    }

    final buoyCode = _buoyCodeController.text.trim();

    if (_selectedAddressOption == 'new') {
      // ➜ ไปหน้ากรอกที่อยู่ใหม่ (หน้านี้จะเป็นคนบันทึกลง buoy_registry ให้เลย)
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuoyAddressInformationScreen(buoyCode: buoyCode),
        ),
      );
      // กลับมาหน้านี้: ไม่ต้องทำอะไรต่อ
      return;
    }

    // ➜ ใช้ที่อยู่จากโปรไฟล์
    try {
      final addr = await _getProfileAddressFromUsers();
      if (addr == null) {
        _showSnackBar('ไม่พบบันทึกที่อยู่ของผู้ใช้ใน users/{uid}');
        return;
      }
      await _saveInstallAddressToRegistry(
          buoyCode: buoyCode, installAddress: addr);
      _showSnackBar('บันทึกตำแหน่งทุ่นจากโปรไฟล์สำเร็จ');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('บันทึกไม่สำเร็จ: $e');
    }
  }

  /// ✅ ดึงที่อยู่จากคอลเลกชัน users/{uid}
  /// คาดหวังคีย์: line1, subdistrict, district, province, postal_code
  Future<Map<String, dynamic>?> _getProfileAddressFromUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    final d = doc.data() ?? {};
    // ตรวจค่าที่จำเป็น
    if ((d['line1'] ?? '').toString().isEmpty ||
        (d['subdistrict'] ?? '').toString().isEmpty ||
        (d['district'] ?? '').toString().isEmpty ||
        (d['province'] ?? '').toString().isEmpty ||
        (d['postal_code'] ?? '').toString().isEmpty) {
      return null;
    }
    // โครง install_address ให้สอดคล้องกับรูป Firestore ของคุณ
    return {
      'label': 'ตำแหน่งทุ่น', // ใส่ label เองได้
      'line1': d['line1'],
      'subdistrict': d['subdistrict'],
      'district': d['district'],
      'province': d['province'],
      'postal_code': d['postal_code'],
      'note': d['note'] ?? '',
    };
  }

  /// ✅ เขียน/อัปเดตเอกสาร buoy_registry/{buoyCode}
  /// - เซ็ต active=true, buoy_id, created_at(ครั้งแรก), updated_at(ทุกครั้ง)
  /// - merge:true เพื่อไม่ทับ field อื่น เช่น location, sensor ฯลฯ
  Future<void> _saveInstallAddressToRegistry({
    required String buoyCode,
    required Map<String, dynamic> installAddress,
  }) async {
    final ref =
        FirebaseFirestore.instance.collection('buoy_registry').doc(buoyCode);

    final now = FieldValue.serverTimestamp();

    await ref.set({
      'buoy_id': buoyCode,
      'active': true,
      'install_address': installAddress,
      'updated_at': now,
      'created_at':
          now, // ถ้ามีอยู่แล้ว Firestore จะเวลากลบด้วย set/merge? → ไม่เป็นไร
    }, SetOptions(merge: true));
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ✅ กรอบสีขาว - Buoy Code Section
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
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
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

                    // ✅ Use Address from Profile
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

                    // ✅ Enter New Address
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
          ]),
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
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF003366).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
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
            child: Icon(icon,
                color: selected ? Colors.white : const Color(0xFF003366),
                size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600)),
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

/// ------------------------------------------------------------
/// BuoyAddressInformationScreen
/// - กรอกที่อยู่ใหม่ (Province/District/Subdistrict auto)
/// - บันทึก install_address ลง buoy_registry/{buoy_code}
/// ------------------------------------------------------------
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
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
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
    setState(
        () => _provinces = List<String>.from(data.map((e) => e['name_th'])));
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _villageController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_houseNumberController.text.isEmpty ||
        _villageController.text.isEmpty ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedSubdistrict == null ||
        _postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')));
      return;
    }

    final installAddress = {
      'label': 'ตำแหน่งทุ่น',
      'line1': _houseNumberController.text.trim() +
          (_villageController.text.trim().isEmpty
              ? ''
              : ', ${_villageController.text.trim()}'),
      'subdistrict': _selectedSubdistrict,
      'district': _selectedDistrict,
      'province': _selectedProvince,
      'postal_code': _postalCodeController.text.trim(),
      'note': '',
    };

    try {
      await FirebaseFirestore.instance
          .collection('buoy_registry')
          .doc(widget.buoyCode)
          .set({
        'buoy_id': widget.buoyCode,
        'active': true,
        'install_address': installAddress,
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('เพิ่มทุ่นสำเร็จ')));
      Navigator.pop(context); // กลับไปหน้า AddBuoy
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
          onPressed: () => Navigator.pop(context),
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
                  _buildLabel('House Number'),
                  TextField(
                    controller: _houseNumberController,
                    decoration: _inputStyle(Icons.home, 'Enter house number'),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Village / Soi / Street'),
                  TextField(
                    controller: _villageController,
                    decoration: _inputStyle(
                        Icons.signpost, 'Enter village, soi or street'),
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
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      );

  InputDecoration _dropdownStyle(IconData icon, String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF003366)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      );

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: '',
                style: TextStyle(),
              ),
            ],
          ),
        ),
      );
}
