import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'registration_data.dart';
import 'create_account_name_screen.dart';

class CreateAccountPasswordScreen extends StatefulWidget {
  final RegistrationData regData;
  const CreateAccountPasswordScreen({Key? key, required this.regData})
      : super(key: key);

  @override
  State<CreateAccountPasswordScreen> createState() =>
      _CreateAccountPasswordScreenState();
}

class _CreateAccountPasswordScreenState
    extends State<CreateAccountPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true; // Untuk toggle visibility password

  // Contoh validasi minimal 8 karakter
  bool get _isPasswordValid => _passwordController.text.trim().length >= 8;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Logika sederhana untuk menampilkan "strength" password
  String get _passwordStrengthText {
    final length = _passwordController.text.trim().length;
    if (length >= 12) {
      return "Very Strong!";
    } else if (length >= 10) {
      return "Strong!";
    } else if (length >= 8) {
      return "Medium!";
    } else if (length > 0) {
      return "Weak!";
    }
    return "";
  }

  /// Warna text "Password Strength" berdasarkan hasil strength
  Color get _passwordStrengthColor {
    switch (_passwordStrengthText) {
      case "Very Strong!":
        return Colors.green;
      case "Strong!":
        return Colors.lightGreen;
      case "Medium!":
        return Colors.orange;
      case "Weak!":
        return Colors.redAccent;
      default:
        return Colors.transparent; // Tidak ada teks
    }
  }

  void _continue() {
    // Validasi password
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Password must be at least 8 characters.")),
      );
      return;
    }
    // Simpan password ke registrationData
    widget.regData.password = _passwordController.text.trim();

    // Lanjut ke screen berikutnya
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAccountNameScreen(regData: widget.regData),
      ),
    );
  }

  /// Contoh fungsi progress indicator (misal 8 titik).
  /// Ubah jumlah titik dan currentStep sesuai kebutuhan flow Anda.
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
      // Latar belakang ungu gelap
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),

      body: SafeArea(
        child: Stack(
          children: [
            // Panah kembali di kiri atas
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Indikator titik di atas tengah (misal step ke-4)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(11),
            ),

            // Konten utama
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40), // Agar tidak ketumpuk arrow
                  // Judul
                  const Text(
                    "Create account",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Subjudul
                  const Text(
                    textAlign: TextAlign.center,
                    "Please enter a new password. We will ask for this password whenever you sign in.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "",
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () =>
                              setState(() => _isObscure = !_isObscure),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Keterangan minimal password 8 karakter dsb.
                  const Text(
                    textAlign: TextAlign.center,
                    "Passwords must be at least 8 characters. Try to include an uppercase character, numbers and symbols (like ! and &).",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Password Strength
                  if (_passwordController.text.trim().isNotEmpty)
                    Text(
                      "Password Strength: $_passwordStrengthText",
                      style: TextStyle(
                        fontSize: 14,
                        color: _passwordStrengthColor,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Tombol Continue (disabled jika password < 8 karakter)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isPasswordValid ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isPasswordValid ? Colors.green : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Disclaimer di bawah
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "By continuing you agree to the ",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms and Conditions",
                            style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Buka halaman Terms & Conditions
                              },
                          ),
                          const TextSpan(
                            text: " and ",
                          ),
                          TextSpan(
                            text: "Privacy Policy.",
                            style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Buka halaman Privacy Policy
                              },
                          ),
                        ],
                      ),
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
