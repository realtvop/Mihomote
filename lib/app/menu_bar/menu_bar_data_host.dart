import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mihomo/mihomo_api.dart';
import '../../core/mihomo/json.dart';
import '../../core/state/core_providers.dart';
import '../../features/proxies/proxies_providers.dart';
import 'menu_bar_shared_data.dart';

/// The only owner of Mihomo-backed state used by the macOS menu-bar window.
///
/// It runs inside the main engine's ProviderScope, publishes state snapshots
/// to the secondary rendering engine, and executes all actions there through
/// the same Notifiers used by the main UI.
class MenuBarDataHost extends ConsumerStatefulWidget {
  const MenuBarDataHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MenuBarDataHost> createState() => _MenuBarDataHostState();
}

class _MenuBarDataHostState extends ConsumerState<MenuBarDataHost> {
  static const _channel = MethodChannel('app.mihomote/menu_bar_host');

  final Map<String, Object?> _lastMarkers = {};
  final Map<String, Object?> _pending = {};
  var _publishScheduled = false;

  bool get _enabled => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (_enabled) _channel.setMethodCallHandler(_handleCall);
  }

  @override
  void dispose() {
    if (_enabled) _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<Object?> _handleCall(MethodCall call) async {
    if (call.method != 'call') return null;
    final request = readMap(call.arguments);
    final arguments = readMap(request['arguments']);
    try {
      switch (readString(request['method'])) {
        case 'reloadAll':
          await ref.read(proxyRefreshProvider.notifier).refresh();
          break;
        case 'reloadGroups':
          await ref.read(proxiesProvider.notifier).reload();
          break;
        case 'reloadProviders':
          await ref.read(proxyProvidersProvider.notifier).reload();
          break;
        case 'select':
          await ref
              .read(proxiesProvider.notifier)
              .select(
                readString(arguments['group']),
                readString(arguments['name']),
              );
          break;
        case 'testGroup':
          await ref
              .read(proxiesProvider.notifier)
              .testGroup(readString(arguments['group']));
          break;
        case 'testNode':
          await ref
              .read(proxiesProvider.notifier)
              .testNode(
                readString(arguments['name']),
                url: readStringOrNull(arguments['url']),
              );
          break;
        case 'updateProvider':
          await ref
              .read(proxyProvidersProvider.notifier)
              .updateProvider(readString(arguments['name']));
          break;
        case 'healthCheckProvider':
          await ref
              .read(proxyProvidersProvider.notifier)
              .healthCheck(readString(arguments['name']));
          break;
        default:
          throw const MihomoException(
            MihomoErrorKind.unknown,
            'Unsupported menu-bar action',
          );
      }
      return null;
    } on MihomoException catch (error) {
      throw PlatformException(
        code: error.kind.name,
        message: error.message ?? error.toString(),
      );
    } catch (error) {
      throw PlatformException(code: 'unknown', message: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;

    final proxies = ref.watch(proxiesProvider);
    final providers = ref.watch(proxyProvidersProvider);
    final config = ref.watch(coreConfigProvider);
    final traffic = ref.watch(trafficProvider);
    final connections = ref.watch(connectionsStreamProvider);
    final groupTraffic = ref.watch(proxyGroupTrafficProvider);
    final delayTesting = ref.watch(delayTestingProvider);
    final updatingProviders = ref.watch(updatingProxyProvidersProvider);
    final checkingProviders = ref.watch(checkingProxyProvidersProvider);

    _queue('proxies', (
      proxies.value,
      proxies.isLoading,
      proxies.error,
    ), encodeAsyncValue(proxies, (state) => encodeProxies(state.proxies)));
    _queue(
      'providers',
      (providers.value, providers.isLoading, providers.error),
      encodeAsyncValue(
        providers,
        (items) => items.map(encodeProxyProvider).toList(growable: false),
      ),
    );
    _queue(
      'globalMode',
      config.value?.mode,
      config.value?.mode == TunnelMode.global,
    );
    _queue(
      'traffic',
      traffic.value,
      traffic.value == null
          ? null
          : {'up': traffic.value!.up, 'down': traffic.value!.down},
    );
    final connectionCount = connections.value?.connections.length;
    _queue('connectionCount', connectionCount, connectionCount);
    _queue('groupTraffic', groupTraffic, {
      for (final entry in groupTraffic.entries)
        entry.key: {'down': entry.value.down, 'up': entry.value.up},
    });
    _queue('delayTesting', delayTesting, delayTesting.toList(growable: false));
    _queue(
      'updatingProviders',
      updatingProviders,
      updatingProviders.toList(growable: false),
    );
    _queue(
      'checkingProviders',
      checkingProviders,
      checkingProviders.toList(growable: false),
    );

    return widget.child;
  }

  void _queue(String topic, Object? marker, Object? value) {
    if (_lastMarkers[topic] == marker && _lastMarkers.containsKey(topic)) {
      return;
    }
    _lastMarkers[topic] = marker;
    _pending[topic] = value;
    if (_publishScheduled) return;
    _publishScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  void _publish() {
    _publishScheduled = false;
    final pending = Map<String, Object?>.from(_pending);
    _pending.clear();
    for (final entry in pending.entries) {
      unawaited(
        _channel
            .invokeMethod<void>('publish', {
              'topic': entry.key,
              'value': entry.value,
            })
            .onError<MissingPluginException>((_, _) {}),
      );
    }
  }
}
