// change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration_data.dart';

class ChangePasswordScreen extends StatefulWidget {
  final RegistrationData regData;
  const ChangePasswordScreen({Key? key, required this.regData})
      : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // 1) Verifikasi password lama menggunakan regData.password
    if (currentPassController.text != widget.regData.password) {
      setState(() {
        _isLoading = false;
        _errorText = 'Current password is incorrect';
      });
      return;
    }

    // 2) Update ke Firestore dan ke objek regData
    try {
      final newPass = newPassController.text.trim();

      // Simulasi delay jika diperlukan
      await Future.delayed(const Duration(seconds: 1));

      // Update di Firestore: collection 'user' → doc(docID) → field 'password'
      final uid = widget.regData.docID;
      if (uid != null && uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(uid)
            .update({'password': newPass});
      }

      // Update di objek RegistrationData
      setState(() {
        widget.regData.password = newPass;
        _isLoading = false;
      });

      // Kembali dan tampilkan snackbar sukses
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to update password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Judul
                const Text(
                  "Change Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your current and new password below.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Panel semi‐transparan untuk form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Jika ada error, tampilkan teks merah
                        if (_errorText != null) ...[
                          Text(
                            _errorText!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Field: Current Password
                        _buildPasswordField(
                          label: "Current Password",
                          controller: currentPassController,
                        ),
                        const SizedBox(height: 20),

                        // Field: New Password
                        _buildPasswordField(
                          label: "New Password",
                          controller: newPassController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "New Password cannot be empty";
                            }
                            if (value.length < 6) {
                              return "New Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Field: Confirm New Password
                        _buildPasswordField(
                          label: "Confirm New Password",
                          controller: confirmPassController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Confirm New Password cannot be empty";
                            }
                            if (value != newPassController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Tombol Change Password
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A78B5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _changePassword,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Change Password",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                // Tombol “Back to Profile” tanpa border
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Back to Profile",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A78B5), width: 2),
        ),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return "$label cannot be empty";
            }
            return null;
          },
    );
  }
}
