import 'package:flutter/material.dart';

/// Widget สำหรับ Bottom Navigation Bar ที่ใช้ซ้ำได้ในทุกหน้า
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
        if (index == currentIndex) return; // ถ้ากดหน้าปัจจุบัน ให้ข้าม

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
