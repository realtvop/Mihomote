import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../../core/mihomo/mihomo_api.dart';
import '../../core/mihomo/json.dart';
import '../../features/proxies/proxies_providers.dart';
import 'menu_bar_bridge.dart';

class MenuBarSharedState {
  static const _unset = Object();

  const MenuBarSharedState({
    this.proxies = const AsyncLoading(),
    this.providers = const AsyncLoading(),
    this.globalMode = false,
    this.traffic,
    this.connectionCount,
    this.delayTesting = const {},
    this.updatingProviders = const {},
    this.checkingProviders = const {},
  });

  final AsyncValue<ProxiesState> proxies;
  final AsyncValue<List<ProxyProvider>> providers;
  final bool globalMode;
  final TrafficSample? traffic;
  final int? connectionCount;
  final Set<String> delayTesting;
  final Set<String> updatingProviders;
  final Set<String> checkingProviders;

  MenuBarSharedState copyWith({
    AsyncValue<ProxiesState>? proxies,
    AsyncValue<List<ProxyProvider>>? providers,
    bool? globalMode,
    Object? traffic = _unset,
    Object? connectionCount = _unset,
    Set<String>? delayTesting,
    Set<String>? updatingProviders,
    Set<String>? checkingProviders,
  }) => MenuBarSharedState(
    proxies: proxies ?? this.proxies,
    providers: providers ?? this.providers,
    globalMode: globalMode ?? this.globalMode,
    traffic: identical(traffic, _unset)
        ? this.traffic
        : traffic as TrafficSample?,
    connectionCount: identical(connectionCount, _unset)
        ? this.connectionCount
        : connectionCount as int?,
    delayTesting: delayTesting ?? this.delayTesting,
    updatingProviders: updatingProviders ?? this.updatingProviders,
    checkingProviders: checkingProviders ?? this.checkingProviders,
  );
}

class MenuBarSharedStateNotifier extends Notifier<MenuBarSharedState> {
  @override
  MenuBarSharedState build() => const MenuBarSharedState();

  void apply(Object? message) {
    final envelope = readMap(message);
    final value = envelope['value'];
    state = switch (readString(envelope['topic'])) {
      'proxies' => state.copyWith(
        proxies: decodeAsyncValue(
          value,
          (data) => ProxiesState.from(decodeProxies(data)),
        ),
      ),
      'providers' => state.copyWith(
        providers: decodeAsyncValue(
          value,
          (data) =>
              readList(data)
                  .map((item) => ProxyProvider.fromJson(readMap(item)))
                  .toList(growable: false),
        ),
      ),
      'globalMode' => state.copyWith(globalMode: value == true),
      'traffic' => state.copyWith(
        traffic: value == null ? null : TrafficSample.fromJson(readMap(value)),
      ),
      'connectionCount' => state.copyWith(
        connectionCount: readIntOrNull(value),
      ),
      'delayTesting' => state.copyWith(delayTesting: _decodeNames(value)),
      'updatingProviders' => state.copyWith(
        updatingProviders: _decodeNames(value),
      ),
      'checkingProviders' => state.copyWith(
        checkingProviders: _decodeNames(value),
      ),
      _ => state,
    };
  }

  static Set<String> _decodeNames(Object? value) =>
      readStringList(value).toSet();
}

final menuBarSharedStateProvider =
    NotifierProvider<MenuBarSharedStateNotifier, MenuBarSharedState>(
      MenuBarSharedStateNotifier.new,
    );

class MenuBarProxyScope extends StatelessWidget {
  const MenuBarProxyScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      proxiesViewProvider.overrideWith(
        (ref) => ref.watch(
          menuBarSharedStateProvider.select((state) => state.proxies),
        ),
      ),
      proxyProvidersViewProvider.overrideWith(
        (ref) => ref.watch(
          menuBarSharedStateProvider.select((state) => state.providers),
        ),
      ),
      proxyGlobalModeViewProvider.overrideWith(
        (ref) => ref.watch(
          menuBarSharedStateProvider.select((state) => state.globalMode),
        ),
      ),
      delayTestingViewProvider.overrideWith(
        (ref) => ref.watch(
          menuBarSharedStateProvider.select((state) => state.delayTesting),
        ),
      ),
      updatingProxyProvidersViewProvider.overrideWith(
        (ref) => ref.watch(
          menuBarSharedStateProvider.select((state) => state.updatingProviders),
        ),
      ),
      checkingProxyProvidersViewProvider.overrideWith(
        (ref) => ref.watch(
          menuBarSharedStateProvider.select((state) => state.checkingProviders),
        ),
      ),
      proxyActionsProvider.overrideWith((ref) => _menuBarProxyActions),
    ],
    child: child,
  );
}

final _menuBarProxyActions = ProxyActions(
  reloadGroups: () => MenuBarBridge.hostCall('reloadGroups'),
  reloadProviders: () => MenuBarBridge.hostCall('reloadProviders'),
  select: (group, name) =>
      MenuBarBridge.hostCall('select', {'group': group, 'name': name}),
  testGroup: (group) => MenuBarBridge.hostCall('testGroup', {'group': group}),
  testNode: _testNode,
  updateProvider: (name) =>
      MenuBarBridge.hostCall('updateProvider', {'name': name}),
  healthCheckProvider: (name) =>
      MenuBarBridge.hostCall('healthCheckProvider', {'name': name}),
);

Future<void> _testNode(String name, {String? url}) {
  final arguments = <String, Object?>{'name': name};
  if (url != null) arguments['url'] = url;
  return MenuBarBridge.hostCall('testNode', arguments);
}

Object encodeAsyncValue<T>(AsyncValue<T> value, Object? Function(T) encode) {
  final data = value.value;
  if (data != null) return {'status': 'data', 'data': encode(data)};
  if (value.hasError) {
    final error = value.error;
    return {
      'status': 'error',
      'kind': error is MihomoException ? error.kind.name : 'unknown',
      'message': error is MihomoException
          ? error.message ?? error.toString()
          : error.toString(),
    };
  }
  return const {'status': 'loading'};
}

AsyncValue<T> decodeAsyncValue<T>(
  Object? value,
  T Function(Object? data) decode,
) {
  final envelope = readMap(value);
  return switch (readString(envelope['status'])) {
    'data' => AsyncData(decode(envelope['data'])),
    'error' => AsyncError(
      MihomoException(
        MihomoErrorKind.values.asNameMap()[readString(envelope['kind'])] ??
            MihomoErrorKind.unknown,
        readStringOrNull(envelope['message']),
      ),
      StackTrace.empty,
    ),
    _ => const AsyncLoading(),
  };
}

Object encodeProxies(Map<String, ProxyNode> proxies) => {
  for (final entry in proxies.entries) entry.key: encodeProxyNode(entry.value),
};

Map<String, ProxyNode> decodeProxies(Object? value) =>
    readMap(value)
        .map((name, node) => MapEntry(name, ProxyNode.fromJson(readMap(node))));

Object encodeProxyNode(ProxyNode node) => {
  'name': node.name,
  'type': node.type,
  'udp': node.udp,
  'history': node.history.map(_encodeDelay).toList(growable: false),
  'extra': {
    for (final entry in node.extraHistory.entries)
      entry.key: {
        'history': entry.value.map(_encodeDelay).toList(growable: false),
      },
  },
  'all': node.all,
  if (node.now != null) 'now': node.now,
  if (node.fixed != null) 'fixed': node.fixed,
  'hidden': node.hidden,
  if (node.icon != null) 'icon': node.icon,
  if (node.testUrl != null) 'testUrl': node.testUrl,
  if (node.providerName != null) 'provider-name': node.providerName,
};

Object _encodeDelay(DelayRecord record) => {
  'delay': record.delay,
  if (record.time != null) 'time': record.time!.toIso8601String(),
};

Object encodeProxyProvider(ProxyProvider provider) => {
  'name': provider.name,
  'vehicleType': provider.vehicleType,
  'proxies': provider.proxies.map(encodeProxyNode).toList(growable: false),
  if (provider.testUrl != null) 'testUrl': provider.testUrl,
  if (provider.updatedAt != null)
    'updatedAt': provider.updatedAt!.toIso8601String(),
  if (provider.subscription case final subscription?)
    'subscriptionInfo': {
      'Upload': subscription.upload,
      'Download': subscription.download,
      'Total': subscription.total,
      'Expire': subscription.expire?.millisecondsSinceEpoch == null
          ? 0
          : subscription.expire!.millisecondsSinceEpoch ~/ 1000,
    },
};
