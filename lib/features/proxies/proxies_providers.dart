import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/mihomo_api.dart';

@immutable
class ProxiesState {
  const ProxiesState({required this.proxies, required this.groupNames});

  /// Groups in config order (`GLOBAL.all`), `GLOBAL` first, hidden excluded.
  factory ProxiesState.from(Map<String, ProxyNode> proxies) {
    final order = <String>['GLOBAL', ...?proxies['GLOBAL']?.all];
    final seen = <String>{};
    final groups = <String>[];
    void add(String name) {
      final node = proxies[name];
      if (node == null || !node.isGroup || node.hidden || !seen.add(name)) {
        return;
      }
      groups.add(name);
    }

    order.forEach(add);
    (proxies.keys.toList()..sort()).forEach(add);
    return ProxiesState(proxies: proxies, groupNames: groups);
  }

  final Map<String, ProxyNode> proxies;
  final List<String> groupNames;

  ProxiesState withProxies(Map<String, ProxyNode> next) =>
      ProxiesState(proxies: next, groupNames: groupNames);

  /// Delay of [name]; for a group, the delay of whatever it resolves to.
  int? delayOf(String name, {String? url}) {
    var node = proxies[name];
    for (var depth = 0; node != null && node.isGroup && depth < 8; depth++) {
      final now = node.now;
      if (now == null) return null;
      node = proxies[now];
    }
    return node?.delayFor(url);
  }
}

class ProxiesNotifier extends AsyncNotifier<ProxiesState> {
  MihomoApi get _api => ref.read(mihomoApiProvider);

  @override
  Future<ProxiesState> build() async {
    final api = ref.watch(mihomoApiProvider);
    return ProxiesState.from(await api.proxies());
  }

  /// Re-fetches without flashing a loading state.
  Future<void> reload() async {
    final next = ProxiesState.from(await _api.proxies());
    state = AsyncData(next);
  }

  Future<void> select(String group, String name) async {
    final current = state.value;
    final node = current?.proxies[group];
    if (current == null || node == null || node.now == name) return;
    state = AsyncData(
      current.withProxies({
        ...current.proxies,
        group: node.copyWith(now: name),
      }),
    );
    try {
      await _api.selectProxy(group, name);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
    // URLTest/Fallback pin a selection; pick up the core's view of it.
    if (node.groupType != ProxyGroupType.selector) await reload();
  }

  Future<void> testGroup(String group) async {
    final node = state.value?.proxies[group];
    if (node == null) return;
    final testing = ref.read(delayTestingProvider.notifier);
    testing.add(group);
    try {
      final url = node.testUrl ?? defaultDelayTestUrl;
      final results = await _api.groupDelay(group, url: url);
      final latest = state.value!;
      final next = {...latest.proxies};
      for (final member in node.all) {
        final proxy = next[member];
        if (proxy == null || proxy.isGroup) continue;
        next[member] = proxy.withDelay(results[member] ?? 0, url: node.testUrl);
      }
      state = AsyncData(latest.withProxies(next));
    } finally {
      testing.remove(group);
    }
  }

  Future<void> testNode(String name, {String? url}) async {
    final testing = ref.read(delayTestingProvider.notifier);
    testing.add(name);
    try {
      final delay = await _api.proxyDelay(
        name,
        url: url ?? defaultDelayTestUrl,
      );
      final latest = state.value!;
      final proxy = latest.proxies[name];
      if (proxy == null) return;
      state = AsyncData(
        latest.withProxies({
          ...latest.proxies,
          name: proxy.withDelay(delay, url: url),
        }),
      );
    } finally {
      testing.remove(name);
    }
  }
}

final proxiesProvider = AsyncNotifierProvider<ProxiesNotifier, ProxiesState>(
  ProxiesNotifier.new,
);

/// Proxy providers, without the core's implicit provider for inline proxies.
class ProxyProvidersNotifier extends AsyncNotifier<List<ProxyProvider>> {
  MihomoApi get _api => ref.read(mihomoApiProvider);

  @override
  Future<List<ProxyProvider>> build() async =>
      _visible(await ref.watch(mihomoApiProvider).proxyProviders());

  static List<ProxyProvider> _visible(List<ProxyProvider> providers) => [
    for (final provider in providers)
      if (!provider.isInline) provider,
  ];

  /// Re-fetches without flashing a loading state.
  Future<void> reload() async {
    state = AsyncData(_visible(await _api.proxyProviders()));
  }

  /// Re-downloads [name]. Its nodes may change, so the groups reload too.
  Future<void> updateProvider(String name) =>
      _busy(updatingProxyProvidersProvider, name, () async {
        await _api.updateProxyProvider(name);
        await _reloadAll();
      });

  /// Tests every node of [name]; the core records the results in the nodes'
  /// histories, which both tabs read.
  Future<void> healthCheck(String name) =>
      _busy(checkingProxyProvidersProvider, name, () async {
        await _api.healthCheckProxyProvider(name);
        await _reloadAll();
      });

  Future<void> _reloadAll() async {
    await Future.wait([reload(), ref.read(proxiesProvider.notifier).reload()]);
  }

  Future<void> _busy(
    NotifierProvider<BusyNamesNotifier, Set<String>> provider,
    String name,
    Future<void> Function() action,
  ) async {
    final busy = ref.read(provider.notifier)..add(name);
    try {
      await action();
    } finally {
      busy.remove(name);
    }
  }
}

final proxyProvidersProvider =
    AsyncNotifierProvider<ProxyProvidersNotifier, List<ProxyProvider>>(
      ProxyProvidersNotifier.new,
    );

/// Names with an operation in flight, for per-item loading indicators.
class BusyNamesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String name) => state = {...state, name};

  void remove(String name) => state = {...state}..remove(name);
}

/// Groups and nodes with a delay test in flight.
final delayTestingProvider = NotifierProvider<BusyNamesNotifier, Set<String>>(
  BusyNamesNotifier.new,
);

/// Proxy providers being re-downloaded.
final updatingProxyProvidersProvider =
    NotifierProvider<BusyNamesNotifier, Set<String>>(BusyNamesNotifier.new);

/// Proxy providers with a health check in flight.
final checkingProxyProvidersProvider =
    NotifierProvider<BusyNamesNotifier, Set<String>>(BusyNamesNotifier.new);

/// Which cards are expanded, kept across tab switches.
class ExpandedNamesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String name) => state = state.contains(name)
      ? ({...state}..remove(name))
      : {...state, name};
}

final expandedGroupsProvider =
    NotifierProvider<ExpandedNamesNotifier, Set<String>>(
      ExpandedNamesNotifier.new,
    );

/// Separate from groups: a provider and a group may share a name.
final expandedProxyProvidersProvider =
    NotifierProvider<ExpandedNamesNotifier, Set<String>>(
      ExpandedNamesNotifier.new,
    );
