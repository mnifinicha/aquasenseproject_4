import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:aquasenseproject/addbuoy/addbuoy.dart';

class AddressInformationScreen extends StatefulWidget {
  const AddressInformationScreen({Key? key}) : super(key: key);

  @override
  State<AddressInformationScreen> createState() =>
      _AddressInformationScreenState();
}

class _AddressInformationScreenState extends State<AddressInformationScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;
  bool _agreedToTerms = false;

  List<String> _provinces = [];
  List<String> _districts = [];
  List<String> _subdistricts = [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _houseNumberController.dispose();
    _villageController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _saveUserToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // ถ้ายังไม่ได้ login จะใช้ timestamp เป็น uid ชั่วคราว
      final uid = user?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': _firstNameController.text.trim(),
        'surname': _lastNameController.text.trim(),
        'line1': _houseNumberController.text.trim(),
        'village': _villageController.text.trim(),
        'province': _selectedProvince,
        'district': _selectedDistrict,
        'subdistrict': _selectedSubdistrict,
        'postal_code': _postalCodeController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': user?.email ?? '',
        'role': 'user',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true)); // ป้องกันทับ field อื่นใน doc เดิม

      debugPrint('✅ Firestore: User saved successfully');
    } catch (e) {
      debugPrint('❌ Firestore save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces
          ..clear()
          ..addAll(provinces);
      });
    } catch (e) {
      debugPrint('❌ Error loading provinces: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
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
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Address Information',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      Container(
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
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1976D2),
                                        Color(0xFF42A5F5)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Personal Information',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // First Name
                            _buildLabel('First Name', required: true),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _firstNameController,
                              hintText: 'Enter your first name',
                              prefixIcon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Last Name
                            _buildLabel('Last Name', required: true),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _lastNameController,
                              hintText: 'Enter your last name',
                              prefixIcon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Address Section
                      Container(
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
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1976D2),
                                        Color(0xFF42A5F5)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.home_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Container',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // House Number
                            _buildLabel('House Number', required: true),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _houseNumberController,
                              hintText: 'Enter house number',
                              prefixIcon: Icons.house_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter house number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Village / Soi / Street
                            _buildLabel('Village / Soi / Street',
                                required: true),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _villageController,
                              hintText: 'Enter village, soi or street',
                              prefixIcon: Icons.signpost_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter village/soi/street';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Province
                            _buildLabel('Province', required: true),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: _selectedProvince,
                              hint: 'Select province',
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
                                  if (!mounted) return;
                                  setState(() {
                                    _districts.addAll(districts);
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // District
                            _buildLabel('District', required: true),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: _selectedDistrict,
                              hint: 'Select district',
                              icon: Icons.map_outlined,
                              items: _districts,
                              onChanged: (value) async {
                                setState(() {
                                  _selectedDistrict = value;
                                  _selectedSubdistrict = null;
                                  _subdistricts.clear();
                                  _postalCodeController.clear();
                                });
                                if (_selectedProvince != null &&
                                    value != null) {
                                  final subdistricts = await getSubDistricts(
                                      _selectedProvince!, value);
                                  if (!mounted) return;
                                  setState(() {
                                    _subdistricts.addAll(subdistricts);
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Subdistrict
                            _buildLabel('Subdistrict', required: true),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: _selectedSubdistrict,
                              hint: 'Select subdistrict',
                              icon: Icons.place_outlined,
                              items: _subdistricts,
                              onChanged: (value) async {
                                setState(() {
                                  _selectedSubdistrict = value;
                                });
                                if (_selectedProvince != null &&
                                    _selectedDistrict != null &&
                                    value != null) {
                                  final zipcode = await getPostalCode(
                                      _selectedProvince!,
                                      _selectedDistrict!,
                                      value);
                                  if (zipcode != null) {
                                    if (!mounted) return;
                                    setState(() {
                                      _postalCodeController.text = zipcode;
                                    });
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Postal Code (read-only)
                            _buildLabel('Postal Code', required: true),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _postalCodeController,
                              hintText: 'Enter postal code',
                              prefixIcon: Icons.markunread_mailbox_outlined,
                              keyboardType: TextInputType.number,
                              readOnly: true, // 🔒 ล็อกไม่ให้แก้เอง
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter postal code';
                                }
                                if (value.length != 5) {
                                  return 'Postal code must be 5 digits';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Contact Information
                      Container(
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
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1976D2),
                                        Color(0xFF42A5F5)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.contact_phone_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Contact Information',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _buildLabel('Phone Number', required: true),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _phoneController,
                              hintText: 'กรอกเบอร์โทร 10 หลัก เช่น 0812345678',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกเบอร์โทรศัพท์';
                                }
                                if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                                  return 'เบอร์โทรต้องขึ้นต้นด้วยเลข 0 และมีทั้งหมด 10 หลัก';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Terms & Conditions
                      Container(
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
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1976D2),
                                        Color(0xFF42A5F5)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Terms & Conditions',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            InkWell(
                              onTap: () {
                                setState(() {
                                  _agreedToTerms = !_agreedToTerms;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _agreedToTerms
                                      ? const Color(0xFF1976D2)
                                          .withOpacity(0.05)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _agreedToTerms
                                        ? const Color(0xFF1976D2)
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _agreedToTerms
                                            ? const Color(0xFF1976D2)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _agreedToTerms
                                              ? const Color(0xFF1976D2)
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: _agreedToTerms
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'I agree to the terms of service and privacy policy for buoy location data collection and monitoring services.',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.5,
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

                      const SizedBox(height: 32),

                      // ✅ Next Button (ตัวจริง ใช้งานได้)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_selectedProvince == null ||
                                  _selectedDistrict == null ||
                                  _selectedSubdistrict == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.warning,
                                            color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Please select all required fields',
                                          style: GoogleFonts.inter(),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                                return;
                              }

                              if (!_agreedToTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.warning,
                                            color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Please agree to the terms and conditions',
                                          style: GoogleFonts.inter(),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                                return;
                              }

                              // ✅ 1. บันทึกข้อมูลลง Firestore
                              await _saveUserToFirestore();

                              // ✅ 2. แจ้งเตือนสำเร็จ
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Information saved successfully!',
                                        style: GoogleFonts.inter(),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              // ✅ 3. ไปหน้า AddBuoyScreen หลังจากบันทึกเสร็จ
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddBuoyScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            shadowColor:
                                const Color(0xFF1976D2).withOpacity(0.3),
                          ),
                          child: Text(
                            'Next',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

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
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: Colors.black87,
      ),
      validator: validator,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        counterText: maxLength != null ? '' : null,
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF1976D2),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: Color(0xFF1976D2),
            width: 2,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF1976D2),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(
              color: Color(0xFF1976D2),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.black87,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ✅ โหลดจังหวัดทั้งหมด
  Future<List<String>> getProvinces() async {
    final jsonString =
        await rootBundle.loadString('assets/thai_data/provinces.json');
    final List data = json.decode(jsonString);
    return List<String>.from(data.map((e) => e['name_th']));
  }

  // ✅ โหลดอำเภอตามจังหวัด
  Future<List<String>> getDistricts(String province) async {
    final provinceJson =
        await rootBundle.loadString('assets/thai_data/provinces.json');
    final districtJson =
        await rootBundle.loadString('assets/thai_data/districts.json');

    final List provinces = json.decode(provinceJson);
    final List districts = json.decode(districtJson);

    final provinceId = provinces.firstWhere(
      (e) => e['name_th'] == province,
      orElse: () => {},
    )['id'];

    return List<String>.from(
      districts
          .where((e) => e['province_id'] == provinceId)
          .map((e) => e['name_th']),
    );
  }

  // ✅ โหลดตำบลตามอำเภอ
  Future<List<String>> getSubDistricts(String province, String district) async {
    final districtJson =
        await rootBundle.loadString('assets/thai_data/districts.json');
    final subJson =
        await rootBundle.loadString('assets/thai_data/sub_districts.json');

    final List districts = json.decode(districtJson);
    final List subs = json.decode(subJson);

    final districtId = districts.firstWhere(
      (e) => e['name_th'] == district,
      orElse: () => {},
    )['id'];

    return List<String>.from(
      subs
          .where((e) => e['district_id'] == districtId)
          .map((e) => e['name_th']),
    );
  }

  // ✅ ดึงรหัสไปรษณีย์
  Future<String?> getPostalCode(
      String province, String district, String subDistrict) async {
    final subJson =
        await rootBundle.loadString('assets/thai_data/sub_districts.json');
    final districtJson =
        await rootBundle.loadString('assets/thai_data/districts.json');

    final List subs = json.decode(subJson);
    final List districts = json.decode(districtJson);

    final districtId = districts.firstWhere(
      (e) => e['name_th'] == district,
      orElse: () => {},
    )['id'];

    final sub = subs.firstWhere(
      (e) => e['district_id'] == districtId && e['name_th'] == subDistrict,
      orElse: () => {},
    );

    return sub.isNotEmpty ? sub['zip_code'].toString() : null;
  }
}
