import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'storage_service.dart';
import 'theme_service.dart';
import 'classic_theme.dart';

void main() {
  runApp(const SnakeGameApp());
}

// Цвета в стиле Brawl Stars
class BSColors {
  static const Color primary = Color(0xFFF4921A); // оранжевый
  static const Color secondary = Color(0xFFFFc200); // золотой
  static const Color background = Color(0xFF0d1b35); // тёмно-синий фон
  static const Color card = Color(0xFF1a2d55); // карточки
  static const Color border = Color(0xFFA05800); // тёмная обводка
  static const Color text = Color(0xFFFFFFFF); // белый текст

  @Deprecated('Use surface instead')
  static Color get backgroundOld => background;
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Змейка Brawl Stars',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: BSColors.primary,
          secondary: BSColors.secondary,
          surface: BSColors.card,
          background: BSColors.background,
        ),
        scaffoldBackgroundColor: BSColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: BSColors.card,
          elevation: 0,
        ),
        textTheme: GoogleFonts.lilitaOneTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: BSColors.text, displayColor: BSColors.text),
      ),
      home: const SnakeGame(),
    );
  }
}

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int gridSize = 20;
  static const int blockSize = 25;
  
  List<Point<int>> snake = [];
  Point<int>? food;
  Direction direction = Direction.right;
  Direction nextDirection = Direction.right;
  bool gameOver = false;
  int score = 0;
  Timer? gameTimer;
  
  // Статистика игры
  int highScore = 0;
  bool isLoadingStats = true;
  
  // Тема
  bool isBrawlStarsTheme = true;
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadStats();
    resetGame();
  }
  
  Future<void> _loadTheme() async {
    final isBS = await ThemeService.isBrawlStarsTheme();
    setState(() {
      isBrawlStarsTheme = isBS;
    });
  }
  
  Future<void> _toggleTheme() async {
    final newTheme = await ThemeService.toggleTheme();
    final isBS = newTheme == ThemeService.brawlStarsTheme;
    setState(() {
      isBrawlStarsTheme = isBS;
    });
  }
  
  Future<void> _loadStats() async {
    final stats = await GameStorageService.getStats();
    setState(() {
      highScore = stats['high_score'] as int;
      isLoadingStats = false;
    });
    debugPrint('📊 Статистика загружена | Рекорд: $highScore');
  }
  
  Color get _snakeHeadColor => isBrawlStarsTheme ? BSColors.primary : ClassicColors.snakeHead;
  Color get _snakeBodyColor => isBrawlStarsTheme ? BSColors.secondary : ClassicColors.snakeBody;
  Color get _foodColor => isBrawlStarsTheme ? BSColors.secondary : ClassicColors.food;
  Color get _backgroundColor => isBrawlStarsTheme ? BSColors.background : ClassicColors.background;
  Color get _cardColor => isBrawlStarsTheme ? BSColors.card : ClassicColors.card;
  Color get _textColor => isBrawlStarsTheme ? BSColors.text : ClassicColors.text;
  Color get _primaryColor => isBrawlStarsTheme ? BSColors.primary : ClassicColors.snakeHead;
  Color get _secondaryColor => isBrawlStarsTheme ? BSColors.secondary : ClassicColors.snakeHead;

  Future<void> _saveGameStats() async {
    if (score > 0) {
      await GameStorageService.saveHighScore(score);
      debugPrint('💾 Результ сохранён | Счёт: $score');
    }
    await _loadStats();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void resetGame() {
    setState(() {
      snake = [
        Point(gridSize ~/ 2, gridSize ~/ 2),
        Point(gridSize ~/ 2 - 1, gridSize ~/ 2),
        Point(gridSize ~/ 2 - 2, gridSize ~/ 2),
      ];
      direction = Direction.right;
      nextDirection = Direction.right;
      gameOver = false;
      score = 0;
      spawnFood();

      gameTimer?.cancel();
      gameTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        updateGame();
      });

      debugPrint('🎮 ИГРА ЗАПУЩЕНА | Направление: $direction');
    });
  }

  void spawnFood() {
    final random = Random();
    bool validPosition = false;

    while (!validPosition) {
      food = Point(random.nextInt(gridSize), random.nextInt(gridSize));

      validPosition = true;
      for (var segment in snake) {
        if (segment == food) {
          validPosition = false;
          break;
        }
      }
    }
    debugPrint('🍎 Еда создана: ${food?.x}, ${food?.y}');
  }

  void updateGame() {
    if (gameOver) return;

    setState(() {
      direction = nextDirection;

      Point<int> head = snake.first;
      Point<int> newHead;

      switch (direction) {
        case Direction.up:
          newHead = Point(head.x, head.y - 1);
          break;
        case Direction.down:
          newHead = Point(head.x, head.y + 1);
          break;
        case Direction.left:
          newHead = Point(head.x - 1, head.y);
          break;
        case Direction.right:
          newHead = Point(head.x + 1, head.y);
          break;
      }

      debugPrint(
        '🐍 Ход | Текущее направление: $direction | Новая голова: (${newHead.x}, ${newHead.y})',
      );

      // Проверка столкновений
      if (newHead.x < 0 ||
          newHead.x >= gridSize ||
          newHead.y < 0 ||
          newHead.y >= gridSize ||
          snake.contains(newHead)) {
        gameOver = true;
        gameTimer?.cancel();
        debugPrint('💥 СТОЛКНОВЕНИЕ! Игра окончена | Счёт: $score');
        return;
      }

      snake.insert(0, newHead);

      // Проверка еды
      if (newHead == food) {
        score += 10;
        debugPrint('✅ ЕДА СЪЕДЕНА! +10 очков | Счёт: $score');
        spawnFood();
      } else {
        snake.removeLast();
      }

      debugPrint(
        '📏 Длина змейки: ${snake.length} | Позиция головы: (${snake.first.x}, ${snake.first.y})',
      );
    });
  }

  void handleDirectionChange(Direction newDirection) {
    debugPrint(
      '👆 ВВОД | Запрошено направление: $newDirection | Текущее: $direction | Следующее: $nextDirection',
    );

    // Запрещаем разворот на 180 градусов
    bool canChange = false;
    if (newDirection == Direction.up && direction != Direction.down) {
      canChange = true;
      debugPrint('✅ Разрешён поворот ВВЕРХ');
    } else if (newDirection == Direction.down && direction != Direction.up) {
      canChange = true;
      debugPrint('✅ Разрешён поворот ВНИЗ');
    } else if (newDirection == Direction.left && direction != Direction.right) {
      canChange = true;
      debugPrint('✅ Разрешён поворот ВЛЕВО');
    } else if (newDirection == Direction.right && direction != Direction.left) {
      canChange = true;
      debugPrint('✅ Разрешён поворот ВПРАВО');
    } else {
      debugPrint('❌ ОТКЛОНЁНО! Нельзя развернуться на 180°');
    }

    if (canChange) {
      nextDirection = newDirection;
      debugPrint('➡️ УСТАНОВЛЕНО следующее направление: $nextDirection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ЗМЕЙКА',
          style: GoogleFonts.lilitaOne(
            fontSize: 24,
            color: BSColors.secondary,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: BSColors.card,
        elevation: 0,
        leading: GestureDetector(
          onTap: () async {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: BSColors.card,
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: BSColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'ВЫЙТИ?',
                      style: GoogleFonts.lilitaOne(
                        fontSize: 18,
                        color: BSColors.text,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Прогресс будет сохранён',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: BSColors.text.withValues(alpha: 0.7),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'ОТМЕНА',
                      style: GoogleFonts.lilitaOne(
                        color: BSColors.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BSColors.primary,
                      foregroundColor: BSColors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ВЫЙТИ',
                      style: GoogleFonts.lilitaOne(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );

            if (shouldExit == true && !gameOver && score > 0) {
              await _saveGameStats();
            }
            if (shouldExit == true && mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: BSColors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BSColors.border, width: 2),
            ),
            child: Icon(Icons.exit_to_app, color: BSColors.text, size: 20),
          ),
        ),
        actions: [
          // Кнопка переключения темы
          GestureDetector(
            onTap: _toggleTheme,
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: isBrawlStarsTheme 
                    ? LinearGradient(colors: [BSColors.primary, BSColors.secondary])
                    : null,
                color: !isBrawlStarsTheme ? ClassicColors.snakeHead : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isBrawlStarsTheme ? BSColors.border : ClassicColors.text, width: 2),
              ),
              child: Icon(
                isBrawlStarsTheme ? Icons.star : Icons.brightness_2,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          // Кнопка рестарта
          GestureDetector(
            onTap: () => resetGame(),
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isBrawlStarsTheme ? BSColors.secondary : ClassicColors.snakeHead,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isBrawlStarsTheme ? BSColors.border : ClassicColors.text, width: 2),
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: BSColors.background,
        child: Column(
          children: [
            // Верхняя панель со счётом и рекордом в стиле Brawl Stars
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Счёт
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: BSColors.card,
                      border: Border.all(color: BSColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: BSColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'СЧЁТ',
                          style: GoogleFonts.lilitaOne(
                            fontSize: 14,
                            color: BSColors.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$score',
                          style: GoogleFonts.lilitaOne(
                            fontSize: 32,
                            color: BSColors.text,
                            shadows: [
                              Shadow(
                                color: BSColors.primary,
                                offset: const Offset(0, -2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Рекорд
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: BSColors.card,
                      border: Border.all(color: BSColors.secondary, width: 3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: BSColors.secondary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'РЕКОРД',
                          style: GoogleFonts.lilitaOne(
                            fontSize: 14,
                            color: BSColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$highScore',
                          style: GoogleFonts.lilitaOne(
                            fontSize: 32,
                            color: BSColors.secondary,
                            shadows: [
                              Shadow(
                                color: BSColors.primary,
                                offset: const Offset(0, -2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (gameOver) {
                    debugPrint('⚠️ Свайп отклонён - игра окончена');
                    return;
                  }

                  debugPrint(
                    '🖐️ СВАЙП ПОЛУЧЕН | dx: ${details.delta.dx.toStringAsFixed(1)}, dy: ${details.delta.dy.toStringAsFixed(1)}',
                  );

                  if (details.delta.dx.abs() > details.delta.dy.abs()) {
                    // Горизонтальный свайп
                    if (details.delta.dx > 0) {
                      debugPrint('➡️ Свайп вправо');
                      handleDirectionChange(Direction.right);
                    } else {
                      debugPrint('⬅️ Свайп влево');
                      handleDirectionChange(Direction.left);
                    }
                  } else {
                    // Вертикальный свайп
                    if (details.delta.dy > 0) {
                      debugPrint('⬇️ Свайп вниз');
                      handleDirectionChange(Direction.down);
                    } else {
                      debugPrint('⬆️ Свайп вверх');
                      handleDirectionChange(Direction.up);
                    }
                  }
                },
                child: CustomPaint(
                  size: Size(
                    (gridSize * blockSize).toDouble(),
                    (gridSize * blockSize).toDouble(),
                  ),
                  painter: SnakePainter(
                    snake: snake,
                    food: food,
                    blockSize: blockSize,
                    gameOver: gameOver,
                  ),
                ),
              ),
            ),
            // Компактный баннер "Игра завершена" в стиле Brawl Stars
            if (gameOver)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BSColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BSColors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: BSColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: BSColors.secondary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ИГРА ЗАВЕРШЕНА',
                            style: GoogleFonts.lilitaOne(
                              fontSize: 14,
                              color: BSColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Счёт: $score',
                            style: GoogleFonts.lilitaOne(
                              fontSize: 20,
                              color: BSColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (score > highScore && score > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: BSColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: BSColors.border, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: BSColors.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$highScore',
                              style: GoogleFonts.lilitaOne(
                                fontSize: 16,
                                color: BSColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Кастомная кнопка в стиле Brawl Stars
                    GestureDetector(
                      onTap: () => resetGame(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BSColors.primary,
                          borderRadius: BorderRadius.circular(50),
                          border: Border(
                            bottom: BorderSide(
                              color: BSColors.border,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: BSColors.text,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum Direction { up, down, left, right }

class SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int>? food;
  final int blockSize;
  final bool gameOver;

  SnakePainter({
    required this.snake,
    this.food,
    required this.blockSize,
    required this.gameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Рисуем фон в стиле Brawl Stars - тёмно-синий со звёздами
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = BSColors.background,
    );

    // Рисуем маленькие звёзды на фоне
    _drawBackgroundStars(canvas, size, paint);

    // Рисуем еду как звезду
    if (food != null) {
      _drawStar(
        canvas,
        paint,
        food!.x * blockSize.toDouble() + blockSize / 2,
        food!.y * blockSize.toDouble() + blockSize / 2,
        blockSize / 2 - 2,
        BSColors.secondary,
      );
    }

    // Рисуем змейку
    for (int i = 0; i < snake.length; i++) {
      if (i == 0) {
        paint.color = BSColors.primary; // Голова оранжевая
      } else {
        paint.color = BSColors.secondary; // Тело золотое
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            snake[i].x * blockSize.toDouble(),
            snake[i].y * blockSize.toDouble(),
            blockSize - 2,
            blockSize - 2,
          ),
          const Radius.circular(6),
        ),
        paint,
      );

      // Рисуем глаза у головы
      if (i == 0) {
        _drawEyes(canvas, snake[i], blockSize, paint);
      }
    }

    if (gameOver) {
      // Затемнение при проигрыше
      paint.color = Colors.black.withValues(alpha: 0.5);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  // Рисуем звёзды на фоне
  void _drawBackgroundStars(Canvas canvas, Size size, Paint paint) {
    paint.color = BSColors.secondary.withValues(alpha: 0.1);
    final random = Random(42); // Фиксированный seed для постоянных звёзд

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  // Рисуем звезду (еду)
  void _drawStar(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double radius,
    Color color,
  ) {
    paint.color = color;
    paint.style = PaintingStyle.fill;

    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? radius : innerRadius;
      final angle = (i * pi / points) - pi / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Добавляем блеск
    paint.color = Colors.white.withValues(alpha: 0.3);
    canvas.drawPath(path, paint);
  }

  // Рисуем глаза змее
  void _drawEyes(Canvas canvas, Point<int> head, int blockSize, Paint paint) {
    final x = head.x * blockSize.toDouble();
    final y = head.y * blockSize.toDouble();
    final eyeSize = blockSize / 5;
    final pupilSize = eyeSize / 2;

    // Белки глаз
    paint.color = Colors.white;
    final leftEye = Offset(x + blockSize / 3, y + blockSize / 3);
    final rightEye = Offset(x + 2 * blockSize / 3, y + blockSize / 3);

    canvas.drawCircle(leftEye, eyeSize, paint);
    canvas.drawCircle(rightEye, eyeSize, paint);

    // Зрачки
    paint.color = Colors.black;
    canvas.drawCircle(Offset(leftEye.dx, leftEye.dy), pupilSize, paint);
    canvas.drawCircle(Offset(rightEye.dx, rightEye.dy), pupilSize, paint);
  }

  @override
  bool shouldRepaint(SnakePainter oldDelegate) => true;
}
