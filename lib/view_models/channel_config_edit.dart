import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:record_platform_interface/src/types/input_device.dart';
import 'package:shma_server/components/progress_indicator.dart';
import 'package:shma_server/models/channel_config.dart';
import 'package:shma_server/services/db.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';
import 'package:shma_server/services/router.dart';

class ChannelViewModel extends ChangeNotifier {
  /// Current build context.
  late BuildContext _context;

  /// Key of the user edit form.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final DBService _dbService = DBService.getInstance();

  /// Locales of the application.
  late AppLocalizations locales;

  late ChannelConfig channel = ChannelConfig();

  final recorder = AudioRecorder();
  List<InputDevice> inputSources = List.empty(growable: true);

  bool loaded = false;

  /// Initialize the registration client view model.
  Future<bool> init(BuildContext context, int? channelId) async {
    return Future<bool>.microtask(() async {
      _context = context;
      locales = AppLocalizations.of(_context)!;
      try {
        if (channelId != null) {
          channel = await _dbService.loadChannel(channelId);
        }
        // TODO Windows only solution. For other os need to setup different steps:
        // see: https://pub.dev/packages/record
        // see: https://pub.dev/packages/permission_handler
        await Permission.microphone.request();
        if (await Permission.microphone.isGranted) {
          inputSources = await recorder.listInputDevices();
        }
        loaded = true;
        notifyListeners();
      } catch (e) {
        // Catch all errors and do nothing, since handled by api service!
      }
      return true;
    });
  }

  String? validateTitle(String? value) {
    return value != null && value.isNotEmpty ? null : locales.required;
  }

  String? validatePort(String? port) {
    var p = int.tryParse(port ?? '');
    return p != null && p > 0 && p < 65535
        ? null
        : locales.connectionInvalidPort;
  }

  void selectInputSource(InputDevice? value) {
    channel.inputSource = value?.id;
    notifyListeners();
  }

  InputDevice? inputDevice() {
    return inputSources
        .where((element) => element.id == channel.inputSource)
        .firstOrNull;
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

    if (channel.id == null) {
      await _dbService.createChannel(channel);
    } else {
      await _dbService.updateChannel(channel);
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
