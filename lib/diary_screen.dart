import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'community_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'registration_data.dart';
import 'food_suggestion.dart';
import 'usda_api_service.dart';

/// Custom FAB location using a fraction of screen width
class FractionalOffsetFabLocation extends FloatingActionButtonLocation {
  final double fraction;
  FractionalOffsetFabLocation(this.fraction);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry s) {
    final fabW = s.floatingActionButtonSize.width;
    final sw = s.scaffoldSize.width;
    final x = fraction * sw - fabW / 2;
    final fabH = s.floatingActionButtonSize.height;
    final bottom = s.scaffoldSize.height - s.minViewPadding.bottom;
    final y = bottom - fabH - 16;
    return Offset(x, y);
  }
}

// Predefined FAB positions for navigation bar
final dashLocation = FractionalOffsetFabLocation(0.2);
final diaryLocation = FractionalOffsetFabLocation(0.35);
final planLocation = FractionalOffsetFabLocation(0.65);
final profileLocation = FractionalOffsetFabLocation(0.8);

class DiaryScreen extends StatefulWidget {
  final RegistrationData registrationData;
  const DiaryScreen({Key? key, required this.registrationData})
      : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final USDAApiService _apiService = USDAApiService();

  Map<String, List<Map<String, dynamic>>>? _diaryData;
  Map<String, dynamic>? _dailySummary;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDiaryData(_selectedDate);
  }

  // -------------------- FIRESTORE LOAD/SAVE --------------------

  String _fmtDocId(DateTime d) => DateFormat('yyyyMMdd').format(d);
  String _fmtDateField(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadDiaryData(DateTime date) async {
    final col = FirebaseFirestore.instance.collection('diaries');
    final todayId = '${widget.registrationData.docID}_${_fmtDocId(date)}';

    // 1) Try fetch today's doc
    final todayDoc = await col.doc(todayId).get();
    if (todayDoc.exists) {
      _setDiaryFromRaw(todayDoc.get('meals') as Map<String, dynamic>);
      // Load saved summary if exists
      if (todayDoc.data()!.containsKey('summary')) {
        _dailySummary = todayDoc.get('summary') as Map<String, dynamic>;
      } else {
        _setDefaultSummary();
      }
      return;
    }

    // 2) If not found, try fetch yesterday's doc
    final prevDate = date.subtract(const Duration(days: 1));
    final prevId = '${widget.registrationData.docID}_${_fmtDocId(prevDate)}';
    final prevDoc = await col.doc(prevId).get();

    if (prevDoc.exists) {
      _setDiaryFromRaw(prevDoc.get('meals') as Map<String, dynamic>);
    } else {
      // First-ever day: empty lists
      _setDiaryData({
        'Breakfast': [],
        'Lunch': [],
        'Dinner': [],
        'Snacks': [],
      });
    }
    _setDefaultSummary();
  }

  void _setDefaultSummary() {
    final consumed = _totalCalories;
    final sugar = _totalSugar;
    final remaining = dailyCalorieGoal - consumed;
    _dailySummary = {
      'consumed': consumed,
      'remaining': remaining,
      'sugar': sugar,
    };
  }

  void _setDiaryFromRaw(Map<String, dynamic> raw) {
    final parsed = raw.map((meal, list) {
      return MapEntry(
        meal,
        (list as List).map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    });
    _setDiaryData(parsed);
  }

  void _setDiaryData(Map<String, List<Map<String, dynamic>>> data) {
    setState(() {
      _diaryData = data;
    });
  }

  Future<void> _saveDiaryData() async {
    if (_diaryData == null) return;

    // Recalculate summary
    final consumed = _totalCalories;
    final sugar = _totalSugar;
    final remaining = dailyCalorieGoal - consumed;
    _dailySummary = {
      'consumed': consumed,
      'remaining': remaining,
      'sugar': sugar,
    };

    final todayId =
        '${widget.registrationData.docID}_${_fmtDocId(_selectedDate)}';
    final dateStr = _fmtDateField(_selectedDate);

    await FirebaseFirestore.instance.collection('diaries').doc(todayId).set({
      'userId': widget.registrationData.docID,
      'date': dateStr,
      'meals': _diaryData,
      'summary': _dailySummary,
    }, SetOptions(merge: true));
  }

  // -------------------- PROFILE HELPERS --------------------

  double _getWeight() =>
      double.tryParse(widget.registrationData.currentWeight ?? '') ?? 0;
  double _getHeight() =>
      double.tryParse(widget.registrationData.height ?? '') ?? 0;
  int _getAge() {
    final dob = widget.registrationData.dateOfBirth;
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day))
      age--;
    return age;
  }

  double _getActivityFactor() {
    switch (widget.registrationData.activityLevel) {
      case 'Sedentary':
        return 1.2;
      case 'Lightly active':
        return 1.375;
      case 'Moderately active':
        return 1.55;
      case 'Very active':
        return 1.725;
      default:
        return 1.2;
    }
  }

  double _calculateBMR() {
    final w = _getWeight(), h = _getHeight(), a = _getAge();
    final g = widget.registrationData.gender?.toLowerCase() ?? '';
    return (g == 'male' || g == 'pria')
        ? 10 * w + 6.25 * h - 5 * a + 5
        : 10 * w + 6.25 * h - 5 * a - 161;
  }

  double _calculateTDEE() => _calculateBMR() * _getActivityFactor();
  double _calculateSugarLimit({double pct = 0.10}) =>
      (_calculateTDEE() * pct) / 4.0;
  int get dailyCalorieGoal => _calculateTDEE().round();
  double get dailySugarLimit => _calculateSugarLimit();

  // -------------------- MEAL TARGET CALCULATION --------------------

  double _targetCaloriesForMeal(String meal) {
    final total = dailyCalorieGoal.toDouble();
    switch (meal) {
      case 'Breakfast':
        return total * 0.25;
      case 'Lunch':
        return total * 0.30;
      case 'Dinner':
        return total * 0.30;
      case 'Snacks':
        return total * 0.15;
      default:
        return total * 0.25;
    }
  }

  final Map<String, List<String>> _mealKeywords = {
    'Breakfast': ['cereal', 'egg', 'pancake', 'toast'],
    'Lunch': ['sandwich', 'salad', 'rice', 'wrap', 'burger'],
    'Dinner': ['pasta', 'soup', 'steak', 'roast', 'casserole'],
    'Snacks': ['chips', 'cookie', 'bar', 'popcorn', 'fruit'],
  };

  // -------------------- SUGGESTION LOGIC --------------------

  Future<List<FoodSuggestion>> fetchSuggestions(String mealType) async {
    final kws = _mealKeywords[mealType] ?? ['food'];
    final seen = <String>{};
    final rawMaps = <Map<String, dynamic>>[];

    // kumpulkan ~20 unik
    for (final kw in kws) {
      final list = await _apiService.searchFoodsByMeal(kw, mealType);
      for (final e in list.cast<Map<String, dynamic>>()) {
        final desc = ((e['description'] as String?) ?? '').toLowerCase();
        if (seen.add(desc)) rawMaps.add(e);
        if (rawMaps.length >= 20) break;
      }
      if (rawMaps.length >= 20) break;
    }

    final target = _targetCaloriesForMeal(mealType);

    return rawMaps.take(10).map((orig) {
      final mod = Map<String, dynamic>.from(orig);

      final nutrients =
          (orig['foodNutrients'] as List).cast<Map<String, dynamic>>();
      final energyEntry = nutrients.firstWhere(
        (n) => (n['nutrientName'] as String).toLowerCase().contains('energy'),
        orElse: () => {'value': 0},
      );
      final sugarEntry = nutrients.firstWhere(
        (n) => (n['nutrientName'] as String).toLowerCase().contains('sugar'),
        orElse: () => {'value': 0.0},
      );

      final cal = (energyEntry['value'] as num).toDouble();
      final sugarVal = (sugarEntry['value'] as num).toDouble();
      final portion = (orig['servingSize'] as num?)?.toDouble() ?? 100.0;

      double scale = 1.0;
      if (cal < target * 0.8 || cal > target * 1.2) {
        scale = target / (cal == 0 ? target : cal);
      }

      // override nutrients supaya fromJson juga dapat baca versi ter-scaled
      mod['foodNutrients'] = [
        {'nutrientName': 'Energy', 'value': (cal * scale).round()},
        {'nutrientName': 'Sugar', 'value': (sugarVal * scale)},
      ];
      mod['servingSize'] = portion * scale;

      // field custom langsung
      mod['calories'] = (cal * scale).round();
      mod['sugar'] = (sugarVal * scale);

      return FoodSuggestion.fromJson(mod);
    }).toList();
  }

  Future<void> _showAddEntryDialog(String meal) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add to $meal'),
        content: FutureBuilder<List<FoodSuggestion>>(
          future: fetchSuggestions(meal),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Text('No suggestions available.');
            }
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final s = list[i];
                  var displayName = s.name.split(',')[0].trim();
                  if (displayName.isEmpty) displayName = s.name;
                  displayName = displayName[0].toUpperCase() +
                      displayName.substring(1).toLowerCase();
                  return ListTile(
                    title: Text(displayName),
                    subtitle: Text(
                        '${s.calories} cal, ${s.portion.toStringAsFixed(0)} ${s.unit}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add, color: Colors.blueAccent),
                      onPressed: () {
                        setState(() {
                          _diaryData![meal]!.add({
                            'name': displayName,
                            'calories': s.calories,
                            'sugar': s.sugar,
                          });
                        });
                        _saveDiaryData();
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  // -------------------- CALCULATION & UI BUILDERS --------------------

  int _sumCalories(List<Map<String, dynamic>> items) =>
      items.fold(0, (sum, it) => sum + (it['calories'] as int? ?? 0));
  double _sumSugar(List<Map<String, dynamic>> items) =>
      items.fold(0.0, (sum, it) => sum + (it['sugar'] as double? ?? 0.0));

  int get _totalCalories => _diaryData == null
      ? 0
      : _diaryData!.entries.fold(0, (sum, e) => sum + _sumCalories(e.value));
  double get _totalSugar => _diaryData == null
      ? 0.0
      : _diaryData!.entries.fold(0.0, (sum, e) => sum + _sumSugar(e.value));

  Widget _row(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white70)),
        ],
      );

  Widget _buildDailySummary() {
    final consumed = _totalCalories;
    final remaining = dailyCalorieGoal - consumed;
    final sugar = _totalSugar;
    return Card(
      color: Colors.white12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Daily Summary',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('Calories Consumed:', '$consumed / $dailyCalorieGoal'),
          const SizedBox(height: 4),
          _row('Remaining:', '$remaining kcal'),
          const SizedBox(height: 4),
          _row(
            'Sugar:',
            '${sugar.toStringAsFixed(1)} / ${dailySugarLimit.toStringAsFixed(1)} g',
            valueColor:
                sugar > dailySugarLimit ? Colors.redAccent : Colors.white70,
          ),
        ]),
      ),
    );
  }

  Widget _buildMealSection(String meal, List<Map<String, dynamic>> items) {
    final c = _sumCalories(items), s = _sumSugar(items);
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(meal,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$c kcal', style: const TextStyle(color: Colors.white70)),
              Text('${s.toStringAsFixed(1)} g sugar',
                  style: const TextStyle(color: Colors.white54)),
            ])
          ]),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(
                    child: Text(e.value['name'],
                        style: const TextStyle(color: Colors.white))),
                Text(
                    '${e.value['calories']} kcal | ${e.value['sugar'].toStringAsFixed(1)} g',
                    style: const TextStyle(color: Colors.white70)),
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditEntryDialog(meal, e.key)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => items.removeAt(e.key));
                      _saveDiaryData();
                    }),
              ]),
            );
          }).toList(),
        ]),
      ),
    );
  }

  Future<void> _showEditEntryDialog(String meal, int idx) async {
    final item = _diaryData![meal]![idx];
    final nameCtl = TextEditingController(text: item['name']);
    final calCtl = TextEditingController(text: '${item['calories']}');
    final sugarCtl = TextEditingController(text: '${item['sugar']}');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Food Entry'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Food Name')),
          TextField(
              controller: calCtl,
              decoration: const InputDecoration(labelText: 'Calories'),
              keyboardType: TextInputType.number),
          TextField(
              controller: sugarCtl,
              decoration: const InputDecoration(labelText: 'Sugar (g)'),
              keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final nm = nameCtl.text.trim();
                final cal = int.tryParse(calCtl.text.trim()) ?? 0;
                final sg = double.tryParse(sugarCtl.text.trim()) ?? 0.0;
                if (nm.isNotEmpty && cal > 0) {
                  setState(() => _diaryData![meal]![idx] = {
                        'name': nm,
                        'calories': cal,
                        'sugar': sg
                      });
                  _saveDiaryData();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'))
        ],
      ),
    );
  }

  void _prevDay() {
    setState(
        () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
    _loadDiaryData(_selectedDate);
  }

  void _nextDay() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
    _loadDiaryData(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black45,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Dashboard
            IconButton(
              icon: const Icon(Icons.dashboard, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    registrationData: widget.registrationData,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),

            // Community (calendar icon)
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityScreen(
                    regData: widget.registrationData,
                  ),
                ),
              ),
            ),

            // Profile
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    regData: widget.registrationData,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: diaryLocation,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.book),
        onPressed: () {},
      ),
      body: SafeArea(
        child: _diaryData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date nav
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.arrow_left,
                                    size: 32, color: Colors.white),
                                onPressed: _prevDay),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                                icon: const Icon(Icons.arrow_right,
                                    size: 32, color: Colors.white),
                                onPressed: _nextDay),
                          ]),
                      const SizedBox(height: 16),
                      _buildDailySummary(),
                      const SizedBox(height: 16),
                      ..._diaryData!.entries.map((entry) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMealSection(entry.key, entry.value),
                              ElevatedButton.icon(
                                onPressed: () => _showAddEntryDialog(entry.key),
                                icon: const Icon(Icons.add),
                                label: Text('Add ${entry.key}'),
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12)),
                              ),
                              const SizedBox(height: 16),
                            ]);
                      }).toList()
                    ]),
              ),
      ),
    );
  }
}
