//jocs_page.dart
/*
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JocsPage extends StatelessWidget {
  const JocsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jocs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.sports_esports),
            title: const Text('Competencia'),
            onTap: () {
              context.go('/jocs/competencia');
            },
          ),
        ],
      ),
    );
  }
}
*/

// lib/screens/jocs_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/users_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/language_selector.dart';

class JocsPage extends StatelessWidget {
  const JocsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompetitor = context.watch<UserProvider>().isCompetitor;
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.games),
        actions: [
          const LanguageSelector(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/logo_skynet.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 32),
            _buildGameCard(
              context,
              title: 'COMPETÈNCIA',
              image: 'assets/competencia.png',
              buttonText: localizations.submit,
              onTap: () {
                if (isCompetitor) {
                  context.go('/jocs/open');
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(localizations.error),
                      content: Text(localizations.accessDenied ?? 'No estás autorizado para jugar a la competencia.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(), 
                          child: Text(localizations.ok)
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            _buildGameCard(
              context,
              title: 'CURSES',
              image: 'assets/curses.png',
              buttonText: localizations.submit,
              onTap: () {},
            ),
            const SizedBox(height: 24),
            _buildGameCard(
              context,
              title: 'OBSTACLES',
              image: 'assets/obstacles.png',
              buttonText: localizations.submit,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, {required String title, required String image, required String buttonText, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              image,
              width: 350,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onTap,
          child: Text(buttonText),
        ),
      ],
    );
  }
}

