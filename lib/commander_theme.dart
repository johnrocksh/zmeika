import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_theme.dart';

/// Commander Keen / Wolf3D — пиксельный аркадный стиль 90-х.
/// Жёсткие пиксели, EGA-палитра (16 цветов), никакой сглаживалки.
class CommanderTheme extends GameTheme {
  // EGA палитра (16 цветов, реальные значения)
  static const _black       = Color(0xFF000000);
  static const _blue        = Color(0xFF0000AA);
  static const _green       = Color(0xFF00AA00);
  static const _cyan        = Color(0xFF00AAAA);
  static const _red         = Color(0xFFAA0000);
  static const _magenta     = Color(0xFFAA00AA);
  static const _brown       = Color(0xFFAA5500);
  static const _lightGray   = Color(0xFFAAAAAA);
  static const _darkGray    = Color(0xFF555555);
  static const _lightBlue   = Color(0xFF5555FF);
  static const _lightGreen  = Color(0xFF55FF55);
  static const _lightCyan   = Color(0xFF55FFFF);
  static const _lightRed    = Color(0xFFFF5555);
  static const _lightMagenta= Color(0xFFFF55FF);
  static const _yellow      = Color(0xFFFFFF55);
  static const _white       = Color(0xFFFFFFFF);

  // Тайлы фона (задник EGA)
  static const _bgTile = [
    [0,0,0,0,0,1,0,0],
    [0,0,0,0,1,1,0,0],
    [1,0,0,0,1,1,0,0],
    [1,1,0,0,1,1,1,1],
    [1,1,0,0,0,0,1,1],
    [0,1,1,0,0,0,1,0],
    [0,0,1,1,0,0,0,0],
    [0,0,0,1,0,0,0,0],
  ];

  @override String get id => 'commander';
  @override String get name => 'Commander Keen';
  @override String get description => 'EGA пиксели. 4.77 MHz. DOS.';
  @override String get emoji => '🕹';

  @override Color get primaryColor => _lightCyan;
  @override Color get secondaryColor => _yellow;
  @override Color get backgroundColor => _blue;
  @override Color get cardColor => _darkGray;
  @override Color get textColor => _white;
  @override Color get borderColor => _lightBlue;

  final _paint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = false; // ПИКСЕЛИ! Без сглаживания!

  @override
  void paintBackground(Canvas canvas, Size size, int frame) {
    // Однотонный EGA-синий
    _paint.color = _blue;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

    // EGA-тайл паттерн — рисуем пиксели вручную
    const tileSize = 8.0;
    final cols = (size.width / tileSize).ceil();
    final rows = (size.height / tileSize).ceil();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final tileRow = _bgTile[r % 8];
        final tileCol = tileRow[c % 8];
        if (tileCol == 1) {
          _paint.color = _darkGray.withValues(alpha: 0.12);
          canvas.drawRect(Rect.fromLTWH(c * tileSize, r * tileSize, tileSize, tileSize), _paint);
        }
      }
    }

    // Мигающая "звезда" — классическая EGA анимация
    if ((frame ~/ 10) % 2 == 0) {
      _paint.color = _yellow;
      const starX = 8.0, starY = 8.0;
      canvas.drawRect(const Rect.fromLTWH(starX, starY, 3, 3), _paint);
    }
  }

  @override
  void paintFood(Canvas canvas, Point<int> food, int blockSize, int frame) {
    final px = food.x * blockSize.toDouble();
    final py = food.y * blockSize.toDouble();
    final bs = blockSize.toDouble();

    // Пиксельная "монета" Commander Keen (желтая)
    final frame4 = (frame ~/ 8) % 4;
    final coinW = [bs * 0.7, bs * 0.3, bs * 0.1, bs * 0.3][frame4];
    final coinX = px + (bs - coinW) / 2;

    _paint.color = _yellow;
    canvas.drawRect(Rect.fromLTWH(coinX, py + bs * 0.15, coinW, bs * 0.7), _paint);

    _paint.color = _brown;
    canvas.drawRect(Rect.fromLTWH(coinX + 2, py + bs * 0.15 + 2, coinW - 4, bs * 0.7 - 4), _paint);

    if (coinW > bs * 0.4) {
      _paint.color = _white;
      canvas.drawRect(Rect.fromLTWH(coinX + 3, py + bs * 0.25, 2, 2), _paint);
    }
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
      final bs = blockSize.toDouble();
      final isHead = i == 0;

      // EGA пиксельный спрайт — никакой прозрачности, чёткие цвета
      if (isHead) {
        _drawKeenHead(canvas, x, y, bs, direction, frame);
      } else {
        _drawBodySegment(canvas, x, y, bs, i);
      }
    }
  }

  void _drawKeenHead(Canvas canvas, double x, double y, double bs, SnakeDirection dir, int frame) {
    // Тело головы — голубое
    _paint.color = _lightCyan;
    canvas.drawRect(Rect.fromLTWH(x + 1, y + 1, bs - 2, bs - 2), _paint);

    // Шлем (Commander Keen signature!) — желтый верх
    _paint.color = _yellow;
    canvas.drawRect(Rect.fromLTWH(x + 2, y + 1, bs - 4, 4), _paint);

    // Визир шлема — красный
    _paint.color = _red;
    canvas.drawRect(Rect.fromLTWH(x + 3, y + 3, bs - 6, 2), _paint);

    // Глаза — белые пиксели
    _paint.color = _white;
    final eyeY = y + bs * 0.45;
    canvas.drawRect(Rect.fromLTWH(x + bs * 0.25, eyeY, 3, 3), _paint);
    canvas.drawRect(Rect.fromLTWH(x + bs * 0.62, eyeY, 3, 3), _paint);

    // Зрачки — чёрные
    _paint.color = _black;
    final pupilOff = _pupilOffset(dir);
    canvas.drawRect(Rect.fromLTWH(x + bs * 0.25 + 1 + pupilOff.dx, eyeY + 1 + pupilOff.dy, 1, 1), _paint);
    canvas.drawRect(Rect.fromLTWH(x + bs * 0.62 + 1 + pupilOff.dx, eyeY + 1 + pupilOff.dy, 1, 1), _paint);
  }

  Offset _pupilOffset(SnakeDirection dir) {
    switch (dir) {
      case SnakeDirection.right: return const Offset(1, 0);
      case SnakeDirection.left: return const Offset(-1, 0);
      case SnakeDirection.up: return const Offset(0, -1);
      case SnakeDirection.down: return const Offset(0, 1);
    }
  }

  void _drawBodySegment(Canvas canvas, double x, double y, double bs, int index) {
    // Чередующийся EGA паттерн тела
    final isEven = index.isEven;
    _paint.color = isEven ? _lightBlue : _cyan;
    canvas.drawRect(Rect.fromLTWH(x + 1, y + 1, bs - 2, bs - 2), _paint);

    // Пиксельная "чешуя" — темная полоска
    _paint.color = isEven ? _blue : _darkGray;
    canvas.drawRect(Rect.fromLTWH(x + 2, y + bs * 0.45, bs - 4, 2), _paint);
  }

  @override
  void paintGameOver(Canvas canvas, Size size) {
    // EGA мигающий экран смерти
    _paint.color = _black.withValues(alpha: 0.85);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);

    // Прямоугольник в духе DOS
    _paint.color = _blue;
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 70, size.height / 2 - 24, 140, 44), _paint);
    _paint
      ..color = _lightGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 70, size.height / 2 - 24, 140, 44), _paint);
    _paint.style = PaintingStyle.fill;

    GameTheme.drawTextOnCanvas(
      canvas, 'GAME OVER!',
      size.width / 2, size.height / 2 - 16,
      GoogleFonts.pressStart2p(fontSize: 11, color: _yellow),
      align: TextAlign.center,
    );
  }

  @override TextStyle get titleStyle => GoogleFonts.pressStart2p(fontSize: 14, color: _yellow);
  @override TextStyle get scoreStyle => GoogleFonts.pressStart2p(fontSize: 16, color: _white);
  @override TextStyle get labelStyle => GoogleFonts.pressStart2p(fontSize: 9, color: _lightCyan, letterSpacing: 1);
}
