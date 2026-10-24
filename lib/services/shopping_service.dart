
import 'dart:convert';
import 'package:http/http.dart' as http;

class ShoppingService {
  // For Flutter Web running on this same computer.
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<Map<String, dynamic>>> recommendProducts({
    required String objectType,
    String color = '',
    required int budget,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'object_type': objectType,
        'color': color,
        'budget': budget,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Shopping API error: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['products'] as List<dynamic>? ?? [];

    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
