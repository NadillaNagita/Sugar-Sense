import 'package:flutter/material.dart';
import 'package:sugarsense/login_screen.dart';
import 'package:sugarsense/sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Contoh tampilan dengan tema gelap
    return Scaffold(
      backgroundColor: Color.fromARGB(200, 33, 0, 83),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            // Atur posisi children agar mirip dengan desain Anda
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bagian atas: teks "Welcome to myfitnesspal"
              Column(
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Welcome to',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bisa tambahkan subteks lagi kalau perlu
                  Text(
                    'Sugar Sense',
                    style: TextStyle(
                      color: Color.fromARGB(255, 207, 67, 231),
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ],
              ),

              // Bagian tengah: gambar dan/atau chart dummy
              // Gambar bisa diambil dari assets atau network
              Column(
                children: [
                  // Contoh pakai gambar dari asset
                  Container(
                    width: 200,
                    height: 200,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/images/welcome_image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 100),
                  // Contoh teks "Ready for some wins..."
                  const Text(
                    'Ready for some wins?\nStart tracking, it\'s easy!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              // Bagian bawah: tombol Sign Up dan Log In
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          // warna sesuai selera
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          )),
                      child: const Text(
                        'Sign Up For Free',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
