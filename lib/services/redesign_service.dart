
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class RedesignService {
  static const String baseUrl =
    'https://backward-banknote-backlog.ngrok-free.dev';

  static Future<Uint8List> redesignRoom({
    required Uint8List imageBytes,
    required String fileName,
    required String prompt,
  }) async {
    final uri = Uri.parse('$baseUrl/redesign');

    
final request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/redesign'),
)
  ..fields['prompt'] = prompt
  ..headers['ngrok-skip-browser-warning'] = 'true'
  ..files.add(
    http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: fileName,
    ),
  );

final streamedResponse = await request.send();
final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Redesign failed (${response.statusCode}): ${response.body}',
      );
    }

    if (!response.headers['content-type']
            .toString()
            .contains('image/png')) {
      throw Exception('The API did not return a PNG image.');
    }

    return response.bodyBytes;
  }
}
