// lib/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:SkyNet/components/my_textfield.dart';
import 'package:SkyNet/components/my_button.dart';
import 'package:SkyNet/services/auth_service.dart';
import 'package:SkyNet/provider/users_provider.dart';
import 'package:SkyNet/models/user.dart';
import 'package:SkyNet/services/socket_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _signUserIn(BuildContext context) async {
    final email    = emailController.text.trim();
    final password = passwordController.text.trim();
    final loc      = AppLocalizations.of(context)!;

    if (email.isEmpty || password.isEmpty) {
      _showError(context, loc.emptyFieldsError);
      return;
    }

    try {
      final result = await AuthService().login(email, password);
      if (result.containsKey('error')) {
        if (context.mounted) _showError(context, result['error'] as String);
        return;
      }
      final mapUser = result['user'] as Map<String, dynamic>;
      if (context.mounted) {
        // Guardamos el usuario en el provider
        context.read<UserProvider>().setCurrentUser(
          User.fromJson(mapUser),
        );
        // Solo guardamos email, sin validar color
        SocketService.setUserEmail(mapUser['email'] as String);
        // Vamos al home
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  void _showError(BuildContext ctx, String msg) {
    final loc = AppLocalizations.of(ctx)!;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(loc.error),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc    = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 25),
                Image.asset('assets/logo_skynet.png', width: 120, height: 120),
                const SizedBox(height: 25),
                Text(
                  loc.welcome,
                  style: TextStyle(
                    color: colors.onBackground,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                MyTextfield(
                  controller: emailController,
                  hintText: loc.email,
                  obscureText: false,
                ),
                const SizedBox(height: 12),
                MyTextfield(
                  controller: passwordController,
                  hintText: loc.password,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      loc.forgotPassword,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                MyButton(
                  onTap: () => _signUserIn(context),
                  text: loc.login,
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loc.notAMember, style: TextStyle(color: colors.onSurfaceVariant)),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        loc.register,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
