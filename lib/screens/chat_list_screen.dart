//lib/screens/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/users_provider.dart';
import '../models/user.dart';
import '../widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../provider/theme_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserProvider>().initData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final convIds = provider.conversationUserIds;
    final convUsers = provider.users.where((u) => convIds.contains(u.id)).toList();
    final allUsers = provider.users.where((u) => u.id != provider.currentUser?.id).toList();
    String _search = '';

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(AppLocalizations.of(context)!.chat),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: _UserSearchDelegate(allUsers),
              );
              if (result != null) {
                provider.addConversation(result.id!);
                GoRouter.of(context).go('/chat/${result.id}');
              }
            },
          ),
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
          : convUsers.isEmpty
              ? const Center(child: Text('Aún no tienes conversaciones.'))
              : ListView.separated(
                  itemCount: convUsers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final user = convUsers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.userName.isNotEmpty
                              ? user.userName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(user.userName),
                      subtitle: Text(user.email),
                      onTap: () => GoRouter.of(context).go('/chat/${user.id}'),
                    );
                  },
                ),
    );
  }
}

class _UserSearchDelegate extends SearchDelegate<User?> {
  final List<User> users;
  _UserSearchDelegate(this.users);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final filtered = users.where((u) =>
        u.userName.toLowerCase().contains(query.toLowerCase()) ||
        u.email.toLowerCase().contains(query.toLowerCase()));
    return ListView(
      children: filtered
          .map((u) => ListTile(
                leading: CircleAvatar(child: Text(u.userName[0].toUpperCase())),
                title: Text(u.userName),
                subtitle: Text(u.email),
                onTap: () => close(context, u),
              ))
          .toList(),
    );
  }
}
