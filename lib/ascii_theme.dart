import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_theme.dart';

/// ASCII 80-х — зелёный фосфорный монитор. Всё — символы.
class AsciiTheme extends GameTheme {
  @override String get id => 'ascii_80s';
  @override String get name => 'ASCII 80s';
  @override String get description => 'Фосфорный монитор. Только символы.';
  @override String get emoji => '█';

  static const _phosphor = Color(0xFF00FF41);       // классический зелёный
  static const _phosphorDim = Color(0xFF003B0E);    // тёмный фон CRT
  static const _phosphorMid = Color(0xFF00B32C);
  static const _amber = Color(0xFFFFB000);           // янтарный монитор (еда)

  @override Color get primaryColor => _phosphor;
  @override Color get secondaryColor => _amber;
  @override Color get backgroundColor => const Color(0xFF000D02);
  @override Color get cardColor => _phosphorDim;
  @override Color get textColor => _phosphor;
  @override Color get borderColor => _phosphorMid;

  final _paint = Paint()..style = PaintingStyle.fill;

  // Кэш TextPainters для скорости
  static TextPainter? _snakeHead;
  static TextPainter? _snakeBody;
  static TextPainter? _foodPainter;
  static TextPainter? _wallPainter;

  TextPainter _makeTp(String text, Color color, double size) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.vt323(fontSize: size, color: color, height: 1.0),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paintBackground(Canvas canvas, Size size, int frame) {
    // Фосфорный экран
    _paint.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

    // CRT scanlines — горизонтальные полосы
    _paint.color = Colors.black.withValues(alpha: 0.25);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), _paint);
    }

    // Рамка из символов ASCII
    const borderChar = '▓';
    final bp = _makeTp(borderChar, _phosphorDim, 14);
    final cols = (size.width / bp.width).ceil();
    final rows = (size.height / bp.height).ceil();

    // Верхняя/нижняя рамка
    for (int c = 0; c < cols; c++) {
      bp.paint(canvas, Offset(c * bp.width, 0));
      bp.paint(canvas, Offset(c * bp.width, size.height - bp.height));
    }
    // Левая/правая
    for (int r = 0; r < rows; r++) {
      bp.paint(canvas, Offset(0, r * bp.height));
      bp.paint(canvas, Offset(size.width - bp.width, r * bp.height));
    }

    // Мигающий курсор в углу
    if ((frame ~/ 8) % 2 == 0) {
      final cursor = _makeTp('_', _phosphor, 14);
      cursor.paint(canvas, Offset(size.width - bp.width * 3, size.height - bp.height * 2));
    }
  }

  @override
  void paintFood(Canvas canvas, Point<int> food, int blockSize, int frame) {
    // Мигающий символ еды
    if ((frame ~/ 6) % 2 == 0) {
      final foodStr = (frame ~/ 12) % 2 == 0 ? '*' : '+';
      final fp = _makeTp(foodStr, _amber, blockSize * 1.1);
      final x = food.x * blockSize.toDouble() + (blockSize - fp.width) / 2;
      final y = food.y * blockSize.toDouble() + (blockSize - fp.height) / 2;
      fp.paint(canvas, Offset(x, y));
    }
    // Свечение пикселя
    _paint.color = _amber.withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(food.x * blockSize + blockSize / 2.0, food.y * blockSize + blockSize / 2.0),
      blockSize * 0.8,
      _paint,
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
      final isHead = i == 0;

      // Символы для разных частей
      final char = _segmentChar(i, snake.length, direction, isHead);
      final brightness = isHead ? _phosphor : Color.lerp(_phosphorMid, _phosphorDim, i / snake.length)!;

      // Фоновое свечение пикселя (CRT phosphor glow)
      _paint.color = _phosphor.withValues(alpha: isHead ? 0.12 : 0.05);
      canvas.drawRect(
        Rect.fromLTWH(x, y, blockSize.toDouble(), blockSize.toDouble()),
        _paint,
      );

      final tp = _makeTp(char, brightness, blockSize * 1.05);
      final tx = x + (blockSize - tp.width) / 2;
      final ty = y + (blockSize - tp.height) / 2;
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  String _segmentChar(int i, int total, SnakeDirection dir, bool isHead) {
    if (isHead) {
      switch (dir) {
        case SnakeDirection.right: return '>';
        case SnakeDirection.left: return '<';
        case SnakeDirection.up: return '^';
        case SnakeDirection.down: return 'v';
      }
    }
    if (i == total - 1) return 'o'; // хвост
    return '█'; // тело
  }

  @override
  void paintGameOver(Canvas canvas, Size size) {
    _paint.color = Colors.black.withValues(alpha: 0.8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

    final lines = ['GAME OVER', '> PRESS ANY KEY _'];
    for (int i = 0; i < lines.length; i++) {
      final tp = _makeTp(lines[i], i == 0 ? _phosphor : _phosphorMid, i == 0 ? 22 : 14);
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2 - 20 + i * 28));
    }
  }

  @override TextStyle get titleStyle => GoogleFonts.vt323(fontSize: 28, color: _phosphor, letterSpacing: 3);
  @override TextStyle get scoreStyle => GoogleFonts.vt323(fontSize: 36, color: _phosphor);
  @override TextStyle get labelStyle => GoogleFonts.vt323(fontSize: 16, color: _phosphorMid, letterSpacing: 2);
}
