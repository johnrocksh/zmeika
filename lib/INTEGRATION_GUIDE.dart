/// ════════════════════════════════════════════════════
///  ИЗМЕНЕНИЯ В main.dart — интеграция системы тем
/// ════════════════════════════════════════════════════

// 1. ДОБАВЬ в _SnakeGameState:
//
//   GameTheme _theme = BrawlStarsTheme();   // текущая тема
//   int _frame = 0;                          // кадр анимации
//   Timer? _animTimer;                       // таймер анимации фона
//
// 2. В initState() добавь:
//
//   ThemeService.getCurrentTheme().then((t) => setState(() => _theme = t));
//   _animTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
//     if (mounted) setState(() => _frame++);
//   });
//
// 3. В dispose() добавь:
//
//   _animTimer?.cancel();
//
// 4. В AppBar.actions добавь кнопку выбора темы:
//
//   GestureDetector(
//     onTap: () => ThemeSelectorSheet.show(context, _theme, (t) => setState(() => _theme = t)),
//     child: Container(
//       padding: const EdgeInsets.all(8),
//       margin: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: _theme.primaryColor,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: _theme.borderColor, width: 2),
//       ),
//       child: Text(_theme.emoji, style: const TextStyle(fontSize: 18)),
//     ),
//   ),

// ════════════════════════════════════════════════════
//  НОВЫЙ SnakePainter — делегирует тему
// ════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'game_theme.dart';

class SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int>? food;
  final int blockSize;
  final bool gameOver;
  final GameTheme theme;
  final SnakeDirection direction;
  final int frame;

  const SnakePainter({
    required this.snake,
    this.food,
    required this.blockSize,
    required this.gameOver,
    required this.theme,
    required this.direction,
    required this.frame,
  });

  @override
  void paint(Canvas canvas, Size size) {
    theme.paintBackground(canvas, size, frame);

    if (food != null) {
      theme.paintFood(canvas, food!, blockSize, frame);
    }

    theme.paintSnake(canvas, snake, blockSize, direction, frame);

    if (gameOver) {
      theme.paintGameOver(canvas, size);
    }
  }

  @override
  bool shouldRepaint(SnakePainter old) =>
      old.frame != frame ||
      old.snake != snake ||
      old.food != food ||
      old.gameOver != gameOver ||
      old.theme.id != theme.id;
}

// ════════════════════════════════════════════════════
//  КОНВЕРТАЦИЯ Direction → SnakeDirection (добавь утилиту)
// ════════════════════════════════════════════════════

// В файле с enum Direction добавь:
//
// extension DirectionExt on Direction {
//   SnakeDirection get toSnake {
//     switch (this) {
//       case Direction.up: return SnakeDirection.up;
//       case Direction.down: return SnakeDirection.down;
//       case Direction.left: return SnakeDirection.left;
//       case Direction.right: return SnakeDirection.right;
//     }
//   }
// }

// ════════════════════════════════════════════════════
//  pubspec.yaml — добавь зависимости и шрифты
// ════════════════════════════════════════════════════
//
// dependencies:
//   google_fonts: ^6.2.1
//
// (google_fonts автоматически подтянет все нужные шрифты:
//  Lilita One, Orbitron, Press Start 2P, VT323, Metal)
