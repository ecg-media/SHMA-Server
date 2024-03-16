import 'package:json_annotation/json_annotation.dart';
import 'package:string_validator/string_validator.dart';

part 'connection.g.dart';

/// Album model that holds all informations of a record album.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Connection {
  /// Id
  final int? id;

  /// the host or ip of connection.
  String? host;

  /// The port number connection is listening to.
  int? port;

  ConnectionMode? mode;

  /// Initializes the model.
  Connection({
    this.id,
    this.mode = ConnectionMode.lan,
    this.host,
    this.port = 42422,
  });

  /// Converts a json object/map to the model.
  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);

  bool get isValid {
    return (port != null && port! > 0 && port! <= 65535) && host != null && (isIP(host!) || isFQDN(host!));
  }

  /// Converts the current model to a json object/map.
  Map<String, dynamic> toJson() => _$ConnectionToJson(this);
}

enum ConnectionMode {
  lan,
  hotspot,
}
