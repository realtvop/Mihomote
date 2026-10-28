import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'json.dart';
import 'mihomo_api.dart';

/// [MihomoApi] backed by a real external-controller.
///
/// REST calls send `Authorization: Bearer <secret>`. WebSockets pass the
/// secret as `?token=` because browsers can't set headers on them.
class MihomoClient implements MihomoApi {
  MihomoClient({required Uri baseUri, String secret = '', Dio? dio})
    : _base = baseUri,
      _secret = secret,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 10),
              headers: {
                if (secret.isNotEmpty) 'Authorization': 'Bearer $secret',
              },
            ),
          );

  final Uri _base;
  final String _secret;
  final Dio _dio;

  Uri _uri(List<String> segments, [Map<String, String>? query]) =>
      _base.replace(
        pathSegments: [
          ..._base.pathSegments.where((s) => s.isNotEmpty),
          ...segments,
        ],
        queryParameters: query == null || query.isEmpty ? null : query,
      );

  Uri _wsUri(List<String> segments, [Map<String, String> query = const {}]) {
    final http = _uri(segments, {
      ...query,
      if (_secret.isNotEmpty) 'token': _secret,
    });
    return http.replace(scheme: http.scheme == 'https' ? 'wss' : 'ws');
  }

  Future<JsonMap> _getJson(
    List<String> segments, {
    Map<String, String>? query,
    Options? options,
  }) => _guard(() async {
    final response = await _dio.getUri<Object?>(
      _uri(segments, query),
      options: options,
    );
    return readMap(response.data);
  });

  Future<void> _send(
    String method,
    List<String> segments, {
    Object? body,
    Map<String, String>? query,
  }) => _guard(() async {
    await _dio.requestUri<Object?>(
      _uri(segments, query),
      data: body,
      options: Options(method: method),
    );
  });

  @override
  Future<MihomoVersion> version() async =>
      MihomoVersion.fromJson(await _getJson(['version']));

  @override
  Future<CoreConfig> configs() async =>
      CoreConfig.fromJson(await _getJson(['configs']));

  @override
  Future<void> patchConfigs(JsonMap patch) =>
      _send('PATCH', ['configs'], body: patch);

  @override
  Future<void> reloadConfigs() => _send(
    'PUT',
    ['configs'],
    query: {'force': 'true'},
    body: {'path': '', 'payload': ''},
  );

  @override
  Future<void> updateGeoDatabases() =>
      _send('POST', ['configs', 'geo'], body: <String, Object?>{});

  @override
  Future<void> flushDnsCache() => _send('POST', ['cache', 'dns', 'flush']);

  @override
  Future<void> flushFakeIpCache() =>
      _send('POST', ['cache', 'fakeip', 'flush']);

  @override
  Future<Map<String, ProxyNode>> proxies() async {
    final json = await _getJson(['proxies']);
    return readMap(
      json['proxies'],
    ).map((name, value) => MapEntry(name, ProxyNode.fromJson(readMap(value))));
  }

  @override
  Future<void> selectProxy(String group, String name) =>
      _send('PUT', ['proxies', group], body: {'name': name});

  @override
  Future<void> unfixProxy(String group) => _send('DELETE', ['proxies', group]);

  Map<String, String> _delayQuery(String url, Duration timeout) => {
    'url': url,
    'timeout': timeout.inMilliseconds.toString(),
  };

  // The core answers 408/503/504 when a test fails; that's a result, not an
  // error, so it maps to delay 0.
  static bool _isFailedTest(MihomoException e) =>
      e.kind == MihomoErrorKind.timeout || e.kind == MihomoErrorKind.server;

  @override
  Future<int> proxyDelay(
    String name, {
    String url = defaultDelayTestUrl,
    Duration timeout = defaultDelayTimeout,
  }) async {
    try {
      final json = await _getJson(
        ['proxies', name, 'delay'],
        query: _delayQuery(url, timeout),
        options: Options(receiveTimeout: timeout + const Duration(seconds: 5)),
      );
      return readInt(json['delay']);
    } on MihomoException catch (e) {
      if (_isFailedTest(e)) return 0;
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> groupDelay(
    String group, {
    String url = defaultDelayTestUrl,
    Duration timeout = defaultDelayTimeout,
  }) async {
    try {
      final json = await _getJson(
        ['group', group, 'delay'],
        query: _delayQuery(url, timeout),
        options: Options(receiveTimeout: timeout + const Duration(seconds: 10)),
      );
      return json.map((name, delay) => MapEntry(name, readInt(delay)));
    } on MihomoException catch (e) {
      if (_isFailedTest(e)) return const {};
      rethrow;
    }
  }

  @override
  Future<List<ProxyProvider>> proxyProviders() async {
    final json = await _getJson(['providers', 'proxies']);
    return readMap(json['providers']).values
        .map((e) => ProxyProvider.fromJson(readMap(e)))
        .toList(growable: false);
  }

  @override
  Future<void> updateProxyProvider(String name) =>
      _send('PUT', ['providers', 'proxies', name]);

  @override
  Future<void> healthCheckProxyProvider(String name) => _guard(() async {
    await _dio.getUri<Object?>(
      _uri(['providers', 'proxies', name, 'healthcheck']),
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
  });

  @override
  Future<List<Rule>> rules() async {
    final json = await _getJson(['rules']);
    final list = readList(json['rules']);
    return [
      for (var i = 0; i < list.length; i++)
        Rule.fromJson(readMap(list[i]), fallbackIndex: i),
    ];
  }

  @override
  Future<List<RuleProvider>> ruleProviders() async {
    final json = await _getJson(['providers', 'rules']);
    return readMap(json['providers']).values
        .map((e) => RuleProvider.fromJson(readMap(e)))
        .toList(growable: false);
  }

  @override
  Future<void> updateRuleProvider(String name) =>
      _send('PUT', ['providers', 'rules', name]);

  @override
  Future<void> closeConnection(String id) =>
      _send('DELETE', ['connections', id]);

  @override
  Future<void> closeAllConnections() => _send('DELETE', ['connections']);

  @override
  Stream<TrafficSample> traffic() =>
      _socket(['traffic'], (json) => TrafficSample.fromJson(readMap(json)));

  @override
  Stream<MemorySample> memory() =>
      _socket(['memory'], (json) => MemorySample.fromJson(readMap(json)));

  @override
  Stream<LogEntry> logs({LogLevel level = LogLevel.info}) => _socket(
    ['logs'],
    (json) => LogEntry.fromJson(readMap(json)),
    query: {'level': level.name},
  );

  @override
  Stream<ConnectionsSnapshot> connections({
    Duration interval = const Duration(seconds: 1),
  }) => _socket(
    ['connections'],
    (json) => ConnectionsSnapshot.fromJson(readMap(json)),
    query: {'interval': interval.inMilliseconds.toString()},
  );

  /// A WebSocket JSON stream that reconnects with exponential backoff until
  /// the listener cancels. Failures are reported as error events.
  Stream<T> _socket<T>(
    List<String> segments,
    T Function(Object? json) parse, {
    Map<String, String> query = const {},
  }) {
    late final StreamController<T> controller;
    WebSocketChannel? channel;
    StreamSubscription<Object?>? subscription;
    Timer? retry;
    var attempt = 0;
    var cancelled = false;

    void connect() {
      if (cancelled) return;
      final socket = WebSocketChannel.connect(_wsUri(segments, query));
      channel = socket;
      socket.ready.ignore(); // Failures also surface on the stream below.
      subscription = socket.stream.listen(
        (message) {
          attempt = 0;
          if (message is! String) return;
          try {
            controller.add(parse(jsonDecode(message)));
          } on FormatException {
            // Skip a malformed frame rather than tearing down the stream.
          }
        },
        onError: (Object _) {
          if (!cancelled) {
            controller.addError(const MihomoException(MihomoErrorKind.network));
          }
        },
        onDone: () {
          if (cancelled) return;
          final backoff = math.min(10000, 500 * math.pow(2, attempt).toInt());
          attempt++;
          retry = Timer(Duration(milliseconds: backoff), connect);
        },
        cancelOnError: false,
      );
    }

    controller = StreamController<T>(
      onListen: connect,
      onCancel: () async {
        cancelled = true;
        retry?.cancel();
        await subscription?.cancel();
        await channel?.sink.close();
      },
    );
    return controller.stream;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  static MihomoException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const MihomoException(MihomoErrorKind.timeout);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final data = e.response?.data;
        final message = data is Map ? readStringOrNull(data['message']) : null;
        return switch (status) {
          401 || 403 => MihomoException(MihomoErrorKind.unauthorized, message),
          404 => MihomoException(MihomoErrorKind.notFound, message),
          408 || 504 => MihomoException(MihomoErrorKind.timeout, message),
          _ => MihomoException(
            MihomoErrorKind.server,
            message ?? 'HTTP $status',
          ),
        };
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const MihomoException(MihomoErrorKind.network);
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        // On web a CORS or mixed-content block also lands here.
        return MihomoException(MihomoErrorKind.network, e.message);
    }
  }

  @override
  void close() => _dio.close(force: true);
}
