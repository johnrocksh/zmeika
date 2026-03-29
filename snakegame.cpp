#include "snakegame.h"
#include <QBrush>
#include <QFont>

SnakeGame::SnakeGame(QWidget *parent) : QWidget(parent)
{
    blockSize = 20;
    boardWidth = 30;
    boardHeight = 25;
    
    setFixedSize(boardWidth * blockSize, boardHeight * blockSize);
    setWindowTitle("Змейка");
    
    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &SnakeGame::updateGame);
    
    resetGame();
    
    srand(static_cast<unsigned>(time(nullptr)));
}

SnakeGame::~SnakeGame()
{
}

void SnakeGame::resetGame()
{
    snake.clear();
    snake.append(QPoint(boardWidth / 2, boardHeight / 2));
    snake.append(QPoint(boardWidth / 2 - 1, boardHeight / 2));
    snake.append(QPoint(boardWidth / 2 - 2, boardHeight / 2));
    
    direction = 0;
    nextDirection = 0;
    gameOver = false;
    score = 0;
    
    checkFood();
    
    timer->start(150); // Скорость игры (мс)
}

void SnakeGame::paintEvent(QPaintEvent *event)
{
    Q_UNUSED(event);
    
    QPainter painter(this);
    
    // Очистка фона
    painter.fillRect(rect(), QColor(30, 30, 30));
    
    if (gameOver) {
        painter.setPen(Qt::white);
        QFont font("Arial", 24, QFont::Bold);
        painter.setFont(font);
        QString text = "Игра окончена! Счёт: " + QString::number(score);
        QRect textRect = painter.fontMetrics().boundingRect(text);
        textRect.moveCenter(rect().center());
        painter.drawText(textRect, Qt::AlignCenter, text);
        
        QFont smallFont("Arial", 14);
        painter.setFont(smallFont);
        QString restartText = "Нажмите Пробел для рестарта";
        QRect restartRect = painter.fontMetrics().boundingRect(restartText);
        restartRect.moveCenter(QPoint(rect().center().x(), textRect.bottom() + 30));
        painter.drawText(restartRect, Qt::AlignCenter, restartText);
        return;
    }
    
    // Рисуем еду
    painter.setBrush(QBrush(Qt::red));
    painter.drawRect(food.x() * blockSize, food.y() * blockSize, 
                     blockSize - 2, blockSize - 2);
    
    // Рисуем змейку
    for (int i = 0; i < snake.size(); ++i) {
        if (i == 0) {
            // Голова змейки (темно-зеленая)
            painter.setBrush(QBrush(QColor(0, 200, 0)));
        } else {
            // Тело змейки (светло-зеленое)
            painter.setBrush(QBrush(QColor(0, 255, 0)));
        }
        painter.drawRect(snake[i].x() * blockSize, snake[i].y() * blockSize,
                         blockSize - 2, blockSize - 2);
    }
    
    // Рисуем счёт
    painter.setPen(Qt::white);
    QFont scoreFont("Arial", 14);
    painter.setFont(scoreFont);
    painter.drawText(10, 20, "Счёт: " + QString::number(score));
}

void SnakeGame::keyPressEvent(QKeyEvent *event)
{
    switch (event->key()) {
    case Qt::Key_Up:
    case Qt::Key_W:
        changeDirection(3);
        break;
    case Qt::Key_Down:
    case Qt::Key_S:
        changeDirection(1);
        break;
    case Qt::Key_Left:
    case Qt::Key_A:
        changeDirection(2);
        break;
    case Qt::Key_Right:
    case Qt::Key_D:
        changeDirection(0);
        break;
    case Qt::Key_Space:
        if (gameOver) {
            resetGame();
            update();
        }
        break;
    }
}

void SnakeGame::changeDirection(int newDirection)
{
    // Запрещаем разворот на 180 градусов
    if ((newDirection == 0 && direction != 2) ||
        (newDirection == 1 && direction != 3) ||
        (newDirection == 2 && direction != 0) ||
        (newDirection == 3 && direction != 1)) {
        nextDirection = newDirection;
    }
}

void SnakeGame::updateGame()
{
    if (gameOver) {
        return;
    }
    
    direction = nextDirection;
    
    // Новая голова в направлении движения
    QPoint head = snake.first();
    switch (direction) {
    case 0: // вправо
        head.rx()++;
        break;
    case 1: // вниз
        head.ry()++;
        break;
    case 2: // влево
        head.rx()--;
        break;
    case 3: // вверх
        head.ry()--;
        break;
    }
    
    snake.prepend(head);
    
    checkCollision();
    checkFood();
    
    update();
}

void SnakeGame::checkCollision()
{
    QPoint head = snake.first();
    
    // Столкновение со стенами
    if (head.x() < 0 || head.x() >= boardWidth || 
        head.y() < 0 || head.y() >= boardHeight) {
        gameOver = true;
        timer->stop();
        return;
    }
    
    // Столкновение с хвостом
    for (int i = 1; i < snake.size(); ++i) {
        if (head == snake[i]) {
            gameOver = true;
            timer->stop();
            return;
        }
    }
}

void SnakeGame::checkFood()
{
    if (snake.first() == food) {
        score += 10;
        // Генерируем новую еду в случайном месте
        bool validPosition = false;
        while (!validPosition) {
            food = QPoint(rand() % boardWidth, rand() % boardHeight);
            validPosition = true;
            
            // Проверяем, чтобы еда не появилась на змейке
            for (int i = 0; i < snake.size(); ++i) {
                if (snake[i] == food) {
                    validPosition = false;
                    break;
                }
            }
        }
    } else {
        snake.removeLast();
    }
}
