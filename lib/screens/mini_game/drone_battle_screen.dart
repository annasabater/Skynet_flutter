import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'drone_battle_game.dart';

class DroneBattleScreen extends StatefulWidget {
  const DroneBattleScreen({Key? key}) : super(key: key);

  @override
  State<DroneBattleScreen> createState() => _DroneBattleScreenState();
}

class _DroneBattleScreenState extends State<DroneBattleScreen> {
  bool gameStarted = false;

  @override
  Widget build(BuildContext context) {
    if (gameStarted) {
      return const DroneBattleGame();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batalla de Drones'),
        backgroundColor: Colors.blue[900],
        leading: BackButton(onPressed: () => context.go('/play-testing')),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.black],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¡Batalla de Drones!',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PressStart2P',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Controles:\nJugador 1: WASD + Espacio\nJugador 2: Flechas + Enter',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'PressStart2P',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    gameStarted = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                child: const Text(
                  'Comenzar Juego',
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
    );
  }
} 