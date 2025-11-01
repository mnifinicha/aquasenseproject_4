import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBuoyAddressScreen extends StatefulWidget {
  final String buoyCode;
  final Map<String, dynamic> currentAddress;

  const EditBuoyAddressScreen({
    Key? key,
    required this.buoyCode,
    required this.currentAddress,
  }) : super(key: key);

  @override
  State<EditBuoyAddressScreen> createState() => _EditBuoyAddressScreenState();
}

class _EditBuoyAddressScreenState extends State<EditBuoyAddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  List<String> _provinces = [];
  List<String> _districts = [];
  List<String> _subdistricts = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces().then((_) {
      _loadCurrentAddress();
    });
  }

  Future<void> _loadProvinces() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/thai_data/provinces.json');
      final List data = json.decode(jsonStr);
      setState(() {
        _provinces = List<String>.from(data.map((e) => e['name_th']));
      });
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    }
  }

  void _loadCurrentAddress() {
    final addr = widget.currentAddress;
    _addressController.text = addr['line1'] ?? '';
    _selectedProvince = addr['province'];
    _selectedDistrict = addr['district'];
    _selectedSubdistrict = addr['subdistrict'];
    _postalCodeController.text = addr['postal_code'] ?? '';

    if (_selectedProvince != null) {
      _loadDistricts(_selectedProvince!).then((_) {
        if (_selectedDistrict != null) {
          _loadSubdistricts(_selectedProvince!, _selectedDistrict!);
        }
      });
    }
  }

  Future<void> _loadDistricts(String province) async {
    try {
      final provJson =
          await rootBundle.loadString('assets/thai_data/provinces.json');
      final distJson =
          await rootBundle.loadString('assets/thai_data/districts.json');
      final List prov = json.decode(provJson);
      final List dist = json.decode(distJson);
      final provId = prov.firstWhere((e) => e['name_th'] == province)['id'];
      setState(() {
        _districts = List<String>.from(dist
            .where((e) => e['province_id'] == provId)
            .map((e) => e['name_th']));
      });
    } catch (e) {
      debugPrint('Error loading districts: $e');
    }
  }

  Future<void> _loadSubdistricts(String province, String district) async {
    try {
      final distJson =
          await rootBundle.loadString('assets/thai_data/districts.json');
      final subJson =
          await rootBundle.loadString('assets/thai_data/sub_districts.json');
      final List dist = json.decode(distJson);
      final List subs = json.decode(subJson);
      final distId = dist.firstWhere((e) => e['name_th'] == district)['id'];
      setState(() {
        _subdistricts = List<String>.from(subs
            .where((e) => e['district_id'] == distId)
            .map((e) => e['name_th']));
      });
    } catch (e) {
      debugPrint('Error loading subdistricts: $e');
    }
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.isEmpty ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedSubdistrict == null ||
        _postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final installAddress = {
        'label': 'ตำแหน่งทุ่น',
        'line1': _addressController.text.trim(),
        'subdistrict': _selectedSubdistrict,
        'district': _selectedDistrict,
        'province': _selectedProvince,
        'postal_code': _postalCodeController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('buoy_registry')
          .doc(widget.buoyCode)
          .update({
        'install_address': installAddress,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แก้ไขที่อยู่สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
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
          'Edit Address',
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
          child: Container(
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
                        Icons.edit_location,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Buoy Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            widget.buoyCode,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel('Address'),
                TextField(
                  controller: _addressController,
                  decoration: _inputStyle(Icons.home, '198/114'),
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
                    if (value != null) {
                      await _loadDistricts(value);
                    }
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
                    if (value != null && _selectedProvince != null) {
                      await _loadSubdistricts(_selectedProvince!, value);
                    }
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
                    if (value != null) {
                      try {
                        final distJson = await rootBundle
                            .loadString('assets/thai_data/districts.json');
                        final subJson = await rootBundle
                            .loadString('assets/thai_data/sub_districts.json');
                        final List dist = json.decode(distJson);
                        final List subs = json.decode(subJson);
                        final distId = dist.firstWhere(
                            (e) => e['name_th'] == _selectedDistrict)['id'];
                        final sub = subs.firstWhere((e) =>
                            e['district_id'] == distId &&
                            e['name_th'] == value);
                        setState(() {
                          _postalCodeController.text =
                              sub['zip_code'].toString();
                        });
                      } catch (e) {
                        debugPrint('Error loading postal code: $e');
                      }
                    }
                  },
                  decoration: _dropdownStyle(Icons.place, 'Select subdistrict'),
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
                    onPressed: _isLoading ? null : _saveAddress,
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
                            'Save Changes',
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
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red))
            ],
          ),
        ),
      );
}
