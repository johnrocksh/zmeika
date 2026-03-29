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
  int totalGames = 0;
  int totalWins = 0;
  double averageScore = 0.0;
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
      totalGames = stats['total_games'] as int;
      totalWins = stats['total_wins'] as int;
      averageScore = stats['average_score'] as double;
      isLoadingStats = false;
    });
    debugPrint('📊 Статистика загружена | Рекорд: $highScore | Игр: $totalGames');
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
  
  Future<void> resetGame() async {
    // Сохраняем статистику предыдущей игры если она была закончена
    if (gameOver && score > 0) {
      await _saveGameStats();
    }
    
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
  
  Future<void> _saveGameStats() async {
    // Увеличиваем счетчик игр
    await GameStorageService.incrementTotalGames();
    
    // Обновляем средний счёт
    await GameStorageService.updateAverageScore(score);
    
    // Если набрали очки - это победа
    if (score > 0) {
      await GameStorageService.incrementTotalWins();
    }
    
    // Проверяем рекорд
    if (score > highScore) {
      await GameStorageService.saveHighScore(score);
      debugPrint('🏆 НОВЫЙ РЕКОРД! $score');
    }
    
    // Загружаем обновлённую статистику
    await _loadStats();
  }
  
  void spawnFood() {
    final random = Random();
    bool validPosition = false;
    
    while (!validPosition) {
      food = Point(
        random.nextInt(gridSize),
        random.nextInt(gridSize),
      );
      
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
      
      debugPrint('🐍 Ход | Текущее направление: $direction | Новая голова: (${newHead.x}, ${newHead.y})');
      
      // Проверка столкновений
      if (newHead.x < 0 || newHead.x >= gridSize ||
          newHead.y < 0 || newHead.y >= gridSize ||
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
      
      debugPrint('📏 Длина змейки: ${snake.length} | Позиция головы: (${snake.first.x}, ${snake.first.y})');
    });
  }
  
  void handleDirectionChange(Direction newDirection) {
    debugPrint('👆 ВВОД | Запрошено направление: $newDirection | Текущее: $direction | Следующее: $nextDirection');
    
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => resetGame(),
            tooltip: 'Рестарт',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            // Верхняя панель со счётом и рекордом
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Счёт',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Рекорд',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$highScore',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isLoadingStats ? Colors.grey : Colors.amber,
                        ),
                      ),
                    ],
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
                  
                  debugPrint('🖐️ СВАЙП ПОЛУЧЕН | dx: ${details.delta.dx.toStringAsFixed(1)}, dy: ${details.delta.dy.toStringAsFixed(1)}');
                  
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
            if (gameOver)
              AnimatedOpacity(
                opacity: gameOver ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850]?.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок с иконкой
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[300],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Игра завершена',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Счёт
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[700]!, Colors.blue[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Счёт: $score',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Новый рекорд (если есть)
                      if (score > highScore && score > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber[900]?.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[700]!, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Рекорд: $highScore',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[200],
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Кнопка рестарта
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => resetGame(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Ещё раз'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(SnakePainter oldDelegate) => true;
}
