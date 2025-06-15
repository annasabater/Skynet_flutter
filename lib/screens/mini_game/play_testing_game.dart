import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayTestingGameScreen extends StatefulWidget {
  const PlayTestingGameScreen({super.key});

  @override
  State<PlayTestingGameScreen> createState() => _PlayTestingGameScreenState();
}

class _PlayTestingGameScreenState extends State<PlayTestingGameScreen> {
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
              '¡Dron Dodge!\nEsquiva las rocas, recoge corazones y sobrevive',
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
  static const double droneWidth = 50.0;
  static const double droneHeight = 36.0;
  static const double rockWidth = 32.0;
  static const double rockHeight = 32.0;
  static const double heartSize = 28.0;

  double droneX = 0.0;
  int vidas = 3;
  int puntuacion = 0;
  bool gameOver = false;
  List<_FallingObj> rocas = [];
  List<_FallingObj> corazones = [];
  Timer? gameTimer;
  Timer? rocaSpawnTimer;
  Timer? corazonSpawnTimer;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    iniciarJuego();
  }

  void iniciarJuego() {
    setState(() {
      vidas = 3;
      puntuacion = 0;
      gameOver = false;
      rocas.clear();
      corazones.clear();
      droneX = 0.0;
    });
    rocaSpawnTimer?.cancel();
    gameTimer?.cancel();
    corazonSpawnTimer?.cancel();
    rocaSpawnTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!gameOver) {
        rocas.add(_FallingObj(
          x: random.nextDouble() * (MediaQuery.of(context).size.width - rockWidth),
          y: -rockHeight,
        ));
      }
    });
    corazonSpawnTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!gameOver && random.nextDouble() < 0.5) {
        corazones.add(_FallingObj(
          x: random.nextDouble() * (MediaQuery.of(context).size.width - heartSize),
          y: -heartSize,
        ));
      }
    });
    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!gameOver) {
        actualizarJuego();
      }
    });
  }

  void actualizarJuego() {
    setState(() {
      for (var roca in rocas) {
        roca.y += 9;
      }
      for (var corazon in corazones) {
        corazon.y += 7;
      }
      rocas.removeWhere((roca) => roca.y > MediaQuery.of(context).size.height);
      corazones.removeWhere((corazon) => corazon.y > MediaQuery.of(context).size.height);
      for (var roca in rocas) {
        if (_colision(roca, droneWidth, droneHeight)) {
          vidas--;
          rocas.remove(roca);
          if (vidas <= 0) {
            terminarJuego();
          }
          break;
        }
      }
      for (var corazon in corazones) {
        if (_colision(corazon, droneWidth, droneHeight)) {
          if (vidas < 3) vidas++;
          corazones.remove(corazon);
          break;
        }
      }
      puntuacion++;
    });
  }

  bool _colision(_FallingObj obj, double w, double h) {
    return (obj.x < droneX + w &&
            obj.x + obj.size > droneX &&
            obj.y < MediaQuery.of(context).size.height - h &&
            obj.y + obj.size > MediaQuery.of(context).size.height - h);
  }

  void terminarJuego() {
    setState(() {
      gameOver = true;
    });
    gameTimer?.cancel();
    rocaSpawnTimer?.cancel();
    corazonSpawnTimer?.cancel();
  }

  void moverDrone(double delta) {
    if (!gameOver) {
      setState(() {
        droneX += delta;
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
    rocaSpawnTimer?.cancel();
    corazonSpawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
            moverDrone(-38);
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
            moverDrone(38);
          }
        },
        child: Stack(
          children: [
            // Fondo arcade
            Positioned.fill(
              child: CustomPaint(
                painter: _ArcadeBackgroundPainter(),
              ),
            ),
            // Rocas
            ...rocas.map((roca) => Positioned(
              left: roca.x,
              top: roca.y,
              child: _RockSprite(size: rockWidth),
            )),
            // Corazones
            ...corazones.map((corazon) => Positioned(
              left: corazon.x,
              top: corazon.y,
              child: _HeartSprite(size: heartSize),
            )),
            // Drone
            Positioned(
              left: droneX,
              bottom: 0,
              child: _DroneSprite(width: droneWidth, height: droneHeight),
            ),
            // UI Overlay
            Positioned(
              top: 20,
              left: 20,
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.favorite,
                        color: i < vidas ? Colors.redAccent : Colors.grey[700],
                        size: 28,
                      ),
                    ),
                  const SizedBox(width: 24),
                  Text(
                    'Puntuación: $puntuacion',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'PressStart2P',
                    ),
                  ),
                ],
              ),
            ),
            // Pantalla de Game Over
            if (gameOver)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 32,
                          fontFamily: 'PressStart2P',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Puntuación final: $puntuacion',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'PressStart2P',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: iniciarJuego,
                        icon: const Icon(Icons.refresh),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        label: const Text(
                          'Volver a jugar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'PressStart2P',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: widget.onExit,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text('Volver', style: TextStyle(color: Colors.white)),
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

class _FallingObj {
  double x;
  double y;
  double get size => 32;
  _FallingObj({required this.x, required this.y});
}

class _DroneSprite extends StatelessWidget {
  final double width;
  final double height;
  const _DroneSprite({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _DronePainter(),
      ),
    );
  }
}

class _RockSprite extends StatelessWidget {
  final double size;
  const _RockSprite({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RockPainter(),
      ),
    );
  }
}

class _HeartSprite extends StatelessWidget {
  final double size;
  const _HeartSprite({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HeartPainter(),
      ),
    );
  }
}

class _DronePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.fill;
    // Cuerpo
    canvas.drawRect(Rect.fromLTWH(size.width * 0.2, size.height * 0.4, size.width * 0.6, size.height * 0.3), paint);
    // Hélices
    paint.color = Colors.blue[900]!;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.35, size.width * 0.2, size.height * 0.1), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.8, size.height * 0.35, size.width * 0.2, size.height * 0.1), paint);
    // Luz
    paint.color = Colors.yellowAccent;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), size.height * 0.08, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[700]!
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = Colors.brown[900]!;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ),
      paint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, size.height * 0.8);
    path.cubicTo(
      size.width * 1.1, size.height * 0.5,
      size.width * 0.8, size.height * 0.1,
      size.width / 2, size.height * 0.3,
    );
    path.cubicTo(
      size.width * 0.2, size.height * 0.1,
      -size.width * 0.1, size.height * 0.5,
      size.width / 2, size.height * 0.8,
    );
    canvas.drawPath(path, paint);
    paint.color = Colors.white.withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.45), size.width * 0.13, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcadeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.indigo[900]!, Colors.black, Colors.deepPurple[900]!],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    // Líneas horizontales tipo scanlines
    paint.color = Colors.white.withOpacity(0.04);
    paint.shader = null;
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    }
    // Efecto de estrellas
    final starPaint = Paint()..color = Colors.white.withOpacity(0.10);
    final rand = Random(42);
    for (int i = 0; i < 40; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), rand.nextDouble() * 1.5 + 0.5, starPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 