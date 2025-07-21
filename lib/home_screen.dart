import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'diary_screen.dart';
import 'profile_screen.dart';
import 'registration_data.dart';
import 'usda_api_service.dart';
import 'community_screen.dart';

// Kelas kustom FABLocation untuk posisi FAB
class FractionalOffsetFabLocation extends FloatingActionButtonLocation {
  final double fraction;
  FractionalOffsetFabLocation(this.fraction);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabWidth = scaffoldGeometry.floatingActionButtonSize.width;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double scaffoldWidth = scaffoldGeometry.scaffoldSize.width;

    final double x = fraction * scaffoldWidth - (fabWidth / 2);
    final double contentBottom = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.minViewPadding.bottom;
    final double y = contentBottom - fabHeight - 16.0;

    return Offset(x, y);
  }
}

// Posisi FAB untuk masing-masing ikon di BottomAppBar
final dashboardLocation = FractionalOffsetFabLocation(0.125);
final bookLocation = FractionalOffsetFabLocation(0.375);
final calendarLocation = FractionalOffsetFabLocation(0.625);
final personLocation = FractionalOffsetFabLocation(0.875);

class HomeScreen extends StatefulWidget {
  final RegistrationData registrationData;
  const HomeScreen({Key? key, required this.registrationData})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // FAB default: di posisi Dashboard (kiri)
  FloatingActionButtonLocation _fabLocation = dashboardLocation;
  IconData _fabIcon = Icons.dashboard;

  List<Map<String, dynamic>>? _foodList;

  @override
  void initState() {
    super.initState();
    _saveDataToFirestore();
    _loadNutritionData();
  }

  // Fungsi format tanggal
  String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  // Simpan data ke Firestore (jika docID belum ada)
  Future<void> _saveDataToFirestore() async {
    final regData = widget.registrationData;
    if (regData.docID == null) {
      final newDocRef = FirebaseFirestore.instance.collection('user').doc();
      regData.docID = newDocRef.id;
      try {
        await newDocRef.set({
          'docID': regData.docID,
          'firstName': regData.firstName,
          'name': regData.name,
          'email': regData.email,
          'goal': regData.goal,
          'targetWeight': regData.targetWeight,
          'gender': regData.gender,
          'activityLevel': regData.activityLevel,
          'currentWeight': regData.currentWeight,
          'height': regData.height,
          'dateOfBirth': regData.dateOfBirth != null
              ? formatDate(regData.dateOfBirth!)
              : "Not set",
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving data: $e")),
          );
        }
      }
    }
  }

  // Hitung TDEE user
  double _calculateUserTDEE() {
    final regData = widget.registrationData;
    final currentWeight = double.tryParse(regData.currentWeight ?? "0") ?? 0;
    final height = double.tryParse(regData.height ?? "0") ?? 0;
    final gender = regData.gender ?? "Male";
    final activity = regData.activityLevel ?? "Sedentary";
    final goal = regData.goal ?? "Maintenance";

    // Perkiraan usia (sederhana)
    int age = 25;
    if (regData.dateOfBirth != null) {
      final now = DateTime.now();
      age = now.year - regData.dateOfBirth!.year;
    }

    // 1) Hitung BMR
    double bmr;
    if (gender.toLowerCase() == "male") {
      bmr = 10 * currentWeight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * currentWeight + 6.25 * height - 5 * age - 161;
    }

    // 2) Activity factor
    double factor;
    switch (activity.toLowerCase()) {
      case "lightly active":
        factor = 1.375;
        break;
      case "moderately active":
        factor = 1.55;
        break;
      case "very active":
        factor = 1.725;
        break;
      case "extra active":
        factor = 1.9;
        break;
      default:
        factor = 1.2; // Sedentary
        break;
    }

    // 3) TDEE
    double tdee = bmr * factor;

    // 4) Sesuaikan dengan goal (surplus/defisit)
    if (goal.toLowerCase().contains("gain")) {
      tdee += 300;
    } else if (goal.toLowerCase().contains("loss")) {
      tdee -= 300;
    }

    return tdee;
  }

  // Tentukan query untuk USDA API berdasarkan goal user
  String _getSearchQueryFromGoal(String? goal) {
    if (goal == null) return "balanced foods";
    switch (goal.toLowerCase()) {
      case "weight loss":
        return "low calorie snack";
      case "weight gain":
        return "high calorie foods";
      default:
        return "balanced foods";
    }
  }

  // Filter hasil USDA sesuai TDEE dan kebutuhan nutrisi
  bool _passesFilter(
      double energy, double protein, double userTDEE, String goal) {
    final g = goal.toLowerCase();
    if (g.contains("gain")) {
      // Weight Gain: energi <= 50% TDEE & protein >= 10 g
      return (energy <= userTDEE * 0.50 && protein >= 10);
    } else if (g.contains("loss")) {
      // Weight Loss: energi <= 25% TDEE & protein >= 8 g
      return (energy <= userTDEE * 0.25 && protein >= 8);
    } else {
      // Maintenance: energi <= 30% TDEE & protein >= 10 g
      return (energy <= userTDEE * 0.30 && protein >= 10);
    }
  }

  // Load data nutrisi: ambil data dari Firestore jika sudah tersimpan
  // jika belum, panggil USDA API untuk filtering, kemudian simpan ke Firestore
  Future<void> _loadNutritionData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.registrationData.docID)
          .get();

      if (userDoc.exists &&
          userDoc.data()?.containsKey('recommendedFoods') == true) {
        // Ambil data rekomendasi yang sudah tersimpan
        setState(() {
          _foodList = List<Map<String, dynamic>>.from(
              userDoc.data()!['recommendedFoods']);
        });
      } else {
        // Jika data belum ada, lakukan pemanggilan dan filtering USDA API
        final userGoal = widget.registrationData.goal ?? 'Maintenance';
        final query = _getSearchQueryFromGoal(userGoal);
        final searchResults = await USDAApiService().searchFoods(query);

        final userTDEE = _calculateUserTDEE();
        final List<Map<String, dynamic>> finalFoods = [];

        for (var item in searchResults) {
          final foodId = item['fdcId']?.toString();
          if (foodId == null) continue;

          final detail = await USDAApiService().fetchFoodData(foodId);
          final nutrients = detail['foodNutrients'] as List<dynamic>?;

          if (nutrients == null) continue;

          double energy = 0;
          double protein = 0;

          final energyObj = nutrients.firstWhere(
            (n) => n['nutrient'] != null && n['nutrient']['name'] == 'Energy',
            orElse: () => null,
          );
          if (energyObj != null && energyObj['amount'] != null) {
            energy = (energyObj['amount'] as num).toDouble();
          }

          final proteinObj = nutrients.firstWhere(
            (n) => n['nutrient'] != null && n['nutrient']['name'] == 'Protein',
            orElse: () => null,
          );
          if (proteinObj != null && proteinObj['amount'] != null) {
            protein = (proteinObj['amount'] as num).toDouble();
          }

          if (!_passesFilter(energy, protein, userTDEE, userGoal)) {
            continue;
          }

          finalFoods.add({
            'description': detail['description'] ?? 'No Description',
            'energy': energy,
            'protein': protein,
          });
        }

        // Simpan data rekomendasi ke Firestore
        await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.registrationData.docID)
            .update({'recommendedFoods': finalFoods});

        if (mounted) {
          setState(() {
            _foodList = finalFoods;
          });
        }
      }
    } catch (e) {
      print("Error fetching USDA data: $e");
      if (mounted) {
        setState(() {
          _foodList = [];
        });
      }
    }
  }

  // Widget untuk menampilkan chart 2-ring (lapisan) untuk TDEE
  Widget _buildTwoLayerChart(double userTDEE) {
    final double outerValue = (userTDEE / 4000).clamp(0, 1);
    final double innerValue = outerValue * 0.6;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: outerValue,
              strokeWidth: 12,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Colors.purple),
            ),
          ),
          SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
              value: innerValue,
              strokeWidth: 12,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Colors.cyan),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userTDEE.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "kcal",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userTDEE = _calculateUserTDEE();

    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      // BottomAppBar dengan empat ikon (Dashboard disembunyikan) + FAB
      bottomNavigationBar: BottomAppBar(
        color: Colors.black45,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1) Dashboard disembunyikan (pakai Opacity 0.0)
            Opacity(
              opacity: 0.0, // Ikon tidak terlihat
              child: IconButton(
                icon: const Icon(Icons.dashboard, color: Colors.white),
                onPressed: () {
                  // Kosong atau tidak perlu aksi
                  // Supaya spacing empat kolom tetap ada
                },
              ),
            ),

            // 2) Ikon Book
            IconButton(
              icon: const Icon(Icons.book, color: Colors.white),
              onPressed: () async {
                setState(() {
                  _fabLocation = bookLocation;
                  _fabIcon = Icons.book;
                });
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiaryScreen(
                      registrationData: widget.registrationData,
                    ),
                  ),
                );
                setState(() {
                  _fabLocation = dashboardLocation;
                  _fabIcon = Icons.dashboard;
                });
              },
            ),

            // 3) Ikon Calendar
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () {
                // 1) Update FAB ke posisi Community
                setState(() {
                  _fabIcon = Icons.calendar_today;
                });

                // 2) Navigasi ke CommunityScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CommunityScreen(regData: widget.registrationData),
                  ),
                ).then((_) {
                  // 3) Saat kembali, reset FAB ke Dashboard (atau Person, sesuai kebutuhan)
                  setState(() {
                    _fabLocation = dashboardLocation;
                    _fabIcon = Icons.dashboard;
                  });
                });
              },
            ),

            // 4) Ikon Person
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () async {
                setState(() {
                  _fabLocation = personLocation;
                  _fabIcon = Icons.person;
                });
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(regData: widget.registrationData),
                  ),
                );
                setState(() {
                  _fabLocation = dashboardLocation;
                  _fabIcon = Icons.dashboard;
                });
              },
            ),
          ],
        ),
      ),

      // FAB dengan lokasi di Dashboard (kiri) secara default
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(_fabIcon),
        onPressed: () {
          // Aksi FAB jika diperlukan
        },
      ),
      floatingActionButtonLocation: _fabLocation,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "Sugar Sense",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 207, 67, 231),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Card TDEE dengan chart 2-layer
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Estimated TDEE",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${userTDEE.toStringAsFixed(0)} kcal/day",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: _buildTwoLayerChart(userTDEE),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Card Recommended Foods
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Recommended Foods",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_foodList == null)
                              const Center(child: CircularProgressIndicator())
                            else if (_foodList!.isEmpty)
                              const Text(
                                "No foods found matching your needs.",
                                style: TextStyle(color: Colors.white70),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _foodList!.length,
                                itemBuilder: (context, index) {
                                  final item = _foodList![index];
                                  final desc =
                                      item['description'] ?? 'No Description';
                                  final energy = item['energy'] ?? 0;
                                  final protein = item['protein'] ?? 0;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      desc,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      "${energy.toStringAsFixed(0)} kcal | ${protein.toStringAsFixed(1)} g protein",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
