// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:SkyNet/models/user.dart';          
import 'package:SkyNet/provider/users_provider.dart';
import 'package:SkyNet/provider/theme_provider.dart';
import 'package:SkyNet/provider/language_provider.dart';
import 'package:SkyNet/routes/app_router.dart';
import 'package:SkyNet/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Aseguramos que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Precargamos SharedPreferences para uso posterior
  await SharedPreferences.getInstance();
  
  // Inicializamos y precargamos el LanguageProvider antes de ejecutar la app
  final languageProvider = LanguageProvider();
  // Esperamos hasta que el provider esté inicializado o por un máximo de 2 segundos
  await Future.wait([
    Future.doWhile(() async {
      if (languageProvider.isInitialized) return false;
      await Future.delayed(const Duration(milliseconds: 50));
      return true;
    }).timeout(const Duration(seconds: 2), onTimeout: () => false),
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF81D4FA),
      brightness: Brightness.light,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Usamos LanguageProvider.instance para asegurar que usamos la misma instancia
        ChangeNotifierProvider.value(value: LanguageProvider()),

        // Injecta l'usuari desat (si existeix) al provider en arrencar
        ProxyProvider<UserProvider, void>(
          update: (_, prov, __) {
            final raw = AuthService().currentUser; 
            if (raw != null) prov.setCurrentUser(User.fromJson(raw));
          },
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          // Si el proveedor de idioma aún no está inicializado, mostrar indicador de carga
          if (!languageProvider.isInitialized) {
            return MaterialApp(
              title: 'S K Y N E T',
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
          
          return MaterialApp.router(
            title: 'S K Y N E T',
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('es'), // Spanish
              Locale('ca'), // Catalan
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightScheme,
              scaffoldBackgroundColor: lightScheme.background,
              appBarTheme: AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: lightScheme.primary,
                foregroundColor: lightScheme.onPrimary,
              ),
              drawerTheme: DrawerThemeData(backgroundColor: lightScheme.surface),
              cardTheme: CardTheme(
                color: lightScheme.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightScheme.primary,
                  foregroundColor: lightScheme.onPrimary,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: lightScheme.primaryContainer),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: lightScheme.primaryContainer),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: lightScheme.primary),
                ),
                filled: true,
                fillColor: lightScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF263238),
                brightness: Brightness.dark,
              ),
            ),
          );
        },
      ),
    );
  }
}
