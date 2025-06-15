import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DroneBattleGame extends StatefulWidget {
  const DroneBattleGame({super.key});

  @override
  State<DroneBattleGame> createState() => _DroneBattleGameState();
}

class _DroneBattleGameState extends State<DroneBattleGame> {
  static const double droneSize = 50.0;
  
  // Posiciones de los drones
  double drone1X = 100.0;
  double drone1Y = 300.0;
  double drone2X = 300.0;
  double drone2Y = 300.0;
  
  // Vidas de los drones
  int drone1Lives = 3;
  int drone2Lives = 3;
  
  // Velocidad de movimiento
  static const double moveSpeed = 5.0;
  
  // Estado del juego
  bool gameOver = false;
  String? winner;
  
  // Proyectiles
  List<Projectile> projectiles = [];
  
  // Temporizadores
  Timer? gameTimer;
  
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
      drone1X = 100.0;
      drone1Y = 300.0;
      drone2X = 300.0;
      drone2Y = 300.0;
      drone1Lives = 3;
      drone2Lives = 3;
      gameOver = false;
      winner = null;
      projectiles.clear();
    });
    
    // Cancelar temporizador existente si hay uno
    gameTimer?.cancel();
    
    // Game loop
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (!gameOver) {
        updateGame();
      } else {
        timer.cancel();
      }
    });
  }
  
  void updateGame() {
    if (!mounted) return;
    
    setState(() {
      // Actualizar posición de proyectiles
      for (var projectile in projectiles) {
        projectile.update();
      }
      
      // Comprobar colisiones
      checkCollisions();
      
      // Eliminar proyectiles fuera de pantalla
      projectiles.removeWhere((p) => 
        p.x < 0 || p.x > MediaQuery.of(context).size.width ||
        p.y < 0 || p.y > MediaQuery.of(context).size.height
      );
    });
  }
  
  void checkCollisions() {
    if (!mounted) return;
    
    for (var projectile in List.from(projectiles)) {
      // Colisión con drone 1
      if (projectile.owner == 2 && // Solo proyectiles del drone 2
          projectile.x >= drone1X &&
          projectile.x <= drone1X + droneSize &&
          projectile.y >= drone1Y &&
          projectile.y <= drone1Y + droneSize) {
        drone1Lives--;
        projectiles.remove(projectile);
        if (drone1Lives <= 0) {
          endGame(winner: "Jugador 2");
        }
        break;
      }
      
      // Colisión con drone 2
      if (projectile.owner == 1 && // Solo proyectiles del drone 1
          projectile.x >= drone2X &&
          projectile.x <= drone2X + droneSize &&
          projectile.y >= drone2Y &&
          projectile.y <= drone2Y + droneSize) {
        drone2Lives--;
        projectiles.remove(projectile);
        if (drone2Lives <= 0) {
          endGame(winner: "Jugador 1");
        }
        break;
      }
    }
  }
  
  void endGame({required String winner}) {
    if (!mounted) return;
    
    setState(() {
      gameOver = true;
      this.winner = winner;
    });
    gameTimer?.cancel();
  }
  
  void handleKeyEvent(RawKeyEvent event) {
    if (gameOver || !mounted) return;
    
    // Movimiento Jugador 1 (WASD)
    if (event.isKeyPressed(LogicalKeyboardKey.keyW)) {
      setState(() => drone1Y = (drone1Y - moveSpeed).clamp(0, MediaQuery.of(context).size.height - droneSize));
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyS)) {
      setState(() => drone1Y = (drone1Y + moveSpeed).clamp(0, MediaQuery.of(context).size.height - droneSize));
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyA)) {
      setState(() => drone1X = (drone1X - moveSpeed).clamp(0, MediaQuery.of(context).size.width - droneSize));
    }
    if (event.isKeyPressed(LogicalKeyboardKey.keyD)) {
      setState(() => drone1X = (drone1X + moveSpeed).clamp(0, MediaQuery.of(context).size.width - droneSize));
    }
    if (event.isKeyPressed(LogicalKeyboardKey.space)) {
      shoot(1);
    }
    
    // Movimiento Jugador 2 (Flechas)
    if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      setState(() => drone2Y = (drone2Y - moveSpeed).clamp(0, MediaQuery.of(context).size.height - droneSize));
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      setState(() => drone2Y = (drone2Y + moveSpeed).clamp(0, MediaQuery.of(context).size.height - droneSize));
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      setState(() => drone2X = (drone2X - moveSpeed).clamp(0, MediaQuery.of(context).size.width - droneSize));
    }
    if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
      setState(() => drone2X = (drone2X + moveSpeed).clamp(0, MediaQuery.of(context).size.width - droneSize));
    }
    if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
      shoot(2);
    }
  }
  
  void shoot(int player) {
    if (!mounted) return;
    
    final now = DateTime.now();
    final drone = player == 1 
        ? Drone(x: drone1X, y: drone1Y)
        : Drone(x: drone2X, y: drone2Y);
        
    // Limitar la frecuencia de disparo
    if (projectiles.any((p) => 
        p.owner == player && 
        now.difference(p.createdAt).inMilliseconds < 500)) {
      return;
    }
    
    setState(() {
      projectiles.add(
        Projectile(
          x: drone.x + droneSize / 2,
          y: drone.y + droneSize / 2,
          angle: player == 1 ? 0 : pi,
          speed: 8.0,
          owner: player,
        ),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Batalla de Drones'),
        backgroundColor: Colors.blue[900],
        leading: BackButton(
          onPressed: () {
            gameTimer?.cancel();
            context.go('/play-testing');
          },
        ),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: handleKeyEvent,
        child: Stack(
          children: [
            // Fondo con estrellas
            CustomPaint(
              painter: StarFieldPainter(),
              size: Size.infinite,
            ),
            
            // Drone 1
            Positioned(
              left: drone1X,
              top: drone1Y,
              child: DroneWidget(
                size: droneSize,
                color: Colors.blue,
                lives: drone1Lives,
              ),
            ),
            
            // Drone 2
            Positioned(
              left: drone2X,
              top: drone2Y,
              child: DroneWidget(
                size: droneSize,
                color: Colors.red,
                lives: drone2Lives,
              ),
            ),
            
            // Proyectiles
            ...projectiles.map((p) => Positioned(
              left: p.x - 2,
              top: p.y - 2,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: p.owner == 1 ? Colors.blue : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            )),
            
            // Game Over Screen
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
                      Text(
                        '¡$winner Gana!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
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
                          'Jugar de nuevo',
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

class Drone {
  final double x;
  final double y;
  
  Drone({required this.x, required this.y});
}

class Projectile {
  double x;
  double y;
  final double angle;
  final double speed;
  final int owner;
  final DateTime createdAt;
  
  Projectile({
    required this.x,
    required this.y,
    required this.angle,
    required this.speed,
    required this.owner,
  }) : createdAt = DateTime.now();
  
  void update() {
    x += cos(angle) * speed;
    y += sin(angle) * speed;
  }
}

class DroneWidget extends StatelessWidget {
  final double size;
  final Color color;
  final int lives;
  
  const DroneWidget({
    super.key,
    required this.size,
    required this.color,
    required this.lives,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: DronePainter(color: color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Icon(
              Icons.favorite,
              color: index < lives ? Colors.red : Colors.grey[800],
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class DronePainter extends CustomPainter {
  final Color color;
  
  DronePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
      
    // Cuerpo principal
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.2,
          size.height * 0.3,
          size.width * 0.6,
          size.height * 0.4,
        ),
        Radius.circular(size.width * 0.1),
      ),
      paint,
    );
    
    // Hélices
    paint.color = color.withOpacity(0.6);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.15,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      size.width * 0.15,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final random = Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 