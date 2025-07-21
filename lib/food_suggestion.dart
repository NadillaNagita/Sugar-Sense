class FoodSuggestion {
  final String name;
  final int calories;
  final double sugar; // <— baru: gula (g)
  final double portion; // serving size default
  final String unit; // satuan porsi
  final String source; // dataType (Foundation, Branded, dll)

  FoodSuggestion({
    required this.name,
    required this.calories,
    required this.sugar,
    required this.portion,
    required this.unit,
    required this.source,
  });

  factory FoodSuggestion.fromJson(Map<String, dynamic> json) {
    final name = json['description'] as String? ?? '';

    int calories = 0;
    double sugar = 0.0;
    if (json['foodNutrients'] is List) {
      for (final n in (json['foodNutrients'] as List)) {
        final nm = (n['nutrientName'] as String?)?.toLowerCase() ?? '';
        final val = (n['value'] as num?)?.toDouble() ?? 0.0;
        if (nm.contains('energy')) {
          calories = val.round();
        }
        // tangkap baik "sugar" maupun "sugars"
        if (nm.contains('sugar')) {
          sugar = val;
        }
      }
    }

    final portion = (json['servingSize'] as num?)?.toDouble() ?? 100.0;
    final unit = json['servingSizeUnit'] as String? ?? 'g';
    final source = json['dataType'] as String? ?? '';

    return FoodSuggestion(
      name: name,
      calories: calories,
      sugar: sugar,
      portion: portion,
      unit: unit,
      source: source,
    );
  }
}
