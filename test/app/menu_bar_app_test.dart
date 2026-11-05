import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mihomote/app/menu_bar/menu_bar_app.dart';
import 'package:mihomote/app/menu_bar/menu_bar_bridge.dart';
import 'package:mihomote/core/backends/backend_profile.dart';
import 'package:mihomote/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('menu-bar popover renders proxies and reports live traffic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1360);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    await preferences.setBool('settings.dynamicColor', false);
    await preferences.setString(
      'backends.profiles',
      jsonEncode([const BackendProfile.mock(name: 'Mock').toJson()]),
    );

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MenuBarApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.text('Proxies'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Connections'), findsOneWidget);
    expect(calls.any((call) => call.method == 'configure'), isTrue);
    expect(calls.any((call) => call.method == 'updateTraffic'), isTrue);

    await tester.tap(find.byIcon(Icons.open_in_new_rounded));
    await tester.pump();
    expect(calls.last.method, 'openMainWindow');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
