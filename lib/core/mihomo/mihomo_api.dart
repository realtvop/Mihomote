import 'json.dart';
import 'models/basic.dart';
import 'models/connection.dart';
import 'models/proxy.dart';
import 'models/rule.dart';

export 'json.dart' show JsonMap;
export 'mihomo_exception.dart';
export 'models/basic.dart';
export 'models/connection.dart';
export 'models/proxy.dart';
export 'models/rule.dart';

const defaultDelayTestUrl = 'https://www.gstatic.com/generate_204';
const defaultDelayTimeout = Duration(seconds: 5);

/// Everything the panel can ask of a Mihomo controller.
///
/// Implemented by `MihomoClient` (real REST + WebSocket) and `MockMihomoApi`
/// (in-app sample data for development). UI and providers only see this type.
/// All methods throw `MihomoException` on failure.
abstract interface class MihomoApi {
  Future<MihomoVersion> version();

  Future<CoreConfig> configs();

  /// Partially updates the running config, e.g. `{'mode': 'global'}`.
  Future<void> patchConfigs(JsonMap patch);

  /// Reloads the config file the core was started with.
  Future<void> reloadConfigs();

  Future<void> updateGeoDatabases();

  Future<void> flushDnsCache();

  Future<void> flushFakeIpCache();

  /// All proxies and groups, keyed by name.
  Future<Map<String, ProxyNode>> proxies();

  Future<void> selectProxy(String group, String name);

  /// Clears a pinned selection on a URLTest/Fallback group.
  Future<void> unfixProxy(String group);

  /// Tests one proxy; returns milliseconds, or `0` if it failed or timed out.
  Future<int> proxyDelay(
    String name, {
    String url = defaultDelayTestUrl,
    Duration timeout = defaultDelayTimeout,
  });

  /// Tests every member of a group; members missing from the result failed.
  Future<Map<String, int>> groupDelay(
    String group, {
    String url = defaultDelayTestUrl,
    Duration timeout = defaultDelayTimeout,
  });

  Future<List<ProxyProvider>> proxyProviders();

  Future<void> updateProxyProvider(String name);

  Future<void> healthCheckProxyProvider(String name);

  Future<List<Rule>> rules();

  Future<List<RuleProvider>> ruleProviders();

  Future<void> updateRuleProvider(String name);

  Future<void> closeConnection(String id);

  Future<void> closeAllConnections();

  /// Speed ticks, roughly once per second. Reconnects on its own; transient
  /// failures arrive as error events while it keeps retrying.
  Stream<TrafficSample> traffic();

  Stream<MemorySample> memory();

  /// Log lines at [level] and above.
  Stream<LogEntry> logs({LogLevel level = LogLevel.info});

  Stream<ConnectionsSnapshot> connections({
    Duration interval = const Duration(seconds: 1),
  });

  /// Releases sockets and HTTP resources.
  void close();
}
