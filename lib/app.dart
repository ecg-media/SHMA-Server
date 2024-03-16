import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shma_server/lib_color_schemes.g.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';
import 'package:shma_server/services/messenger.dart';
import 'package:shma_server/services/router.dart';

/// Scroll behaviour overrides default behaviour, so drag scrolls can be made by mouse on windows system.
class WekodeScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class App extends StatelessWidget {
  /// Initializes the instance.
  const App({Key? key}) : super(key: key);

  /// Creates the app with the necessary configurations.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.appTitle,

      // Specify key for the snackbar at the bottom of the app.
      scaffoldMessengerKey: MessengerService.getInstance().snackbarKey,

      scrollBehavior: WekodeScrollBehavior(),

      // Configure theme data.
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,

      // Configure the main navigator of the app.
      navigatorKey: RouterService.getInstance().navigatorKey,
      initialRoute: RouterService.getInstance().initialRoute,
      routes: RouterService.getInstance().routes,

      // Configure the localizations of the app.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('de', ''),
        Locale('ru', ''),
      ],
    );
  }
}
