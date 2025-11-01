import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../addbuoy/addbuoy.dart';
import '../edit_buoy_address_screen.dart';
import '../navigation/custom_bottom_nav.dart';

class AddBuoyListScreen extends StatefulWidget {
  const AddBuoyListScreen({Key? key}) : super(key: key);

  @override
  State<AddBuoyListScreen> createState() => _AddBuoyListScreenState();
}

class _AddBuoyListScreenState extends State<AddBuoyListScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getBuoysStream() {
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('buoy_registry')
        .where('uid', isEqualTo: user!.uid)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  void _editBuoy(String buoyId, Map<String, dynamic> installAddress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBuoyAddressScreen(
          buoyCode: buoyId,
          currentAddress: installAddress,
        ),
      ),
    );
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return 'Unknown';
    final now = DateTime.now();
    final d = now.difference(ts.toDate());
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} minutes ago';
    if (d.inHours < 24) return '${d.inHours} hours ago';
    return '${d.inDays} days ago';
  }

  String _formatAddr(Map<String, dynamic>? a) {
    if (a == null) return 'No address';
    return '${a['line1'] ?? ''}\n${a['subdistrict'] ?? ''}, ${a['district'] ?? ''},\n${a['province'] ?? ''} ${a['postal_code'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('กรุณาเข้าสู่ระบบ')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'My Buoys',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your registered buoys',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add, review or edit the buoys linked to your account.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getBuoysStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'ยังไม่มีทุ่นในระบบ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final buoyId = data['buoy_id'] ?? docs[index].id;
                      final addr =
                          data['install_address'] as Map<String, dynamic>?;
                      final ts = (data['updated_at'] ?? data['created_at'])
                          as Timestamp?;

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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      buoyId,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _editBuoy(buoyId, addr ?? {}),
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xFF007BFF)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatAddr(addr),
                                style:
                                    const TextStyle(fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Added ${_timeAgo(ts)}',
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
                  );
                },
              ),
            ),

            const SizedBox(height: 4),
            // ปุ่ม add อันเดียว
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 👉 ไปหน้าเพิ่มทุ่นที่ไม่มีแท็บ
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddBuoyScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Buoy',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // 👇 อันนี้มีแท็บ
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}
