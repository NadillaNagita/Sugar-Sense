import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'gender_screen.dart';
import 'registration_data.dart';
import 'login_screen.dart';

class WeightScreen extends StatefulWidget {
  final RegistrationData regData;
  const WeightScreen({Key? key, required this.regData}) : super(key: key);

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final TextEditingController _weightController = TextEditingController();

  void _continue() {
    final text = _weightController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your target weight.")),
      );
      return;
    }
    widget.regData.targetWeight = text;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenderScreen(regData: widget.regData),
      ),
    );
  }

  // Fungsi untuk navigasi ke halaman LoginScreen
  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // Fungsi untuk membangun slider indikator dengan total 7 titik.
  // currentStep adalah angka 1-7 untuk menandai titik aktif.
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
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            // Slider indicator 7 titik di top center.
            // Untuk WeightScreen, misal currentStep = 3 (sesuai urutan)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(3),
            ),
            // Konten utama di bagian atas layar
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 80.0, 24.0, 80.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Target Weight",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please enter your target weight (kg).",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // TextField untuk input target weight
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter your target weight (kg)",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bagian bawah: tombol arrow di tengah dan tulisan "Got An Account? Sign In" di bawahnya
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
