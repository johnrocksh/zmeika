import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_theme.dart';

/// Need for Speed — неоновая гонка ночью. Скорость. Асфальт. Огни города.
class NeedForSpeedTheme extends GameTheme {
  static final _rng = Random(99);
  // Огни трасс — пары точек (начало-конец полосы)
  static final _lanes = List.generate(
    30,
    (i) => _Lane(
      x: _rng.nextDouble() * 500,
      y: _rng.nextDouble() * 500,
      speed: 2.0 + _rng.nextDouble() * 4.0,
      length: 8.0 + _rng.nextDouble() * 24,
      color: i % 3 == 0
          ? const Color(0xFFFF00FF)
          : i % 3 == 1
              ? const Color(0xFF00FFFF)
              : const Color(0xFFFFFF00),
    ),
  );

  @override String get id => 'need_for_speed';
  @override String get name => 'NFS: Underground';
  @override String get description => 'Ночной город. 200 км/ч. Неон.';
  @override String get emoji => '🚀';

  @override Color get primaryColor => const Color(0xFF00FFFF);   // неоновый циан
  @override Color get secondaryColor => const Color(0xFFFF00FF); // маджента
  @override Color get backgroundColor => const Color(0xFF060610);
  @override Color get cardColor => const Color(0xFF0D0D25);
  @override Color get textColor => const Color(0xFF00FFFF);
  @override Color get borderColor => const Color(0xFF4400AA);

  final _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paintBackground(Canvas canvas, Size size, int frame) {
    // Тёмный асфальт
    _paint.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

    // Асфальтовая текстура — горизонтальные полосы
    _paint
      ..color = Colors.white.withValues(alpha: 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _paint);
    }
    _paint.style = PaintingStyle.fill;

    // Движущиеся неоновые полосы скорости
    for (final lane in _lanes) {
      final yPos = (lane.y + frame * lane.speed) % (size.height + lane.length);
      _paint.color = lane.color.withValues(alpha: 0.35);
      canvas.drawRect(
        Rect.fromLTWH(lane.x, yPos - lane.length, 1.5, lane.length),
        _paint,
      );
      // Блёстки вверху полосы
      _paint.color = lane.color.withValues(alpha: 0.6);
      canvas.drawRect(Rect.fromLTWH(lane.x - 0.5, yPos - lane.length, 2.5, 3), _paint);
    }

    // Неоновая разметка дороги (вертикальные полосы)
    for (int i = 1; i <= 3; i++) {
      final lx = size.width / 4 * i;
      _paint.color = Colors.white.withValues(alpha: 0.04);
      canvas.drawRect(Rect.fromLTWH(lx - 0.5, 0, 1, size.height), _paint);
    }
  }

  @override
  void paintFood(Canvas canvas, Point<int> food, int blockSize, int frame) {
    final cx = food.x * blockSize + blockSize / 2.0;
    final cy = food.y * blockSize + blockSize / 2.0;
    final pulse = 0.7 + 0.3 * sin(frame * 0.22);

    // Неоновый диамант (нитро)
    final r = blockSize * 0.38 * pulse;
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.7, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.7, cy)
      ..close();

    // Внешнее свечение
    _paint.color = primaryColor.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(cx, cy), r * 2, _paint);

    // Основная форма
    _paint.color = primaryColor.withValues(alpha: 0.85);
    canvas.drawPath(path, _paint);

    // Нижняя часть темнее
    final path2 = Path()
      ..moveTo(cx + r * 0.7, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.7, cy)
      ..close();
    _paint.color = const Color(0xFF006666);
    canvas.drawPath(path2, _paint);

    // Блик
    _paint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx - r * 0.12, cy - r * 0.3), r * 0.18, _paint);

    // "NITRO" — неоновая обводка
    _paint
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, _paint);
    _paint.style = PaintingStyle.fill;
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

      // Неоновый перетёк циан → маджента
      final bodyColor = Color.lerp(primaryColor, secondaryColor, pct)!;
      final r = isHead ? 8.0 : 5.0;

      // Неоновое свечение
      _paint.color = bodyColor.withValues(alpha: 0.12 * (1 - pct * 0.5));
      GameTheme.drawRoundedRect(canvas, _paint, x - 1, y - 1, s + 4, s + 4, r + 3);

      // Основной сегмент — тёмный с неоновым отливом
      _paint.color = Color.lerp(const Color(0xFF0A0A20), const Color(0xFF100010), pct)!;
      GameTheme.drawRoundedRect(canvas, _paint, x + 1, y + 1, s, s, r);

      // Неоновая обводка
      _paint
        ..color = bodyColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHead ? 2.5 : 1.8;
      GameTheme.drawRoundedRect(canvas, _paint, x + 1, y + 1, s, s, r);
      _paint.style = PaintingStyle.fill;

      // Полоса "скорости" через тело
      if (!isHead) {
        _paint.color = bodyColor.withValues(alpha: 0.2);
        canvas.drawRect(Rect.fromLTWH(x + 3, y + s / 2 - 0.5, s - 6, 1), _paint);
      }

      if (isHead) _drawNFSHead(canvas, x, y, blockSize, direction, frame, bodyColor);
    }
  }

  void _drawNFSHead(Canvas canvas, double x, double y, int bs, SnakeDirection dir, int frame, Color color) {
    final glowPulse = 0.5 + 0.5 * sin(frame * 0.3);
    final c = bs / 2.0;

    // Фары (глаза) — горят неоново
    final Offset e1, e2;
    switch (dir) {
      case SnakeDirection.right:
        e1 = Offset(x + c + 4, y + c - bs * 0.18);
        e2 = Offset(x + c + 4, y + c + bs * 0.18);
        break;
      case SnakeDirection.left:
        e1 = Offset(x + c - 4, y + c - bs * 0.18);
        e2 = Offset(x + c - 4, y + c + bs * 0.18);
        break;
      case SnakeDirection.up:
        e1 = Offset(x + c - bs * 0.18, y + c - 4);
        e2 = Offset(x + c + bs * 0.18, y + c - 4);
        break;
      case SnakeDirection.down:
        e1 = Offset(x + c - bs * 0.18, y + c + 4);
        e2 = Offset(x + c + bs * 0.18, y + c + 4);
        break;
    }
    for (final e in [e1, e2]) {
      // Свет фар
      _paint.color = Colors.white.withValues(alpha: 0.2 * glowPulse);
      canvas.drawCircle(e, 6, _paint);
      // Фара
      _paint.color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(e, 2.5, _paint);
      _paint.color = color.withValues(alpha: 0.4 * glowPulse);
      canvas.drawCircle(e, 4, _paint);
    }
  }

  @override
  void paintGameOver(Canvas canvas, Size size) {
    _paint.color = Colors.black.withValues(alpha: 0.75);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
    GameTheme.drawTextOnCanvas(
      canvas, 'BUSTED!',
      size.width / 2, size.height / 2 - 14,
      GoogleFonts.orbitron(fontSize: 22, color: const Color(0xFF00FFFF), letterSpacing: 6, fontWeight: FontWeight.w900),
      align: TextAlign.center,
    );
  }

  @override TextStyle get titleStyle => GoogleFonts.orbitron(fontSize: 22, color: primaryColor, letterSpacing: 4, fontWeight: FontWeight.w700);
  @override TextStyle get scoreStyle => GoogleFonts.orbitron(fontSize: 26, color: textColor, fontWeight: FontWeight.w600);
  @override TextStyle get labelStyle => GoogleFonts.orbitron(fontSize: 10, color: secondaryColor, letterSpacing: 2);
}

class _Lane {
  final double x, y, speed, length;
  final Color color;
  const _Lane({required this.x, required this.y, required this.speed, required this.length, required this.color});
}
