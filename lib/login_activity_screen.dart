// login_activity_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'registration_data.dart'; // pastikan import ini mengarah ke file yang berisi class RegistrationData

class LoginActivityScreen extends StatelessWidget {
  final RegistrationData registrationData;

  const LoginActivityScreen({
    Key? key,
    required this.registrationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Pastikan registrationData.docID tidak null
    final String? uid = registrationData.docID;
    if (uid == null || uid.isEmpty) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(200, 33, 0, 83),
        body: _buildErrorState(),
      );
    }

    // 2. Referensi ke sub‐koleksi 'login_activity' di Firestore:
    final loginActivityRef = FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('login_activity')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Judul
              const Text(
                'Login Activity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Here are your recent login sessions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Container utama: daftar aktivitas
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: loginActivityRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return _buildErrorText(
                            'Error memuat aktivitas: ${snapshot.error}');
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Tampilkan setiap dokumen login_activity
                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          // Ambil timestamp dan format
                          final Timestamp ts = data['timestamp'] as Timestamp;
                          final dateTime = ts.toDate();
                          final formattedDate =
                              '${dateTime.day.toString().padLeft(2, '0')}-'
                              '${dateTime.month.toString().padLeft(2, '0')}-'
                              '${dateTime.year} '
                              '${dateTime.hour.toString().padLeft(2, '0')}:'
                              '${dateTime.minute.toString().padLeft(2, '0')}';

                          final device = data['device'] as String? ?? 'Unknown';
                          final location =
                              data['location'] as String? ?? 'Unknown';

                          return _LoginActivityCard(
                            dateTimeText: formattedDate,
                            device: device,
                            location: location,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // Tombol “Back to Profile” tanpa border
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: const Text(
        'User ID tidak ditemukan.',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }

  Widget _buildErrorText(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No recent login activity found.',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}

class _LoginActivityCard extends StatelessWidget {
  final String dateTimeText;
  final String device;
  final String location;

  const _LoginActivityCard({
    Key? key,
    required this.dateTimeText,
    required this.device,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Icon di dalam lingkaran
            Container(
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(
                Icons.login,
                color: Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Teks utama
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateTimeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$device    $location',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
