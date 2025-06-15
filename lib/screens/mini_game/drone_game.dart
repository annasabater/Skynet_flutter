import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DroneGame extends StatefulWidget {
  const DroneGame({super.key});

  @override
  State<DroneGame> createState() => _DroneGameState();
}

class _DroneGameState extends State<DroneGame> {
  static const double droneWidth = 50.0;
  static const double droneHeight = 30.0;
  static const double rockWidth = 30.0;
  static const double rockHeight = 30.0;
  
  double droneX = 0.0;
  int lives = 3;
  int score = 0;
  bool isGameOver = false;
  List<Rock> rocks = [];
  Timer? gameTimer;
  Timer? rockSpawnTimer;
  
  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    setState(() {
      lives = 3;
      score = 0;
      isGameOver = false;
      rocks.clear();
      droneX = 0.0;
    });

    // Spawn rocks every 2 seconds
    rockSpawnTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!isGameOver) {
        spawnRock();
      }
    });

    // Game loop
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isGameOver) {
        updateGame();
      }
    });
  }

  void spawnRock() {
    final random = Random();
    setState(() {
      rocks.add(Rock(
        x: random.nextDouble() * (MediaQuery.of(context).size.width - rockWidth),
        y: -rockHeight,
      ));
    });
  }

  void updateGame() {
    setState(() {
      // Move rocks down
      for (var rock in rocks) {
        rock.y += 5;
      }

      // Remove rocks that are off screen
      rocks.removeWhere((rock) => rock.y > MediaQuery.of(context).size.height);

      // Check collisions
      for (var rock in rocks) {
        if (checkCollision(rock)) {
          lives--;
          rocks.remove(rock);
          if (lives <= 0) {
            gameOver();
          }
          break;
        }
      }

      // Increase score
      score++;
    });
  }

  bool checkCollision(Rock rock) {
    return (rock.x < droneX + droneWidth &&
            rock.x + rockWidth > droneX &&
            rock.y < MediaQuery.of(context).size.height - droneHeight &&
            rock.y + rockHeight > MediaQuery.of(context).size.height - droneHeight);
  }

  void gameOver() {
    setState(() {
      isGameOver = true;
    });
    gameTimer?.cancel();
    rockSpawnTimer?.cancel();
  }

  void moveDrone(double delta) {
    if (!isGameOver) {
      setState(() {
        droneX += delta;
        // Keep drone within screen bounds
        if (droneX < 0) droneX = 0;
        if (droneX > MediaQuery.of(context).size.width - droneWidth) {
          droneX = MediaQuery.of(context).size.width - droneWidth;
        }
      });
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    rockSpawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
            moveDrone(-10);
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
            moveDrone(10);
          }
        },
        child: Stack(
          children: [
            // Background
            Container(
              color: Colors.black,
            ),
            
            // Game elements
            ...rocks.map((rock) => Positioned(
              left: rock.x,
              top: rock.y,
              child: Container(
                width: rockWidth,
                height: rockHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            )),

            // Drone
            Positioned(
              left: droneX,
              bottom: 0,
              child: Container(
                width: droneWidth,
                height: droneHeight,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),

            // UI Overlay
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vides: $lives',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'PressStart2P',
                    ),
                  ),
                  Text(
                    'Puntuació: $score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'PressStart2P',
                    ),
                  ),
                ],
              ),
            ),

            // Game Over Screen
            if (isGameOver)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 32,
                          fontFamily: 'PressStart2P',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Puntuació final: $score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'PressStart2P',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Tornar a començar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'PressStart2P',
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

class Rock {
  double x;
  double y;

  Rock({required this.x, required this.y});
} 