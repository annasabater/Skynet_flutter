import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlujaAsteroidesScreen extends StatefulWidget {
  const PlujaAsteroidesScreen({super.key});

  @override
  State<PlujaAsteroidesScreen> createState() => _PlujaAsteroidesScreenState();
}

class _PlujaAsteroidesScreenState extends State<PlujaAsteroidesScreen> {
  bool started = false;

  @override
  Widget build(BuildContext context) {
    return started
        ? _GameView(onExit: () => setState(() => started = false))
        : _WelcomeView(onStart: () => setState(() => started = true));
  }
}

class _WelcomeView extends StatelessWidget {
  final VoidCallback onStart;
  const _WelcomeView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/play-testing')),
        title: Text(AppLocalizations.of(context)!.games),
        backgroundColor: Colors.indigo[900],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo_skynet.png', width: 120),
            const SizedBox(height: 32),
            const Text(
              'Pluja d\'Asteroides!\nEsquiva les roques, recull cors i sobreviu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontFamily: 'PressStart2P',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                textStyle: const TextStyle(fontSize: 22, fontFamily: 'PressStart2P'),
              ),
              label: const Text('JUGAR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameView extends StatefulWidget {
  final VoidCallback onExit;
  const _GameView({required this.onExit});

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  static const double playerSize = 50.0;
  static const double asteroidSize = 40.0;
  static const double heartSize = 30.0;
  static const double moveSpeed = 8.0;
  
  double? playerX;
  double? playerY;
  List<Offset> asteroids = [];
  List<Offset> hearts = [];
  Timer? gameTimer;
  int score = 0;
  int lives = 3;
  bool gameOver = false;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    if (!mounted) return;
    
    setState(() {
      asteroids = [];
      hearts = [];
      score = 0;
      lives = 3;
      gameOver = false;
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      updateGame();
    });
  }

  void updateGame() {
    if (!mounted || gameOver) return;

    final size = MediaQuery.of(context).size;
    if (playerX == null || playerY == null) {
      playerX = size.width / 2 - playerSize / 2;
      playerY = size.height - playerSize * 2;
    }

    setState(() {
      // Aumentar velocidad de caída de asteroides
      for (int i = 0; i < asteroids.length; i++) {
        asteroids[i] = Offset(asteroids[i].dx, asteroids[i].dy + 5);
      }

      // Mover corazones más rápido también
      for (int i = 0; i < hearts.length; i++) {
        hearts[i] = Offset(hearts[i].dx, hearts[i].dy + 3);
      }

      // Aumentar frecuencia de asteroides (0.02 -> 0.03)
      if (random.nextDouble() < 0.03) {
        asteroids.add(Offset(
          random.nextDouble() * (size.width - asteroidSize),
          -asteroidSize,
        ));
      }

      // Reducir frecuencia de corazones (0.005 -> 0.003)
      if (random.nextDouble() < 0.003) {
        hearts.add(Offset(
          random.nextDouble() * (size.width - heartSize),
          -heartSize,
        ));
      }

      // Comprobar colisiones
      checkCollisions();

      // Limpiar objetos fuera de pantalla
      asteroids.removeWhere((asteroid) => 
        asteroid.dy > size.height);
      hearts.removeWhere((heart) => 
        heart.dy > size.height);

      // Incrementar puntuación
      score++;
    });
  }

  void checkCollisions() {
    // Colisiones con asteroides
    for (var asteroid in List.from(asteroids)) {
      if (playerX! < asteroid.dx + asteroidSize &&
          playerX! + playerSize > asteroid.dx &&
          playerY! < asteroid.dy + asteroidSize &&
          playerY! + playerSize > asteroid.dy) {
        asteroids.remove(asteroid);
        lives--;
        if (lives <= 0) {
          gameOver = true;
          gameTimer?.cancel();
        }
      }
    }

    // Colisiones con corazones
    for (var heart in List.from(hearts)) {
      if (playerX! < heart.dx + heartSize &&
          playerX! + playerSize > heart.dx &&
          playerY! < heart.dy + heartSize &&
          playerY! + playerSize > heart.dy) {
        hearts.remove(heart);
        if (lives < 3) lives++;
      }
    }
  }

  void handleKeyEvent(RawKeyEvent event) {
    if (!mounted || gameOver || playerX == null || playerY == null) return;

    final size = MediaQuery.of(context).size;
    setState(() {
      if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
        playerX = (playerX! - moveSpeed).clamp(0, size.width - playerSize);
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
        playerX = (playerX! + moveSpeed).clamp(0, size.width - playerSize);
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
        playerY = (playerY! - moveSpeed).clamp(0, size.height - playerSize);
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
        playerY = (playerY! + moveSpeed).clamp(0, size.height - playerSize);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Inicializar posición del jugador si aún no se ha hecho
    if (playerX == null || playerY == null) {
      playerX = size.width / 2 - playerSize / 2;
      playerY = size.height - playerSize * 2;
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onExit),
        title: Text(AppLocalizations.of(context)!.games),
        backgroundColor: Colors.indigo[900],
      ),
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: handleKeyEvent,
        child: Stack(
          children: [
            // Puntuación y vidas
            Positioned(
              top: 20,
              left: 20,
              child: Text(
                'Puntuació: $score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'PressStart2P',
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Icon(
                    Icons.favorite,
                    color: index < lives ? Colors.red : Colors.grey[800],
                    size: 30,
                  ),
                ),
              ),
            ),

            if (playerX != null && playerY != null) ...[
              // Jugador (Dron)
              Positioned(
                left: playerX,
                top: playerY,
                child: CustomPaint(
                  size: Size(playerSize, playerSize),
                  painter: DronePainter(color: Colors.blue),
                ),
              ),
            ],

            // Asteroides
            ...asteroids.map((asteroid) => Positioned(
              left: asteroid.dx,
              top: asteroid.dy,
              child: Container(
                width: asteroidSize,
                height: asteroidSize,
                decoration: BoxDecoration(
                  color: Colors.brown[700],
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.brown[500]!, Colors.brown[900]!],
                    center: Alignment.center,
                  ),
                ),
              ),
            )),

            // Corazones
            ...hearts.map((heart) => Positioned(
              left: heart.dx,
              top: heart.dy,
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: heartSize,
              ),
            )),

            // Pantalla de Game Over
            if (gameOver)
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
                        'Game Over!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontFamily: 'PressStart2P',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Puntuació: $score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'PressStart2P',
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Tornar a jugar',
                          style: TextStyle(
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

class DronePainter extends CustomPainter {
  final Color color;
  
  DronePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Cuerpo principal
    final bodyPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.4)
      ..lineTo(size.width * 0.8, size.height * 0.4)
      ..lineTo(size.width * 0.6, size.height * 0.8)
      ..lineTo(size.width * 0.4, size.height * 0.8)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Hélices
    paint.color = color.withOpacity(0.8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.3),
        width: size.width * 0.3,
        height: size.height * 0.1,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.3),
        width: size.width * 0.3,
        height: size.height * 0.1,
      ),
      paint,
    );

    // Detalles
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.05,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 