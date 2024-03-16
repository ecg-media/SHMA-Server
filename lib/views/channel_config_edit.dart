import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';
import 'package:record/record.dart';
import 'package:shma_server/components/vertical_spacer.dart';
import 'package:shma_server/view_models/channel_config_edit.dart';

class ChannelScreen extends StatelessWidget {
  /// Id of the record to be edited.
  final int? channelId;

  /// Initializes the instance.
  const ChannelScreen({Key? key, required this.channelId}) : super(key: key);

  /// Builds the clients overview screen.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChannelViewModel>(
      create: (context) => ChannelViewModel(),
      builder: (context, _) {
        var vm = Provider.of<ChannelViewModel>(context, listen: false);
        var locales = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(locales.channelConfig),
          content: FutureBuilder(
            future: vm.init(context, channelId),
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
                            TextFormField(
                              initialValue: vm.channel.title,
                              decoration: InputDecoration(
                                labelText: locales.title,
                                errorMaxLines: 5,
                              ),
                              onSaved: (String? txt) {
                                vm.channel.title = txt;
                              },
                              onChanged: (String? txt) {
                                vm.channel.title = txt;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: vm.validateTitle,
                            ),
                            verticalSpacer,
                            Consumer<ChannelViewModel>(
                              builder: (context, vm, child) {
                                return DropdownButton<InputDevice>(
                                  isExpanded: true,
                                  value: vm.inputDevice(),
                                  hint: Text(locales.selectInputSource),
                                  items: vm.inputSources
                                      .map<DropdownMenuItem<InputDevice>>(
                                          (InputDevice value) {
                                    return DropdownMenuItem<InputDevice>(
                                      value: value,
                                      child: Text(value.label),
                                    );
                                  }).toList(),
                                  onChanged: (value) =>
                                      vm.selectInputSource(value),
                                );
                              },
                            ),
                            verticalSpacer,
                            TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              initialValue: "${vm.channel.port ?? ''}",
                              decoration: InputDecoration(
                                labelText: locales.connectionPort,
                                helperText: locales.connectionPortInfo,
                                helperMaxLines: 2,
                                errorMaxLines: 5,
                              ),
                              onSaved: (String? txt) {
                                vm.channel.port = int.tryParse(txt ?? '');
                              },
                              onChanged: (String? txt) {
                                vm.channel.port = int.tryParse(txt ?? '');
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: vm.validatePort,
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
    ChannelViewModel vm,
  ) {
    var locales = AppLocalizations.of(context)!;

    return [
      TextButton(
        onPressed: vm.abort,
        child: Text(locales.cancel),
      ),
      TextButton(
        onPressed: vm.save,
        child: Text(locales.save),
      ),
    ];
  }
}
