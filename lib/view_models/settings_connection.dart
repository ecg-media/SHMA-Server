import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shma_server/components/progress_indicator.dart';
import 'package:shma_server/models/connection.dart';
import 'package:shma_server/models/network_ips.dart';
import 'package:shma_server/services/db.dart';
import 'package:shma_server/services/router.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';
import 'package:string_validator/string_validator.dart';

class SettingsConnectionViewModel extends ChangeNotifier {
  /// Current build context.
  late BuildContext _context;

  /// Key of the user edit form.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final DBService _dbService = DBService.getInstance();

  /// Locales of the application.
  late AppLocalizations locales;

  late Connection connection = Connection();

  bool loaded = false;

  List<NetworkIps> networks = List.empty(growable: true);

  /// Initialize the registration client view model.
  Future<bool> init(BuildContext context) async {
    return Future<bool>.microtask(() async {
      _context = context;
      locales = AppLocalizations.of(_context)!;
      try {
        connection = await _dbService.loadConfig();
        var netInterfaces = await NetworkInterface.list();
        for (var element in netInterfaces) {
          networks.add(
            NetworkIps(
              name: element.name,
              ip: element.addresses.first.address,
            ),
          );
        }
        loaded = true;
        notifyListeners();
      } catch (e) {
        // Catch all errors and do nothing, since handled by api service!
      }
      return true;
    });
  }

  String? validateHost(String? host) {
    return host != null && host.isNotEmpty && (isIP(host) || isFQDN(host))
        ? null
        : locales.connectionInvalidHost;
  }

  String? validatePort(String? port) {
    var p = int.tryParse(port ?? '');
    return p != null && p > 0 && p < 65535
        ? null
        : locales.connectionInvalidPort;
  }

  void updateMode(ConnectionMode mode) {
    connection.mode = mode;
    update();
  }

  void selectIP(NetworkIps netIp) {
    connection.host = netIp.ip;
    update();
  }

  void update() {
    notifyListeners();
  }

  Future<void> save() async {
    var nav = Navigator.of(_context);
    showProgressIndicator();

    if (!formKey.currentState!.validate()) {
      RouterService.getInstance().navigatorKey.currentState!.pop();
      return;
    }

    formKey.currentState!.save();

    var shouldClose = false;

    if (connection.id == null) {
      await _dbService.createConfig(connection);
    } else {
      await _dbService.updateConfig(connection);
    }
    shouldClose = true;

    RouterService.getInstance().navigatorKey.currentState!.pop();

    if (shouldClose) {
      nav.pop(true);
    }
  }

  /// Closes the view.
  void abort() async {
    var nav = Navigator.of(_context);
    showProgressIndicator();
    RouterService.getInstance().navigatorKey.currentState!.pop();
    nav.pop(false);
  }
}
