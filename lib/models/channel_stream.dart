import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

class ChannelStream {
  ServerSocket? _server;
  final AudioRecorder _rec = AudioRecorder();
  Stream<Uint8List>? _stream;
  final List<Socket> _clientSockets = List.empty(growable: true);
  final Map<Socket, StreamSubscription<Uint8List>> _streamSubscriptions = {};

  int get activeClients => _clientSockets.length;

  Future<Stream<Uint8List>> stream(String? deviceId) async {
    if (_stream == null) {
      var devices = await _rec.listInputDevices();
      _stream = await _rec.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          numChannels: 1,
          device: devices.where((d) => d.id == deviceId).firstOrNull,
        ),
      );
    }
    return Future.value(_stream);
  }

  void addServer(ServerSocket server) {
    _server = server;
  }

  Future<void> dispose() async {
    final cSockets = List.from(_clientSockets);
    for (var socket in cSockets) {
      socket.destroy();
      await _removeSubscription(socket);
    }
    _clientSockets.clear();
    if (_server != null) {
      await _server?.close();
      _server = null;
    }
    await _rec.stop();
    _rec.dispose();
  }

  Future<void> removeClient(Socket client) async {
    await _removeSubscription(client);
    _clientSockets.remove(client);
  }

  Future<void> _removeSubscription(Socket client) async {
    await _streamSubscriptions[client]?.cancel();
    _streamSubscriptions.remove(client);
  }

  bool contains(Socket client) {
    return _clientSockets.contains(client);
  }

  void addClient(Socket client) {
    _clientSockets.add(client);
  }

  Future<void> addSubscription(
    Socket client,
    StreamSubscription<Uint8List> streamSubscription,
  ) async {
    if (_streamSubscriptions.containsKey(client)) {
      await _streamSubscriptions[client]?.cancel();
    }

    _streamSubscriptions[client] = streamSubscription;
  }
}
