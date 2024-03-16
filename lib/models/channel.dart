import 'package:json_annotation/json_annotation.dart';

part 'channel.g.dart';

/// Album model that holds all informations of a record album.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Channel {
  /// Id
  final int? id;

  /// the host or ip of connection.
  String? title;

  /// The port number connection is listening to.
  int? port;

  /// Initializes the model.
  Channel({
    this.id,
    this.title,
    this.port,
  });

  /// Converts a json object/map to the model.
  factory Channel.fromJson(Map<String, dynamic> json) =>
      _$ChannelFromJson(json);

  /// Converts the current model to a json object/map.
  Map<String, dynamic> toJson() => _$ChannelToJson(this);
}