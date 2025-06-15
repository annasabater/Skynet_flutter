import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayTestingMenuScreen extends StatelessWidget {
  const PlayTestingMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.games),
        backgroundColor: Colors.indigo[900],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/play-testing/dodge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                textStyle: const TextStyle(fontSize: 22, fontFamily: 'PressStart2P'),
              ),
              child: const Text('Dron Dodge'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/play-testing/battle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                textStyle: const TextStyle(fontSize: 22, fontFamily: 'PressStart2P'),
              ),
              child: const Text('Batalla de Drones'),
            ),
          ],
        ),
      ),
    );
  }
} 