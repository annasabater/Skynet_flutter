// lib/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/Layout.dart';
import '../services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = AuthService();
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      try {
        final res = await auth.getUserById(currentUser['_id']);
        setState(() {
          _user = res.containsKey('error') ? currentUser : res;
        });
      } catch (_) {
        setState(() {
          _user = currentUser;
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return LayoutWrapper(
      title: localizations.profile,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo_skynet.png',
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person, size: 70, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _user?['userName'] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user?['email'] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${localizations.role}: ${_user?['role'] ?? ''}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID', style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(_user?['_id'] ?? ''),
                                const Divider(),
                                Text(localizations.role, style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(_user?['role'] ?? ''),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ListTile(
                          leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                          title: Text(localizations.editProfile ?? 'Editar Perfil'),
                          subtitle: Text(localizations.updateProfileInfo ?? 'Actualitza la teva informació personal'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => context.go('/profile/edit'),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            AuthService().logout();
                            context.go('/login');
                          },
                          icon: const Icon(Icons.logout),
                          label: Text(localizations.logout),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
