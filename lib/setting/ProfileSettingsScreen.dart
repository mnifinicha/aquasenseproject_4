import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;
  String? _userEmail;

  List<String> _provinces = [];
  List<String> _districts = [];
  List<String> _subdistricts = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await getProvinces();
      setState(() {
        _provinces
          ..clear()
          ..addAll(provinces);
      });
    } catch (e) {
      debugPrint('❌ Error loading provinces: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          _userEmail = data['email'] ?? user.email ?? '';
          _firstNameController.text = data['firstname'] ?? '';
          _lastNameController.text = data['lastname'] ?? '';
          _addressController.text = data['address'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _selectedProvince = data['province'];
          _selectedDistrict = data['district'];
          _selectedSubdistrict = data['subdistrict'];
          _postalCodeController.text = data['postal_code'] ?? '';
        });

        // preload อำเภอ/ตำบล
        if (_selectedProvince != null) {
          final districts = await getDistricts(_selectedProvince!);
          setState(() {
            _districts.addAll(districts);
          });

          if (_selectedDistrict != null) {
            final subs =
                await getSubDistricts(_selectedProvince!, _selectedDistrict!);
            setState(() {
              _subdistricts.addAll(subs);
            });
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedSubdistrict == null) {
      _showSnackBar('กรุณาเลือกจังหวัด อำเภอ และตำบล', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final first = _firstNameController.text.trim();
      final last = _lastNameController.text.trim();
      final fullName =
          (first.isNotEmpty && last.isNotEmpty) ? '$first $last' : first;

      // 1) อัปเดตใน Firestore
      final data = {
        'firstname': first,
        'lastname': last,
        'address': _addressController.text.trim(),
        'province': _selectedProvince,
        'district': _selectedDistrict,
        'subdistrict': _selectedSubdistrict,
        'postal_code': _postalCodeController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(data);

      // 2) อัปเดตชื่อใน Firebase Auth ด้วย → จะไปเปลี่ยนตรง Welcome back, ...
      await user.updateDisplayName(fullName);

      _showSnackBar('บันทึกข้อมูลสำเร็จ', Colors.green);
      // ✅ เด้งกลับไปหน้า dashboard
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard', // ← ใส่ชื่อ route ของหน้า Dashboard ของคุณ
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildAccountSection(),
                            const SizedBox(height: 20),
                            _buildPersonalSection(),
                            const SizedBox(height: 20),
                            _buildAddressSection(),
                            const SizedBox(height: 20),
                            _buildContactSection(),
                            const SizedBox(height: 32),
                            _buildSaveButton(),
                            const SizedBox(height: 24),
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Profile Settings',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon: Icons.account_circle, title: 'User Account'),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.email_outlined, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Text(
                _userEmail ?? '-',
                style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon: Icons.person_outline, title: 'Profile Settings'),
          const SizedBox(height: 20),
          _buildLabel('First Name', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _firstNameController,
            hintText: 'กรอกชื่อจริง',
            prefixIcon: Icons.person_outline,
            validator: (v) => v?.isEmpty ?? true ? 'กรุณากรอกชื่อจริง' : null,
          ),
          const SizedBox(height: 16),
          _buildLabel('Last Name', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _lastNameController,
            hintText: 'กรอกนามสกุล',
            prefixIcon: Icons.person_outline,
            validator: (v) => v?.isEmpty ?? true ? 'กรุณากรอกนามสกุล' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon: Icons.home_outlined, title: 'Address'),
          const SizedBox(height: 20),
          _buildLabel('Address', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _addressController,
            hintText: 'เช่น 123 หมู่บ้านพฤกษา 45 ซอย 6',
            prefixIcon: Icons.home_outlined,
            validator: (v) =>
                v?.isEmpty ?? true ? 'กรุณากรอกรายละเอียดที่อยู่' : null,
          ),
          const SizedBox(height: 16),
          _buildLabel('Province', required: true),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedProvince,
            hint: 'เลือกจังหวัด',
            icon: Icons.location_city_outlined,
            items: _provinces,
            onChanged: (value) async {
              setState(() {
                _selectedProvince = value;
                _selectedDistrict = null;
                _selectedSubdistrict = null;
                _districts.clear();
                _subdistricts.clear();
                _postalCodeController.clear();
              });
              if (value != null) {
                final districts = await getDistricts(value);
                setState(() => _districts.addAll(districts));
              }
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('District', required: true),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedDistrict,
            hint: 'เลือกอำเภอ',
            icon: Icons.map_outlined,
            items: _districts,
            onChanged: (value) async {
              setState(() {
                _selectedDistrict = value;
                _selectedSubdistrict = null;
                _subdistricts.clear();
                _postalCodeController.clear();
              });
              if (_selectedProvince != null && value != null) {
                final subs = await getSubDistricts(_selectedProvince!, value);
                setState(() => _subdistricts.addAll(subs));
              }
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('Subdistrict', required: true),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedSubdistrict,
            hint: 'เลือกตำบล',
            icon: Icons.place_outlined,
            items: _subdistricts,
            onChanged: (value) async {
              setState(() => _selectedSubdistrict = value);
              if (_selectedProvince != null &&
                  _selectedDistrict != null &&
                  value != null) {
                final zipcode = await getPostalCode(
                    _selectedProvince!, _selectedDistrict!, value);
                if (zipcode != null) {
                  setState(() => _postalCodeController.text = zipcode);
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('Postal Code', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _postalCodeController,
            hintText: 'รหัสไปรษณีย์',
            prefixIcon: Icons.markunread_mailbox_outlined,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              icon: Icons.phone_outlined, title: 'Contact Information'),
          const SizedBox(height: 20),
          _buildLabel('Phone Number', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hintText: '0812345678',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              if (v?.isEmpty ?? true) return 'กรุณากรอกเบอร์โทร';
              if (!RegExp(r'^0\d{9}$').hasMatch(v!)) {
                return 'เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 10 หลัก';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _updateUserData,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Save',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  // ────────────── Helper Widgets ──────────────
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF1976D2), size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2), size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  // ────────────── JSON Helpers ──────────────
  Future<List<String>> getProvinces() async {
    final jsonString =
        await rootBundle.loadString('assets/thai_data/provinces.json');
    final List data = json.decode(jsonString);
    return List<String>.from(data.map((e) => e['name_th']));
  }

  Future<List<String>> getDistricts(String province) async {
    final provinceJson =
        await rootBundle.loadString('assets/thai_data/provinces.json');
    final districtJson =
        await rootBundle.loadString('assets/thai_data/districts.json');
    final List provinces = json.decode(provinceJson);
    final List districts = json.decode(districtJson);
    final provinceId = provinces.firstWhere((e) => e['name_th'] == province,
        orElse: () => {})['id'];
    return List<String>.from(districts
        .where((e) => e['province_id'] == provinceId)
        .map((e) => e['name_th']));
  }

  Future<List<String>> getSubDistricts(String province, String district) async {
    final districtJson =
        await rootBundle.loadString('assets/thai_data/districts.json');
    final subJson =
        await rootBundle.loadString('assets/thai_data/sub_districts.json');
    final List districts = json.decode(districtJson);
    final List subs = json.decode(subJson);
    final districtId = districts.firstWhere((e) => e['name_th'] == district,
        orElse: () => {})['id'];
    return List<String>.from(subs
        .where((e) => e['district_id'] == districtId)
        .map((e) => e['name_th']));
  }

  Future<String?> getPostalCode(
      String province, String district, String subDistrict) async {
    final subJson =
        await rootBundle.loadString('assets/thai_data/sub_districts.json');
    final districtJson =
        await rootBundle.loadString('assets/thai_data/districts.json');
    final List subs = json.decode(subJson);
    final List districts = json.decode(districtJson);
    final districtId = districts.firstWhere((e) => e['name_th'] == district,
        orElse: () => {})['id'];
    final sub = subs.firstWhere(
      (e) => e['district_id'] == districtId && e['name_th'] == subDistrict,
      orElse: () => {},
    );
    return sub.isNotEmpty ? sub['zip_code'].toString() : null;
  }
}
