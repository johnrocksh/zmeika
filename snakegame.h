#ifndef SNAKEGAME_H
#define SNAKEGAME_H

#include <QWidget>
#include <QPainter>
#include <QTimer>
#include <QKeyEvent>
#include <QVector>
#include <QPoint>
#include <cstdlib>
#include <ctime>

class SnakeGame : public QWidget
{
    Q_OBJECT

public:
    explicit SnakeGame(QWidget *parent = nullptr);
    ~SnakeGame();

protected:
    void paintEvent(QPaintEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;

private slots:
    void updateGame();

private:
    void checkCollision();
    void checkFood();
    void resetGame();
    void changeDirection(int newDirection);

    QVector<QPoint> snake;
    QPoint food;
    int direction; // 0=вправо, 1=вниз, 2=влево, 3=вверх
    int nextDirection;
    int blockSize;
    int boardWidth;
    int boardHeight;
    QTimer *timer;
    bool gameOver;
    int score;
};

#endif // SNAKEGAME_H
