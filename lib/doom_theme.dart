import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_theme.dart';

/// DOOM / QUAKE — Ад на земле. Кровь, огонь, черепа.
class DoomTheme extends GameTheme {
  static final _rng = Random(13);
  // Огненные частицы на фоне
  static final _embers = List.generate(
    40,
    (i) => _Ember(
      x: _rng.nextDouble() * 500,
      y: _rng.nextDouble() * 500,
      speed: 0.3 + _rng.nextDouble() * 0.7,
      size: 1.0 + _rng.nextDouble() * 2.5,
      phase: _rng.nextDouble() * pi * 2,
    ),
  );

  @override String get id => 'doom';
  @override String get name => 'DOOM: HELLFIRE';
  @override String get description => 'Ад разверзся. Змея — демон.';
  @override String get emoji => '💀';

  @override Color get primaryColor => const Color(0xFFCC0000);
  @override Color get secondaryColor => const Color(0xFFFF6600);
  @override Color get backgroundColor => const Color(0xFF0A0000);
  @override Color get cardColor => const Color(0xFF1A0505);
  @override Color get textColor => const Color(0xFFFF4400);
  @override Color get borderColor => const Color(0xFF660000);

  final _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paintBackground(Canvas canvas, Size size, int frame) {
    _paint.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

    // Огонь снизу — градиент
    const fireH = 80.0;
    for (int row = 0; row < fireH.toInt(); row++) {
      final t = row / fireH;
      final intensity = (1 - t) * (0.15 + 0.08 * sin(frame * 0.1 + row * 0.3));
      _paint.color = Color.lerp(
        secondaryColor,
        primaryColor,
        t,
      )!.withValues(alpha: intensity);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - fireH + row, size.width, 1),
        _paint,
      );
    }

    // Летящие угольки
    for (int i = 0; i < _embers.length; i++) {
      final e = _embers[i];
      final yOff = (frame * e.speed * 1.2) % size.height;
      final xWobble = 6 * sin(frame * 0.05 + e.phase);
      final glow = 0.3 + 0.4 * sin(frame * 0.15 + e.phase);
      _paint.color = secondaryColor.withValues(alpha: glow * 0.6);
      canvas.drawCircle(
        Offset(e.x + xWobble, size.height - yOff),
        e.size,
        _paint,
      );
    }

    // Кровавая решётка
    _paint
      ..color = primaryColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _paint);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _paint);
    }
    _paint.style = PaintingStyle.fill;
  }

  @override
  void paintFood(Canvas canvas, Point<int> food, int blockSize, int frame) {
    final cx = food.x * blockSize + blockSize / 2.0;
    final cy = food.y * blockSize + blockSize / 2.0;
    final pulse = 0.75 + 0.25 * sin(frame * 0.25);

    // Огненное свечение
    _paint.color = secondaryColor.withValues(alpha: 0.1 + 0.1 * pulse);
    canvas.drawCircle(Offset(cx, cy), blockSize * 0.8, _paint);
    _paint.color = primaryColor.withValues(alpha: 0.2);
    canvas.drawCircle(Offset(cx, cy), blockSize * 0.5, _paint);

    // Пятиугольная пентаграмма (Doomguy approved)
    GameTheme.drawStar(
      canvas,
      _paint,
      cx,
      cy,
      blockSize * 0.38 * pulse,
      blockSize * 0.16 * pulse,
      primaryColor,
      points: 5,
    );

    // Внутренняя часть
    GameTheme.drawStar(
      canvas,
      _paint,
      cx,
      cy,
      blockSize * 0.22 * pulse,
      blockSize * 0.1 * pulse,
      secondaryColor,
      points: 5,
    );
  }

  @override
  void paintSnake(
    Canvas canvas,
    List<Point<int>> snake,
    int blockSize,
    SnakeDirection direction,
    int frame,
  ) {
    for (int i = snake.length - 1; i >= 0; i--) {
      final seg = snake[i];
      final x = seg.x * blockSize.toDouble();
      final y = seg.y * blockSize.toDouble();
      final s = blockSize - 2.0;
      final isHead = i == 0;
      final pct = snake.length > 1 ? i / (snake.length - 1) : 0.0;

      // Огненный перетёк от головы к хвосту
      final bodyColor = Color.lerp(secondaryColor, const Color(0xFF3A0000), pct * 0.9)!;

      // Внутреннее свечение сегмента
      _paint.color = bodyColor.withValues(alpha: 0.15);
      GameTheme.drawRoundedRect(canvas, _paint, x, y, s + 2, s + 2, 4);

      // Сам сегмент
      _paint.color = bodyColor;
      GameTheme.drawRoundedRect(canvas, _paint, x + 1, y + 1, s, s, isHead ? 5 : 3);

      // Металлическая обводка
      _paint
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      GameTheme.drawRoundedRect(canvas, _paint, x + 1, y + 1, s, s, isHead ? 5 : 3);
      _paint.style = PaintingStyle.fill;

      // Насечки на броне (каждые 3 сегмента)
      if (!isHead && i % 3 == 0) {
        _paint.color = Colors.black.withValues(alpha: 0.3);
        canvas.drawRect(Rect.fromLTWH(x + 5, y + s / 2 - 0.5, s - 10, 1), _paint);
      }

      if (isHead) _drawDemonHead(canvas, x, y, blockSize, direction, frame);
    }
  }

  void _drawDemonHead(Canvas canvas, double x, double y, int bs, SnakeDirection dir, int frame) {
    final glowPulse = 0.6 + 0.4 * sin(frame * 0.2);

    // Горящие глаза демона
    final Offset e1, e2;
    final c = bs / 2.0;
    switch (dir) {
      case SnakeDirection.right:
        e1 = Offset(x + c + 2, y + c - bs * 0.2);
        e2 = Offset(x + c + 2, y + c + bs * 0.2);
        break;
      case SnakeDirection.left:
        e1 = Offset(x + c - 2, y + c - bs * 0.2);
        e2 = Offset(x + c - 2, y + c + bs * 0.2);
        break;
      case SnakeDirection.up:
        e1 = Offset(x + c - bs * 0.2, y + c - 2);
        e2 = Offset(x + c + bs * 0.2, y + c - 2);
        break;
      case SnakeDirection.down:
        e1 = Offset(x + c - bs * 0.2, y + c + 2);
        e2 = Offset(x + c + bs * 0.2, y + c + 2);
        break;
    }
    for (final e in [e1, e2]) {
      // Ореол
      _paint.color = secondaryColor.withValues(alpha: 0.3 * glowPulse);
      canvas.drawCircle(e, 5, _paint);
      // Глаз
      _paint.color = secondaryColor.withValues(alpha: glowPulse);
      canvas.drawCircle(e, 3, _paint);
      // Зрачок
      _paint.color = Colors.yellow.withValues(alpha: glowPulse);
      canvas.drawCircle(e, 1.2, _paint);
    }
  }

  @override
  void paintGameOver(Canvas canvas, Size size) {
    _paint.color = Colors.red.withValues(alpha: 0.65);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
    GameTheme.drawTextOnCanvas(
      canvas, 'YOU DIED',
      size.width / 2, size.height / 2 - 14,
      GoogleFonts.metal(fontSize: 24, color: const Color(0xFFFFDD00), letterSpacing: 4),
      align: TextAlign.center,
    );
  }

  @override TextStyle get titleStyle => GoogleFonts.metal(fontSize: 26, color: textColor, letterSpacing: 4);
  @override TextStyle get scoreStyle => GoogleFonts.metal(fontSize: 28, color: Colors.orange);
  @override TextStyle get labelStyle => GoogleFonts.metal(fontSize: 12, color: primaryColor, letterSpacing: 2);
}

class _Ember {
  final double x, y, speed, size, phase;
  const _Ember({required this.x, required this.y, required this.speed, required this.size, required this.phase});
}
