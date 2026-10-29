
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class RedesignService {
  // Replace this with your computer's IPv4 address.
  // Example: http://192.168.1.5:8000
static const String baseUrl = 'http://127.0.0.1:8002';
  static Future<Uint8List> redesignRoom({
    required Uint8List imageBytes,
    required String fileName,
    required String roomType,
    required String prompt,
    String existingObjects = '[]',
  }) async {
    if (imageBytes.isEmpty) {
      throw Exception('Please upload a valid room image.');
    }

    final uri = Uri.parse('$baseUrl/redesign');
    final request = http.MultipartRequest('POST', uri);

    request.fields['room_type'] = roomType;
    request.fields['existing_objects'] = existingObjects;
    request.fields['prompt'] = prompt;

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Redesign API error (${response.statusCode}): '
          '${response.body}',
        );
      }

      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();

      if (!contentType.contains('image/png')) {
        throw Exception(
          'Expected PNG image, received: $contentType',
        );
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('The API returned an empty image.');
      }

      return response.bodyBytes;
    } catch (e) {
      throw Exception('Unable to generate redesign: $e');
    }
  }
}
