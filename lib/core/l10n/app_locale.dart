import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Locale fixo em espanhol do México: o produto é lançado só no México e
/// todos os textos do app já estão em es-MX. Os delegates globais cobrem
/// os widgets do Material (date picker, tooltips, etc.).
///
/// Compartilhado por `main.dart` e `main_demo.dart` (o demo não pode
/// importar `main.dart`, que depende do `firebase_options.dart` gerado).
const Locale appLocale = Locale('es', 'MX');

const List<Locale> appSupportedLocales = [appLocale, Locale('es')];

const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
