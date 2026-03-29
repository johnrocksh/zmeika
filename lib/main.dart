import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'storage_service.dart';
import 'theme_service.dart';
import 'game_theme.dart';
import 'brawl_stars_theme.dart';

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
  
  // Новая система тем
  GameTheme _theme = BrawlStarsTheme();
  int _frame = 0;
  Timer? _animTimer;
  
  // Статистика игры
  int highScore = 0;
  bool isLoadingStats = true;
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadStats();
    resetGame();
    
    // Таймер анимации фона
    _animTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() => _frame++);
    });
  }
  
  Future<void> _loadTheme() async {
    final theme = await ThemeService.getCurrentTheme();
    setState(() {
      _theme = theme;
    });
  }
  
  Future<void> _switchTheme() async {
    final currentId = await ThemeService.getCurrentThemeId();
    final allThemes = ThemeRegistry.all;
    final currentIndex = allThemes.indexWhere((t) => t.id == currentId);
    final nextIndex = (currentIndex + 1) % allThemes.length;
    final nextTheme = allThemes[nextIndex];
    
    await ThemeService.setTheme(nextTheme.id);
    setState(() {
      _theme = nextTheme;
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
  
  Future<void> _saveGameStats() async {
    if (score > 0) {
      await GameStorageService.saveHighScore(score);
      debugPrint('💾 Результ сохранён | Счёт: $score');
    }
    await _loadStats();
  }
  
  @override
  void dispose() {
    _animTimer?.cancel();
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
          style: _theme.titleStyle.copyWith(
            fontSize: 24,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: _theme.backgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () async {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: _theme.cardColor,
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: _theme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'ВЫЙТИ?',
                      style: _theme.titleStyle.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                content: Text(
                  'Прогресс будет сохранён',
                  style: _theme.scoreStyle.copyWith(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'ОТМЕНА',
                      style: _theme.labelStyle,
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
            onTap: _switchTheme,
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _theme.borderColor, width: 2),
              ),
              child: Text(_theme.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          // Кнопка рестарта
          GestureDetector(
            onTap: () => resetGame(),
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _theme.secondaryColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _theme.borderColor, width: 2),
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
                      color: _theme.cardColor,
                      border: Border.all(color: _theme.primaryColor, width: 3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'СЧЁТ',
                          style: _theme.labelStyle.copyWith(fontSize: 14, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$score',
                          style: _theme.scoreStyle.copyWith(fontSize: 32),
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
                      color: _theme.cardColor,
                      border: Border.all(color: _theme.secondaryColor, width: 3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _theme.secondaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'РЕКОРД',
                          style: _theme.labelStyle.copyWith(fontSize: 14, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$highScore',
                          style: _theme.scoreStyle.copyWith(fontSize: 32),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: _theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _theme.borderColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _theme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                        theme: _theme,
                        direction: direction.toSnake,
                        frame: _frame,
                      ),
                    ),
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
                    Icon(Icons.star, color: _theme.secondaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ИГРА ЗАВЕРШЕНА',
                            style: _theme.labelStyle.copyWith(
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Счёт: $score',
                            style: _theme.scoreStyle.copyWith(fontSize: 20),
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
                          color: _theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _theme.borderColor, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$highScore',
                              style: _theme.scoreStyle.copyWith(fontSize: 16),
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
                          color: _theme.primaryColor,
                          borderRadius: BorderRadius.circular(50),
                          border: Border(
                            bottom: BorderSide(
                              color: _theme.borderColor,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: Colors.white,
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

extension DirectionExt on Direction {
  SnakeDirection get toSnake {
    switch (this) {
      case Direction.up: return SnakeDirection.up;
      case Direction.down: return SnakeDirection.down;
      case Direction.left: return SnakeDirection.left;
      case Direction.right: return SnakeDirection.right;
    }
  }
}

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
  bool shouldRepaint(SnakePainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.snake != snake ||
      oldDelegate.food != food ||
      oldDelegate.gameOver != gameOver ||
      oldDelegate.theme.id != theme.id;
}
