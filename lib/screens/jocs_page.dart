//lib/screens/jocs_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/users_provider.dart';
import '../services/socket_service.dart';
import '../data/game_texts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class _FancyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _FancyButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A6572), Color(0xFF344955)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JocsPage extends StatelessWidget {
  const JocsPage({super.key});

  void _showTextDialog(BuildContext ctx, String title, String content) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompetitor = context.watch<UserProvider>().isCompetitor;
    final email = context.read<UserProvider>().currentUser!.email;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.games)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(child: Image.asset('assets/logo_skynet.png', width: 100)),
            const SizedBox(height: 32),

            // Botones superiores
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FancyButton(
                  label: 'Descripción',
                  icon: Icons.info_outline,
                  onTap: () => _showTextDialog(context, 'Descripción', kGameDescription),
                ),
                _FancyButton(
                  label: 'Manual',
                  icon: Icons.menu_book_outlined,
                  onTap: () => _showTextDialog(context, 'Manual', kGameManual),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildGameCard(
              context,
              title: 'COMBATE',
              image: 'assets/competencia.png',
              buttonText: 'Entrar',
              onTap: () async {
                if (isCompetitor) {
                  SocketService.setCompetitionUserEmail(email);
                  await SocketService.initWaitingSocket();
                  final sid = SocketService.currentSessionId!;
                  context.go('/jocs/open/$sid');
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Acceso denegado'),
                      content: const Text('No estás autorizado para jugar a la competencia.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String image,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            image,
            width: 550,
            height: 240,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.play_arrow),
          label: Text(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006064),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
