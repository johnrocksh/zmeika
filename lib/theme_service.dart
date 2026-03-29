import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для управления темами/скинами
class ThemeService {
  static const String _themeKey = 'selected_theme';
  
  // Доступные темы
  static const String classicTheme = 'classic';
  static const String brawlStarsTheme = 'brawl_stars';
  
  /// Получить текущую тему
  static Future<String> getCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? brawlStarsTheme;
  }
  
  /// Установить тему
  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }
  
  /// Переключить тему
  static Future<String> toggleTheme() async {
    final current = await getCurrentTheme();
    final newTheme = current == classicTheme ? brawlStarsTheme : classicTheme;
    await setTheme(newTheme);
    return newTheme;
  }
  
  /// Проверить, активна ли тема Brawl Stars
  static Future<bool> isBrawlStarsTheme() async {
    final theme = await getCurrentTheme();
    return theme == brawlStarsTheme;
  }
  
  /// Получить название текущей темы
  static Future<String> getCurrentThemeName() async {
    final theme = await getCurrentTheme();
    switch (theme) {
      case classicTheme:
        return 'Классический';
      case brawlStarsTheme:
        return 'Brawl Stars';
      default:
        return 'Неизвестно';
    }
  }
}
