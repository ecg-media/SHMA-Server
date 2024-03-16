import 'package:json_annotation/json_annotation.dart';
import 'package:shma_server/models/channel.dart';

part 'channel_config.g.dart';

/// Album model that holds all informations of a record album.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ChannelConfig extends Channel {
  /// The port number connection is listening to.
  String? inputSource;

  bool isStreaming = false;
  int activeClients = 0;

  /// Initializes the model.
  ChannelConfig({
    int? id,
    String? title,
    int? port,
    this.inputSource,
  }) : super(
          id: id,
          title: title,
          port: port,
        );

  /// Converts a json object/map to the model.
  factory ChannelConfig.fromJson(Map<String, dynamic> json) =>
      _$ChannelConfigFromJson(json);

  /// Converts the current model to a json object/map.
  @override
  Map<String, dynamic> toJson() => _$ChannelConfigToJson(this);
}
