import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../navigation/custom_bottom_nav.dart';

class SensorGraphsPage extends StatefulWidget {
  final String buoyId;

  const SensorGraphsPage({
    Key? key,
    this.buoyId = 'buoy_001',
  }) : super(key: key);

  @override
  State<SensorGraphsPage> createState() => _SensorGraphsPageState();
}

class _SensorGraphsPageState extends State<SensorGraphsPage> {
  String selectedPeriod = 'Day';
  final Map<String, DateTime?> selectedDates = {
    'temperature': null,
    'ph': null,
    'turbidity': null,
    'ec': null,
    'rainfall': null,
    'tds': null,
  };

  // เก็บข้อมูลจาก Firestore
  Map<String, List<SensorData>> sensorHistory = {
    'temperature': [],
    'ph': [],
    'turbidity': [],
    'ec': [],
    'rainfall': [],
    'tds': [],
  };

  bool isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  // ดึงข้อมูลจาก Firestore (แบบแยก parameter)
  Future<void> _fetchSensorData() async {
    setState(() {
      isLoading = true;
    });

    try {
      DateTime startDate = _getStartDate(selectedPeriod);

      print('🔍 Fetching data from: $startDate');

      // ดึงข้อมูลทั้งหมด
      final querySnapshot = await _firestore
          .collection('sensor_timeseries')
          .where('buoy_id', isEqualTo: widget.buoyId)
          .orderBy('timestamp_ms', descending: false)
          .get();

// ✅ กรองข้อมูลภายหลังด้วย Dart (แทนการ where)
      final filteredDocs = querySnapshot.docs.where((doc) {
        final ts = doc['timestamp_ms'];
        if (ts is int) {
          final time = DateTime.fromMillisecondsSinceEpoch(ts);
          return time.isAfter(startDate); // กรองตามช่วงเวลา
        }
        return false;
      }).toList();

      print('📊 Total records found: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isNotEmpty) {
        // รีเซ็ตข้อมูล
        Map<String, List<SensorData>> tempData = {
          'temperature': [],
          'ph': [],
          'turbidity': [],
          'ec': [],
          'rainfall': [],
          'tds': [],
        };

        for (var doc in filteredDocs) {
          final data = doc.data();
          final parameter = data['parameter'] as String?;
          final value = data['value'];

          // แปลง timestamp
          DateTime? timestamp;
          if (data['timestamp_ms'] != null) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(
                data['timestamp_ms'] as int);
          } else {
            print('⚠️ No timestamp_ms in document: ${doc.id}');
            continue;
          }

          // เช็คว่ามี parameter และ value ไหม
          if (parameter != null && value != null) {
            final sensorKey = parameter.toLowerCase();

            if (tempData.containsKey(sensorKey)) {
              tempData[sensorKey]!.add(SensorData(
                value: (value as num).toDouble(),
                timestamp: timestamp,
              ));

              print(
                  '✅ Added $sensorKey: $value at ${DateFormat('HH:mm:ss').format(timestamp)}');
            } else {
              print('⚠️ Unknown parameter: $parameter');
            }
          }
        }

        setState(() {
          sensorHistory = tempData;
          isLoading = false;
        });

        // แสดงสรุปจำนวนข้อมูล
        print('\n📈 Data Summary:');
        sensorHistory.forEach((key, value) {
          print('   $key: ${value.length} data points');
        });
      } else {
        print('⚠️ No documents found');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching data: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  DateTime _getStartDate(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Week':
        return now.subtract(const Duration(days: 7));
      case 'Month':
        return now.subtract(const Duration(days: 30));
      default: // Day
        return now.subtract(const Duration(hours: 24));
    }
  }

  Future<void> _fetchDataByDate(String sensorKey, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print(
          '🔍 Fetching $sensorKey for date: ${DateFormat('dd/MM/yyyy').format(date)}');

      final querySnapshot = await _firestore
          .collection('sensor_timeseries')
          .where('buoy_id', isEqualTo: widget.buoyId)
          .where('parameter', isEqualTo: sensorKey) // ✅ ใช้ sensorKey
          .where('timestamp_ms',
              isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .orderBy('timestamp_ms', descending: true) // ✅ เปลี่ยนเป็น true
          .get();

      List<SensorData> data = [];

      for (var doc in querySnapshot.docs) {
        final docData = doc.data();
        final value = docData['value'];

        DateTime? timestamp;
        if (docData['timestamp_ms'] != null) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(
              docData['timestamp_ms'] as int);
        }

        if (value != null && timestamp != null) {
          if (timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay)) {
            data.add(SensorData(
              value: (value as num).toDouble(),
              timestamp: timestamp,
            ));
          }
        }
      }
      data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      print('✅ Found ${data.length} data points for $sensorKey');

      setState(() {
        sensorHistory[sensorKey] = data;
      });
    } catch (e) {
      print('❌ Error fetching data by date: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading date: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sensor Graphs',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                // ✅ รีเซ็ตวันที่ทั้งหมดกลับเป็น null เพื่อให้ dropdown แสดง "Date"
                selectedDates.updateAll((key, value) => null);
              });

              // ✅ โหลดข้อมูลใหม่ตาม period ปัจจุบัน (Day / Week / Month)
              _fetchSensorData();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Period selector
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      _buildPeriodButton('Day'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('Week'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('Month'),
                    ],
                  ),
                ),

                // Scrollable graphs
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchSensorData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSensorCard(
                            'Temperature Sensor', '°C', 'temperature'),
                        const SizedBox(height: 16),
                        _buildSensorCard('PH Sensor', '', 'ph'),
                        const SizedBox(height: 16),
                        _buildSensorCard(
                            'Turbidity Sensor', 'NTU', 'turbidity'),
                        const SizedBox(height: 16),
                        _buildSensorCard('EC Sensor', 'μS/cm', 'ec'),
                        const SizedBox(height: 16),
                        _buildSensorCard('Rain Sensor', 'mm', 'rainfall'),
                        const SizedBox(height: 16),
                        _buildSensorCard('TDS Sensor', 'ppm', 'tds'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = period;
          });
          _fetchSensorData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, String unit, String sensorKey) {
    List<SensorData> data = sensorHistory[sensorKey] ?? [];

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                _buildDateDropdown(sensorKey),
              ],
            ),
            const SizedBox(height: 80),
            const Center(
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    // คำนวณ min/max อัตโนมัติ
    List<double> values = data.map((e) => e.value).toList();
    double minValue = values.reduce((a, b) => a < b ? a : b);
    double maxValue = values.reduce((a, b) => a > b ? a : b);

    double range = maxValue - minValue;
    double padding = range * 0.15;

    if (range < 1) {
      padding = 2;
    }

    double minY = minValue - padding;
    double maxY = maxValue + padding;

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              _buildDateDropdown(sensorKey),
            ],
          ),
          if (unit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      //reservedSize: 40,
                      reservedSize: 50,
                      interval: (maxY - minY) / 2,
                      //interval: (maxY - minY) / 4,
                      //interval: (maxY - minY) / 5,
                      getTitlesWidget: (value, meta) {
                        double midValue = (minY + maxY) / 2;
                        if ((value - minY).abs() < 0.01 ||
                            (value - midValue).abs() < 0.01 ||
                            (value - maxY).abs() < 0.01) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              //
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: data.length > 6
                          ? (data.length / 6).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final time = data[index].timestamp;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(time),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (index == spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.blue[800]!,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
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

  Widget _buildDateDropdown(String sensorKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: GestureDetector(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDates[sensorKey] ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.blue,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              selectedDates[sensorKey] = picked;
            });
            _fetchDataByDate(sensorKey, picked);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedDates[sensorKey] != null
                  ? DateFormat('dd/MM/yy').format(selectedDates[sensorKey]!)
                  : 'Date',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 18),
          ],
        ),
      ),
    );
  }

  /* Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Forecast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Store',
          ),
        ],
      ),
    );
  }*/
}

class SensorData {
  final double value;
  final DateTime timestamp;

  SensorData({
    required this.value,
    required this.timestamp,
  });
}
