// lib/screens/social/xarxes_socials_screen.dart

import 'package:flutter/material.dart';
import 'package:SkyNet/screens/social/explore_screen.dart';
import 'package:SkyNet/screens/social/feed_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/language_selector.dart';
import '../../provider/theme_provider.dart';
import 'package:provider/provider.dart';

class XarxesSocialsScreen extends StatelessWidget {
  const XarxesSocialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          title: Text(loc.socialFeatureTitle),
          actions: [
            const LanguageSelector(),
            IconButton(
              icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              tooltip: isDark ? loc.lightMode : loc.darkMode,
              onPressed: () => themeProv.toggleTheme(),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              height: 56,
              color: theme.colorScheme.primary,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Red Social',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Botón para ir a la pantalla de seguidos
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.people_alt_outlined),
                  label: Text(loc.following),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () => context.go('/following'),
                ),
              ],
            ),

            // TabBar justo debajo, fondo blanco
            Material(
              color: Colors.white,
              child: TabBar(
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                  insets: const EdgeInsets.symmetric(horizontal: 24),
                ),
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                ),
                tabs: [
                  Tab(icon: const Icon(Icons.explore_outlined), text: 'Explorar'),
                  Tab(icon: const Icon(Icons.dynamic_feed_outlined), text: 'Siguiendo'),
                ],
              ),
            ),

            // Contenido de las pestañas
            Expanded(
              child: TabBarView(
                children: const [ExploreScreen(), FeedScreen()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
