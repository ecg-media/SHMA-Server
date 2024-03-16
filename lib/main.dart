import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shma_server/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isAndroid && !Platform.isIOS) {
    await windowManager.ensureInitialized();
    await findSystemLocale();

    var systemLocale = Locale(Intl.systemLocale);
    var locale = AppLocalizations.delegate.isSupported(systemLocale)
        ? systemLocale
        : AppLocalizations.supportedLocales.first;

    var appLocales = await AppLocalizations.delegate.load(locale);

    WindowOptions windowOptions = WindowOptions(
      size: const Size(1600, 900),
      minimumSize: const Size(480, 360),
      center: true,
      title: appLocales.appTitle,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // TODO for release needs to do some additional steps. Ither plattforms needs some updates.
  // see: https://pub.dev/packages/sqflite_common_ffi
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize FFI
    sqfliteFfiInit();
  }

  // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
  // this step, it will use the sqlite version available on the system.
  databaseFactory = databaseFactoryFfi;
  runApp(const App());
}
