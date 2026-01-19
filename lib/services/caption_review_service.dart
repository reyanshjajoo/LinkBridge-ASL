import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/group_captioning_screen.dart';

class CaptionReviewService {
  static const String _baseUrl =
      'http://10.0.2.2:5000'; // Update with your backend URL

  // Save captions to backend
  static Future<bool> saveCaptions(
    String conversationId,
    List<Caption> captions,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/speech/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversation_id': conversationId,
          'captions': captions.map((c) => c.toJson()).toList(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving captions: $e');
      return false;
    }
  }

  // Retrieve saved captions
  static Future<List<Caption>> getCaptions(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/speech/captions/$conversationId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> captionsJson = data['captions'] ?? [];
        return captionsJson.map((json) => Caption.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error retrieving captions: $e');
    }

    return [];
  }

  // Get list of all conversations for a user
  static Future<List<Map<String, dynamic>>> getConversationList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/speech/conversations'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['conversations'] ?? []);
      }
    } catch (e) {
      print('Error retrieving conversation list: $e');
    }

    return [];
  }
}
