import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'current_weight_screen.dart';
import 'registration_data.dart';
import 'login_screen.dart';

class ActivityLevelScreen extends StatefulWidget {
  final RegistrationData regData;
  const ActivityLevelScreen({Key? key, required this.regData})
      : super(key: key);

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  String? _selectedActivity;

  void _continue() {
    if (_selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your activity level.")),
      );
      return;
    }
    widget.regData.activityLevel = _selectedActivity;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurrentWeightScreen(regData: widget.regData),
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

  void _goBack() {
    Navigator.pop(context);
  }

  // Indikator 7 titik, currentStep menandakan titik mana yang aktif.
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

  // Widget opsi Activity Level, mirip dengan opsi gender.
  Widget _buildActivityOption(String label) {
    final bool isSelected = (_selectedActivity == label);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivity = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white54,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _goBack,
              ),
            ),

            // Indikator 7 titik di tengah atas (misal langkah ke-5)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(5),
            ),

            // Konten utama: judul, deskripsi, dan opsi activity level
            Center(
              child: Padding(
                // Kurangi padding agar konten tidak terlalu jauh ke bawah
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Activity Level",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please select your activity level.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildActivityOption("Sedentary"),
                    _buildActivityOption("Lightly Active"),
                    _buildActivityOption("Moderately Active"),
                    _buildActivityOption("Very Active"),
                    _buildActivityOption("Extra Active"),
                  ],
                ),
              ),
            ),

            // Bagian bawah: tombol arrow di tengah, dan "Got An Account? Sign In"
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
                      text: "Got An Account? ",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
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
