import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'storage_service.dart';

void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Змейка',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.lightGreen,
        ),
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

  @override
  void initState() {
    super.initState();
    _loadStats();
    resetGame();
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
        title: const Text('Змейка'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () async {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.grey[850],
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Выйти?', style: TextStyle(color: Colors.white)),
                  ],
                ),
                content: const Text(
                  'Прогресс будет сохранён',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Выйти'),
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
          tooltip: 'Выход',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetGame,
            tooltip: 'Рестарт',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Счёт: $score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
            // Компактный баннер "Игра завершена"
            if (gameOver)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[700]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Игра завершена',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Счёт: $score',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (score > highScore && score > 0) ...[
                      Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$highScore',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: () => resetGame(),
                      icon: const Icon(Icons.refresh, size: 20),
                      color: Colors.blue[300],
                      tooltip: 'Ещё раз',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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

    // Рисуем фон
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey[850]!,
    );

    // Рисуем еду
    if (food != null) {
      paint.color = Colors.red;
      canvas.drawRect(
        Rect.fromLTWH(
          food!.x * blockSize.toDouble(),
          food!.y * blockSize.toDouble(),
          blockSize - 2,
          blockSize - 2,
        ),
        paint,
      );
    }

    // Рисуем змейку
    for (int i = 0; i < snake.length; i++) {
      if (i == 0) {
        paint.color = Colors.lightGreen[400]!; // Голова
      } else {
        paint.color = Colors.green[400]!; // Тело
      }

      canvas.drawRect(
        Rect.fromLTWH(
          snake[i].x * blockSize.toDouble(),
          snake[i].y * blockSize.toDouble(),
          blockSize - 2,
          blockSize - 2,
        ),
        paint,
      );
    }

    if (gameOver) {
      // Затемнение при проигрыше
      paint.color = Colors.black.withValues(alpha: 0.5);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(SnakePainter oldDelegate) => true;
}
