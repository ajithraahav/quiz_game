import 'package:flutter/foundation.dart';
import 'api_service.dart';

class QuizProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool? _isCorrect;
  bool get isCorrect => _isCorrect ?? false;
  bool get hasAnswered => _isCorrect != null;

  Future<void> checkAnswer(String answer) async {
    _isCorrect = await _apiService.checkAnswer(answer);
    notifyListeners();
  }

  void reset() {
    _isCorrect = null;
    notifyListeners();
  }
}
