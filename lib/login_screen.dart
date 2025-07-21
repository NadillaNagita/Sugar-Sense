// login_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Firebase & Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Google Sign In
import 'package:google_sign_in/google_sign_in.dart';
// Facebook Sign In
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// Device Info & Location (untuk mencatat aktivitas login)
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Layar lain
import 'home_screen.dart';
import 'registration_data.dart';
import 'first_name_screen.dart';
import 'password_recovery_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Example',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

/// Halaman login (Email/Password via Firestore saja) + Google + Facebook.
/// Setelah login berhasil, fungsi `recordLoginActivity(uid)` dipanggil
/// agar Firestore: user/{uid}/login_activity ditambahkan dokumen baru.
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  /// Mencatat aktivitas login ke Firestore:
  ///   koleksi 'user' → doc(uid) → sub‐koleksi 'login_activity'.
  Future<void> recordLoginActivity(String uid) async {
    // 1) Deteksi jenis perangkat
    String deviceName = "Unknown";
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = "Android (${androidInfo.model})";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = "iOS (${iosInfo.utsname.machine})";
      } else {
        deviceName = "Web";
      }
    } catch (_) {
      deviceName = "Unknown";
    }

    // 2) Cek & Minta izin lokasi, lalu geocode → "City, Country"
    String locationText = "Unknown";
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          locationText = "${pm.locality}, ${pm.country}";
        }
      }
    } catch (_) {
      locationText = "Unknown";
    }

    // 3) Simpan dokumen baru di sub‐koleksi login_activity
    await FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('login_activity')
        .add({
      'timestamp': FieldValue.serverTimestamp(),
      'device': deviceName,
      'location': locationText,
    });
  }

  /// Login via Google → FirebaseAuth + kemudian catat aktivitas
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // user cancel

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      // Catat login activity
      await recordLoginActivity(user.uid);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Login via Facebook → FirebaseAuth + kemudian catat aktivitas
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final LoginResult result =
          await FacebookAuth.instance.login(permissions: ['email']);
      if (result.status != LoginStatus.success) return null;

      final accessToken = result.accessToken;
      if (accessToken == null) return null;

      final credential = FacebookAuthProvider.credential(accessToken.token);
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      // Catat login activity
      await recordLoginActivity(user.uid);

      // Jika email tidak ada, ambil dari Facebook data
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

  /// Ambil 4 huruf pertama dari bagian sebelum '@'
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
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

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
                  const SizedBox(height: 30),

                  // Field: Email
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Field: Password
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // BUTTON: Login dengan Email/Password (via Firestore manual)
                  ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text;
                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter email and password')),
                        );
                        return;
                      }

                      try {
                        // 0) Jika ada sesi Google/FB, keluarkan dulu
                        await FirebaseAuth.instance.signOut();

                        // 1) Ambil dokumen user dari Firestore (koleksi 'user')
                        final querySnapshot = await FirebaseFirestore.instance
                            .collection('user')
                            .where('email', isEqualTo: email)
                            .limit(1)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {
                          final userDoc = querySnapshot.docs.first;
                          final userData = userDoc.data();

                          // 2) Cek apakah password di Firestore cocok
                          if (userData['password'] == password) {
                            final docID = userDoc.id; // docID di Firestore

                            // 3) 🛈 CATAT LOGIN ACTIVITY (gunakan docID)
                            await recordLoginActivity(docID);

                            // 4) Siapkan objek RegistrationData
                            DateTime? dob;
                            if (userData['dateOfBirth'] != null &&
                                userData['dateOfBirth'] != "Not set") {
                              try {
                                dob = DateFormat('dd-MM-yyyy')
                                    .parse(userData['dateOfBirth']);
                              } catch (_) {
                                dob = null;
                              }
                            }

                            final registrationData = RegistrationData(
                              docID: docID,
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

                            // 5) Navigasi ke HomeScreen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(
                                    registrationData: registrationData),
                              ),
                            );
                          } else {
                            // Password salah
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Incorrect password')),
                            );
                          }
                        } else {
                          // Email tidak terdaftar di Firestore
                          await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  "Email Not Registered",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  "The email $email is not registered. Please complete your account information.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
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

                          final regData = RegistrationData(
                            docID: '',
                            firstName: '',
                            name: '',
                            email: email,
                            goal: '',
                            targetWeight: '',
                            gender: '',
                            activityLevel: '',
                            currentWeight: '',
                            height: '',
                            dateOfBirth: null,
                            password: password,
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FirstNameScreen(regData: regData),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error logging in: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Log In',
                        style: TextStyle(color: Colors.white)),
                  ),

                  const SizedBox(height: 8),

                  // Tombol Lupa Password
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PasswordRecoveryScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot password?',
                        style: TextStyle(color: Colors.blueAccent)),
                  ),

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BUTTON: Login dengan Google
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
                          // Belum terdaftar di Firestore → minta lengkapi data
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
                          // Sudah ada → ambil data dan langsung ke Home
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
                                    registrationData: registrationData)),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error login with Google: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Continue with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BUTTON: Login dengan Facebook
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final fbResult = await signInWithFacebook();
                        if (fbResult == null) return;

                        final userFb = fbResult['user'] as User;
                        final emailFromFacebook = fbResult['email'] as String;
                        final docRef = FirebaseFirestore.instance
                            .collection('user')
                            .doc(userFb.uid);
                        final docSnap = await docRef.get();

                        if (!docSnap.exists) {
                          // Belum terdaftar di Firestore → minta lengkapi data
                          String firstName = "";
                          if (emailFromFacebook.isNotEmpty) {
                            firstName = extractFirstName(emailFromFacebook);
                          }
                          final regData = RegistrationData(
                            docID: userFb.uid,
                            firstName: firstName,
                            name: userFb.displayName ?? "",
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
                          // Sudah ada → ambil data, ke HomeScreen
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
                                    registrationData: registrationData)),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error login with Facebook: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    label: const Text('Continue with Facebook'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'We will never post anything without your permission.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Header custom: Back arrow + label "Log In"
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () async {
                      await SystemChannels.textInput
                          .invokeMethod('TextInput.hide');
                      await Future.delayed(const Duration(milliseconds: 200));
                      Navigator.pop(context);
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Log In",
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
