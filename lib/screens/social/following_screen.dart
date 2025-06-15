import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../provider/users_provider.dart';
import '../../services/social_service.dart';
import '../../widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../provider/theme_provider.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({Key? key}) : super(key: key);

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<dynamic> _followingUsers = [];
  List<dynamic> _searchResults = [];
  bool _loading = true;
  String _query = '';
  int _page = 1;
  final int _limit = 20;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowing() async {
    setState(() => _loading = true);
    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = provider.currentUser;
      if (currentUser == null) return;
      // El endpoint devuelve { following: [...] }
      final res = await SocialService.getMyFollowing(
        page: _page,
        limit: _limit,
      );
      setState(() => _followingUsers = res);
    } catch (e) {
      setState(() => _followingUsers = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    // No pongas setState(() => _loading = true) aquí, solo muestra loading si realmente quieres bloquear la UI
    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      await provider.loadUsers();
      final users = provider.users;
      setState(() {
        _searchResults =
            users
                .where(
                  (u) =>
                      u.userName.toLowerCase().contains(query.toLowerCase()) ||
                      u.email.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      });
    } catch (e) {
      setState(() => _searchResults = []);
    }
  }

  int get followingCount => _followingUsers.length;

  Future<void> _followUser(String userId) async {
    setState(() => _loading = true);
    await SocialService.follow(userId);
    await _loadFollowing();
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ahora sigues a este usuario')),
    );
  }

  Future<void> _unfollowUser(String userId) async {
    setState(() => _loading = true);
    await SocialService.unFollow(userId);
    await _loadFollowing();
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Has dejado de seguir a este usuario')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode),
            tooltip: Theme.of(context).brightness == Brightness.dark ? AppLocalizations.of(context)!.lightMode : AppLocalizations.of(context)!.darkMode,
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar usuarios...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _query.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _query = '';
                                      _searchResults = [];
                                      _searchController.clear();
                                    });
                                  },
                                )
                                : null,
                      ),
                      onChanged: (v) {
                        setState(() => _query = v);
                        if (v.isNotEmpty) {
                          _searchUsers(v);
                        } else {
                          setState(() => _searchResults = []);
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sigues a $followingCount usuario${followingCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (_query.isEmpty && followingCount > 0)
                          Icon(
                            Icons.people_alt_outlined,
                            color: Colors.blueGrey.shade400,
                          ),
                      ],
                    ),
                  ),
                  if (_query.isEmpty)
                    Expanded(
                      child:
                          _followingUsers.isEmpty
                              ? const Center(child: Text('No sigues a nadie.'))
                              : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 0,
                                ),
                                itemCount: _followingUsers.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final user = _followingUsers[i];
                                  return Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Card(
                                        key: ValueKey(user.id),
                                        elevation: 1.5,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                          leading: CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            child: Text(
                                              user.userName[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            user.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          subtitle: Text(
                                            user.email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.person,
                                                  color: Colors.blueGrey,
                                                  size: 22,
                                                ),
                                                tooltip: 'Ver perfil',
                                                onPressed: () {
                                                  Navigator.of(
                                                    context,
                                                  ).pushNamed('/u/${user.id}');
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.chat_bubble_outline,
                                                  color: Colors.teal,
                                                  size: 22,
                                                ),
                                                tooltip: 'Chat',
                                                onPressed: () {
                                                  GoRouter.of(
                                                    context,
                                                  ).go('/chat/${user.id}');
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.person_remove,
                                                  color: Colors.red,
                                                  size: 22,
                                                ),
                                                tooltip: 'Unfollow',
                                                onPressed:
                                                    () =>
                                                        _unfollowUser(user.id!),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (ctx, i) {
                          final user = _searchResults[i];
                          final isFollowing = _followingUsers.any(
                            (u) => u.id == user.id,
                          );
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(user.userName[0].toUpperCase()),
                            ),
                            title: Text(user.userName),
                            subtitle: Text(user.email),
                            trailing:
                                isFollowing
                                    ? ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade100,
                                        foregroundColor: Colors.green.shade800,
                                      ),
                                      child: const Text('Siguiendo'),
                                    )
                                    : ElevatedButton(
                                      child: const Text('Seguir'),
                                      onPressed: () async {
                                        await _followUser(user.id!);
                                        setState(() {
                                          _searchResults[i] = user;
                                          _followingUsers.add(user);
                                        });
                                      },
                                    ),
                          );
                        },
                      ),
                    ),
                ],
              ),
    );
  }
}
