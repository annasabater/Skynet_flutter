// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:SkyNet/provider/language_provider.dart';
import 'package:SkyNet/screens/auth/login_screen.dart';
import 'package:SkyNet/screens/auth/register_screen.dart';
import 'package:SkyNet/screens/edit_profile_screen.dart';
import 'package:SkyNet/screens/home_screen.dart';
import 'package:SkyNet/screens/details_screen.dart';
import 'package:SkyNet/screens/editar_screen.dart';
import 'package:SkyNet/screens/borrar_screen.dart';
import 'package:SkyNet/screens/imprimir_screen.dart';
import 'package:SkyNet/screens/perfil_screen.dart';
import 'package:SkyNet/screens/jocs_page.dart';
import 'package:SkyNet/screens/waiting_room_page.dart';
import 'package:SkyNet/screens/drone_control_page.dart';
import 'package:SkyNet/screens/mapa_screen.dart';
import 'package:SkyNet/screens/chat_list_screen.dart';
import 'package:SkyNet/screens/chat_screen.dart';
import 'package:SkyNet/services/auth_service.dart';
import 'package:SkyNet/screens/search_user_screen.dart';

// Widget para asegurar que el idioma se cargue apropiadamente
class LanguageAwareRouter extends StatelessWidget {
  final Widget child;
  
  const LanguageAwareRouter({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Accedemos al LanguageProvider con listen: true para que el widget se reconstruya cuando cambie el idioma
    final languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    
    // Si el provider aún no está inicializado, mostramos un indicador de carga
    if (!languageProvider.isInitialized) {
      return Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return child;
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AuthService().isLoggedIn ? '/' : '/login',
  
  // Usamos redirect para manejar la redirección basada en inicio de sesión
  redirect: (BuildContext context, GoRouterState state) {
    // No es necesario realizar cambios adicionales aquí por ahora
    return null;
  },
  
  // Definimos la envoltura para que cada ruta acceda al LanguageProvider
  observers: [
    // Observer para asegurar que el idioma se aplique en cambios de ruta
  ],
  
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) {
        // Envolvemos cada página en LanguageAwareRouter
        return MaterialPage(
          key: state.pageKey,
          child: LanguageAwareRouter(
            child: LoginPage(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: LanguageAwareRouter(
            child: const RegisterPage(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/',
      name: 'home',
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: LanguageAwareRouter(
            child: const HomeScreen(),
          ),
        );
      },
      routes: [
        GoRoute(
          path: 'details',
          name: 'details',
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: LanguageAwareRouter(
                child: const DetailsScreen(),
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'imprimir',
              name: 'imprimir',
              pageBuilder: (context, state) {
                return MaterialPage(
                  key: state.pageKey,
                  child: LanguageAwareRouter(
                    child: const ImprimirScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'editar',
          name: 'editar',
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: LanguageAwareRouter(
                child: const EditarScreen(),
              ),
            );
          },
        ),
        GoRoute(
          path: 'borrar',
          name: 'borrar',
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: LanguageAwareRouter(
                child: const BorrarScreen(),
              ),
            );
          },
        ),
        GoRoute(
          path: 'profile',
          name: 'profile',
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: LanguageAwareRouter(
                child: const PerfilScreen(),
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'editProfile',
              pageBuilder: (context, state) {
                return MaterialPage(
                  key: state.pageKey,
                  child: LanguageAwareRouter(
                    child: const EditProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),

        // ----------------- JOCS -----------------
        GoRoute(
          path: 'jocs',
          name: 'jocs',
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: LanguageAwareRouter(
                child: const JocsPage(),
              ),
            );
          },
          routes: [
            // Al pulsar "Competencia" va directamente a la sala de espera
            GoRoute(
              path: 'open',
              name: 'jocsOpen',
              pageBuilder: (context, state) {
                return MaterialPage(
                  key: state.pageKey,
                  child: LanguageAwareRouter(
                    child: const WaitingRoomPage(),
                  ),
                );
              },
            ),
            // Al recibir 'game_started' navega a /jocs/control
            GoRoute(
              path: 'control',
              name: 'jocsControl',
              pageBuilder: (context, state) {
                return MaterialPage(
                  key: state.pageKey,
                  child: LanguageAwareRouter(
                    child: const DroneControlPage(),
                  ),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'mapa',
          name: 'mapa',
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: LanguageAwareRouter(
                child: const MapaScreen(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/chat',
          name: 'chatList',
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              child: LanguageAwareRouter(
                child: const ChatListScreen(),
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'search',
              name: 'chatSearch',
              pageBuilder: (context, state) {
                return MaterialPage(
                  key: state.pageKey,
                  child: LanguageAwareRouter(
                    child: const SearchUserScreen(),
                  ),
                );
              },
            ),
            GoRoute(
              path: ':userId',
              name: 'chatConversation',
              pageBuilder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return MaterialPage(
                  key: state.pageKey,
                  child: LanguageAwareRouter(
                    child: ChatScreen(userId: userId),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
