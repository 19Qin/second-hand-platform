import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/features/auth/presentation/pages/cover_page.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/language_manager.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _currentLocale = const Locale('en', 'US');

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLocale = await LanguageManager().getSavedLanguage();
    setState(() {
      _currentLocale = savedLocale;
    });
  }

  void _changeLanguage(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
    LanguageManager().setLanguage(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fliliy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF32C286)),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _currentLocale,
      home: CoverPage(onLanguageChanged: _changeLanguage),
    );
  }
}