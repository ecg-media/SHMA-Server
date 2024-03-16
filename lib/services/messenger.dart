import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';

/// Service that shows messages in the snackbar of the app.
class MessengerService {
  /// Instance of the messenger service.
  static final MessengerService _instance = MessengerService._();

  /// Global key to access the state of the snackbar.
  final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey();

  /// Private constructor of the service.
  MessengerService._();

  /// Returns the singleton instance of the [MessengerService].
  static MessengerService getInstance() {
    return _instance;
  }

  /// Shows the given [text] in the app snackbar.
  showMessage(String text) {
    final SnackBar snackBar = SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 5),
    );
    snackbarKey.currentState?.showSnackBar(snackBar);
  }

  /// Translated string for a message if a record is not found.
  String get errorStartStream {
    return AppLocalizations.of(snackbarKey.currentContext!)!.errorStartStream;
  }

  String get errorStartServer {
    return AppLocalizations.of(snackbarKey.currentContext!)!.errorStartServer;
  }
}
