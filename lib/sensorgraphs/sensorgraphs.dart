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

  // ✅ เพิ่มตัวแปรเก็บทุ่นที่เลือก
  late String selectedBuoyId;

  // ✅ รายชื่อทุ่นทั้งหมด
  List<String> availableBuoys = [];

  final Map<String, DateTime?> selectedDates = {
    'temperature': null,
    'ph': null,
    'turbidity': null,
    'ec': null,
    'rainfall': null,
    'tds': null,
  };

  Map<String, List<SensorData>> sensorHistory = {
    'temperature': [],
    'ph': [],
    'turbidity': [],
    'ec': [],
    'rainfall': [],
    'tds': [],
  };

  bool isLoading = true;
  bool isLoadingBuoys = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    selectedBuoyId = widget.buoyId; // ✅ ใช้ค่าเริ่มต้น
    _fetchAvailableBuoys(); // ✅ ดึงรายชื่อทุ่นทั้งหมด
    _fetchSensorData();
  }

  // ✅ ดึงรายชื่อทุ่นทั้งหมด
  Future<void> _fetchAvailableBuoys() async {
    try {
      final querySnapshot =
          await _firestore.collection('sensor_timeseries').get();

      // ดึง buoy_id ที่ไม่ซ้ำกัน
      Set<String> buoySet = {};
      for (var doc in querySnapshot.docs) {
        final buoyId = doc.data()['buoy_id'] as String?;
        if (buoyId != null) {
          buoySet.add(buoyId);
        }
      }

      setState(() {
        availableBuoys = buoySet.toList()..sort();
        isLoadingBuoys = false;
      });

      print('🎯 Available buoys: $availableBuoys');
    } catch (e) {
      print('❌ Error fetching buoys: $e');
      setState(() {
        isLoadingBuoys = false;
      });
    }
  }

  // ✅ ดึงข้อมูลตามทุ่นที่เลือก
  Future<void> _fetchSensorData() async {
    setState(() {
      isLoading = true;
    });

    try {
      DateTime startDate = _getStartDate(selectedPeriod);

      print('🔍 Fetching data for buoy: $selectedBuoyId from: $startDate');

      // ✅ ใช้ selectedBuoyId แทน widget.buoyId
      final querySnapshot = await _firestore
          .collection('sensor_timeseries')
          .where('buoy_id', isEqualTo: selectedBuoyId)
          .where('timestamp_ms',
              isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .orderBy('timestamp_ms', descending: false)
          .limit(1000)
          .get();

      print('📊 Total records found: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, List<SensorData>> tempData = {
          'temperature': [],
          'ph': [],
          'turbidity': [],
          'ec': [],
          'rainfall': [],
          'tds': [],
        };

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final parameter = (data['parameter'] as String?)?.toLowerCase();
          final value = data['value'];
          final timestampMs = data['timestamp_ms'] as int?;

          if (parameter != null && value != null && timestampMs != null) {
            if (tempData.containsKey(parameter)) {
              final timestamp =
                  DateTime.fromMillisecondsSinceEpoch(timestampMs);

              tempData[parameter]!.add(SensorData(
                value: (value as num).toDouble(),
                timestamp: timestamp,
              ));
            }
          }
        }

        setState(() {
          sensorHistory = tempData;
          isLoading = false;
        });

        print('\n📈 Data Summary:');
        sensorHistory.forEach((key, value) {
          print('   $key: ${value.length} data points');
        });
      } else {
        print('⚠️ No documents found for $selectedBuoyId');
        setState(() {
          // ✅ รีเซ็ตข้อมูลเมื่อไม่มีข้อมูล
          sensorHistory = {
            'temperature': [],
            'ph': [],
            'turbidity': [],
            'ec': [],
            'rainfall': [],
            'tds': [],
          };
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
      default:
        return now.subtract(const Duration(hours: 24));
    }
  }

  Future<void> _fetchDataByDate(String sensorKey, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print(
          '🔍 Fetching $sensorKey for buoy: $selectedBuoyId, date: ${DateFormat('dd/MM/yyyy').format(date)}');

      // ✅ ใช้ selectedBuoyId
      final querySnapshot = await _firestore
          .collection('sensor_timeseries')
          .where('buoy_id', isEqualTo: selectedBuoyId)
          .where('parameter', isEqualTo: sensorKey)
          .where('timestamp_ms',
              isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('timestamp_ms',
              isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch)
          .orderBy('timestamp_ms', descending: false)
          .limit(500)
          .get();

      List<SensorData> data = [];

      for (var doc in querySnapshot.docs) {
        final docData = doc.data();
        final value = docData['value'];
        final timestampMs = docData['timestamp_ms'] as int?;

        if (value != null && timestampMs != null) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);

          data.add(SensorData(
            value: (value as num).toDouble(),
            timestamp: timestamp,
          ));
        }
      }

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
                // ✅ Buoy Selector (ใหม่)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.water, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Select Buoy:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isLoadingBuoys
                            ? const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.blue.withOpacity(0.05),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedBuoyId,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: Colors.blue),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: availableBuoys.map((String buoyId) {
                                      return DropdownMenuItem<String>(
                                        value: buoyId,
                                        child: Text(buoyId.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedBuoyId = newValue;
                                          // รีเซ็ตวันที่เมื่อเปลี่ยนทุ่น
                                          selectedDates
                                              .updateAll((key, value) => null);
                                        });
                                        _fetchSensorData();
                                      }
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

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
            selectedDates.updateAll((key, value) => null);
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
            Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[400], size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'No data available for $selectedBuoyId',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

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
                      reservedSize: 50,
                      interval: (maxY - minY) / 2,
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
}

class SensorData {
  final double value;
  final DateTime timestamp;

  SensorData({
    required this.value,
    required this.timestamp,
  });
}
