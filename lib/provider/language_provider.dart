import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  
  SharedPreferences? _prefs;
  Locale _currentLocale = const Locale('en');
  bool _initialized = false;
  
  // Patrón singleton para asegurar una única instancia en toda la app
  static final LanguageProvider _instance = LanguageProvider._internal();
  
  factory LanguageProvider() {
    return _instance;
  }
  
  LanguageProvider._internal() {
    _initializePrefs();
  }

  bool get isInitialized => _initialized;
  Locale get currentLocale => _currentLocale;

  // Inicialización asíncrona con manejo de errores
  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final String? languageCode = _prefs?.getString(_languageKey);
      
      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
      }
      
      _initialized = true;
      notifyListeners();
    } catch (e) {
      // En caso de error, al menos asegurar que la app funcione
      _initialized = true;
      notifyListeners();
      debugPrint('Error initializing language preferences: $e');
    }
  }

  // Método para cambiar el idioma
  Future<void> setLanguage(String languageCode) async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      
      _currentLocale = Locale(languageCode);
      await _prefs?.setString(_languageKey, languageCode);
      
      // Notificar a todos los listeners inmediatamente para actualizar UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }
  
  // Método para forzar una recarga del idioma (útil para resolver problemas)
  Future<void> refreshLanguage() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      
      final String? languageCode = _prefs?.getString(_languageKey);
      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing language: $e');
    }
  }
} 