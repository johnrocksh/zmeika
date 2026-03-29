import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для сохранения и загрузки игровых данных
class GameStorageService {
  static const String _highScoreKey = 'high_score';
  static const String _totalGamesKey = 'total_games';
  static const String _totalWinsKey = 'total_wins';
  static const String _averageScoreKey = 'average_score';
  static const String _totalScoreKey = 'total_score';

  /// Получить лучший результат
  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  /// Сохранить лучший результат
  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, score);
  }

  /// Получить общее количество игр
  static Future<int> getTotalGames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalGamesKey) ?? 0;
  }

  /// Увеличить счетчик игр на 1
  static Future<void> incrementTotalGames() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalGamesKey) ?? 0;
    await prefs.setInt(_totalGamesKey, current + 1);
  }

  /// Получить общее количество побед (когда счёт больше 0)
  static Future<int> getTotalWins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalWinsKey) ?? 0;
  }

  /// Увеличить счетчик побед на 1
  static Future<void> incrementTotalWins() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalWinsKey) ?? 0;
    await prefs.setInt(_totalWinsKey, current + 1);
  }

  /// Получить средний счёт
  static Future<double> getAverageScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_averageScoreKey) ?? 0.0;
  }

  /// Обновить средний счёт (вызывается после каждой игры)
  static Future<void> updateAverageScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    final totalGames = prefs.getInt(_totalGamesKey) ?? 0;
    final totalScore = prefs.getInt(_totalScoreKey) ?? 0;
    
    final newTotalGames = totalGames + 1;
    final newTotalScore = totalScore + newScore;
    final newAverage = newTotalScore / newTotalGames;
    
    await prefs.setInt(_totalScoreKey, newTotalScore);
    await prefs.setDouble(_averageScoreKey, newAverage);
  }

  /// Получить общую статистику
  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'high_score': prefs.getInt(_highScoreKey) ?? 0,
      'total_games': prefs.getInt(_totalGamesKey) ?? 0,
      'total_wins': prefs.getInt(_totalWinsKey) ?? 0,
      'average_score': prefs.getDouble(_averageScoreKey) ?? 0.0,
    };
  }

  /// Очистить все сохранения (для тестирования)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
