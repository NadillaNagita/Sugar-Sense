import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'registration_data.dart';
import 'create_account_email_screen.dart';
import 'login_screen.dart';

class FinalSubmissionScreen extends StatefulWidget {
  final RegistrationData regData;
  const FinalSubmissionScreen({Key? key, required this.regData})
      : super(key: key);

  @override
  State<FinalSubmissionScreen> createState() => _FinalSubmissionScreenState();
}

class _FinalSubmissionScreenState extends State<FinalSubmissionScreen> {
  DateTime? selectedDOB;

  @override
  void initState() {
    super.initState();
    // Ambil nilai dateOfBirth dari registrationData (jika sudah diisi)
    selectedDOB = widget.regData.dateOfBirth;
  }

  void _showDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SizedBox(
          height: 300,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: selectedDOB ?? DateTime(2000, 1, 1),
            maximumDate: DateTime.now(),
            onDateTimeChanged: (newDate) {
              setState(() => selectedDOB = newDate);
            },
          ),
        );
      },
    ).whenComplete(() {
      // Update nilai dateOfBirth di registrationData setelah picker ditutup
      widget.regData.dateOfBirth = selectedDOB;
    });
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAccountEmailScreen(regData: widget.regData),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  /// Fungsi untuk membangun progress indicator berupa 7 titik.
  /// Misalnya, step aktif adalah step ke-2.
  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(12, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentStep - 1
                ? Colors.green
                : Colors.white.withOpacity(0.4),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dobText = selectedDOB != null
        ? "${selectedDOB!.day.toString().padLeft(2, '0')}-${selectedDOB!.month.toString().padLeft(2, '0')}-${selectedDOB!.year}"
        : "Not set";

    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      body: SafeArea(
        child: Stack(
          children: [
            // Tombol back di pojok kiri atas
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Progress indicator (7 titik) di top center
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(9), // misalnya step ke-2 aktif
            ),
            // Konten utama di tengah layar
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 80.0, 24.0, 580),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "What's your date of birth?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "We use your date of birth to help personalize your experience.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () => _showDatePicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dobText,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bagian bawah: tombol Next dan tulisan "Got an account? Sign In"
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: "Got an account? ",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _navigateToLogin,
                        ),
                      ],
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
