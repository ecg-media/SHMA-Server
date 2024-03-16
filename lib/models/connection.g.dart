// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connection _$ConnectionFromJson(Map<String, dynamic> json) => Connection(
      id: json['id'] as int?,
      mode: $enumDecodeNullable(_$ConnectionModeEnumMap, json['mode']) ??
          ConnectionMode.lan,
      host: json['host'] as String?,
      port: json['port'] as int? ?? 42422,
    );

Map<String, dynamic> _$ConnectionToJson(Connection instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('host', instance.host);
  writeNotNull('port', instance.port);
  writeNotNull('mode', _$ConnectionModeEnumMap[instance.mode]);
  return val;
}

const _$ConnectionModeEnumMap = {
  ConnectionMode.lan: 'lan',
  ConnectionMode.hotspot: 'hotspot',
};
