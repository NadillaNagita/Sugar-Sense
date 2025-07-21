import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'goal_screen.dart';
import 'registration_data.dart';
import 'login_screen.dart';

class FirstNameScreen extends StatefulWidget {
  final RegistrationData?
      regData; // Data pendaftaran yang sudah ada (misal dari Google)
  const FirstNameScreen({Key? key, this.regData}) : super(key: key);

  @override
  State<FirstNameScreen> createState() => _FirstNameScreenState();
}

class _FirstNameScreenState extends State<FirstNameScreen> {
  final TextEditingController _firstNameController = TextEditingController();

  // Fungsi untuk mengekstrak first name dari email.
  // Contoh: "rudiyantozone@gmail.com" akan menghasilkan "Rudi"
  String extractFirstName(String email) {
    if (email.contains('@')) {
      final namePart = email.split('@')[0];
      final firstName =
          namePart.length >= 4 ? namePart.substring(0, 4) : namePart;
      return firstName[0].toUpperCase() + firstName.substring(1);
    }
    return "";
  }

  @override
  void initState() {
    super.initState();
    // Jika sudah ada data (misal dari Google), prefill first name.
    // Jika firstName kosong, coba ekstrak dari email (jika tersedia).
    if (widget.regData != null) {
      if (widget.regData!.firstName == null ||
          widget.regData!.firstName!.isEmpty) {
        if (widget.regData!.email != null &&
            widget.regData!.email!.isNotEmpty) {
          _firstNameController.text = extractFirstName(widget.regData!.email!);
        }
      } else {
        _firstNameController.text = widget.regData!.firstName!;
      }
    }
  }

  // Fungsi untuk melanjutkan ke GoalScreen dengan RegistrationData yang sudah diperbarui.
  void _continue() {
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your first name")),
      );
      return;
    }
    // Jika regData sudah ada, update firstName-nya; jika belum, buat baru.
    RegistrationData regData = widget.regData ?? RegistrationData();
    regData.firstName = firstName;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GoalScreen(regData: regData),
      ),
    );
  }

  // Fungsi untuk navigasi ke halaman LoginScreen.
  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // Fungsi untuk membangun progress indicator (12 titik) dengan titik aktif sesuai currentStep.
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
            // Tombol back di pojok kiri atas.
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
            // Slider indikator (12 titik) di top center dengan titik pertama aktif.
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(1),
            ),
            // Konten utama di bagian tengah layar.
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 80.0, 24.0, 80.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "First name",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Hi! We'd like to get to know you to make the app personalized to you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _firstNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "First name",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Privacy",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Your first name is private and only ever visible to you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Bagian bawah: tombol arrow dan teks "Got An Account? Sign In".
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
