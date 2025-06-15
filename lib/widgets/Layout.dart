//lib/widgets/Layout.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../provider/users_provider.dart';
import '../provider/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LayoutWrapper extends StatelessWidget {
  final Widget child;
  final String Function(AppLocalizations) titleBuilder;

  const LayoutWrapper({super.key, required this.child, required this.titleBuilder});

  @override
  Widget build(BuildContext context) {
    // Obtener provider de usuarios; puede estar cargando
    final usersProv = context.watch<UserProvider?>();
    final currentUser = usersProv?.currentUser;

    // Si aún no está disponible el usuario, mostramos loader
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final admin = usersProv!.isAdmin;
    final email = currentUser.email.toLowerCase();
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    const droneEmails = {
      'dron_azul1@upc.edu',
      'dron_verde1@upc.edu',
      'dron_rojo1@upc.edu',
      'dron_amarillo1@upc.edu',
    };
    bool isInvitado(String e) =>
        RegExp(r'^invitado\d+@upc\.edu$').hasMatch(e);


    bool isRoute(String r) =>
        GoRouterState.of(context).uri.toString() == r;

    List<Widget> navItems = [
      _navItem(context, loc.home, Icons.home, '/', isRoute('/'))
    ];

    if (droneEmails.contains(email)) {
      navItems.add(
        _navItem(context, loc.games, Icons.sports_esports, '/jocs', isRoute('/jocs')),
      );
    } else if (isInvitado(email)) {
      navItems.addAll([
        _navItem(context, 'Xarxes Socials', Icons.people, '/xarxes', isRoute('/xarxes')),
        _navItem(context, loc.chat, Icons.chat, '/chat', isRoute('/chat')),
        _navItem(
          context,
          loc.spectateGames,
          Icons.visibility,
          '/jocs/spectate',
          isRoute('/jocs/spectate'),
        ),
      ]);
    } else {
      navItems.addAll([
        _navItem(context, 'Xarxes Socials', Icons.people, '/xarxes', isRoute('/xarxes')),
        _navItem(context, loc.chat, Icons.chat, '/chat', isRoute('/chat')),
        _navItem(context, loc.users, Icons.info_outline, '/details', isRoute('/details')),
        if (admin)
          _navItem(context, loc.createUser, Icons.person_add, '/editar', isRoute('/editar')),
        if (admin)
          _navItem(context, loc.deleteUser, Icons.delete_outline, '/borrar', isRoute('/borrar')),
        _navItem(context, loc.profile, Icons.account_circle, '/profile', isRoute('/profile')),
        _navItem(context, loc.map, Icons.map, '/mapa', isRoute('/mapa')),
        _navItem(
          context,
          loc.spectateGames,
          Icons.visibility,
          '/jocs/spectate',
          isRoute('/jocs/spectate'),
        ),
        _navItem(context, loc.store, Icons.store, '/store', isRoute('/store')),
        _navItem(context, 'Play Testing', Icons.videogame_asset, '/play-testing', isRoute('/play-testing')),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(titleBuilder(AppLocalizations.of(context)!)),
        actions: [
          const LanguageSelector(),
          Consumer<ThemeProvider>(
            builder: (_, t, __) => IconButton(
              icon: Icon(t.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              tooltip: t.isDarkMode ? AppLocalizations.of(context)!.lightMode : AppLocalizations.of(context)!.darkMode,
              onPressed: () => t.toggleTheme(),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 240,
              child: _header(scheme),
            ),
            ...navItems,
            const Divider(),
            if (!droneEmails.contains(email) && !isInvitado(email))
              _reloadButton(context, loc),
            _logoutButton(context, loc),
          ],
        ),
      ),
      body: Container(
        color: scheme.surfaceContainerHighest.withOpacity(.10),
        child: child,
      ),
    );
  }

  DrawerHeader _header(ColorScheme scheme) => DrawerHeader(
        decoration: BoxDecoration(color: scheme.primary),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo_skynet.png', width: 80),
              const SizedBox(height: 12),
              const Icon(Icons.people_alt_rounded, color: Colors.white, size: 30),
              const SizedBox(height: 12),
              Text(
                'S K Y N E T',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      );

  ListTile _navItem(BuildContext ctx, String title, IconData icon, String route, bool selected) {
    final scheme = Theme.of(ctx).colorScheme;
    return ListTile(
      leading: Icon(icon, color: selected ? scheme.primary : scheme.onSurface),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withOpacity(.30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(ctx);
        ctx.go(route);
      },
    );
  }

  Padding _reloadButton(BuildContext ctx, AppLocalizations loc) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton.icon(
          onPressed: () {
            ctx.read<UserProvider>().loadUsers();
            Navigator.pop(ctx);
          },
          icon: const Icon(Icons.refresh),
          label: Text(loc.reloadUsers),
        ),
      );

  Padding _logoutButton(BuildContext ctx, AppLocalizations loc) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await AuthService().logout();
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ctx.go('/login');
            }
          },
          icon: const Icon(Icons.logout),
          label: Text(loc.logout),
        ),
      );
}