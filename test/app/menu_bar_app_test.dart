import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mihomote/app/menu_bar/menu_bar_app.dart';
import 'package:mihomote/app/menu_bar/menu_bar_bridge.dart';
import 'package:mihomote/app/menu_bar/menu_bar_shared_data.dart';
import 'package:mihomote/core/mihomo/mihomo_api.dart';
import 'package:mihomote/core/mihomo/mock/mock_data.dart';
import 'package:mihomote/core/mihomo/mock/mock_mihomo_api.dart';
import 'package:mihomote/core/storage/preferences.dart';
import 'package:mihomote/features/proxies/proxies_page.dart';
import 'package:mihomote/features/proxies/proxies_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets(
    'menu-bar popover renders host snapshots and forwards proxy actions',
    (tester) async {
      tester.view.physicalSize = const Size(960, 1360);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );
      await preferences.setBool('settings.dynamicColor', false);

      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MenuBarBridge.channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MenuBarBridge.channel, null),
      );

      final api = MockMihomoApi();
      final proxyMap = await tester.runAsync(api.proxies);
      final proxyProviderList = await tester.runAsync(api.proxyProviders);
      final proxies = ProxiesState.from(proxyMap!);
      final providers = [
        for (final provider in proxyProviderList!)
          if (!provider.isInline) provider,
      ];
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      final shared = container.read(menuBarSharedStateProvider.notifier);
      shared.apply({
        'topic': 'proxies',
        'value': encodeAsyncValue(
          AsyncData(proxies),
          (state) => encodeProxies(state.proxies),
        ),
      });
      shared.apply({
        'topic': 'providers',
        'value': encodeAsyncValue(
          AsyncData(providers),
          (items) => items.map(encodeProxyProvider).toList(growable: false),
        ),
      });
      shared.apply({
        'topic': 'traffic',
        'value': const {'up': 2048, 'down': 4096},
      });
      shared.apply({'topic': 'connectionCount', 'value': 18});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MenuBarProxyScope(child: MenuBarApp()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.text('Proxies'), findsNothing);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Connections'), findsOneWidget);
      expect(find.text(mockSelect), findsWidgets);
      expect(calls.any((call) => call.method == 'configure'), isTrue);

      final menuContainer = ProviderScope.containerOf(
        tester.element(find.byType(ProxiesPage)),
      );
      await menuContainer
          .read(proxyActionsProvider)
          .select(mockSelect, 'DIRECT');
      final hostCall = calls.lastWhere((call) => call.method == 'hostCall');
      expect(hostCall.arguments, {
        'method': 'select',
        'arguments': {'group': mockSelect, 'name': 'DIRECT'},
      });

      await tester.tap(find.byIcon(Icons.open_in_new_rounded));
      await tester.pump();
      expect(calls.last.method, 'openMainWindow');

      await tester.pumpWidget(const SizedBox());
    },
  );

  test('menu-bar host errors retain their Mihomo error kind', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(menuBarSharedStateProvider.notifier).apply({
      'topic': 'proxies',
      'value': encodeAsyncValue<ProxiesState>(
        const AsyncError(
          MihomoException(MihomoErrorKind.unauthorized, 'bad secret'),
          StackTrace.empty,
        ),
        (state) => encodeProxies(state.proxies),
      ),
    });

    final value = container.read(menuBarSharedStateProvider).proxies;
    expect(value.error, isA<MihomoException>());
    expect(
      (value.error! as MihomoException).kind,
      MihomoErrorKind.unauthorized,
    );
  });
}
