// account_information_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'registration_data.dart';

class AccountInformationScreen extends StatefulWidget {
  final RegistrationData regData;
  const AccountInformationScreen({Key? key, required this.regData})
      : super(key: key);

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  final _genderCtrl = TextEditingController();
  final _activityLevelCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _genderCtrl.dispose();
    _activityLevelCtrl.dispose();
    _targetWeightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  /// Widget untuk membuat field dengan styling seragam
  Widget _buildField({
    required String label,
    required String value,
    bool readOnly = false,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: readOnly ? TextInputType.text : keyboardType,
          style: TextStyle(
            color: readOnly ? Colors.white54 : Colors.white,
          ),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: value.isEmpty ? label : value,
            hintStyle: TextStyle(
              color: readOnly ? Colors.white54 : Colors.white54,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    final gender = _genderCtrl.text.trim();
    final activityLevel = _activityLevelCtrl.text.trim();
    final targetWeight = _targetWeightCtrl.text.trim();
    final currentWeight = _currentWeightCtrl.text.trim();
    final height = _heightCtrl.text.trim();

    setState(() => _isSaving = true);

    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(widget.regData.docID);

      await userDocRef.update({
        'gender': gender,
        'activityLevel': activityLevel,
        'targetWeight': targetWeight,
        'currentWeight': currentWeight,
        'height': height,
      });

      widget.regData.gender = gender;
      widget.regData.activityLevel = activityLevel;
      widget.regData.targetWeight = targetWeight;
      widget.regData.currentWeight = currentWeight;
      widget.regData.height = height;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account information updated')),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color.fromARGB(200, 33, 0, 83);
    final docRef =
        FirebaseFirestore.instance.collection('user').doc(widget.regData.docID);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: docRef.get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  "Data not found.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

            final firstName = data['firstName'] ?? '';
            final fullName = data['name'] ?? '';
            final email = data['email'] ?? '';

            String dobText = 'Not set';
            if (data['dateOfBirth'] != null &&
                data['dateOfBirth'] != 'Not set') {
              final dobValue = data['dateOfBirth'];
              if (dobValue is Timestamp) {
                dobText = DateFormat('dd-MM-yyyy').format(dobValue.toDate());
              } else if (dobValue is String) {
                dobText = dobValue;
              }
            }

            _genderCtrl.text = data['gender'] ?? '';
            _activityLevelCtrl.text = data['activityLevel'] ?? '';
            _targetWeightCtrl.text = data['targetWeight'] ?? '';
            _currentWeightCtrl.text = data['currentWeight'] ?? '';
            _heightCtrl.text = data['height'] ?? '';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Judul
                  const Text(
                    'Account Information',
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
                    'Review and update your personal details below.\n'
                    'Fields First Name, Full Name, Email, and Date of Birth are read-only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Panel semi‐transparan berisi form
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Row 1: First Name & Full Name (read-only)
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'First Name',
                                value: firstName,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                label: 'Full Name',
                                value: fullName,
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 2: Email & Date of Birth (read-only)
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'Email',
                                value: email,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                label: 'Date of Birth',
                                value: dobText,
                                readOnly: true,
                                suffixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 3: Gender & Activity Level (editable)
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'Gender',
                                value: _genderCtrl.text,
                                controller: _genderCtrl,
                                readOnly: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                label: 'Activity Level',
                                value: _activityLevelCtrl.text,
                                controller: _activityLevelCtrl,
                                readOnly: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 4: Target Weight & Current Weight
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'Target Weight (kg)',
                                value: _targetWeightCtrl.text,
                                controller: _targetWeightCtrl,
                                readOnly: false,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                label: 'Current Weight (kg)',
                                value: _currentWeightCtrl.text,
                                controller: _currentWeightCtrl,
                                readOnly: false,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 5: Height (full width)
                        _buildField(
                          label: 'Height (cm)',
                          value: _heightCtrl.text,
                          controller: _heightCtrl,
                          readOnly: false,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),

                        // Tombol Save Changes
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
                            onPressed: _isSaving ? null : _saveChanges,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
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

                  const SizedBox(height: 20),

                  // Tombol Back to Profile
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
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
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
