// Renders every page with the mock backend in a compact and an expanded
// window and fails on any exception. Layout bugs in this app tend to blank a
// whole page (AGENTS.md "已知问题"), so this catches them before a device does.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mihomote/app/app.dart';
import 'package:mihomote/app/router.dart';
import 'package:mihomote/features/settings/settings_page.dart';
import 'package:mihomote/core/backends/backend_profile.dart';
import 'package:mihomote/core/settings/app_settings.dart';
import 'package:mihomote/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _sizes = {'compact': Size(402, 874), 'expanded': Size(1280, 820)};

Future<SharedPreferencesWithCache> _prefs({
  required bool withMockBackend,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  // The test binding has no dynamic_color plugin.
  await prefs.setBool('settings.dynamicColor', false);
  if (withMockBackend) {
    await prefs.setString(
      'backends.profiles',
      jsonEncode([const BackendProfile.mock(name: 'Mock').toJson()]),
    );
  }
  return prefs;
}

Future<void> _render(
  WidgetTester tester, {
  required Size size,
  required bool withMockBackend,
  String? route,
  Future<void> Function(ProviderContainer container)? act,
  void Function()? verify,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await _prefs(withMockBackend: withMockBackend),
      ),
    ],
  );
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MihomoteApp(),
      ),
    );
    if (route != null) container.read(routerProvider).go(route);
    // Mock calls answer after ~200 ms; streams tick every second.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));

    if (act != null) {
      await act(container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    verify?.call();
  } finally {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    // Let the mock's pending delays fire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 3));
  }
}

void main() {
  const routes = [
    AppRoutes.overview,
    AppRoutes.proxies,
    AppRoutes.connections,
    AppRoutes.rules,
    AppRoutes.logs,
    AppRoutes.settings,
  ];

  for (final MapEntry(key: label, value: size) in _sizes.entries) {
    testWidgets('welcome renders ($label)', (tester) async {
      await _render(
        tester,
        size: size,
        withMockBackend: false,
        verify: () => expect(find.byType(EditableText), findsWidgets),
      );
    });

    for (final route in routes) {
      testWidgets('$route renders ($label)', (tester) async {
        await _render(tester, size: size, withMockBackend: true, route: route);
      });
    }
  }

  // Regression: an animated theme switch left a light scaffold under dark
  // M3E surfaces (see themeAnimationDuration in lib/app/app.dart).
  testWidgets('switching to dark mode updates the whole theme', (tester) async {
    await _render(
      tester,
      size: _sizes['compact']!,
      withMockBackend: true,
      route: AppRoutes.settings,
      act: (container) => container
          .read(appSettingsProvider.notifier)
          .setThemeMode(ThemeMode.dark),
      verify: () {
        final theme = Theme.of(tester.element(find.byType(SettingsPage)));
        expect(theme.colorScheme.brightness, Brightness.dark);
        expect(theme.scaffoldBackgroundColor.computeLuminance(), lessThan(0.2));
      },
    );
  });
}
