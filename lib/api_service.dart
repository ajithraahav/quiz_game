import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://quiz.nerdslab.in/api';

  Future<bool> checkAnswer(String answer) async {
    final response = await http.get(Uri.parse('$baseUrl/answer/$answer'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Failed to load answer');
    }
  }
}
