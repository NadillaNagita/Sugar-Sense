import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration_data.dart';
import 'home_screen.dart';

class CreateAccountNameScreen extends StatefulWidget {
  final RegistrationData regData;
  const CreateAccountNameScreen({Key? key, required this.regData})
      : super(key: key);

  @override
  State<CreateAccountNameScreen> createState() =>
      _CreateAccountNameScreenState();
}

class _CreateAccountNameScreenState extends State<CreateAccountNameScreen> {
  final TextEditingController _nameController = TextEditingController();

  // Valid jika nama tidak kosong dan sama persis dengan firstName yang sebelumnya
  bool get _isNameValid {
    final nameInput = _nameController.text.trim();
    final firstName = widget.regData.firstName ?? "";
    return nameInput.isNotEmpty && nameInput == firstName;
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate dengan firstName (jika ada)
    _nameController.text = widget.regData.firstName ?? "";
  }

  /// Fungsi untuk menyimpan nama ke Firestore.
  Future<void> _saveNameToFirestore(String name) async {
    // Jika docID belum ada, buat dokumen baru di koleksi 'user'
    if (widget.regData.docID == null) {
      final newDocRef = FirebaseFirestore.instance.collection('user').doc();
      widget.regData.docID = newDocRef.id;
    }
    // Merge data ke dokumen Firestore dengan menggunakan docID yang sama
    await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.regData.docID)
        .set({
      'email': widget.regData.email,
      'password': widget.regData.password,
      'name': name,
      'docID': widget.regData.docID,
      'firstName': widget.regData.firstName,
      'goal': widget.regData.goal,
      'targetWeight': widget.regData.targetWeight,
      'gender': widget.regData.gender,
      'activityLevel': widget.regData.activityLevel,
      'currentWeight': widget.regData.currentWeight,
      'height': widget.regData.height,
      'dateOfBirth': widget.regData.dateOfBirth,
      // Tambahkan field lain jika perlu
    }, SetOptions(merge: true));
  }

  void _continue() async {
    if (!_isNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account name must match your first name."),
        ),
      );
      return;
    }
    widget.regData.name = _nameController.text.trim();
    try {
      await _saveNameToFirestore(widget.regData.name!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(registrationData: widget.regData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    }
  }

  /// Fungsi progress indicator (misal 9 titik).
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background ungu gelap
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      body: SafeArea(
        child: Stack(
          children: [
            // Tombol back di kiri atas
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Progress indicator di top center (misal: step ke-9)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(12),
            ),
            // Konten utama
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                      height: 40), // Agar tidak bertumpuk dengan arrow
                  const Text(
                    "Create account",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Please enter your account name. This name will be displayed on your profile.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Kolom input untuk account name dengan tampilan seperti kolom password
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Account name",
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Enter your account name. This is how your name will appear to other users.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  // Tombol Finish
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isNameValid ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isNameValid ? Colors.green : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Finish",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Disclaimer
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "By finishing, you agree to the ",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
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
                          const TextSpan(text: " and "),
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
