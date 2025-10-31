import 'package:flutter/material.dart';

class BuoyManagementScreen extends StatelessWidget {
  // 🔹 ข้อมูลทุ่นจำลอง (mock data)
  final List<Map<String, dynamic>> buoys = [
    {
      "id": "Buoy -001-2024",
      "address":
          "198/114,6/4,Bang Kruai-Sai Noi,\nBang Rak Phatthana,\nBang Bua Thong, Nonthaburi 11110",
      "added": "2 hours ago",
      "status": "online",
    },
    {
      "id": "Buoy -002-2024",
      "address":
          "98/114,6/4,Bang Kruai-Sai Noi,\nBang Rak Phatthana,\nBang Bua Thong, Nonthaburi 11110",
      "added": "1 day ago",
      "status": "online",
    },
    {
      "id": "Buoy -003-2024",
      "address":
          "98/114,6/4,Bang Kruai-Sai Noi,\nBang Rak Phatthana,\nBang Bua Thong, Nonthaburi 11110",
      "added": "3 days ago",
      "status": "offline",
    },
  ];

  BuoyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF), // พื้นหลังฟ้าอ่อน
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Buoy Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // 🔹 เนื้อหาหลักของหน้า
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Your Buoys',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Review your added buoys before proceeding to the home screen.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // 🔹 รายการการ์ดของ Buoy
            Expanded(
              child: ListView.builder(
                itemCount: buoys.length,
                itemBuilder: (context, index) {
                  final buoy = buoys[index];
                  final isOnline = buoy["status"] == "online";
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // จุดสถานะออนไลน์/ออฟไลน์
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  buoy["id"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // ปุ่มแก้ไข
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Color(0xFF007BFF)),
                                onPressed: () {
                                  // TODO: เพิ่มฟังก์ชันแก้ไข
                                },
                              ),
                              // ปุ่มลบ
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Color(0xFFE53935)),
                                onPressed: () {
                                  // TODO: เพิ่มฟังก์ชันลบ
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            buoy["address"],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Added ${buoy["added"]}",
                            style: const TextStyle(
                              color: Color(0xFF007BFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🔹 ปุ่มล่าง 2 อันในกล่องเดียว
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ปุ่มซ้าย (Add Another)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // 🧭 ไปหน้าสร้างทุ่นใหม่
                        // Navigator.pushNamed(context, '/addBuoy');
                      },
                      icon: const Icon(Icons.add, color: Color(0xFF003366)),
                      label: const Text(
                        'Add Another Buoy',
                        style: TextStyle(
                          color: Color(0xFF003366),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                            color: Color(0xFF003366), width: 1.5),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 2),

                  // ปุ่มขวา (Go to Home)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 🏠 กลับหน้า Dashboard
                        // Navigator.pushReplacementNamed(context, '/dashboard');
                      },
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text(
                        'Go to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
