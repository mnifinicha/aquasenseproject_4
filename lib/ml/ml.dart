import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// ----------------------
/// Bottom Navigation Bar
/// ----------------------
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF1E3C72),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == currentIndex) return;
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
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
        BottomNavigationBarItem(
            icon: Icon(Icons.show_chart), label: 'Forecast'),
      ],
    );
  }
}

/// ----------------------
/// Model
/// ----------------------
class WaterForecast {
  final DateTime date;
  final double forecastWQI;
  final String forecastLevel;
  final double? actualWQI;
  final String? actualLevel;
  final double? accuracy;
  final Map<String, dynamic>? forecastParams;
  final Map<String, dynamic>? actualParams;

  WaterForecast({
    required this.date,
    required this.forecastWQI,
    required this.forecastLevel,
    this.actualWQI,
    this.actualLevel,
    this.accuracy,
    this.forecastParams,
    this.actualParams,
  });
}

class WaterForecastPage extends StatefulWidget {
  final String buoyId;

  const WaterForecastPage({
    Key? key,
    this.buoyId = 'buoy_001',
  }) : super(key: key);

  @override
  State<WaterForecastPage> createState() => _WaterForecastPageState();
}

class _WaterForecastPageState extends State<WaterForecastPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 3 วันปัจจุบัน
  List<WaterForecast> forecasts = [];

  // สำหรับวันที่เลือกย้อนหลัง
  WaterForecast? _selectedForecast;
  DateTime? _selectedDate;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadForecasts(); // โหลด 3 วันแรกเลย
  }

  // ======================
  // helpers
  // ======================
  DateTime _parseCreatedAt(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return 0.0;
  }

  double _truncateTo(double value, int decimals) {
    final factor = pow(10, decimals);
    return (value * factor).truncateToDouble() / factor;
  }

  // =====================================================
  // 1) โหลด 3 วัน (วันนี้ + 2 วัน)
  // =====================================================
  Future<void> _loadForecasts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final now = DateTime.now();
      final List<String> targetDates = [];
      for (int i = 0; i < 3; i++) {
        final d = now.add(Duration(days: i));
        targetDates.add(DateFormat('yyyy-MM-dd').format(d));
      }

      final snap = await _firestore
          .collection('weekly_forecasts')
          .where('buoy_id', isEqualTo: widget.buoyId)
          .get();

      final List<WaterForecast> loaded = [];

      for (final targetDate in targetDates) {
        // เก็บทุก candidate ที่ตรงวัน
        final List<Map<String, dynamic>> candidates = [];

        for (final doc in snap.docs) {
          final data = doc.data();
          final createdAt = _parseCreatedAt(data['created_at']);
          final daily = data['daily'];

          bool matched = false;
          Map<String, dynamic>? matchedDaily;

          // แบบ array
          if (daily is List) {
            for (final day in daily) {
              if (day is Map<String, dynamic> && day['date'] == targetDate) {
                matched = true;
                matchedDaily = day;
                break;
              }
            }
          }

          // แบบ single
          if (!matched && data['forecast_date'] == targetDate) {
            matched = true;
            matchedDaily = data;
          }

          if (matched && matchedDaily != null) {
            candidates.add({
              'created_at': createdAt,
              'daily': matchedDaily,
            });
          }
        }

        if (candidates.isEmpty) {
          continue;
        }

        // เอาอันที่ created_at ล่าสุด
        candidates.sort((a, b) => (b['created_at'] as DateTime)
            .compareTo(a['created_at'] as DateTime));
        final pickedDaily = candidates.first['daily'] as Map<String, dynamic>;

        // ----- forecast -----
        final wqiObj = pickedDaily['wqi'] as Map<String, dynamic>?;
        double forecastWQI = 0.0;
        String forecastStatus = 'Unknown';
        if (wqiObj != null && wqiObj['value'] != null) {
          forecastWQI = _asDouble(wqiObj['value']);
          forecastStatus = (wqiObj['status'] as String?) ?? 'Unknown';
        } else {
          forecastWQI = _asDouble(pickedDaily['value']);
          forecastStatus = (pickedDaily['status'] as String?) ?? 'Unknown';
        }
        final forecastParams = pickedDaily['params'] as Map<String, dynamic>?;

        // ----- actual -----
        final targetDt = DateFormat('yyyy-MM-dd').parse(targetDate);
        final today = DateTime(now.year, now.month, now.day);
        final reached =
            targetDt.isBefore(today) || targetDt.isAtSameMomentAs(today);

        double? actualWQI;
        String? actualStatus;
        double? accuracy;
        Map<String, dynamic>? actualParams;

        if (reached) {
          final evalSnap = await _firestore
              .collection('forecast_evaluations')
              .where('buoy_id', isEqualTo: widget.buoyId)
              .where('date', isEqualTo: targetDate)
              .get();

          if (evalSnap.docs.isNotEmpty) {
            final evalDocs = [...evalSnap.docs]..sort((a, b) {
                final ad = _parseCreatedAt(a.data()['created_at']);
                final bd = _parseCreatedAt(b.data()['created_at']);
                return bd.compareTo(ad);
              });
            final evalData = evalDocs.first.data();

            final actualObj = evalData['actual'] as Map<String, dynamic>?;
            if (actualObj != null) {
              actualWQI = _asDouble(actualObj['wqi']);
              actualStatus = actualObj['status'] as String?;
              actualParams = actualObj['params'] as Map<String, dynamic>?;
            }

            // ใช้ metrics.wqi ก่อน ถ้าไม่มีค่อยใช้ overall
            final metrics = evalData['metrics'] as Map<String, dynamic>?;
            final wqiMetrics = metrics?['wqi'] as Map<String, dynamic>?;
            final overallMetrics = metrics?['overall'] as Map<String, dynamic>?;

            final wqiAcc = _asDouble(wqiMetrics?['accuracy_pct']);
            final ovAcc = _asDouble(overallMetrics?['accuracy_pct']);
            accuracy = wqiAcc != 0.0 ? wqiAcc : ovAcc;
          }
        }

        loaded.add(
          WaterForecast(
            date: targetDt,
            forecastWQI: forecastWQI,
            forecastLevel: forecastStatus,
            actualWQI: actualWQI,
            actualLevel: actualStatus,
            accuracy: accuracy,
            forecastParams: forecastParams,
            actualParams: actualParams,
          ),
        );
      }

      setState(() {
        forecasts = loaded;
        isLoading = false;
      });
    } catch (e, st) {
      print(e);
      print(st);
      setState(() {
        errorMessage = 'Error loading forecasts: $e';
        isLoading = false;
      });
    }
  }

  // =====================================================
  // 2) โหลดเฉพาะวันย้อนหลัง
  // =====================================================
  Future<void> _loadForecastForDate(DateTime date) async {
    try {
      final targetStr = DateFormat('yyyy-MM-dd').format(date);

      final snap = await _firestore
          .collection('weekly_forecasts')
          .where('buoy_id', isEqualTo: widget.buoyId)
          .get();

      Map<String, dynamic>? pickedDaily;
      DateTime pickedCreated = DateTime.fromMillisecondsSinceEpoch(0);

      for (final doc in snap.docs) {
        final data = doc.data();
        final createdAt = _parseCreatedAt(data['created_at']);
        final daily = data['daily'];

        if (daily is List) {
          for (final day in daily) {
            if (day is Map<String, dynamic> && day['date'] == targetStr) {
              if (createdAt.isAfter(pickedCreated)) {
                pickedCreated = createdAt;
                pickedDaily = day;
              }
            }
          }
        }

        if (data['forecast_date'] == targetStr) {
          if (createdAt.isAfter(pickedCreated)) {
            pickedCreated = createdAt;
            pickedDaily = data;
          }
        }
      }

      if (pickedDaily == null) {
        setState(() {
          _selectedDate = date;
          _selectedForecast = null;
        });
        return;
      }

      // forecast
      final wqiObj = pickedDaily['wqi'] as Map<String, dynamic>?;
      double forecastWQI = 0.0;
      String forecastStatus = 'Unknown';
      if (wqiObj != null && wqiObj['value'] != null) {
        forecastWQI = _asDouble(wqiObj['value']);
        forecastStatus = (wqiObj['status'] as String?) ?? 'Unknown';
      } else {
        forecastWQI = _asDouble(pickedDaily['value']);
        forecastStatus = (pickedDaily['status'] as String?) ?? 'Unknown';
      }
      final forecastParams = pickedDaily['params'] as Map<String, dynamic>?;

      // actual
      double? actualWQI;
      String? actualStatus;
      double? accuracy;
      Map<String, dynamic>? actualParams;

      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final targetDay = DateTime(date.year, date.month, date.day);
      final reached =
          targetDay.isBefore(today) || targetDay.isAtSameMomentAs(today);

      if (reached) {
        final evalSnap = await _firestore
            .collection('forecast_evaluations')
            .where('buoy_id', isEqualTo: widget.buoyId)
            .where('date', isEqualTo: targetStr)
            .get();

        if (evalSnap.docs.isNotEmpty) {
          final evalDocs = [...evalSnap.docs]..sort((a, b) {
              final ad = _parseCreatedAt(a.data()['created_at']);
              final bd = _parseCreatedAt(b.data()['created_at']);
              return bd.compareTo(ad);
            });

          final evalData = evalDocs.first.data();

          final actualObj = evalData['actual'] as Map<String, dynamic>?;
          if (actualObj != null) {
            actualWQI = _asDouble(actualObj['wqi']);
            actualStatus = actualObj['status'] as String?;
            actualParams = actualObj['params'] as Map<String, dynamic>?;
          }

          final metrics = evalData['metrics'] as Map<String, dynamic>?;
          final wqiMetrics = metrics?['wqi'] as Map<String, dynamic>?;
          final overallMetrics = metrics?['overall'] as Map<String, dynamic>?;

          final wqiAcc = _asDouble(wqiMetrics?['accuracy_pct']);
          final ovAcc = _asDouble(overallMetrics?['accuracy_pct']);
          accuracy = wqiAcc != 0.0 ? wqiAcc : ovAcc;
        }
      }

      setState(() {
        _selectedDate = date;
        _selectedForecast = WaterForecast(
          date: targetDay,
          forecastWQI: forecastWQI,
          forecastLevel: forecastStatus,
          actualWQI: actualWQI,
          actualLevel: actualStatus,
          accuracy: accuracy,
          forecastParams: forecastParams,
          actualParams: actualParams,
        );
      });
    } catch (e, st) {
      print(e);
      print(st);
      setState(() {
        _selectedDate = date;
        _selectedForecast = null;
      });
    }
  }

  // ============================
  // DEBUG
  // ============================
  Future<void> _debugFetchTodayAll() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snap = await _firestore
        .collection('weekly_forecasts')
        .where('buoy_id', isEqualTo: widget.buoyId)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final daily = data['daily'];
      if (daily is List) {
        for (final d in daily) {
          if (d is Map<String, dynamic> && d['date'] == today) {
            print('doc: ${doc.id}');
            print('created_at: ${data['created_at']}');
            print('wqi: ${d['wqi']}');
            print('params: ${d['params']?.keys.toList()}');
          }
        }
      }
    }
  }

  // ============================
  // UI Helpers
  // ============================
  Color _getWQIColor(double wqi) {
    if (wqi >= 80) return Colors.green;
    if (wqi >= 60) return Colors.orange;
    if (wqi >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatStatus(String status) {
    const statusMap = {
      'good': 'Good',
      'excellent': 'Excellent',
      'moderate': 'Moderate',
      'poor': 'Poor',
      'ดีมาก': 'Excellent',
      'ดี': 'Good',
      'ปานกลาง': 'Moderate',
    };
    return statusMap[status.toLowerCase()] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Water Quality Forecast',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.black),
            onPressed: _debugFetchTodayAll,
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : RefreshIndicator(
                    onRefresh: _loadForecasts,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== ปุ่มเลือกวันย้อนหลัง =====
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Row(
                              children: [
                                const Text(
                                  'ดูข้อมูลย้อนหลัง:',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    _selectedDate == null
                                        ? 'เลือกวันที่'
                                        : DateFormat('d MMM yyyy')
                                            .format(_selectedDate!),
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _selectedDate ?? DateTime.now(),
                                      firstDate: DateTime(2024, 1, 1),
                                      lastDate: DateTime(2030, 12, 31),
                                    );
                                    if (picked != null) {
                                      await _loadForecastForDate(picked);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ===== 3 วันล่าสุด =====
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Latest forecasts (3 days)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800]),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (forecasts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No forecasts available'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: forecasts.length,
                              itemBuilder: (context, index) {
                                return _buildForecastCard(forecasts[index]);
                              },
                            ),

                          // ===== ถ้าเลือกย้อนหลังได้ =====
                          if (_selectedDate != null) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Selected date',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800]),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedForecast == null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'No forecast for this date',
                                    style: TextStyle(color: Colors.red[400]),
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: _buildForecastCard(_selectedForecast!),
                              ),
                          ],

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ========================================
  // การ์ด 1 ใบ
  // ========================================
  Widget _buildForecastCard(WaterForecast f) {
    final hasActual = f.actualWQI != null;
    final forecastColor = _getWQIColor(f.forecastWQI);
    final actualColor = hasActual ? _getWQIColor(f.actualWQI!) : Colors.grey;

    return GestureDetector(
      onTap: () => _showParametersDialog(f),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            Text(
              _formatDate(f.date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Forecast
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('Forecast',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text(
                          'WQI ${f.forecastWQI.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: forecastColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _formatStatus(f.forecastLevel),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.water_drop,
                                size: 20, color: forecastColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Actual
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasActual
                          ? actualColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('Actual',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text(
                          hasActual
                              ? '${f.actualWQI!.toStringAsFixed(1)}%'
                              : '—',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: hasActual ? actualColor : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                hasActual
                                    ? _formatStatus(f.actualLevel ?? '-')
                                    : 'Pending',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: hasActual
                                      ? Colors.black
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.water_drop,
                                size: 20,
                                color:
                                    hasActual ? actualColor : Colors.grey[400]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (hasActual && f.accuracy != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: f.accuracy! >= 90
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.accuracy! >= 90 ? Icons.check_circle : Icons.info,
                      size: 16,
                      color: f.accuracy! >= 90
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Accuracy: ${f.accuracy!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: f.accuracy! >= 90
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Tap to view parameters',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // dialog พารามิเตอร์
  // ========================================
  void _showParametersDialog(WaterForecast f) {
    final forecastParams = f.forecastParams;
    final actualParams = f.actualParams;

    if (forecastParams == null && actualParams == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No parameters available')),
      );
      return;
    }

    // forecast cards
    final List<Widget> forecastCards = [];
    if (forecastParams != null) {
      forecastParams.forEach((name, val) {
        if (val is Map<String, dynamic>) {
          forecastCards.add(_buildParameterCard(name, val));
        }
      });
    }

    // actual cards (แบบรูป 4)
    final List<Widget> actualCards = [];
    if (actualParams != null) {
      actualParams.forEach((name, val) {
        if (val is num) {
          actualCards.add(_buildActualParameterCard(name, val.toDouble()));
        } else if (val is Map<String, dynamic>) {
          final v = val['value'];
          if (v is num) {
            actualCards.add(_buildActualParameterCard(name, v.toDouble()));
          }
        }
      });
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              // header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Water Quality Parameters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              // body
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (forecastCards.isNotEmpty) ...[
                        const Text(
                          'Forecast parameters',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...forecastCards,
                        const SizedBox(height: 20),
                      ],
                      if (actualCards.isNotEmpty) ...[
                        const Text(
                          'Actual parameters',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...actualCards,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // การ์ด forecast (อันเดิม)
  // -----------------------------
  Widget _buildParameterCard(String paramName, Map<String, dynamic> paramData) {
    final mean = _asDouble(paramData['mean']);

    double? piLow;
    double? piHigh;

    if (paramData['pi'] is Map<String, dynamic>) {
      final pi = paramData['pi'] as Map<String, dynamic>;
      piLow = _asDouble(pi['low']);
      piHigh = _asDouble(pi['high']);
    } else {
      piLow = _asDouble(paramData['pi_low']);
      piHigh = _asDouble(paramData['pi_high']);
    }

    String range = 'N/A';
    if (piLow != null && piHigh != null && (piLow != 0 || piHigh != 0)) {
      // ปัด 2 ตำแหน่งทุกตัวเลย
      final lowRound = ((piLow) * 100).roundToDouble() / 100;
      final highRound = ((piHigh) * 100).roundToDouble() / 100;
      range = '${lowRound.toStringAsFixed(2)}-${highRound.toStringAsFixed(2)}';
    }

    final unit = _getUnit(paramName);
    final displayName = unit.isNotEmpty
        ? '${_formatParamName(paramName)} ($unit)'
        : _formatParamName(paramName);

    final status = _determineStatus(paramName, mean);
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Forecasted: ${_formatValue(paramName, mean)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 2),
                Text('Range: $range',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  // -----------------------------
  // การ์ด actual (แบบรูปที่ 4)
  // -----------------------------
  Widget _buildActualParameterCard(String paramName, double value) {
    final status = _determineStatus(paramName, value);
    final color = _getStatusColor(status);

    final unit = _getUnit(paramName);
    final displayName = unit.isNotEmpty
        ? '${_formatParamName(paramName)} ($unit)'
        : _formatParamName(paramName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Actual: ${value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // helpers สำหรับชื่อ/หน่วย/เกณฑ์
  // -----------------------------
  String _getUnit(String paramName) {
    switch (paramName.toLowerCase()) {
      case 'ph':
        return 'pH';
      case 'tds':
        return 'ppm';
      case 'ec':
        return 'µS/cm';
      case 'turbidity':
        return 'NTU';
      case 'temperature':
        return '°C';
      case 'rainfall':
      case 'rain':
        return 'mm';
      default:
        return '';
    }
  }

  String _formatParamName(String name) {
    return name[0].toUpperCase() + name.substring(1);
  }

  String _formatValue(String paramName, double value) {
    switch (paramName.toLowerCase()) {
      case 'ph':
      case 'temperature':
      case 'turbidity':
      case 'ec':
      case 'tds':
      case 'rain':
      case 'rainfall':
        return value.toStringAsFixed(2);
      default:
        return value.toStringAsFixed(0);
    }
  }

  String _determineStatus(String paramName, double value) {
    switch (paramName.toLowerCase()) {
      case 'ph':
        if (value >= 6.5 && value <= 8.5) return 'Excellent';
        if (value >= 6.0 && value <= 9.0) return 'Moderate';
        return 'Poor';
      case 'tds':
        if (value <= 600) return 'Excellent';
        if (value <= 1000) return 'Moderate';
        return 'Poor';
      case 'turbidity':
        if (value <= 50) return 'Excellent';
        if (value <= 100) return 'Moderate';
        return 'Poor';
      default:
        return 'Normal';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'moderate':
      case 'normal':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
