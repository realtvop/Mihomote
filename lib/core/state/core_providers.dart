import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backends/backends_providers.dart';
import '../mihomo/mihomo_api.dart';

/// Core version of the active backend; also serves as its health check.
final versionProvider = FutureProvider<MihomoVersion>(
  (ref) => ref.watch(mihomoApiProvider).version(),
);

/// Running config of the active backend, with optimistic edits.
class CoreConfigNotifier extends AsyncNotifier<CoreConfig> {
  @override
  Future<CoreConfig> build() => ref.watch(mihomoApiProvider).configs();

  Future<void> setMode(TunnelMode mode) =>
      _patch({'mode': mode.name}, (c) => c.copyWith(mode: mode));

  Future<void> setAllowLan(bool value) =>
      _patch({'allow-lan': value}, (c) => c.copyWith(allowLan: value));

  Future<void> setIpv6(bool value) =>
      _patch({'ipv6': value}, (c) => c.copyWith(ipv6: value));

  Future<void> setLogLevel(LogLevel level) =>
      _patch({'log-level': level.name}, (c) => c.copyWith(logLevel: level));

  /// Applies [local] immediately, sends [patch], and rolls back on failure.
  Future<void> _patch(
    JsonMap patch,
    CoreConfig Function(CoreConfig) local,
  ) async {
    final previous = state.value;
    if (previous == null) return;
    state = AsyncData(local(previous));
    try {
      await ref.read(mihomoApiProvider).patchConfigs(patch);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final coreConfigProvider =
    AsyncNotifierProvider<CoreConfigNotifier, CoreConfig>(
      CoreConfigNotifier.new,
    );

final trafficProvider = StreamProvider<TrafficSample>(
  (ref) => ref.watch(mihomoApiProvider).traffic(),
);

final memoryProvider = StreamProvider<MemorySample>(
  (ref) => ref.watch(mihomoApiProvider).memory(),
);

/// Live connection snapshots, shared by the overview count and the
/// connections page.
final connectionsStreamProvider = StreamProvider<ConnectionsSnapshot>(
  (ref) => ref.watch(mihomoApiProvider).connections(),
);
