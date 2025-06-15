//lib/screens/search_user_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/users_provider.dart';
import '../models/user.dart';
import '../widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../provider/theme_provider.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});
  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  String _query = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      if (provider.users.isEmpty) {
        provider.loadUsers();
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final currentUser = provider.currentUser;
    final results = provider.users.where((u) {
      if (u.id == null || u.id == currentUser?.id) return false;
      final q = _query.toLowerCase();
      return u.userName.toLowerCase().contains(q) ||
             u.email.toLowerCase().contains(q);
    }).toList();

    // Mostrar todos los usuarios si la query está vacía
    final showAll = _query.isEmpty;
    final displayUsers = showAll ? provider.users.where((u) => u.id != currentUser?.id).toList() : results;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(AppLocalizations.of(context)!.users),
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
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Nombre o correo…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: displayUsers.isEmpty
                      ? const Center(child: Text('No se encontró nadie.'))
                      : ListView.separated(
                          itemCount: displayUsers.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, i) {
                            final user = displayUsers[i];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(user.userName[0].toUpperCase()),
                              ),
                              title: Text(user.userName),
                              subtitle: Text(user.email),
                              onTap: () {
                                provider.addConversation(user.id!);
                                GoRouter.of(context).go('/chat/${user.id}');
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
