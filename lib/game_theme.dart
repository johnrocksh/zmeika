import 'dart:math';
import 'package:flutter/material.dart';

enum SnakeDirection { up, down, left, right }

/// Абстрактная тема игры — каждая тема сама рисует всё на Canvas
abstract class GameTheme {
  String get id;
  String get name;
  String get description;
  String get emoji;

  // ─── UI цвета (AppBar, карточки, кнопки) ───────────────────────
  Color get primaryColor;
  Color get secondaryColor;
  Color get backgroundColor;
  Color get cardColor;
  Color get textColor;
  Color get borderColor;

  // ─── Canvas рисование ──────────────────────────────────────────
  /// Фон поля (вызывается каждый кадр, frame для анимации)
  void paintBackground(Canvas canvas, Size size, int frame);

  /// Еда
  void paintFood(Canvas canvas, Point<int> food, int blockSize, int frame);

  /// Змейка целиком
  void paintSnake(
    Canvas canvas,
    List<Point<int>> snake,
    int blockSize,
    SnakeDirection direction,
    int frame,
  );

  /// Оверлей Game Over
  void paintGameOver(Canvas canvas, Size size);

  // ─── UI стили текста ───────────────────────────────────────────
  TextStyle get titleStyle;
  TextStyle get scoreStyle;
  TextStyle get labelStyle;

  // ─── Вспомогательные утилиты ───────────────────────────────────
  static void drawRoundedRect(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double w,
    double h,
    double r,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      paint,
    );
  }

  static void drawStar(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double outerR,
    double innerR,
    Color color, {
    int points = 5,
  }) {
    paint
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = i * pi / points - pi / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  static void drawTextOnCanvas(
    Canvas canvas,
    String text,
    double x,
    double y,
    TextStyle style, {
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    tp.paint(canvas, Offset(x - (align == TextAlign.center ? tp.width / 2 : 0), y));
  }
}
