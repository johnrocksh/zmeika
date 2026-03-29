import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_theme.dart';
import 'theme_service.dart';

/// Красивый нижний лист для выбора темы
class ThemeSelectorSheet extends StatelessWidget {
  final GameTheme currentTheme;
  final Function(GameTheme) onSelect;

  const ThemeSelectorSheet({
    super.key,
    required this.currentTheme,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context,
    GameTheme current,
    Function(GameTheme) onSelect,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ThemeSelectorSheet(
        currentTheme: current,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themes = ThemeRegistry.all;

    return Container(
      decoration: BoxDecoration(
        color: currentTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: currentTheme.primaryColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Хэндл
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: currentTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'ВЫБЕРИ СКИН',
              style: currentTheme.titleStyle.copyWith(fontSize: 20, letterSpacing: 4),
            ),
          ),

          // Сетка тем
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.9,
            ),
            itemCount: themes.length,
            itemBuilder: (_, i) {
              final theme = themes[i];
              final isSelected = theme.id == currentTheme.id;
              return _ThemeCard(
                theme: theme,
                isSelected: isSelected,
                onTap: () {
                  ThemeService.setTheme(theme.id);
                  onSelect(theme);
                  Navigator.pop(context);
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final GameTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.borderColor,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            Text(theme.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    theme.name,
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    theme.description,
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.textColor.withValues(alpha: 0.55),
                      fontFamily: 'sans-serif',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.primaryColor, size: 18),
          ],
        ),
      ),
    );
  }
}
