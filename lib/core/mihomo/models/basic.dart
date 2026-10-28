import '../json.dart';

class MihomoVersion {
  const MihomoVersion({required this.version, this.meta = false});

  factory MihomoVersion.fromJson(JsonMap json) => MihomoVersion(
    version: readString(json['version'], 'unknown'),
    meta: readBool(json['meta']),
  );

  final String version;
  final bool meta;
}

/// One `/traffic` tick: current speeds in bytes per second. Newer cores also
/// report running totals.
class TrafficSample {
  const TrafficSample({
    required this.up,
    required this.down,
    this.upTotal,
    this.downTotal,
  });

  factory TrafficSample.fromJson(JsonMap json) => TrafficSample(
    up: readInt(json['up']),
    down: readInt(json['down']),
    upTotal: readIntOrNull(json['upTotal']),
    downTotal: readIntOrNull(json['downTotal']),
  );

  static const zero = TrafficSample(up: 0, down: 0);

  final int up;
  final int down;
  final int? upTotal;
  final int? downTotal;
}

class MemorySample {
  const MemorySample({required this.inUse, this.osLimit = 0});

  factory MemorySample.fromJson(JsonMap json) => MemorySample(
    inUse: readInt(json['inuse']),
    osLimit: readInt(json['oslimit']),
  );

  final int inUse;
  final int osLimit;
}

enum TunnelMode {
  rule,
  global,
  direct,
  unknown;

  static TunnelMode parse(Object? value) =>
      switch (readString(value).toLowerCase()) {
        'rule' => rule,
        'global' => global,
        'direct' => direct,
        _ => unknown,
      };
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  silent,
  unknown;

  static LogLevel parse(Object? value) =>
      switch (readString(value).toLowerCase()) {
        'debug' => debug,
        'info' => info,
        'warning' || 'warn' => warning,
        'error' => error,
        'silent' => silent,
        _ => unknown,
      };
}

/// The subset of `/configs` the panel reads. [raw] keeps everything else.
class CoreConfig {
  const CoreConfig({
    required this.mode,
    required this.logLevel,
    this.mixedPort = 0,
    this.port = 0,
    this.socksPort = 0,
    this.allowLan = false,
    this.ipv6 = false,
    this.tunEnabled = false,
    this.raw = const {},
  });

  factory CoreConfig.fromJson(JsonMap json) => CoreConfig(
    mode: TunnelMode.parse(json['mode']),
    logLevel: LogLevel.parse(json['log-level']),
    mixedPort: readInt(json['mixed-port']),
    port: readInt(json['port']),
    socksPort: readInt(json['socks-port']),
    allowLan: readBool(json['allow-lan']),
    ipv6: readBool(json['ipv6']),
    tunEnabled: readBool(readMap(json['tun'])['enable']),
    raw: json,
  );

  final TunnelMode mode;
  final LogLevel logLevel;
  final int mixedPort;
  final int port;
  final int socksPort;
  final bool allowLan;
  final bool ipv6;
  final bool tunEnabled;
  final JsonMap raw;

  CoreConfig copyWith({
    TunnelMode? mode,
    LogLevel? logLevel,
    bool? allowLan,
    bool? ipv6,
  }) => CoreConfig(
    mode: mode ?? this.mode,
    logLevel: logLevel ?? this.logLevel,
    mixedPort: mixedPort,
    port: port,
    socksPort: socksPort,
    allowLan: allowLan ?? this.allowLan,
    ipv6: ipv6 ?? this.ipv6,
    tunEnabled: tunEnabled,
    raw: raw,
  );
}

class LogEntry {
  const LogEntry({
    required this.level,
    required this.payload,
    required this.time,
  });

  factory LogEntry.fromJson(JsonMap json, {DateTime? receivedAt}) => LogEntry(
    level: LogLevel.parse(json['type']),
    payload: readString(json['payload']),
    time: receivedAt ?? DateTime.now(),
  );

  final LogLevel level;
  final String payload;

  /// Mihomo doesn't timestamp log lines, so this is when the panel got it.
  final DateTime time;
}
