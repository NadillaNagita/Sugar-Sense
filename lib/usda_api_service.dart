import 'dart:convert';
import 'package:http/http.dart' as http;

class USDAApiService {
  final String _apiKey = "ekXMz0530gbGrUaSbsCkKbXMfkCIeYktnZhdU8S1";

  /// Ambil detail satu makanan
  Future<Map<String, dynamic>> fetchFoodData(String foodId) async {
    final String baseUrl = "https://api.nal.usda.gov/fdc/v1/food/$foodId";
    final Uri url = Uri.parse("$baseUrl?api_key=$_apiKey");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? data : {"error": "Data kosong."};
      } else {
        throw Exception(
            "Error ${response.statusCode}: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Terjadi kesalahan fetchFoodData: $e");
      return {"error": e.toString()};
    }
  }

  /// Cari daftar makanan (default)
  Future<List<dynamic>> searchFoods(String query) async {
    final params = {
      'api_key': _apiKey,
      'query': query,
      'pageSize': '50',
    };

    final uri = Uri.https(
      'api.nal.usda.gov',
      '/fdc/v1/foods/search',
      params,
    );

    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      return body['foods'] ?? [];
    }
    throw Exception('USDA search failed ${resp.statusCode}');
  }

  /// Cari daftar makanan khusus untuk jenis meal tertentu
  Future<List<dynamic>> searchFoodsByMeal(String query, String mealType) async {
    final all = await searchFoods(query);
    final Map<String, List<String>> keywords = {
      'Breakfast': ['cereal', 'egg', 'pancake', 'toast'],
      'Lunch': ['sandwich', 'salad', 'rice', 'wrap', 'burger'],
      'Dinner': ['pasta', 'soup', 'steak', 'roast', 'casserole'],
      'Snacks': ['chips', 'cookie', 'bar', 'popcorn', 'fruit'],
    };
    final ks = keywords[mealType] ?? [];
    if (ks.isEmpty) return all;
    return all.where((item) {
      final desc = (item['description'] as String? ?? '').toLowerCase();
      return ks.any((kw) => desc.contains(kw));
    }).toList();
  }
}
