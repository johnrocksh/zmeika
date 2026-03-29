import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_theme.dart';

/// StarCraft — Зерг нашествие. Биомасса расползается по полю.
class StarCraftTheme extends GameTheme {
  static final _rng = Random(7);
  // Случайные "биологические" пятна на фоне
  static final _blobs = List.generate(
    20,
    (_) => Offset(_rng.nextDouble() * 500, _rng.nextDouble() * 500),
  );

  @override String get id => 'starcraft';
  @override String get name => 'StarCraft: ZERG';
  @override String get description => 'Рой поглощает всё. Мутируй или умри.';
  @override String get emoji => '👾';

  @override Color get primaryColor => const Color(0xFF7B2FFF);      // Зерговый фиолет
  @override Color get secondaryColor => const Color(0xFF00FF88);    // Биоплазма
  @override Color get backgroundColor => const Color(0xFF050A0F);   // Космос
  @override Color get cardColor => const Color(0xFF0D1A14);
  @override Color get textColor => const Color(0xFF00FF88);
  @override Color get borderColor => const Color(0xFF3D0080);

  final _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paintBackground(Canvas canvas, Size size, int frame) {
    // Тёмный космос
    _paint.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

    // Пульсирующая биомасса — фиолетовые кляксы
    for (int i = 0; i < _blobs.length; i++) {
      final pulse = 0.04 + 0.06 * sin(frame * 0.04 + i).abs();
      final r = 8.0 + (i % 5) * 6;
      _paint.color = primaryColor.withValues(alpha: pulse * 0.6);
      canvas.drawCircle(_blobs[i], r, _paint);
    }

    // Сетка-гексагоны (имитация)
    _paint
      ..color = secondaryColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const step = 25.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawRect(Rect.fromLTWH(x, y, step, step), _paint);
      }
    }
    _paint.style = PaintingStyle.fill;
  }

  @override
  void paintFood(Canvas canvas, Point<int> food, int blockSize, int frame) {
    final cx = food.x * blockSize + blockSize / 2.0;
    final cy = food.y * blockSize + blockSize / 2.0;
    final pulse = 0.8 + 0.2 * sin(frame * 0.2);

    // Ядро личинки (яйцо зерга)
    final eggR = blockSize * 0.38 * pulse;

    // Внешнее биозарево
    _paint.color = secondaryColor.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(cx, cy), eggR * 2, _paint);
    _paint.color = secondaryColor.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx, cy), eggR * 1.4, _paint);

    // Яйцо
    _paint.color = const Color(0xFF1A3320);
    canvas.drawCircle(Offset(cx, cy), eggR, _paint);

    // Зелёный пульс внутри
    _paint.color = secondaryColor.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx, cy), eggR * 0.55, _paint);

    // Зерговый крест-символ
    _paint
      ..color = secondaryColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final hs = eggR * 0.4;
    canvas.drawLine(Offset(cx - hs, cy), Offset(cx + hs, cy), _paint);
    canvas.drawLine(Offset(cx, cy - hs), Offset(cx, cy + hs), _paint);
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
      final isHead = i == 0;
      final cx = x + blockSize / 2;
      final cy = y + blockSize / 2;
      final pct = snake.length > 1 ? i / (snake.length - 1) : 0.0;

      // Тело — биомасса темнеет к хвосту
      final bodyColor = Color.lerp(primaryColor, const Color(0xFF1A003A), pct)!;
      final r = (blockSize / 2 - 2) * (isHead ? 1.0 : 0.85 - pct * 0.15);

      // Внешнее свечение
      _paint.color = primaryColor.withValues(alpha: 0.12 * (1 - pct));
      canvas.drawCircle(Offset(cx, cy), r * 1.5, _paint);

      // Тело
      _paint.color = bodyColor;
      canvas.drawCircle(Offset(cx, cy), r, _paint);

      // Хитин / панцирь — тёмная обводка
      _paint
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), r, _paint);
      _paint.style = PaintingStyle.fill;

      // Биоплазменный блик
      _paint.color = secondaryColor.withValues(alpha: 0.15 - pct * 0.1);
      canvas.drawCircle(Offset(cx - r * 0.2, cy - r * 0.2), r * 0.35, _paint);

      if (isHead) {
        // Глаза зерга — горящие красным
        final eyeOff = r * 0.32;
        for (final eo in [-eyeOff, eyeOff]) {
          final ex = cx + eo * (direction == SnakeDirection.up || direction == SnakeDirection.down ? 1 : 0);
          final ey = cy + eo * (direction == SnakeDirection.left || direction == SnakeDirection.right ? 1 : 0);
          _paint.color = const Color(0xFFFF2200);
          canvas.drawCircle(Offset(ex, ey), r * 0.22, _paint);
          _paint.color = const Color(0xFFFF6644);
          canvas.drawCircle(Offset(ex, ey), r * 0.1, _paint);
        }
      }
    }
  }

  @override
  void paintGameOver(Canvas canvas, Size size) {
    _paint.color = Colors.purple.withValues(alpha: 0.7);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
    GameTheme.drawTextOnCanvas(
      canvas,
      'РОЙ ПОГЛОТИЛ ТЕБЯ',
      size.width / 2,
      size.height / 2 - 16,
      GoogleFonts.orbitron(fontSize: 16, color: secondaryColor, letterSpacing: 2),
      align: TextAlign.center,
    );
  }

  @override TextStyle get titleStyle => GoogleFonts.orbitron(fontSize: 22, color: secondaryColor, letterSpacing: 3, fontWeight: FontWeight.w700);
  @override TextStyle get scoreStyle => GoogleFonts.orbitron(fontSize: 28, color: textColor, fontWeight: FontWeight.w600);
  @override TextStyle get labelStyle => GoogleFonts.orbitron(fontSize: 11, color: primaryColor, letterSpacing: 2);
}
