import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:intl/intl.dart';

// Import file lain (RegistrationData, FirstNameScreen, HomeScreen)
import 'registration_data.dart';
import 'first_name_screen.dart';
import 'home_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  // Sign In dengan Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null; // User batal pilih akun
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In dengan Facebook
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success) {
        return null; // User batal login atau error
      }
      final accessToken = result.accessToken;
      if (accessToken == null) return null;

      final credential = FacebookAuthProvider.credential(accessToken.token);
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;
      if (user == null) return null;

      String email = user.email ?? '';
      if (email.isEmpty) {
        final fbData = await FacebookAuth.instance.getUserData();
        email = fbData['email'] ?? '';
      }
      return {'user': user, 'email': email};
    } catch (e) {
      rethrow;
    }
  }

  // Ekstrak nama depan dari email
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      body: SafeArea(
        child: Stack(
          children: [
            // Konten utama
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100),
                  const Text(
                    "Welcome! Let's customize Sugar Sense for your goals.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Continue manual
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FirstNameScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      "OR",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Continue with Google
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final user = await signInWithGoogle();
                        if (user == null) return;

                        final docRef = FirebaseFirestore.instance
                            .collection('user')
                            .doc(user.uid);
                        final docSnap = await docRef.get();

                        if (!docSnap.exists) {
                          // Dokumen belum ada → tampilkan dialog
                          String firstName = "";
                          if (user.email != null && user.email!.isNotEmpty) {
                            firstName = extractFirstName(user.email!);
                          }

                          final regData = RegistrationData(
                            docID: user.uid,
                            firstName: firstName,
                            name: user.displayName ?? "",
                            email: user.email ?? "",
                            goal: "",
                            targetWeight: "",
                            gender: "",
                            activityLevel: "",
                            currentWeight: "",
                            height: "",
                            dateOfBirth: null,
                            password: "",
                          );

                          // Tampilkan dialog dan tunggu hasil
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  "Email Not Registered",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  "The email ${user.email} is not registered. Please complete your account information.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Tutup dialog & return true
                                      Navigator.of(dialogContext).pop(true);
                                    },
                                    child: const Text(
                                      "OK",
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          // Jika user menekan OK, langsung navigasi ke FirstNameScreen
                          if (result == true) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FirstNameScreen(regData: regData),
                              ),
                            );
                          }
                        } else {
                          // Dokumen sudah ada → ambil data dan ke HomeScreen
                          final userData = docSnap.data()!;
                          DateTime? dob;
                          if (userData['dateOfBirth'] != null &&
                              userData['dateOfBirth'] != "Not set") {
                            try {
                              dob = DateFormat('dd-MM-yyyy')
                                  .parse(userData['dateOfBirth']);
                            } catch (_) {}
                          }
                          final registrationData = RegistrationData(
                            docID: userData['docID'],
                            firstName: userData['firstName'],
                            name: userData['name'],
                            email: userData['email'],
                            goal: userData['goal'],
                            targetWeight: userData['targetWeight'],
                            gender: userData['gender'],
                            activityLevel: userData['activityLevel'],
                            currentWeight: userData['currentWeight'],
                            height: userData['height'],
                            dateOfBirth: dob,
                            password: userData['password'],
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(
                                  registrationData: registrationData),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error signing in with Google: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text("Continue with Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Continue with Facebook
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final fbResult = await signInWithFacebook();
                        if (fbResult == null) return;

                        final user = fbResult['user'] as User;
                        final emailFromFacebook = fbResult['email'] as String;
                        final docRef = FirebaseFirestore.instance
                            .collection('user')
                            .doc(user.uid);
                        final docSnap = await docRef.get();

                        if (!docSnap.exists) {
                          // Dokumen belum ada → tampilkan dialog
                          String firstName = "";
                          if (emailFromFacebook.isNotEmpty) {
                            firstName = extractFirstName(emailFromFacebook);
                          }

                          final regData = RegistrationData(
                            docID: user.uid,
                            firstName: firstName,
                            name: user.displayName ?? "",
                            email: emailFromFacebook,
                            goal: "",
                            targetWeight: "",
                            gender: "",
                            activityLevel: "",
                            currentWeight: "",
                            height: "",
                            dateOfBirth: null,
                            password: "",
                          );

                          // Tampilkan dialog dan tunggu hasil
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  "Email Not Registered",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  "The email $emailFromFacebook is not registered. Please complete your account information.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Tutup dialog & return true
                                      Navigator.of(dialogContext).pop(true);
                                    },
                                    child: const Text(
                                      "OK",
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          // Jika user menekan OK, langsung navigasi ke FirstNameScreen
                          if (result == true) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FirstNameScreen(regData: regData),
                              ),
                            );
                          }
                        } else {
                          // Dokumen sudah ada → ambil data dan ke HomeScreen
                          final userData = docSnap.data()!;
                          DateTime? dob;
                          if (userData['dateOfBirth'] != null &&
                              userData['dateOfBirth'] != "Not set") {
                            try {
                              dob = DateFormat('dd-MM-yyyy')
                                  .parse(userData['dateOfBirth']);
                            } catch (_) {}
                          }
                          final registrationData = RegistrationData(
                            docID: userData['docID'],
                            firstName: userData['firstName'],
                            name: userData['name'],
                            email: userData['email'],
                            goal: userData['goal'],
                            targetWeight: userData['targetWeight'],
                            gender: userData['gender'],
                            activityLevel: userData['activityLevel'],
                            currentWeight: userData['currentWeight'],
                            height: userData['height'],
                            dateOfBirth: dob,
                            password: userData['password'],
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(
                                  registrationData: registrationData),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error signing in with Facebook: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    label: const Text("Continue with Facebook"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    "We will collect personal information from you and use it for various purposes, including to customize your Sugar Sense experience. Read more about the purposes, our practices, your choices, and your rights in our Privacy Policy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Header
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
