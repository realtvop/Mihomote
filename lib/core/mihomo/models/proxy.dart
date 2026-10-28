import '../json.dart';

class DelayRecord {
  const DelayRecord({required this.delay, this.time});

  factory DelayRecord.fromJson(JsonMap json) => DelayRecord(
    delay: readInt(json['delay']),
    time: readDateTime(json['time']),
  );

  /// Milliseconds; `0` means the test failed or timed out.
  final int delay;
  final DateTime? time;
}

enum ProxyGroupType {
  selector('Selector'),
  urlTest('URLTest'),
  fallback('Fallback'),
  loadBalance('LoadBalance'),
  relay('Relay');

  const ProxyGroupType(this.wireName);

  final String wireName;

  static ProxyGroupType? tryParse(String type) {
    for (final value in values) {
      if (value.wireName.toLowerCase() == type.toLowerCase()) return value;
    }
    return null;
  }
}

/// A proxy node or a proxy group, as returned by `/proxies`.
class ProxyNode {
  const ProxyNode({
    required this.name,
    required this.type,
    this.udp = false,
    this.history = const [],
    this.extraHistory = const {},
    this.all = const [],
    this.now,
    this.fixed,
    this.hidden = false,
    this.icon,
    this.testUrl,
    this.providerName,
  });

  factory ProxyNode.fromJson(JsonMap json) {
    final extra = <String, List<DelayRecord>>{};
    readMap(json['extra']).forEach((url, value) {
      extra[url] = _readHistory(readMap(value)['history']);
    });
    return ProxyNode(
      name: readString(json['name']),
      type: readString(json['type']),
      udp: readBool(json['udp']),
      history: _readHistory(json['history']),
      extraHistory: extra,
      all: readStringList(json['all']),
      now: readStringOrNull(json['now']),
      fixed: readStringOrNull(json['fixed']),
      hidden: readBool(json['hidden']),
      icon: readStringOrNull(json['icon']),
      testUrl: readStringOrNull(json['testUrl']),
      providerName: readStringOrNull(json['provider-name']),
    );
  }

  static List<DelayRecord> _readHistory(Object? value) =>
      readList(value)
          .map((e) => DelayRecord.fromJson(readMap(e)))
          .toList(growable: false);

  final String name;

  /// Wire type, e.g. `Selector`, `URLTest`, `Shadowsocks`, `Vless`, `Direct`.
  final String type;
  final bool udp;

  /// Delay history for the core's default test URL.
  final List<DelayRecord> history;

  /// Delay history keyed by test URL (groups with a custom `testUrl`).
  final Map<String, List<DelayRecord>> extraHistory;

  /// Members, for groups.
  final List<String> all;

  /// Current selection, for groups.
  final String? now;

  /// Pinned selection of a URLTest/Fallback group (newer cores).
  final String? fixed;
  final bool hidden;
  final String? icon;
  final String? testUrl;
  final String? providerName;

  ProxyGroupType? get groupType => ProxyGroupType.tryParse(type);

  bool get isGroup => groupType != null;

  /// Whether picking a member from the UI is meaningful.
  bool get isSelectable => switch (groupType) {
    ProxyGroupType.selector ||
    ProxyGroupType.urlTest ||
    ProxyGroupType.fallback => true,
    _ => false,
  };

  /// Latest delay measured against [url] (falls back to the default history).
  /// `null` means never tested; `0` means the last test failed.
  int? delayFor([String? url]) {
    final records = (url != null ? extraHistory[url] : null) ?? history;
    return records.isEmpty ? null : records.last.delay;
  }

  ProxyNode copyWith({
    String? now,
    String? fixed,
    bool clearFixed = false,
    List<DelayRecord>? history,
    Map<String, List<DelayRecord>>? extraHistory,
  }) => ProxyNode(
    name: name,
    type: type,
    udp: udp,
    history: history ?? this.history,
    extraHistory: extraHistory ?? this.extraHistory,
    all: all,
    now: now ?? this.now,
    fixed: clearFixed ? null : (fixed ?? this.fixed),
    hidden: hidden,
    icon: icon,
    testUrl: testUrl,
    providerName: providerName,
  );

  /// Returns a copy with [delay] appended to the history for [url].
  ProxyNode withDelay(int delay, {String? url}) {
    final record = DelayRecord(delay: delay, time: DateTime.now());
    if (url != null && extraHistory.containsKey(url)) {
      return copyWith(
        extraHistory: {
          ...extraHistory,
          url: [...extraHistory[url]!, record],
        },
      );
    }
    return copyWith(history: [...history, record]);
  }
}
