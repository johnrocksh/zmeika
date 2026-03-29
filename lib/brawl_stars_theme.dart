import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_theme.dart';

class BrawlStarsTheme extends GameTheme {
  static final _rng = Random(42);
  static final _stars = List.generate(
    60,
    (_) => Offset(_rng.nextDouble() * 500, _rng.nextDouble() * 500),
  );

  @override String get id => 'brawl_stars';
  @override String get name => 'Brawl Stars';
  @override String get description => 'Арена, золото, слава!';
  @override String get emoji => '⭐';

  @override Color get primaryColor => const Color(0xFFF4921A);
  @override Color get secondaryColor => const Color(0xFFFFc200);
  @override Color get backgroundColor => const Color(0xFF0d1b35);
  @override Color get cardColor => const Color(0xFF1a2d55);
  @override Color get textColor => Colors.white;
  @override Color get borderColor => const Color(0xFFA05800);

  final _paint = Paint();

  @override
  void paintBackground(Canvas canvas, Size size, int frame) {
    _paint.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

    // Фоновые звёзды с мерцанием
    for (int i = 0; i < _stars.length; i++) {
      final pulse = 0.05 + 0.08 * sin(frame * 0.05 + i * 0.7).abs();
      _paint.color = secondaryColor.withValues(alpha: pulse);
      canvas.drawCircle(_stars[i], 1.2 + (i % 3) * 0.4, _paint);
    }

    // Мягкая сетка
    _paint.color = Colors.white.withValues(alpha: 0.03);
    _paint.strokeWidth = 0.5;
    _paint.style = PaintingStyle.stroke;
  }

  @override
  void paintFood(Canvas canvas, Point<int> food, int blockSize, int frame) {
    final cx = food.x * blockSize + blockSize / 2.0;
    final cy = food.y * blockSize + blockSize / 2.0;
    final pulse = 0.85 + 0.15 * sin(frame * 0.18);
    final r = blockSize / 2.2 * pulse;

    // Свечение вокруг звезды
    _paint
      ..color = secondaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 1.6, _paint);

    GameTheme.drawStar(canvas, _paint, cx, cy, r, r * 0.42, secondaryColor);

    // Блик
    GameTheme.drawStar(canvas, _paint, cx, cy, r * 0.55, r * 0.22,
        Colors.white.withValues(alpha: 0.35));
  }

  @override
  void paintSnake(
    Canvas canvas,
    List<Point<int>> snake,
    int blockSize,
    SnakeDirection direction,
    int frame,
  ) {
    final s = blockSize - 3.0;
    for (int i = snake.length - 1; i >= 0; i--) {
      final seg = snake[i];
      final x = seg.x * blockSize.toDouble();
      final y = seg.y * blockSize.toDouble();
      final isHead = i == 0;

      // Тело с градиентным переходом
      final t = snake.length > 1 ? i / (snake.length - 1) : 0.0;
      final bodyColor = Color.lerp(primaryColor, secondaryColor, t)!;

      _paint
        ..color = bodyColor
        ..style = PaintingStyle.fill;
      GameTheme.drawRoundedRect(canvas, _paint, x + 1, y + 1, s, s, isHead ? 8 : 5);

      // Обводка
      _paint
        ..color = isHead ? borderColor : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      GameTheme.drawRoundedRect(canvas, _paint, x + 1, y + 1, s, s, isHead ? 8 : 5);

      // Блик
      _paint
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      GameTheme.drawRoundedRect(canvas, _paint, x + 4, y + 3, s - 8, s * 0.3, 3);

      if (isHead) _drawEyes(canvas, x, y, blockSize, direction);
    }
  }

  void _drawEyes(Canvas canvas, double x, double y, int bs, SnakeDirection dir) {
    final c = bs / 2.0;
    final eo = bs * 0.22;
    final Offset e1, e2;
    switch (dir) {
      case SnakeDirection.right:
        e1 = Offset(x + c + 2, y + c - eo);
        e2 = Offset(x + c + 2, y + c + eo);
        break;
      case SnakeDirection.left:
        e1 = Offset(x + c - 2, y + c - eo);
        e2 = Offset(x + c - 2, y + c + eo);
        break;
      case SnakeDirection.up:
        e1 = Offset(x + c - eo, y + c - 2);
        e2 = Offset(x + c + eo, y + c - 2);
        break;
      case SnakeDirection.down:
        e1 = Offset(x + c - eo, y + c + 2);
        e2 = Offset(x + c + eo, y + c + 2);
        break;
    }
    for (final e in [e1, e2]) {
      _paint.color = Colors.white;
      canvas.drawCircle(e, 3.5, _paint);
      _paint.color = Colors.black87;
      canvas.drawCircle(Offset(e.dx + 0.5, e.dy + 0.5), 1.8, _paint);
    }
  }

  @override
  void paintGameOver(Canvas canvas, Size size) {
    _paint.color = Colors.black.withValues(alpha: 0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
  }

  @override TextStyle get titleStyle => GoogleFonts.lilitaOne(fontSize: 28, color: secondaryColor, letterSpacing: 3);
  @override TextStyle get scoreStyle => GoogleFonts.lilitaOne(fontSize: 32, color: textColor);
  @override TextStyle get labelStyle => GoogleFonts.lilitaOne(fontSize: 14, color: secondaryColor, letterSpacing: 1.5);
}
