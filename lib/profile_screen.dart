// profile_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'support_center_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_condition_screen.dart';
import 'application_settings_screen.dart';
import 'login_activity_screen.dart';
import 'change_password_screen.dart';
import 'account_information_screen.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';
import 'diary_screen.dart';
import 'community_screen.dart';
import 'registration_data.dart';

/// Kelas kustom untuk mengatur posisi FloatingActionButton
class FractionalOffsetFabLocation extends FloatingActionButtonLocation {
  final double fraction;
  FractionalOffsetFabLocation(this.fraction);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabWidth = scaffoldGeometry.floatingActionButtonSize.width;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double scaffoldWidth = scaffoldGeometry.scaffoldSize.width;

    final double x = fraction * scaffoldWidth - (fabWidth / 2);
    final double contentBottom = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.minViewPadding.bottom;
    final double y =
        contentBottom - fabHeight - 12.0; // jarak lebih rapat agar pas

    return Offset(x, y);
  }
}

// Posisi FAB untuk masing-masing ikon
final dashboardLocation = FractionalOffsetFabLocation(0.125);
final bookLocation = FractionalOffsetFabLocation(0.375);
final calendarLocation = FractionalOffsetFabLocation(0.625);
final personLocation = FractionalOffsetFabLocation(0.875);

class ProfileScreen extends StatefulWidget {
  final RegistrationData regData;
  const ProfileScreen({Key? key, required this.regData}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // FAB default: Person
  FloatingActionButtonLocation _fabLocation = personLocation;
  IconData _fabIcon = Icons.person;

  // Untuk memilih gambar
  final ImagePicker _picker = ImagePicker();
  File? _localPickedImage;

  /// Fungsi memanggil galeri untuk memilih foto.
  /// Setelah dipilih, gambar di‐convert ke Base64,
  /// lalu di‐upload (update) ke Firestore pada field 'photoBase64'.
  Future<void> _pickAndUploadProfileImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (picked == null) return;

      final File file = File(picked.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      // Simpan ke Firestore field 'photoBase64'
      final userRef = FirebaseFirestore.instance
          .collection('user')
          .doc(widget.regData.docID);

      await userRef.update({'photoBase64': base64Str});

      // Simpan di local state untuk preview langsung
      setState(() {
        _localPickedImage = file;
      });
    } catch (e) {
      debugPrint('Error picking/uploading profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRef =
        FirebaseFirestore.instance.collection('user').doc(widget.regData.docID);

    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      body: FutureBuilder<DocumentSnapshot>(
        future: userRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Data tidak ditemukan.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Ambil data user, termasuk field 'photoBase64' jika ada
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final displayName = userData['firstName'] ?? "No Name";
          final displayEmail = userData['email'] ?? "No Email";
          final photoBase64 = userData['photoBase64'] as String?;

          Widget avatarWidget;

          // 1) Jika state lokal _localPickedImage sudah ada (baru dipilih), pakai itu
          if (_localPickedImage != null) {
            avatarWidget = ClipOval(
              child: Image.file(
                _localPickedImage!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            );
          }
          // 2) Jika Firestore punya 'photoBase64', decode dan pakai MemoryImage
          else if (photoBase64 != null && photoBase64.isNotEmpty) {
            final bytes = base64Decode(photoBase64);
            avatarWidget = ClipOval(
              child: Image.memory(
                bytes,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            );
          }
          // 3) Default: tampilkan gradasi + ikon person
          else {
            avatarWidget = Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 100, 70, 200),
                    Color.fromARGB(255, 150, 100, 230),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // ====== HEADER: AVATAR, IKON EDIT, NAMA, EMAIL ======
                  Center(
                    child: Column(
                      children: [
                        // GestureDetector agar avatar bisa ditekan untuk memilih foto
                        GestureDetector(
                          onTap: _pickAndUploadProfileImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Tambahkan shadow pada avatar
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child:
                                    avatarWidget, // Widget avatar sesuai kondisi
                              ),

                              // Ikon edit kecil di pojok kanan bawah avatar
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayEmail,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to change',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ====== PANEL 1: AKUN & PENGATURAN ======
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.person_outline,
                            label: "Account Information",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AccountInformationScreen(
                                    regData: widget.regData,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildMenuTile(
                            icon: Icons.lock_reset,
                            label: "Change Password",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangePasswordScreen(
                                    regData: widget.regData,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildMenuTile(
                            icon: Icons.history,
                            label: "Login Activity",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginActivityScreen(
                                    registrationData: widget.regData,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildMenuTile(
                            icon: Icons.settings,
                            label: "Application Settings",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ApplicationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ====== PANEL 2: BANTUAN, KETENTUAN, & LOGOUT ======
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.support_agent,
                            label: "Support Center",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SupportCenterScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildMenuTile(
                            icon: Icons.article,
                            label: "Terms and Conditions",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsConditionScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildMenuTile(
                            icon: Icons.privacy_tip,
                            label: "Privacy and Policy",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildMenuTile(
                            icon: Icons.logout,
                            label: "Log Out Account",
                            iconColor: Colors.redAccent,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),

      // FAB dengan warna dan ikon sesuai state (tetap sama)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(_fabIcon),
        onPressed: () {},
      ),
      floatingActionButtonLocation: _fabLocation,

      // BottomAppBar tetap seperti semula
      bottomNavigationBar: BottomAppBar(
        color: Colors.black45,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.dashboard, color: Colors.white),
              onPressed: () async {
                setState(() {
                  _fabLocation = dashboardLocation;
                  _fabIcon = Icons.dashboard;
                });
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HomeScreen(registrationData: widget.regData),
                  ),
                );
                setState(() {
                  _fabLocation = personLocation;
                  _fabIcon = Icons.person;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.book, color: Colors.white),
              onPressed: () async {
                setState(() {
                  _fabLocation = bookLocation;
                  _fabIcon = Icons.book;
                });
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DiaryScreen(registrationData: widget.regData),
                  ),
                );
                setState(() {
                  _fabLocation = personLocation;
                  _fabIcon = Icons.person;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () async {
                setState(() {
                  _fabLocation = calendarLocation;
                  _fabIcon = Icons.calendar_today;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CommunityScreen(regData: widget.regData),
                  ),
                ).then((_) {
                  setState(() {
                    _fabLocation = personLocation;
                    _fabIcon = Icons.person;
                  });
                });
              },
            ),
            Opacity(
              opacity: 0.0,
              child: IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper untuk membuat satu baris menu dengan icon dan label
  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}
