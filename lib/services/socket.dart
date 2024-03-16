import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shma_server/models/channel_config.dart';
import 'package:shma_server/models/channel_stream.dart';
import 'package:shma_server/services/db.dart';
import 'package:shma_server/services/messenger.dart';
import 'package:string_validator/string_validator.dart';

/// Service that holds all routing information of the navigators of the app.
class SocketService {
  /// Instance of the Socket service.
  static final SocketService _instance = SocketService._();

  /// GlobalKey of the state of the main navigator.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  /// Private constructor of the service.
  SocketService._();

  /// Returns the singleton instance of the [SocketService].
  static SocketService getInstance() {
    return _instance;
  }

  final String _socketMessageLoadChannels = 'de.wekode.shma.channels';

  ServerSocket? _server;
  bool _running = false;
  final List<Socket> _sockets = [];

  final DBService _dbService = DBService.getInstance();

  final Map<ChannelConfig, ChannelStream> _streams = {};

  Future<bool> startedSuccessfully() async {
    // check if configuration is available
    var configuration = await _dbService.loadConfig();
    if (!configuration.isValid) {
      return false;
    }

    // check if ip in config is available
    var ips = await NetworkInterface.list();
    if (isIP(configuration.host!) &&
        !ips.any((element) => element.addresses
            .any((adr) => adr.address == configuration.host))) {
      return false;
    }

    start(configuration.port!);

    return true;
  }

  Future<void> start(int port) async {
    if (_running) {
      return;
    }
    runZonedGuarded(() async {
      _server = await ServerSocket.bind('0.0.0.0', port);
      _running = true;
      _server!.listen((client) {
        onRequest(client);
      });
    }, (e, stackTrace) {
      if (kDebugMode) print(stackTrace);
      MessengerService.getInstance().showMessage(
        MessengerService.getInstance().errorStartServer,
      );
    });
  }

  Future<void> stop() async {
    for (var socket in _sockets) {
      socket.destroy();
    }
    _sockets.clear();
    await _server?.close();
    _server = null;
    _running = false;
  }

  Future<void> restart(int port) async {
    await stop();
    await start(port);
  }

  onRequest(Socket client) {
    if (!_sockets.contains(client)) {
      _sockets.add(client);
      if (kDebugMode) print('Client connected. Remaining: ${_sockets.length}');
    }
    client.listen(
      (Uint8List data) async {
        final message = String.fromCharCodes(data);
        if (message == _socketMessageLoadChannels) {
          if (kDebugMode) print('Received reload message');
          var channels = await _dbService.loadChannelsOnly();
          final msg = jsonEncode(channels);
          if (kDebugMode) print('Send message: $msg');
          client.write(msg);
        }
      },
      onError: (error) {
        if (kDebugMode) print(error);
        _sockets.remove(client);
        client.close();
      },
      onDone: () {
        _sockets.remove(client);
        client.close();
        if (kDebugMode) print('Client left. Remaining: ${_sockets.length}');
      },
    );
  }

  Future<void> startStreaming(
    ChannelConfig channel,
    ValueSetter<int> onSocketNumberChanged,
    VoidCallback onError,
  ) async {
    if (isStreaming(channel)) {
      return;
    }
    runZonedGuarded(() async {
      var channelServer = await ServerSocket.bind('0.0.0.0', channel.port!);
      _streams[channel] = ChannelStream();
      _streams[channel]?.addServer(channelServer);
      channelServer.listen((client) {
        streamToClient(channel, client, onSocketNumberChanged);
      });
    }, (e, stackTrace) {
      if (kDebugMode) print(stackTrace);
      MessengerService.getInstance().showMessage(
        MessengerService.getInstance().errorStartStream,
      );
      onError();
    });
  }

  Future<void> stopStreaming(ChannelConfig channel) async {
    var clientSocket = _getActiveSockets(channel);
    if (clientSocket != null) {
      clientSocket.value.dispose();
      _streams.remove(clientSocket.key);
    }
  }

  Future<void> stopRunningStreams({List<ChannelConfig>? channels}) async {
    var toStop = (channels ?? List.from(_streams.keys));
    for (var channel in toStop) {
      await stopStreaming(channel);
    }
  }

  bool isStreaming(ChannelConfig item) {
    return _streams.keys.any((elem) => elem.id == item.id);
  }

  int activeClients(ChannelConfig channel) {
    var clientSockets = _getActiveSockets(channel);
    if (clientSockets == null) {
      return 0;
    }
    return clientSockets.value.activeClients;
  }

  streamToClient(
    ChannelConfig channel,
    Socket client,
    ValueSetter<int> onSocketNumberChanged,
  ) async {
    var channelStream = _streams[channel]!;
    if (!channelStream.contains(client)) {
      channelStream.addClient(client);
      onSocketNumberChanged(channelStream.activeClients);
      if (kDebugMode) {
        print(
          'Client connected to channel ${channel.id}. Remaining: ${channelStream.activeClients}',
        );
      }
    }

    await channelStream.addSubscription(
      client,
      (await channelStream.stream(channel.inputSource)).listen(
        (event) {
          if (kDebugMode) print(event);
          client.add(event);
        },
      ),
    );

    client.listen(
      (Uint8List data) {},
      onError: (error) async {
        if (kDebugMode) print(error);
        await _cancelStream(channel, client, onSocketNumberChanged);
      },
      onDone: () async {
        await _cancelStream(channel, client, onSocketNumberChanged);
        if (kDebugMode) {
          print(
            'Client left channel ${channel.id}. Remaining: ${_streams[channel]?.activeClients}',
          );
        }
      },
    );
  }

  Future<void> _cancelStream(
    ChannelConfig channel,
    Socket client,
    ValueSetter<int> onSocketNumberChanged,
  ) async {
    var channelStream = _streams[channel];
    await channelStream?.removeClient(client);
    client.close();
    onSocketNumberChanged(channelStream?.activeClients ?? 0);
  }

  MapEntry<ChannelConfig, ChannelStream>? _getActiveSockets(
    ChannelConfig channel,
  ) {
    return _streams.entries
        .where(
          (elem) => elem.key.id == channel.id,
        )
        .firstOrNull;
  }
}
