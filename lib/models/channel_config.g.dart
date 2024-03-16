// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelConfig _$ChannelConfigFromJson(Map<String, dynamic> json) =>
    ChannelConfig(
      id: json['id'] as int?,
      title: json['title'] as String?,
      port: json['port'] as int?,
      inputSource: json['inputSource'] as String?,
    )
      ..isStreaming = json['isStreaming'] as bool
      ..activeClients = json['activeClients'] as int;

Map<String, dynamic> _$ChannelConfigToJson(ChannelConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('title', instance.title);
  writeNotNull('port', instance.port);
  writeNotNull('inputSource', instance.inputSource);
  val['isStreaming'] = instance.isStreaming;
  val['activeClients'] = instance.activeClients;
  return val;
}
