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

  // วันที่ที่เลือกของแต่ละ sensor
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

  // ✅ ช่วงค่าคงที่ของแต่ละ sensor
  // ถ้าจะเปลี่ยนภายหลัง แก้ที่นี่จุดเดียว
  final Map<String, _SensorRange> sensorRanges = const {
    'ph': _SensorRange(0, 14),
    'tds': _SensorRange(0, 1500),
    'ec': _SensorRange(0, 2240),
    'turbidity': _SensorRange(0, 1000),
    'temperature': _SensorRange(-20, 105),
    'rainfall': _SensorRange(0, 1023), // ถ้าอยากเป็น 0–1023 เปลี่ยนตรงนี้
  };

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  // ดึงข้อมูลทั้งหมดจาก Firestore ตาม period (Day/Week/Month)
  Future<void> _fetchSensorData() async {
    setState(() {
      isLoading = true;
    });

    try {
      DateTime startDate = _getStartDate(selectedPeriod);

      final querySnapshot = await _firestore
          .collection('sensor_timeseries')
          .where('buoy_id', isEqualTo: widget.buoyId)
          .orderBy('timestamp_ms', descending: false)
          .get();

      final filteredDocs = querySnapshot.docs.where((doc) {
        final ts = doc['timestamp_ms'];
        if (ts is int) {
          final time = DateTime.fromMillisecondsSinceEpoch(ts);
          return time.isAfter(startDate);
        }
        return false;
      }).toList();

      if (querySnapshot.docs.isNotEmpty) {
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

          DateTime? timestamp;
          if (data['timestamp_ms'] != null) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(
                data['timestamp_ms'] as int);
          } else {
            continue;
          }

          if (parameter != null && value != null) {
            final sensorKey = parameter.toLowerCase();
            if (tempData.containsKey(sensorKey)) {
              tempData[sensorKey]!.add(
                SensorData(
                  value: (value as num).toDouble(),
                  timestamp: timestamp,
                ),
              );
            }
          }
        }

        setState(() {
          sensorHistory = tempData;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
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
      default:
        return now.subtract(const Duration(hours: 24));
    }
  }

  // ดึงข้อมูลของวันนั้น ๆ สำหรับ sensor เดียว
  Future<void> _fetchDataByDate(String sensorKey, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('sensor_timeseries')
          .where('buoy_id', isEqualTo: widget.buoyId)
          .where('parameter', isEqualTo: sensorKey)
          .where('timestamp_ms',
              isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .orderBy('timestamp_ms', descending: true)
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

      setState(() {
        sensorHistory[sensorKey] = data;
      });
    } catch (e) {
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
                selectedDates.updateAll((key, value) => null);
              });
              _fetchSensorData();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ปุ่ม Day / Week / Month
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
                // กราฟ
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchSensorData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSensorCard('Temperature Sensor', '°C',
                            'temperature'), // -20 – 105
                        const SizedBox(height: 16),
                        _buildSensorCard('PH Sensor', '', 'ph'), // 0 – 14
                        const SizedBox(height: 16),
                        _buildSensorCard(
                            'Turbidity Sensor', 'NTU', 'turbidity'), // 0 – 1000
                        const SizedBox(height: 16),
                        _buildSensorCard(
                            'EC Sensor', 'μS/cm', 'ec'), // 0 – 2240
                        const SizedBox(height: 16),
                        _buildSensorCard(
                            'Rain Sensor', 'mm', 'rainfall'), // 0 – 102
                        const SizedBox(height: 16),
                        _buildSensorCard(
                            'TDS Sensor', 'ppm', 'tds'), // 0 – 1500
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
    final List<SensorData> data = sensorHistory[sensorKey] ?? [];

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

    // ถ้ามี range คงที่ให้ใช้เลย
    final _SensorRange? fixedRange = sensorRanges[sensorKey];

    // สร้างจุด
    final List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      double y = data[i].value;

      // ถ้ามี range คงที่ → clamp แค่ตอนแสดง
      if (fixedRange != null) {
        if (y < fixedRange.min) y = fixedRange.min;
        if (y > fixedRange.max) y = fixedRange.max;
      }

      spots.add(FlSpot(i.toDouble(), y));
    }

    // ถ้าไม่มี range คงที่ → คำนวณจากข้อมูล
    double minY;
    double maxY;
    if (fixedRange != null) {
      minY = fixedRange.min;
      maxY = fixedRange.max;
    } else {
      final values = data.map((e) => e.value).toList();
      double minValue = values.reduce((a, b) => a < b ? a : b);
      double maxValue = values.reduce((a, b) => a > b ? a : b);
      double range = maxValue - minValue;
      double padding = range * 0.15;
      if (range < 1) padding = 2;
      minY = minValue - padding;
      maxY = maxValue + padding;
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
          // title + date picker
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
            height: 220,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval:
                      _getHorizontalInterval(sensorKey, minY, maxY),
                  verticalInterval:
                      data.length > 6 ? (data.length / 6).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.12),
                      strokeWidth: 1,
                    );
                  },
                ),
                // ✅ เส้น max/min
                extraLinesData: fixedRange != null
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: fixedRange.max,
                            color: Colors.red.withOpacity(0.4),
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              labelResolver: (line) => 'max ${fixedRange.max}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          HorizontalLine(
                            y: fixedRange.min,
                            color: Colors.green.withOpacity(0.4),
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.bottomRight,
                              labelResolver: (line) => 'min ${fixedRange.min}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const ExtraLinesData(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        // แสดงทุกเส้นที่เราวาดไว้
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
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
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black.withOpacity(0.7),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final index = barSpot.x.toInt();
                        if (index < 0 || index >= data.length) {
                          return null;
                        }
                        final d = data[index];
                        final timeStr =
                            DateFormat('dd/MM HH:mm').format(d.timestamp);
                        return LineTooltipItem(
                          '$timeStr\n${d.value.toStringAsFixed(2)} $unit',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // จุดล่าสุดใหญ่หน่อย
                        if (index == spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.blue[800]!,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.blue,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
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

  // กำหนด interval ของเส้นแนวนอนให้สวยตามชนิด sensor
  double _getHorizontalInterval(String sensorKey, double minY, double maxY) {
    final range = maxY - minY;
    switch (sensorKey) {
      case 'ph':
        return 2;
      case 'tds':
        return 300;
      case 'ec':
        return 500;
      case 'turbidity':
        return 200;
      case 'temperature':
        return 10;
      case 'rainfall':
        return 20;
      default:
        return range / 4;
    }
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
}

class SensorData {
  final double value;
  final DateTime timestamp;

  SensorData({
    required this.value,
    required this.timestamp,
  });
}

// class ช่วยเก็บช่วงค่า
class _SensorRange {
  final double min;
  final double max;
  const _SensorRange(this.min, this.max);
}
