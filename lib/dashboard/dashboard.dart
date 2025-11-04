import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../navigation/custom_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "-";

  int _selectedIndex = 0;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _dataSubscription;
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  StreamSubscription<DatabaseEvent>? _stateSubscription;

  String? selectedBuoyId;
  List<String> buoyIds = [];

  Map<String, dynamic> sensorData = {};
  double totalScore = 0.0;
  bool isLoading = true;
  bool hasData = false;

  DateTime? lastUpdated;
  double _rotationAngle = 0;

  Map<String, bool> sensorStatus = {
    'PH': false,
    'TDS/EC': false,
    'Turbidity': false,
    'Temperature': false,
    'Rain': false,
  };

  // เก็บสถานะ offline รายเซนเซอร์
  Map<String, bool> _sensorOfflineMap = {
    'ph': false,
    'tds': false,
    'ec': false,
    'turbidity': false,
    'temperature': false,
    'rainfall': false,
  };

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadBuoyList();
  }

  // ⬇️ ดึงชื่อจาก Firestore
  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final firstName = data['firstname']?.toString() ?? '';

        setState(() {
          _userName = firstName.isNotEmpty ? firstName : 'User';
        });
      } else {
        setState(() {
          _userName = 'User';
        });
      }
    } catch (e) {
      print('❌ Error loading user name: $e');
    }
  }

  void _onNavTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/add');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/forecast');
        break;
    }
  }

  // ⬇️ ดึงทุ่นของ user จาก Firestore
  Future<void> _loadBuoyList() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final registrySnap = await FirebaseFirestore.instance
          .collection('buoy_registry')
          .where('uid', isEqualTo: user.uid)
          .where('active', isEqualTo: true)
          .get();

      if (registrySnap.docs.isEmpty) {
        setState(() {
          buoyIds = [];
          selectedBuoyId = null;
          hasData = false;
          isLoading = false;
        });
        return;
      }

      final userBuoyIds = registrySnap.docs
          .map((doc) => doc.data()['buoy_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      setState(() {
        buoyIds = userBuoyIds;
        if (buoyIds.isNotEmpty) {
          selectedBuoyId = buoyIds.first;
          _loadBuoyData();
        } else {
          selectedBuoyId = null;
          hasData = false;
        }
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading buoy list: $e');
      setState(() => isLoading = false);
    }
  }

  // ⬇️ โหลดข้อมูล Realtime DB ของทุ่นนั้นๆ
  Future<void> _loadBuoyData() async {
    if (selectedBuoyId == null) return;

    // ยกเลิก listener เดิม
    await _dataSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _stateSubscription?.cancel();

    // รีเซ็ตค่าเริ่ม
    setState(() {
      sensorStatus = {
        'PH': false,
        'TDS/EC': false,
        'Turbidity': false,
        'Temperature': false,
        'Rain': false,
      };
      sensorData = {
        'ph': "-",
        'tds': "-",
        'ec': "-",
        'turbidity': "-",
        'temperature': "-",
        'rainfall': "-",
      };
      _sensorOfflineMap.updateAll((k, v) => true);
      totalScore = 0.0;
      hasData = false;
    });

    // 1) โหลด state เริ่มต้น
    try {
      final stateSnap =
          await _database.child('buoys/$selectedBuoyId/status/state').get();
      if (stateSnap.exists) {
        _updateGlobalState(stateSnap.value);
      } else {
        // ถ้าไม่มี state → ให้ถือว่า online ไปเลย
        setState(() {
          sensorStatus.updateAll((key, value) => true);
          _sensorOfflineMap.updateAll((key, value) => false);
        });
      }
    } catch (e) {
      print('❌ Error loading initial state: $e');
    }

    // 2) โหลด per_sensor เริ่มต้น
    try {
      final perSensorSnap = await _database
          .child('buoys/$selectedBuoyId/status/per_sensor')
          .get();
      if (perSensorSnap.exists) {
        final perValue = perSensorSnap.value;
        if (perValue is Map) _updatePerSensorStatus(perValue);
      } else {
        // ถ้าไม่มี per_sensor → ถือว่า online ทุกตัว
        setState(() {
          sensorStatus.updateAll((key, value) => true);
          _sensorOfflineMap.updateAll((key, value) => false);
        });
      }
    } catch (e) {
      print('❌ Error loading per_sensor: $e');
    }

    // 3) ฟัง history ล่าสุด (ค่าเซนเซอร์)
    _dataSubscription = _database
        .child('buoys/$selectedBuoyId/history')
        .limitToLast(1)
        .onValue
        .listen((DatabaseEvent event) {
      final historySnapshot = event.snapshot;
      if (!historySnapshot.exists || _isDisposed) return;

      final historyData =
          Map<String, dynamic>.from(historySnapshot.value as Map);
      final latestDate = historyData.keys.last;
      final dateData =
          Map<String, dynamic>.from(historyData[latestDate] as Map);
      final latestTimestamp = dateData.keys.last;
      final latestData =
          Map<String, dynamic>.from(dateData[latestTimestamp] as Map);

      setState(() {
        // อัปเดตค่าจริง
        sensorData['ph'] = latestData['ph'] ?? "-";
        sensorData['tds'] = latestData['tds'] ?? "-";
        sensorData['ec'] = latestData['ec'] ?? "-";
        sensorData['turbidity'] = latestData['turbidity'] ?? "-";
        sensorData['temperature'] = latestData['temperature'] ?? "-";
        sensorData['rainfall'] = latestData['rainfall'] ?? "-";

        totalScore = _toDouble(latestData['total_score']);

        if (latestData['timestamp_ms'] != null) {
          lastUpdated =
              DateTime.fromMillisecondsSinceEpoch(latestData['timestamp_ms']);
        } else if (latestData['timestamp_iso'] != null) {
          lastUpdated = DateTime.parse(latestData['timestamp_iso']);
        } else {
          lastUpdated = DateTime.now();
        }

        hasData = true;
        isLoading = false;

        // ถ้ามี data แล้ว แต่ per_sensor ยังไม่ได้ส่งมา → ถือว่า online
        sensorStatus.updateAll((key, value) => true);
        _sensorOfflineMap.updateAll((key, value) => false);
      });

      print('✅ Updated history data: $latestData');
    });

    // 4) ฟัง per_sensor แบบ realtime
    _sensorSubscription = _database
        .child('buoys/$selectedBuoyId/status/per_sensor')
        .onValue
        .listen((DatabaseEvent event) {
      if (_isDisposed) return;
      final value = event.snapshot.value;
      if (value != null && value is Map) {
        _updatePerSensorStatus(value);
      } else {
        // ถ้าไม่มีค่าเลย ก็อย่าให้มันเป็นแดงทั้งหมด
        setState(() {
          sensorStatus.updateAll((key, value) => true);
          _sensorOfflineMap.updateAll((key, value) => false);
        });
      }
    });

    // 5) ฟัง state (online/offline)
    _stateSubscription = _database
        .child('buoys/$selectedBuoyId/status/state')
        .onValue
        .listen((DatabaseEvent event) {
      if (_isDisposed) return;
      final value = event.snapshot.value;
      _updateGlobalState(value);
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ⬇️ อัปเดตสถานะรายเซนเซอร์
  void _updatePerSensorStatus(Map value) {
    final perSensor = Map<String, dynamic>.from(value);
    bool isOnline(v) =>
        v != null && v.toString().trim().toLowerCase() == 'online';

    final phOnline = isOnline(perSensor['ph']);
    final ecOnline = isOnline(perSensor['ec']);
    final tdsOnline = isOnline(perSensor['tds']);
    final turbidityOnline = isOnline(perSensor['turbidity']);
    final tempOnline = isOnline(perSensor['temperature']);
    final rainOnline = isOnline(perSensor['rainfall']);

    setState(() {
      sensorStatus['PH'] = phOnline;
      sensorStatus['TDS/EC'] = ecOnline && tdsOnline;
      sensorStatus['Turbidity'] = turbidityOnline;
      sensorStatus['Temperature'] = tempOnline;
      sensorStatus['Rain'] = rainOnline;

      _sensorOfflineMap['ph'] = !phOnline;
      _sensorOfflineMap['tds'] = !tdsOnline;
      _sensorOfflineMap['ec'] = !ecOnline;
      _sensorOfflineMap['turbidity'] = !turbidityOnline;
      _sensorOfflineMap['temperature'] = !tempOnline;
      _sensorOfflineMap['rainfall'] = !rainOnline;

      if (!phOnline) sensorData['ph'] = "-";
      if (!tdsOnline) sensorData['tds'] = "-";
      if (!ecOnline) sensorData['ec'] = "-";
      if (!turbidityOnline) sensorData['turbidity'] = "-";
      if (!tempOnline) sensorData['temperature'] = "-";
      if (!rainOnline) sensorData['rainfall'] = "-";
    });

    // ถ้ามีตัวไหน offline/delayed → WQI = 0 ได้เลย
    bool anySensorOffline = perSensor.values.any((v) {
      final s = v.toString().trim().toLowerCase();
      return s == 'offline' || s == 'delayed';
    });

    if (anySensorOffline) {
      setState(() => totalScore = 0.0);
    }
  }

  // ⬇️ อัปเดต global state
  void _updateGlobalState(dynamic stateValue) {
    final state = stateValue?.toString().trim().toLowerCase() ?? '';

    if (state == 'offline') {
      setState(() {
        totalScore = 0.0;
        _sensorOfflineMap.updateAll((key, value) => true);
        sensorStatus.updateAll((key, value) => false);
        sensorData.updateAll((key, value) => "-");
      });
    } else if (state == 'online') {
      // ออนไลน์ก็ไม่ต้องทำอะไร ปล่อยให้ per_sensor จัดการ
    } else {
      // ถ้าไม่มีค่าเลย ให้ถือว่า online
      setState(() {
        sensorStatus.updateAll((key, value) => true);
        _sensorOfflineMap.updateAll((key, value) => false);
      });
    }
  }

  double _calculateScore(String sensorType, double value) {
    switch (sensorType) {
      case 'PH':
        if (value >= 6.5 && value <= 8.599999) return 85.5;
        if ((value >= 6.0 && value < 6.5) || (value >= 8.6 && value <= 9.09)) {
          return 60.0;
        }
        return 24.5;

      case 'TDS':
        if (value >= 0 && value <= 599) return 85.5;
        if (value >= 600 && value <= 900) return 60.0;
        return 24.5;

      case 'EC':
        if (value >= 0 && value <= 894) return 85.5;
        if (value >= 895 && value <= 1343) return 60.0;
        return 24.5;

      case 'Turbidity':
        if (value >= 0 && value <= 25) return 85.5;
        if (value >= 26 && value <= 100) return 60.0;
        return 24.5;

      case 'Temperature':
        if (value >= 26 && value <= 30) return 85.5;
        if ((value >= 23 && value < 26) || (value >= 31 && value <= 33)) {
          return 60.0;
        }
        return 24.5;

      case 'Rain':
        if (value >= 683 && value <= 1023) return 85.5;
        if (value >= 342 && value < 683) return 60.0;
        return 24.5;

      default:
        return 0.0;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 71) return Colors.green;
    if (score >= 50) return Colors.yellow;
    return Colors.red;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dataSubscription?.cancel();
    _sensorSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  void _showLineQRDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add us on LINE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/line_qr.png',
                  width: 230,
                  height: 230,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'สแกน QR Code เพื่อเพิ่มเพื่อน',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
              Color(0xFF7DB9E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 20),
                        child: Column(
                          children: [
                            _buildBuoySelector(),
                            const SizedBox(height: 20),
                            if (hasData) ...[
                              _buildWaterQualityCard(),
                              const SizedBox(height: 20),
                              _buildSensorGrid(),
                              const SizedBox(height: 20),
                              _buildSensorStatus(),
                            ] else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text(
                                    'No data available',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
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
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        // ถ้าอยากให้กดแล้วสลับหน้า เปิดอันนี้: onTap: _onNavTapped,
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,',
                  style:
                      GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
              Text(
                _userName,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.line, color: Colors.white),
                onPressed: _showLineQRDialog,
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/profile-settings');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuoySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a buoy to monitor',
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: selectedBuoyId,
            isExpanded: true,
            items: buoyIds
                .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedBuoyId = value;
                _loadBuoyData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWaterQualityCard() {
    final statusColor = _getColor(totalScore);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Water Quality Index',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: totalScore / 100,
                progressColor: _getColor(totalScore),
                backgroundColor: Colors.grey[200]!,
              ),
              child: Center(
                child: Text(
                  '${totalScore.toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: _getColor(totalScore),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Status: ${_getStatus(totalScore)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (lastUpdated != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _rotationAngle / (2 * math.pi),
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3C72),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.refresh,
                            color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(lastUpdated!),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildSensorCard('PH', sensorData['ph'] ?? 0.0, ''),
        _buildSensorCard('TDS', sensorData['tds'] ?? 0.0, 'ppm'),
        _buildSensorCard('EC', sensorData['ec'] ?? 0.0, 'μS/cm'),
        _buildSensorCard('Turbidity', sensorData['turbidity'] ?? 0.0, 'NTU'),
        _buildSensorCard('Temperature', sensorData['temperature'] ?? 0.0, '°C'),
        _buildSensorCard('Rain', sensorData['rainfall'] ?? 0.0, 'ADC'),
      ],
    );
  }

  Widget _buildSensorCard(String title, dynamic value, String unit) {
    double? numValue;
    String displayValue;
    bool isOffline = false;

    if (value is String && value == "-") {
      displayValue = "-";
      isOffline = true;
    } else {
      numValue = _toDouble(value);
      displayValue = numValue.toStringAsFixed(2);
    }

    Color indicatorColor;
    if (isOffline) {
      indicatorColor = Colors.red;
    } else {
      double score = numValue != null ? _calculateScore(title, numValue) : 0.0;
      indicatorColor = _getScoreColor(score);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: indicatorColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(displayValue,
              style:
                  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(unit,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSensorStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Sensor Status",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: sensorStatus.entries.map((entry) {
              final isOnline = entry.value;
              return Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getColor(double score) {
    if (score > 70.00) return Colors.green;
    if (score > 49.00) return Colors.yellow;
    return Colors.red;
  }

  String _getStatus(double score) {
    if (score > 70.00) return 'Excellent';
    if (score > 49.00) return 'Warning';
    return 'Critical';
  }
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $h:$min';
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 12.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
