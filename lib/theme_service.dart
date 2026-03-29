import 'package:shared_preferences/shared_preferences.dart';
import 'game_theme.dart';
import 'brawl_stars_theme.dart';
import 'starcraft_theme.dart';
import 'ascii_theme.dart';
import 'doom_theme.dart';
import 'commander_theme.dart';
import 'nfs_theme.dart';

/// Реестр всех тем — добавь новую тему сюда и она сразу появится везде
class ThemeRegistry {
  static final List<GameTheme> all = [
    BrawlStarsTheme(),
    StarCraftTheme(),
    AsciiTheme(),
    DoomTheme(),
    CommanderTheme(),
    NeedForSpeedTheme(),
    // ClassicTheme(),      // ← добавь свою тему сюда
  ];

  static GameTheme getById(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => all.first,
    );
  }
}

/// Сервис управления выбранной темой (SharedPreferences)
class ThemeService {
  static const String _key = 'selected_theme_v2';
  static const String defaultThemeId = 'brawl_stars';

  static Future<String> getCurrentThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? defaultThemeId;
  }

  static Future<GameTheme> getCurrentTheme() async {
    final id = await getCurrentThemeId();
    return ThemeRegistry.getById(id);
  }

  static Future<void> setTheme(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }
}
