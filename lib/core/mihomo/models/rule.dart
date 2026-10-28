import '../json.dart';
import 'proxy.dart';

class Rule {
  const Rule({
    required this.index,
    required this.type,
    required this.payload,
    required this.proxy,
    this.size = -1,
    this.disabled = false,
    this.hitCount,
  });

  factory Rule.fromJson(JsonMap json, {required int fallbackIndex}) {
    final extra = readMap(json['extra']);
    return Rule(
      index: readIntOrNull(json['index']) ?? fallbackIndex,
      type: readString(json['type']),
      payload: readString(json['payload']),
      proxy: readString(json['proxy']),
      size: readInt(json['size'], -1),
      disabled: readBool(extra['disabled']),
      hitCount: readIntOrNull(extra['hitCount']),
    );
  }

  final int index;
  final String type;
  final String payload;
  final String proxy;

  /// Number of entries for rule-set rules, `-1` otherwise.
  final int size;
  final bool disabled;
  final int? hitCount;
}

class RuleProvider {
  const RuleProvider({
    required this.name,
    this.behavior = '',
    this.format = '',
    this.vehicleType = '',
    this.ruleCount = 0,
    this.updatedAt,
  });

  factory RuleProvider.fromJson(JsonMap json) => RuleProvider(
    name: readString(json['name']),
    behavior: readString(json['behavior']),
    format: readString(json['format']),
    vehicleType: readString(json['vehicleType']),
    ruleCount: readInt(json['ruleCount']),
    updatedAt: readDateTime(json['updatedAt']),
  );

  final String name;

  /// `Domain`, `IPCIDR` or `Classical`.
  final String behavior;
  final String format;

  /// `HTTP`, `File`, `Inline`…
  final String vehicleType;
  final int ruleCount;
  final DateTime? updatedAt;
}

class SubscriptionInfo {
  const SubscriptionInfo({
    this.upload = 0,
    this.download = 0,
    this.total = 0,
    this.expire,
  });

  factory SubscriptionInfo.fromJson(JsonMap json) {
    final expire = readInt(json['Expire']);
    return SubscriptionInfo(
      upload: readInt(json['Upload']),
      download: readInt(json['Download']),
      total: readInt(json['Total']),
      expire: expire > 0
          ? DateTime.fromMillisecondsSinceEpoch(expire * 1000)
          : null,
    );
  }

  final int upload;
  final int download;
  final int total;
  final DateTime? expire;
}

class ProxyProvider {
  const ProxyProvider({
    required this.name,
    this.vehicleType = '',
    this.proxies = const [],
    this.testUrl,
    this.updatedAt,
    this.subscription,
  });

  factory ProxyProvider.fromJson(JsonMap json) {
    final info = json['subscriptionInfo'];
    return ProxyProvider(
      name: readString(json['name']),
      vehicleType: readString(json['vehicleType']),
      proxies: readList(json['proxies'])
          .map((e) => ProxyNode.fromJson(readMap(e)))
          .toList(growable: false),
      testUrl: readStringOrNull(json['testUrl']),
      updatedAt: readDateTime(json['updatedAt']),
      subscription: info is Map
          ? SubscriptionInfo.fromJson(readMap(info))
          : null,
    );
  }

  final String name;

  /// `Compatible` marks the core's implicit provider for inline proxies.
  final String vehicleType;
  final List<ProxyNode> proxies;
  final String? testUrl;
  final DateTime? updatedAt;
  final SubscriptionInfo? subscription;

  bool get isInline => vehicleType == 'Compatible';
}
