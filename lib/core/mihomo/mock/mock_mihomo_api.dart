import 'dart:async';
import 'dart:math' as math;

import '../json.dart';
import '../mihomo_api.dart';
import 'mock_data.dart';

/// In-memory [MihomoApi] for development: sample data, simulated live
/// streams, and mutations (selection, mode, delay tests) that stick for the
/// lifetime of the instance. Only reachable from debug builds.
class MockMihomoApi implements MihomoApi {
  MockMihomoApi({math.Random? random}) : _random = random ?? math.Random() {
    _seedProxies();
    _seedConnections();
  }

  final math.Random _random;
  final JsonMap _config = {...mockConfig};
  final Map<String, JsonMap> _proxies = {};
  final List<JsonMap> _connections = [];
  int _connectionSeq = 0;
  int _uploadTotal = 182 * 1024 * 1024;
  int _downloadTotal = 3 * 1024 * 1024 * 1024 + 412 * 1024 * 1024;

  static const _latency = Duration(milliseconds: 180);

  Future<void> _wait([Duration? d]) => Future<void>.delayed(d ?? _latency);

  int _jitter(int base) {
    if (base == 0) return 0;
    if (_random.nextDouble() < 0.04) return 0; // Occasional failure.
    return math.max(1, base + _random.nextInt(base ~/ 2 + 10) - base ~/ 6);
  }

  JsonMap _record(int delay) => {
    'time': DateTime.now().toUtc().toIso8601String(),
    'delay': delay,
  };

  void _seedProxies() {
    for (final MapEntry(key: name, value: type) in mockBuiltins.entries) {
      _proxies[name] = {
        'name': name,
        'type': type,
        'udp': true,
        'history': <Object?>[],
      };
    }
    for (final node in mockNodes) {
      // Leave a couple of nodes untested to show the "never tested" state.
      final tested = !node.name.contains('02');
      _proxies[node.name] = {
        'name': node.name,
        'type': node.type,
        'udp': true,
        'history': [if (tested) _record(_jitter(node.baseDelay))],
      };
    }
    for (final group in mockGroups) {
      final all = readStringList(group['all']);
      _proxies[readString(group['name'])] = {
        ...group,
        'now': group['now'] ?? all.first,
        'history': <Object?>[],
      };
    }
    _proxies['GLOBAL'] = {
      'name': 'GLOBAL',
      'type': 'Selector',
      'now': mockSelect,
      'all': [...mockGroups.map((g) => g['name']), 'DIRECT', 'REJECT'],
      'history': <Object?>[],
    };
  }

  JsonMap _newConnection() {
    final target = mockTargets[_random.nextInt(mockTargets.length)];
    final (host, port, process, rule, payload, chain) = target;
    final isIp = RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host);
    return {
      'id': 'mock-${_connectionSeq++}',
      'metadata': {
        'network': _random.nextDouble() < 0.9 ? 'tcp' : 'udp',
        'type': _random.nextBool() ? 'Tun' : 'Mixed',
        'sourceIP': mockSources[_random.nextInt(mockSources.length)],
        'sourcePort': '${49152 + _random.nextInt(16000)}',
        'destinationIP': isIp
            ? host
            : '104.18.${_random.nextInt(255)}.${_random.nextInt(255)}',
        'destinationPort': port,
        'host': isIp ? '' : host,
        'process': process,
        'processPath': '/Applications/$process.app/Contents/MacOS/$process',
        'inboundName': 'DEFAULT-MIXED',
        'dnsMode': 'normal',
      },
      'upload': _random.nextInt(4096),
      'download': _random.nextInt(65536),
      'start': DateTime.now()
          .subtract(Duration(seconds: _random.nextInt(600)))
          .toUtc()
          .toIso8601String(),
      'chains': chain.reversed.toList(),
      'rule': rule,
      'rulePayload': payload,
    };
  }

  void _seedConnections() {
    for (var i = 0; i < 18; i++) {
      _connections.add(_newConnection());
    }
  }

  @override
  Future<MihomoVersion> version() async {
    await _wait();
    return const MihomoVersion(version: 'v1.19.15 (mock)', meta: true);
  }

  @override
  Future<CoreConfig> configs() async {
    await _wait();
    return CoreConfig.fromJson(_config);
  }

  @override
  Future<void> patchConfigs(JsonMap patch) async {
    await _wait();
    _config.addAll(patch);
  }

  @override
  Future<void> reloadConfigs() => _wait(const Duration(milliseconds: 600));

  @override
  Future<void> updateGeoDatabases() => _wait(const Duration(seconds: 2));

  @override
  Future<void> flushDnsCache() => _wait();

  @override
  Future<void> flushFakeIpCache() => _wait();

  @override
  Future<Map<String, ProxyNode>> proxies() async {
    await _wait();
    return _proxies.map(
      (name, json) => MapEntry(name, ProxyNode.fromJson(json)),
    );
  }

  @override
  Future<void> selectProxy(String group, String name) async {
    await _wait();
    final json = _proxies[group];
    if (json == null || !readStringList(json['all']).contains(name)) {
      throw const MihomoException(MihomoErrorKind.notFound, 'proxy not found');
    }
    json['now'] = name;
    if (json['type'] != 'Selector') json['fixed'] = name;
  }

  @override
  Future<void> unfixProxy(String group) async {
    await _wait();
    _proxies[group]?.remove('fixed');
  }

  int _test(String name) {
    final node = mockNodes.where((n) => n.name == name).firstOrNull;
    final delay = node == null
        ? (name == 'DIRECT' ? _jitter(8) : 0)
        : _jitter(node.baseDelay);
    (_proxies[name]?['history'] as List<Object?>?)?.add(_record(delay));
    return delay;
  }

  @override
  Future<int> proxyDelay(
    String name, {
    String url = defaultDelayTestUrl,
    Duration timeout = defaultDelayTimeout,
  }) async {
    await _wait(Duration(milliseconds: 400 + _random.nextInt(900)));
    return _test(name);
  }

  @override
  Future<Map<String, int>> groupDelay(
    String group, {
    String url = defaultDelayTestUrl,
    Duration timeout = defaultDelayTimeout,
  }) async {
    await _wait(Duration(milliseconds: 900 + _random.nextInt(1200)));
    final members = readStringList(_proxies[group]?['all']);
    final result = <String, int>{};
    for (final name in members) {
      if (_proxies[name]?['all'] != null) continue; // Nested group.
      final delay = _test(name);
      if (delay > 0) result[name] = delay;
    }
    return result;
  }

  @override
  Future<List<ProxyProvider>> proxyProviders() async {
    await _wait();
    return [
      ProxyProvider.fromJson({
        'name': 'Subscription',
        'type': 'Proxy',
        'vehicleType': 'HTTP',
        'testUrl': defaultDelayTestUrl,
        'updatedAt': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toUtc()
            .toIso8601String(),
        'subscriptionInfo': {
          'Upload': 2 * 1024 * 1024 * 1024,
          'Download': 86 * 1024 * 1024 * 1024,
          'Total': 200 * 1024 * 1024 * 1024,
          'Expire':
              DateTime.now()
                  .add(const Duration(days: 23))
                  .millisecondsSinceEpoch ~/
              1000,
        },
        'proxies': [for (final node in mockNodes) _proxies[node.name]],
      }),
    ];
  }

  @override
  Future<void> updateProxyProvider(String name) =>
      _wait(const Duration(seconds: 1));

  @override
  Future<void> healthCheckProxyProvider(String name) async {
    await _wait(const Duration(seconds: 2));
    for (final node in mockNodes) {
      _test(node.name);
    }
  }

  @override
  Future<List<Rule>> rules() async {
    await _wait();
    return [
      for (final (i, (type, payload, proxy, size)) in mockRules.indexed)
        Rule.fromJson({
          'index': i,
          'type': type,
          'payload': payload,
          'proxy': proxy,
          'size': size,
          'extra': {'disabled': false, 'hitCount': _random.nextInt(5000)},
        }, fallbackIndex: i),
    ];
  }

  @override
  Future<List<RuleProvider>> ruleProviders() async {
    await _wait();
    return [
      for (final (name, behavior, format, vehicle, count) in mockRuleProviders)
        RuleProvider.fromJson({
          'name': name,
          'behavior': behavior,
          'format': format,
          'vehicleType': vehicle,
          'ruleCount': count,
          'updatedAt': DateTime.now()
              .subtract(Duration(minutes: 30 + _random.nextInt(600)))
              .toUtc()
              .toIso8601String(),
        }),
    ];
  }

  @override
  Future<void> updateRuleProvider(String name) =>
      _wait(const Duration(milliseconds: 1200));

  @override
  Future<void> closeConnection(String id) async {
    await _wait();
    _connections.removeWhere((c) => c['id'] == id);
  }

  @override
  Future<void> closeAllConnections() async {
    await _wait();
    _connections.clear();
  }

  @override
  Stream<TrafficSample> traffic() async* {
    var up = 40.0 * 1024, down = 900.0 * 1024;
    var targetUp = up, targetDown = down;
    for (var tick = 0; ; tick++) {
      if (tick % 4 == 0) {
        // Bursty downloads with a quieter baseline, like real browsing.
        final burst = _random.nextDouble() < 0.3;
        targetDown =
            (burst
                ? 2 + _random.nextDouble() * 9
                : 0.1 + _random.nextDouble() * 1.4) *
            1024 *
            1024;
        targetUp = (12 + _random.nextDouble() * (burst ? 380 : 120)) * 1024;
      }
      up += (targetUp - up) * 0.45 + (_random.nextDouble() - 0.5) * 8 * 1024;
      down +=
          (targetDown - down) * 0.45 +
          (_random.nextDouble() - 0.5) * 120 * 1024;
      up = math.max(0, up);
      down = math.max(0, down);
      _uploadTotal += up.round();
      _downloadTotal += down.round();
      yield TrafficSample(
        up: up.round(),
        down: down.round(),
        upTotal: _uploadTotal,
        downTotal: _downloadTotal,
      );
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Stream<MemorySample> memory() async* {
    var inUse = 68.0 * 1024 * 1024;
    while (true) {
      inUse = (inUse + (_random.nextDouble() - 0.48) * 3 * 1024 * 1024).clamp(
        42.0 * 1024 * 1024,
        140.0 * 1024 * 1024,
      );
      yield MemorySample(inUse: inUse.round());
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Stream<LogEntry> logs({LogLevel level = LogLevel.info}) async* {
    const order = [
      LogLevel.debug,
      LogLevel.info,
      LogLevel.warning,
      LogLevel.error,
    ];
    final minIndex = order.indexOf(level);
    if (minIndex < 0) return;
    while (true) {
      await Future<void>.delayed(
        Duration(milliseconds: 250 + _random.nextInt(1100)),
      );
      // Every tick must reach the yield: a cancelled async* generator only
      // stops there, so skipping filtered entries kept it creating timers.
      LogEntry entry;
      do {
        entry = _randomLog();
      } while (order.indexOf(entry.level) < minIndex);
      yield entry;
    }
  }

  LogEntry _randomLog() {
    final roll = _random.nextDouble();
    final (host, port, _, rule, payload, chain) =
        mockTargets[_random.nextInt(mockTargets.length)];
    final source =
        '${mockSources[_random.nextInt(mockSources.length)]}:${49152 + _random.nextInt(16000)}';
    final (level, text) = switch (roll) {
      < 0.35 => (
        LogLevel.debug,
        '[DNS] $host --> [104.18.${_random.nextInt(255)}.${_random.nextInt(255)}]',
      ),
      < 0.88 => (
        LogLevel.info,
        '[TCP] $source --> $host:$port match $rule${payload.isEmpty ? '' : '($payload)'} using ${chain.first}${chain.length > 1 ? '[${chain.last}]' : ''}',
      ),
      < 0.97 => (
        LogLevel.warning,
        '[TCP] dial ${chain.first} (match $rule/$payload) $source --> $host:$port error: i/o timeout',
      ),
      _ => (
        LogLevel.error,
        '[Provider] Subscription pull error: context deadline exceeded',
      ),
    };
    return LogEntry(level: level, payload: text, time: DateTime.now());
  }

  @override
  Stream<ConnectionsSnapshot> connections({
    Duration interval = const Duration(seconds: 1),
  }) async* {
    while (true) {
      _tickConnections();
      yield ConnectionsSnapshot.fromJson({
        'downloadTotal': _downloadTotal,
        'uploadTotal': _uploadTotal,
        'connections': _connections.map((c) => {...c}).toList(),
        'memory': 70 * 1024 * 1024,
      });
      await Future<void>.delayed(interval);
    }
  }

  void _tickConnections() {
    for (final c in _connections) {
      if (_random.nextDouble() < 0.6) {
        c['upload'] = readInt(c['upload']) + _random.nextInt(24 * 1024);
        c['download'] =
            readInt(c['download']) +
            _random.nextInt(
              _random.nextDouble() < 0.15 ? 2 * 1024 * 1024 : 96 * 1024,
            );
      }
    }
    if (_connections.isNotEmpty && _random.nextDouble() < 0.3) {
      _connections.removeAt(_random.nextInt(_connections.length));
    }
    if (_connections.length < 40 && _random.nextDouble() < 0.5) {
      _connections.add(_newConnection());
    }
  }

  @override
  void close() {}
}
