import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAuthorized = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAuthorization();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ✅ เช็ก Admin Authorization
  Future<void> _checkAuthorization() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        user.email?.toLowerCase() != 'sutthiwat.project@gmail.com') {
      setState(() {
        _isAuthorized = false;
        _isCheckingAuth = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Access Denied: Admin only'),
            backgroundColor: Colors.red,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
      return;
    }

    setState(() {
      _isAuthorized = true;
      _isCheckingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'System Management',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search users, buoys, or sensors...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1976D2),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1976D2),
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Users'),
                  Tab(text: 'Buoys'),
                  Tab(text: 'Sensors'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTab(),
                  _buildBuoysTab(),
                  _buildSensorsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: USERS
  // ═══════════════════════════════════════════════════════════
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading users');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers = users.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final query = _searchQuery.toLowerCase();
          return (data['firstname'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query) ||
              (data['lastname'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query) ||
              (data['email'] ?? '').toString().toLowerCase().contains(query);
        }).toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyWidget('No users found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final doc = filteredUsers[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildUserCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildUserCard(String uid, Map<String, dynamic> data) {
    final firstname = data['firstname'] ?? '';
    final lastname = data['lastname'] ?? '';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '';
    final role = data['role'] ?? 'user';
    final buoys = (data['buoys'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserDetailsDialog(uid, data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(firstname, lastname),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$firstname $lastname',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _buildRoleBadge(role),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),

                if (phone.isNotEmpty || buoys.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],

                // Additional Info
                if (phone.isNotEmpty)
                  _buildInfoRow(Icons.phone_outlined, _formatPhone(phone)),
                if (buoys.isNotEmpty)
                  _buildInfoRow(
                    Icons.water_drop_outlined,
                    '${buoys.length} Buoy${buoys.length > 1 ? 's' : ''}',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: BUOYS
  // ═══════════════════════════════════════════════════════════
  Widget _buildBuoysTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('buoy_registry')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading buoys');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buoys = snapshot.data?.docs ?? [];
        final filteredBuoys = buoys.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final query = _searchQuery.toLowerCase();
          return doc.id.toLowerCase().contains(query) ||
              (data['owner_email'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query);
        }).toList();

        if (filteredBuoys.isEmpty) {
          return _buildEmptyWidget('No buoys found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredBuoys.length,
          itemBuilder: (context, index) {
            final doc = filteredBuoys[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildBuoyCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildBuoyCard(String buoyId, Map<String, dynamic> data) {
    final ownerEmail = data['owner_email'] ?? 'N/A';
    final ownerUid = data['owner_uid'] ?? '';
    final active = data['active'] ?? false;
    final installAddress = data['install_address'] as Map<String, dynamic>?;

    String location = 'No location';
    if (installAddress != null) {
      final province = installAddress['province'] ?? '';
      final district = installAddress['district'] ?? '';
      location = [province, district].where((e) => e.isNotEmpty).join(', ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBuoyDetailsDialog(buoyId, data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: active
                              ? [Colors.green[600]!, Colors.green[400]!]
                              : [Colors.grey[600]!, Colors.grey[400]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  buoyId,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  active ? 'ACTIVE' : 'INACTIVE',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: active ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ownerEmail,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, location),
                if (ownerUid.isNotEmpty)
                  _buildInfoRow(
                    Icons.fingerprint,
                    'UID: ${ownerUid.substring(0, 8)}...',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3: SENSORS (ตัวอย่างข้อมูล)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSensorsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('buoy_registry')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading sensor data');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buoys = snapshot.data?.docs ?? [];

        if (buoys.isEmpty) {
          return _buildEmptyWidget('No active buoys with sensors');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: buoys.length,
          itemBuilder: (context, index) {
            final doc = buoys[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildSensorCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildSensorCard(String buoyId, Map<String, dynamic> data) {
    // ตัวอย่างการแสดงผลข้อมูลเซ็นเซอร์
    // ในความเป็นจริงต้องดึงจาก collection sensor_timeseries

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.sensors,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buoyId,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Real-time Sensor Data',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Sensor Values Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildSensorValue('Temperature', '28.5°C', Icons.thermostat),
                _buildSensorValue('pH Level', '7.2', Icons.science),
                _buildSensorValue('Turbidity', '15 NTU', Icons.water),
                _buildSensorValue('Oxygen', '8.5 mg/L', Icons.bubble_chart),
              ],
            ),

            const SizedBox(height: 12),

            // View Details Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showSensorDetailsDialog(buoyId, data),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: Text(
                  'View Detailed Analytics',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1976D2),
                  side: const BorderSide(color: Color(0xFF1976D2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorValue(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIALOG: User Details
  // ═══════════════════════════════════════════════════════════
  void _showUserDetailsDialog(String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Text(
                      'User Details',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                _buildDetailRow('UID', uid),
                _buildDetailRow('First Name', data['firstname'] ?? '-'),
                _buildDetailRow('Last Name', data['lastname'] ?? '-'),
                _buildDetailRow('Email', data['email'] ?? '-'),
                _buildDetailRow('Phone', data['phone'] ?? '-'),
                _buildDetailRow('Role', data['role'] ?? '-'),

                if (data['address'] != null)
                  _buildDetailRow('Address', data['address']),
                if (data['province'] != null)
                  _buildDetailRow('Province', data['province']),
                if (data['district'] != null)
                  _buildDetailRow('District', data['district']),
                if (data['subdistrict'] != null)
                  _buildDetailRow('Subdistrict', data['subdistrict']),
                if (data['postal_code'] != null)
                  _buildDetailRow('Postal Code', data['postal_code']),

                const SizedBox(height: 16),

                // Buoys Section
                if (data['buoys'] != null &&
                    (data['buoys'] as List).isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Associated Buoys:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...((data['buoys'] as List).map((buoy) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop,
                                  color: Color(0xFF1976D2), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                buoy.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIALOG: Buoy Details
  // ═══════════════════════════════════════════════════════════
  void _showBuoyDetailsDialog(String buoyId, Map<String, dynamic> data) {
    final installAddress = data['install_address'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Text(
                      'Buoy Details',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow('Buoy ID', buoyId),
                _buildDetailRow('Owner UID', data['owner_uid'] ?? '-'),
                _buildDetailRow('Owner Email', data['owner_email'] ?? '-'),
                _buildDetailRow('Active', data['active']?.toString() ?? '-'),
                if (installAddress != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Installation Address:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Label', installAddress['label'] ?? '-'),
                  _buildDetailRow('Address', installAddress['address'] ?? '-'),
                  _buildDetailRow(
                      'Subdistrict', installAddress['subdistrict'] ?? '-'),
                  _buildDetailRow(
                      'District', installAddress['district'] ?? '-'),
                  _buildDetailRow(
                      'Province', installAddress['province'] ?? '-'),
                  _buildDetailRow(
                      'Postal Code', installAddress['postal_code'] ?? '-'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIALOG: Sensor Details
  // ═══════════════════════════════════════════════════════════
  void _showSensorDetailsDialog(String buoyId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Color(0xFF1976D2)),
                  const SizedBox(width: 12),
                  Text(
                    'Sensor Analytics',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Detailed sensor data for $buoyId',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect to sensor_timeseries collection for real-time data',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════
  Widget _buildRoleBadge(String role) {
    final isAdmin = role.toLowerCase() == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.orange.withOpacity(0.1)
            : const Color(0xFF1976D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isAdmin ? Colors.orange : const Color(0xFF1976D2),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _getInitials(String firstname, String lastname) {
    String initials = '';
    if (firstname.isNotEmpty) initials += firstname[0].toUpperCase();
    if (lastname.isNotEmpty) initials += lastname[0].toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  String _formatPhone(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }
}
