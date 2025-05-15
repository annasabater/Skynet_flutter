//lib/widgets/language_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../provider/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usamos listen: true para garantizar que el widget se actualice cuando cambia el idioma
    final languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    final localizations = AppLocalizations.of(context)!;

    // Si el proveedor aún no está inicializado, mostramos un indicador de carga
    if (!languageProvider.isInitialized) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    // Obtenemos el código de idioma actual
    final currentLang = languageProvider.currentLocale.languageCode;

    return PopupMenuButton<String>(
      tooltip: localizations.language,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language),
          const SizedBox(width: 4),
          Text(
            currentLang.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onSelected: (String value) {
        // Al seleccionar un idioma, lo cambiamos en el provider
        languageProvider.setLanguage(value);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              // Mostramos un check para el idioma seleccionado
              if (currentLang == 'en')
                const Icon(Icons.check, color: Colors.green)
              else
                const SizedBox(width: 24),
              const SizedBox(width: 8),
              Text(localizations.english),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'es',
          child: Row(
            children: [
              if (currentLang == 'es')
                const Icon(Icons.check, color: Colors.green)
              else
                const SizedBox(width: 24),
              const SizedBox(width: 8),
              Text(localizations.spanish),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'ca',
          child: Row(
            children: [
              if (currentLang == 'ca')
                const Icon(Icons.check, color: Colors.green)
              else
                const SizedBox(width: 24),
              const SizedBox(width: 8),
              Text(localizations.catalan),
            ],
          ),
        ),
      ],
    );
  }
} 