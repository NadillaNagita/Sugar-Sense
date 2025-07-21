import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan ini
import 'registration_data.dart';
import 'create_account_password_screen.dart';

class CreateAccountEmailScreen extends StatefulWidget {
  final RegistrationData regData;
  const CreateAccountEmailScreen({Key? key, required this.regData})
      : super(key: key);

  @override
  State<CreateAccountEmailScreen> createState() =>
      _CreateAccountEmailScreenState();
}

class _CreateAccountEmailScreenState extends State<CreateAccountEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isReadOnly = false;

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    RegExp emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return email.isNotEmpty && emailRegex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.regData.email ?? "";
    _emailController.addListener(() {
      setState(() {});
    });

    // Bikin readonly kalau dari Google atau Facebook
    _isReadOnly =
        widget.regData.isGoogleSignIn || widget.regData.isFacebookSignIn;
  }

  /// ✅ Versi terbaru untuk cek email di Firestore
  Future<bool> checkEmailExists(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('user') // ganti sesuai koleksi kamu
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  void _showEmailExistsAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Email Already Exists"),
        content: const Text(
            "This email has already been used. Please try another one."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isReadOnly = false;
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    final email = _emailController.text.trim();
    bool emailExists = await checkEmailExists(email);

    if (emailExists) {
      _showEmailExistsAlert();
      // Jika dari Google atau Facebook, setelah alert, izinkan edit
      if (widget.regData.isGoogleSignIn || widget.regData.isFacebookSignIn) {
        setState(() {
          widget.regData.isGoogleSignIn = false;
          widget.regData.isFacebookSignIn = false;
          _isReadOnly = false;
        });
      }
    } else {
      widget.regData.email = email;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateAccountPasswordScreen(regData: widget.regData),
        ),
      );
    }
  }

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
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(10),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "Create account",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Please enter a new email. We will ask for this email whenever you sign in.",
                    textAlign: TextAlign.center,
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
                        const Icon(Icons.email, color: Colors.white54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Email",
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                            readOnly: _isReadOnly,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Enter a valid email address to associate with this account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isEmailValid ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isEmailValid ? Colors.green : Colors.grey,
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
                                // TODO: Open T&C
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy.",
                            style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Open Privacy Policy
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
