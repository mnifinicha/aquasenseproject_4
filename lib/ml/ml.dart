import 'package:flutter/material.dart';

// Model สำหรับข้อมูลการพยากรณ์
class WaterForecast {
  final DateTime date;
  final double forecastWQI;
  final String forecastLevel;
  final double? actualWQI;
  final String? actualLevel;
  final double? accuracy; // ความแม่นยำเมื่อมีค่าจริง

  WaterForecast({
    required this.date,
    required this.forecastWQI,
    required this.forecastLevel,
    this.actualWQI,
    this.actualLevel,
    this.accuracy,
  });
}

// Model สำหรับพารามิเตอร์คุณภาพน้ำ
class WaterParameter {
  final String name;
  final String unit; // เพิ่ม field หน่วย
  final double forecastValue;
  final String range;
  final String status; // Normal, High, Low, Excellent, Moderate, Poor
  final Color statusColor;

  WaterParameter({
    required this.name,
    required this.unit,
    required this.forecastValue,
    required this.range,
    required this.status,
    required this.statusColor,
  });
}

class WaterForecastPage extends StatefulWidget {
  const WaterForecastPage({Key? key}) : super(key: key);

  @override
  State<WaterForecastPage> createState() => _WaterForecastPageState();
}

class _WaterForecastPageState extends State<WaterForecastPage> {
  // ข้อมูลตัวอย่าง - ในการใช้งานจริงจะดึงจาก API
  final List<WaterForecast> forecasts = [
    WaterForecast(
      date: DateTime(2025, 8, 9, 19, 0),
      forecastWQI: 85,
      forecastLevel: 'Excellent',
      actualWQI: 87,
      actualLevel: 'Excellent',
      accuracy: 97.7,
    ),
    WaterForecast(
      date: DateTime(2025, 8, 10, 19, 0),
      forecastWQI: 69,
      forecastLevel: 'Moderate',
      actualWQI: 72,
      actualLevel: 'Moderate',
      accuracy: 95.8,
    ),
    WaterForecast(
      date: DateTime(2025, 8, 11, 19, 0),
      forecastWQI: 68,
      forecastLevel: 'Moderate',
      actualWQI: 61,
      actualLevel: 'Moderate',
      accuracy: 89.8,
    ),
    // พยากรณ์ล่วงหน้า 3 วัน (ยังไม่มีค่าจริง)
    WaterForecast(
      date: DateTime(2025, 8, 12, 19, 0),
      forecastWQI: 65,
      forecastLevel: 'Moderate',
    ),
    WaterForecast(
      date: DateTime(2025, 8, 13, 19, 0),
      forecastWQI: 71,
      forecastLevel: 'Moderate',
    ),
    WaterForecast(
      date: DateTime(2025, 8, 14, 19, 0),
      forecastWQI: 78,
      forecastLevel: 'Good',
    ),
  ];

  // พารามิเตอร์คุณภาพน้ำ (เพิ่มหน่วย)
  final List<WaterParameter> parameters = [
    WaterParameter(
      name: 'PH',
      unit: 'pH', // เพิ่มหน่วย
      forecastValue: 7.2,
      range: '6.5-8.5',
      status: 'Excellent',
      statusColor: Colors.green,
    ),
    WaterParameter(
      name: 'TDS',
      unit: 'ppm', // เพิ่มหน่วย
      forecastValue: 850,
      range: '300-600',
      status: 'Moderate',
      statusColor: Colors.orange,
    ),
    WaterParameter(
      name: 'EC',
      unit: 'µS/cm', // เพิ่มหน่วย
      forecastValue: 900,
      range: '300-600',
      status: 'Moderate',
      statusColor: Colors.orange,
    ),
    WaterParameter(
      name: 'Turbidity',
      unit: 'NTU', // เพิ่มหน่วย
      forecastValue: 90,
      range: '80-100',
      status: 'Poor',
      statusColor: Colors.red,
    ),
    WaterParameter(
      name: 'Temperature',
      unit: '°C', // เพิ่มหน่วย
      forecastValue: 28.5,
      range: '20-30',
      status: 'Excellent',
      statusColor: Colors.green,
    ),
    WaterParameter(
      name: 'Rain',
      unit: 'ADC', // เพิ่มหน่วย
      forecastValue: 1022,
      range: '781-1023',
      status: 'Excellent',
      statusColor: Colors.green,
    ),
  ];

  // คำนวณความแม่นยำโดยรวม
  double getOverallAccuracy() {
    final forecastsWithActual =
        forecasts.where((f) => f.accuracy != null).toList();
    if (forecastsWithActual.isEmpty) return 0;

    double sum = forecastsWithActual.fold(0, (sum, f) => sum + f.accuracy!);
    return sum / forecastsWithActual.length;
  }

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
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final overallAccuracy = getOverallAccuracy();

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
          'Water Quality Forecast',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Forecast List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: forecasts.length,
              itemBuilder: (context, index) {
                final forecast = forecasts[index];
                return _buildForecastCard(forecast);
              },
            ),

            const SizedBox(height: 16),

            // Water Quality Parameters
            Container(
              margin: const EdgeInsets.all(16),
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
                    'Water Quality Parameters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...parameters.map((param) => _buildParameterCard(param)),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(WaterForecast forecast) {
    final hasActual = forecast.actualWQI != null;
    final color = _getWQIColor(forecast.forecastWQI);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasActual && forecast.accuracy != null
            ? Border.all(
                color: forecast.accuracy! >= 90
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 2,
              )
            : null,
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
          // Date
          Text(
            _formatDate(forecast.date),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Forecast and Actual
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
                      Text(
                        'Forecast',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'WQI ${forecast.forecastWQI.toInt()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            forecast.forecastLevel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.water_drop,
                            size: 20,
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Actual (if available)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        hasActual ? color.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Actual',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasActual ? '${forecast.actualWQI!.toInt()}%' : '—',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: hasActual
                              ? _getWQIColor(forecast.actualWQI!)
                              : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasActual ? forecast.actualLevel! : 'Pending',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  hasActual ? Colors.black : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.water_drop,
                            size: 20,
                            color: hasActual
                                ? _getWQIColor(forecast.actualWQI!)
                                : Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Accuracy (if available)
          if (hasActual && forecast.accuracy != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: forecast.accuracy! >= 90
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    forecast.accuracy! >= 90 ? Icons.check_circle : Icons.info,
                    size: 16,
                    color: forecast.accuracy! >= 90
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Accuracy: ${forecast.accuracy!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: forecast.accuracy! >= 90
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParameterCard(WaterParameter param) {
    // สร้างชื่อพร้อมหน่วย
    String displayName =
        param.unit.isNotEmpty ? '${param.name} (${param.unit})' : param.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName, // แสดงชื่อพร้อมหน่วย
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Forecasted: ${param.forecastValue}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Range: ${param.range}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: param.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              param.status,
              style: TextStyle(
                color: param.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ตัวอย่างการใช้งาน
void main() {
  runApp(const MaterialApp(
    home: WaterForecastPage(),
    debugShowCheckedModeBanner: false,
  ));
}
