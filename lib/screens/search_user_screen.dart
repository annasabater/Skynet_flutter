import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/users_provider.dart';
import '../models/user.dart';
import '../widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);
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
    final localizations = AppLocalizations.of(context)!;
    
    final results = provider.users.where((u) {
      if (u.id == null || u.id == currentUser?.id) return false;
      final q = _query.toLowerCase();
      return u.userName.toLowerCase().contains(q) ||
             u.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.searchUser ?? 'Buscar usuario'),
        actions: [
          const LanguageSelector(), 
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: localizations.searchUserHint ?? 'Nombre o correo…',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: results.isEmpty
                      ? Center(child: Text(localizations.noResultsFound ?? 'No se encontró nadie.'))
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, i) {
                            final user = results[i];
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
