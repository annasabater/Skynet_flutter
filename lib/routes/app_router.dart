import 'package:go_router/go_router.dart';

/* ──────────── Auth ──────────── */
import 'package:SkyNet/screens/auth/login_screen.dart';
import 'package:SkyNet/screens/auth/register_screen.dart';

/* ──────────── Perfil & social ──────────── */
import 'package:SkyNet/screens/perfil_screen.dart';
import 'package:SkyNet/screens/social/create_post_screen.dart';
import 'package:SkyNet/screens/social/post_detail_screen.dart';
import 'package:SkyNet/screens/social/user_profile_screen.dart';
import 'package:SkyNet/screens/social/edit_post_screen.dart';
import 'package:SkyNet/screens/edit_profile_screen.dart';

/* ──────────── Nueva pantalla Xarxes Socials ──────────── */
import 'package:SkyNet/screens/social/xarxes_socials_screen.dart';  // ← NUEVO

/* ──────────── Otras pantallas ──────────── */
import 'package:SkyNet/screens/home_screen.dart';
import 'package:SkyNet/screens/details_screen.dart';
import 'package:SkyNet/screens/editar_screen.dart';
import 'package:SkyNet/screens/borrar_screen.dart';
import 'package:SkyNet/screens/imprimir_screen.dart';
import 'package:SkyNet/screens/jocs_page.dart';
import 'package:SkyNet/screens/waiting_room_page.dart';
import 'package:SkyNet/screens/drone_control_page.dart';
import 'package:SkyNet/screens/mapa_screen.dart';
import 'package:SkyNet/screens/google_mapa_screen.dart'; // Nueva pantalla de mapa
import 'package:SkyNet/screens/chat_list_screen.dart';
import 'package:SkyNet/screens/chat_screen.dart';
import 'package:SkyNet/screens/search_user_screen.dart';
import 'package:SkyNet/screens/store/drone_store_screen.dart';
import 'package:SkyNet/screens/store/drone_detail_screen.dart';
import 'package:SkyNet/screens/store/add_drone_screen.dart';

import 'package:SkyNet/services/auth_service.dart';
import 'package:SkyNet/models/drone.dart';
import 'package:SkyNet/models/post.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AuthService().isLoggedIn ? '/xarxes' : '/login',
  routes: [
    /* ───────── Login & Register ───────── */
    GoRoute(path: '/login', builder: (_, __) => LoginPage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

    /* ──────────── Xarxes Socials (nueva pantalla inicial) ──────────── */
    GoRoute(
      path: '/xarxes',
      builder: (_, __) => const XarxesSocialsScreen(),
    ),

    /* ───────── Home (shell) ───────── */
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
      routes: [
        /* ========== SOCIAL ========== */
        GoRoute(path: 'create', builder: (_, __) => const CreatePostScreen()),
        GoRoute(
          path: 'posts/:pid',
          builder: (ctx, st) => PostDetailScreen(postId: st.pathParameters['pid']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (ctx, st) => EditPostScreen(post: st.extra! as Post),
            ),
          ],
        ),
        GoRoute(
          path: 'u/:uid',
          builder: (ctx, st) => UserProfileScreen(userId: st.pathParameters['uid']!),
        ),

        /* Perfil propio */
        GoRoute(
          path: 'profile',
          builder: (_, __) => const PerfilScreen(),
          routes: [
            GoRoute(path: 'edit', builder: (_, __) => const EditProfileScreen()),
          ],
        ),

        /* ========== RESTO DE RUTAS ========== */
        GoRoute(
          path: 'details',
          builder: (_, __) => const DetailsScreen(),
          routes: [
            GoRoute(path: 'imprimir', builder: (_, __) => const ImprimirScreen()),
          ],
        ),
        GoRoute(path: 'editar', builder: (_, __) => const EditarScreen()),
        GoRoute(path: 'borrar', builder: (_, __) => const BorrarScreen()),
        GoRoute(
          path: 'jocs',
          builder: (_, __) => const JocsPage(),
          routes: [
            GoRoute(
              path: 'open/:sessionId',
              builder: (ctx, st) => WaitingRoomPage(sessionId: st.pathParameters['sessionId']!),
            ),
            GoRoute(
              path: 'control/:sessionId',
              builder: (ctx, st) => DroneControlPage(sessionId: st.pathParameters['sessionId']!),
            ),
          ],
        ),
        // Reemplazamos la ruta del mapa con Google Maps por la original
        GoRoute(path: 'mapa', builder: (_, __) => const MapaScreen()),
        GoRoute(
          path: 'store',
          builder: (_, __) => const DroneStoreScreen(),
          routes: [
            GoRoute(path: 'add', builder: (_, __) => const AddDroneScreen()),
            GoRoute(
              path: 'dron/:id',
              builder: (ctx, st) => DroneDetailScreen(drone: st.extra! as Drone),
            ),
          ],
        ),
        GoRoute(
          path: 'chat',
          builder: (_, __) => const ChatListScreen(),
          routes: [
            GoRoute(path: 'search', builder: (_, __) => const SearchUserScreen()),
            GoRoute(
              path: ':userId',
              builder: (ctx, st) => ChatScreen(userId: st.pathParameters['userId']!),
            ),
          ],
        ),
      ],
    ),
  ],
);
