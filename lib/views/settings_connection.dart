import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shma_server/components/vertical_spacer.dart';
import 'package:shma_server/models/connection.dart';
import 'package:shma_server/models/network_ips.dart';
import 'package:shma_server/view_models/settings_connection.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';

class SettingsConnectionScreen extends StatelessWidget {
  /// Initializes the instance.
  const SettingsConnectionScreen({Key? key}) : super(key: key);

  /// Builds the clients overview screen.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsConnectionViewModel>(
      create: (context) => SettingsConnectionViewModel(),
      builder: (context, _) {
        var vm =
            Provider.of<SettingsConnectionViewModel>(context, listen: false);
        var locales = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(locales.connectionConfig),
          content: FutureBuilder(
            future: vm.init(context),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (!snapshot.hasData) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                  ],
                );
              }

              return snapshot.data!
                  ? Form(
                      key: vm.formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(locales.connectionIncorrect),
                            Consumer<SettingsConnectionViewModel>(
                              builder: (context, vm, child) {
                                return vm.connection.isValid
                                    ? BarcodeWidget(
                                        padding: const EdgeInsets.all(15),
                                        barcode: Barcode.qrCode(),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        height: 256,
                                        width: 256,
                                        data:
                                            jsonEncode(vm.connection.toJson()),
                                        errorBuilder: (context, error) =>
                                            Center(
                                          child: Text(error),
                                        ),
                                      )
                                    : const SizedBox(
                                        height: 256,
                                        width: 256,
                                      );
                              },
                            ),
                            ListTile(
                              title: Text(
                                locales.connectionMode,
                              ),
                            ),
                            Consumer<SettingsConnectionViewModel>(
                              builder: (context, vm, child) {
                                return ListTile(
                                  title: Text(
                                    locales.connectionLAN,
                                  ),
                                  leading: Radio<ConnectionMode>(
                                    value: ConnectionMode.lan,
                                    groupValue: vm.connection.mode,
                                    onChanged: (value) => vm.updateMode(value!),
                                  ),
                                );
                              },
                            ),
                            Consumer<SettingsConnectionViewModel>(
                              builder: (context, vm, child) {
                                return ListTile(
                                  title: Text(
                                    locales.connectionHotspot,
                                  ),
                                  leading: Radio<ConnectionMode>(
                                    value: ConnectionMode.hotspot,
                                    groupValue: vm.connection.mode,
                                    onChanged: (value) => vm.updateMode(value!),
                                  ),
                                );
                              },
                            ),
                            Consumer<SettingsConnectionViewModel>(
                              builder: (context, vm, child) {
                                return TextFormField(
                                  controller: TextEditingController()
                                    ..text = vm.connection.host ?? '',
                                  decoration: InputDecoration(
                                    labelText: locales.connectionHost,
                                    helperText: locales.connectionHostInfo,
                                    errorMaxLines: 5,
                                  ),
                                  onSaved: (String? txt) {
                                    vm.connection.host = txt;
                                  },
                                  onChanged: (String? txt) {
                                    vm.connection.host = txt;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: vm.validateHost,
                                );
                              },
                            ),
                            Consumer<SettingsConnectionViewModel>(
                              builder: (context, vm, child) {
                                return DropdownButton<NetworkIps>(
                                  isExpanded: true,
                                  hint: Text(locales.selectNetworkInterface),
                                  items: vm.networks
                                      .map<DropdownMenuItem<NetworkIps>>(
                                          (NetworkIps value) {
                                    return DropdownMenuItem<NetworkIps>(
                                      value: value,
                                      child: Text(value.name),
                                    );
                                  }).toList(),
                                  onChanged: (netIP) => vm.selectIP(netIP!),
                                );
                              },
                            ),
                            verticalSpacer,
                            TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              initialValue: "${vm.connection.port}",
                              decoration: InputDecoration(
                                labelText: locales.connectionPort,
                                helperText: locales.connectionPortInfo,
                                errorMaxLines: 5,
                              ),
                              onSaved: (String? txt) {
                                vm.connection.port = int.tryParse(txt ?? '');
                              },
                              onChanged: (String? txt) {
                                vm.connection.port = int.tryParse(txt ?? '');
                                vm.update();
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: vm.validatePort,
                            ),
                            verticalSpacer,
                            verticalSpacer,
                            Consumer<SettingsConnectionViewModel>(
                              builder: (context, vm, child) {
                                return Text(
                                  vm.connection.mode == ConnectionMode.lan
                                      ? locales.connectionLANInfo
                                      : locales.connectionHotspotInfo,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textScaler: const TextScaler.linear(0.8),
                                  softWrap: true,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container();
            },
          ),
          actions: _createActions(context, vm),
        );
      },
    );
  }

  /// Creates a list of action widgets that should be shown at the bottom of the
  /// edit dialog.
  List<Widget> _createActions(
    BuildContext context,
    SettingsConnectionViewModel vm,
  ) {
    var locales = AppLocalizations.of(context)!;

    return [
      Consumer<SettingsConnectionViewModel>(
        builder: (context, vm, child) {
          return TextButton(
            onPressed: vm.loaded && vm.connection.isValid ? vm.abort : null,
            child: Text(locales.cancel),
          );
        },
      ),
      TextButton(
        onPressed: vm.save,
        child: Text(locales.save),
      ),
    ];
  }
}
