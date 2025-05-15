import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/users_provider.dart';
import '../models/user.dart';
import '../widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      provider.initData();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final convIds = provider.conversationUserIds;
    final convUsers = provider.users.where((u) => convIds.contains(u.id)).toList();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.chat),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => GoRouter.of(context).go('/chat/search'),
          ),
          const LanguageSelector(), 
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : convUsers.isEmpty
              ? Center(child: Text(localizations.noConversations ?? 'Aún no tienes conversaciones.'))
              : ListView.separated(
                  itemCount: convUsers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final user = convUsers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
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
