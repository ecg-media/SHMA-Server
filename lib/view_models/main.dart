import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shma_server/components/delete_dialog.dart';
import 'package:shma_server/models/channel_config.dart';
import 'package:shma_server/services/db.dart';
import 'package:shma_server/services/socket.dart';
import 'package:shma_server/views/settings_connection.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';
import 'package:shma_server/views/channel_config_edit.dart';

class MainViewModel extends ChangeNotifier {
  /// Route of the main screen.
  static String route = '/';

  late BuildContext _context;

  /// Locales of the application.
  late AppLocalizations locales;

  final SocketService _server = SocketService.getInstance();
  final DBService _dbService = DBService.getInstance();

  /// Initializes the view model.
  Future<bool> init(BuildContext context) async {
    _context = context;
    locales = AppLocalizations.of(_context)!;

    return Future<bool>.microtask(() async {
      if (!(await _server.startedSuccessfully())) {
        manageConfiguration();
      }
      return true;
    });
  }

  /// Adds new item to list.
  Future<bool> add() async {
    return await showDialog(
      barrierDismissible: false,
      context: _context,
      builder: (BuildContext context) {
        return const ChannelScreen(channelId: null);
      },
    );
  }

  /// Edits one item in list.
  Future<bool> edit(ChannelConfig item) async {
    if (_server.isStreaming(item)) {
      return false;
    }

    return await showDialog(
      barrierDismissible: false,
      context: _context,
      builder: (BuildContext context) {
        return ChannelScreen(channelId: item.id);
      },
    );
  }

  /// Loads items from persistence.
  Future<List<ChannelConfig>> load() async {
    var channels = await _dbService.loadChannels();
    for (var channel in channels) {
      if (!_server.isStreaming(channel)) {
        continue;
      }

      channel.isStreaming = true;
      channel.activeClients = _server.activeClients(channel);
    }
    return channels;
  }

  /// Opens connection configuration.
  Future<void> manageConfiguration() async {
    final success = await showDialog(
      barrierDismissible: false,
      context: _context,
      builder: (BuildContext context) {
        return const SettingsConnectionScreen();
      },
    );

    if (success) {
      await _server.stopRunningStreams();
      var config = await _dbService.loadConfig();
      _server.restart(config.port!);
    }
  }

  /// Removes items from persistence.
  Future<bool> delete(List itemIdentifiers) async {
    final success = await showDeleteDialog(_context);
    if (!success) {
      return false;
    }

    var channels = List.generate(
      itemIdentifiers.length,
      (index) => (itemIdentifiers[index] as ChannelConfig),
    );

    await _server.stopRunningStreams(channels: channels);
    await _dbService.deleteChannels(
      List.generate(
        itemIdentifiers.length,
        (index) => (channels[index]).id!,
      ),
    );
    return true;
  }

  Future<bool> changeStreamState(ChannelConfig item) async {
    item.isStreaming = !item.isStreaming;

    if (item.isStreaming) {
      await _server.startStreaming(
        item,
        (activeClientsNum) {
          item.activeClients = activeClientsNum;
          notifyListeners();
        },
        () {
          item.isStreaming = false;
          _server.stopStreaming(item);
          item.activeClients = 0;
          notifyListeners();
        },
      );
    } else {
      await _server.stopStreaming(item);
      item.activeClients = 0;
    }
    notifyListeners();
    return true;
  }
}
