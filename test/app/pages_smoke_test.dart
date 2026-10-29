// Renders every page with the mock backend in a compact and an expanded
// window and fails on any exception. Layout bugs in this app tend to blank a
// whole page (AGENTS.md "已知问题"), so this catches them before a device does.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mihomote/app/app.dart';
import 'package:mihomote/app/router.dart';
import 'package:mihomote/app/shell/backend_switcher.dart';
import 'package:mihomote/features/backends/backend_form.dart';
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
  void Function()? verifyMidway,
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
      if (verifyMidway != null) {
        await tester.pump(const Duration(milliseconds: 150));
        verifyMidway();
      }
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

/// Pumps real-length frames. M3E springs (menus, sheets) advance per frame,
/// so one long pump leaves them barely started.
Future<void> _pumpFrames(WidgetTester tester, {int count = 40}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
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

  // Bottom sheet on compact, side sheet on expanded.
  for (final MapEntry(key: label, value: size) in _sizes.entries) {
    testWidgets('connection details open from the list ($label)', (
      tester,
    ) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.connections,
        // On the headline: a wide row's center is empty space between texts.
        act: (_) => tester.tap(
          find
              .descendant(
                of: find.byType(M3EListItem).first,
                matching: find.byType(Text),
              )
              .first,
        ),
        verify: () {
          expect(find.text('Download'), findsOneWidget);
          expect(find.text('Upload'), findsOneWidget);
          // The bundled font has no arrows; they render as boxes on iOS 26
          // (AGENTS.md §6.7).
          expect(find.textContaining(RegExp('[←↑→↓]')), findsNothing);
        },
      );
    });
  }

  // Every menu and dialog opens without layout errors on both window sizes.
  for (final MapEntry(key: label, value: size) in _sizes.entries) {
    testWidgets('backend menu opens ($label)', (tester) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.overview,
        act: (_) async {
          await tester.tap(find.byType(BackendSwitcher).first);
          await _pumpFrames(tester);
        },
        verify: () {
          // The mock profile, then "Manage backends".
          expect(find.byType(M3EMenuItem), findsNWidgets(2));
          expect(find.text('Manage backends'), findsOneWidget);
        },
      );
    });

    testWidgets('log level menu sets the level ($label)', (tester) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.settings,
        act: (_) async {
          final row = find.text('Log level');
          await tester.scrollUntilVisible(
            row,
            200,
            scrollable: find
                .descendant(
                  of: find.byType(SettingsPage),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          // Off the screen edge, where scrollUntilVisible may leave it.
          await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
          await tester.pump();
          await tester.tap(row);
          await _pumpFrames(tester);
          expect(find.byType(M3EMenuItem), findsNWidgets(5));
          await tester.tap(find.widgetWithText(M3EMenuItem, 'Warning'));
          await _pumpFrames(tester);
        },
        verify: () {
          expect(find.byType(M3EMenuItem), findsNothing);
          expect(find.text('Warning'), findsOneWidget);
        },
      );
    });

    testWidgets('log filter menu opens ($label)', (tester) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.logs,
        act: (_) async {
          await tester.tap(find.byIcon(Icons.filter_list_rounded));
          await _pumpFrames(tester);
        },
        verify: () => expect(find.byType(M3EMenuItem), findsNWidgets(4)),
      );
    });

    testWidgets('backend editor opens ($label)', (tester) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.settings,
        act: (_) async {
          await tester.tap(find.byIcon(Icons.add_rounded));
          await _pumpFrames(tester);
        },
        verify: () {
          expect(find.byType(BackendForm), findsOneWidget);
          expect(
            find.byType(label == 'compact' ? M3EFullScreenDialog : M3EDialog),
            findsOneWidget,
          );
        },
      );
    });

    testWidgets('closing all connections asks first ($label)', (tester) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.connections,
        act: (_) async {
          await tester.tap(find.byIcon(Icons.clear_all_rounded));
          await _pumpFrames(tester);
        },
        verify: () => expect(find.byType(M3EDialog), findsOneWidget),
      );
    });

    testWidgets('deleting a backend asks first ($label)', (tester) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.settings,
        act: (_) async {
          await tester.tap(find.byIcon(Icons.delete_outline_rounded));
          await _pumpFrames(tester);
        },
        verify: () {
          expect(find.byType(M3EDialog), findsOneWidget);
          expect(find.widgetWithText(M3EButton, 'Delete'), findsOneWidget);
        },
      );
    });
  }

  // Regression: an animated theme switch left a light scaffold under dark
  // M3E surfaces (see _ThemeTransition in lib/app/app.dart).
  testWidgets('switching to dark mode updates the whole theme', (tester) async {
    await _render(
      tester,
      size: _sizes['compact']!,
      withMockBackend: true,
      route: AppRoutes.settings,
      act: (container) => container
          .read(appSettingsProvider.notifier)
          .setThemeMode(ThemeMode.dark),
      verifyMidway: () {
        final context = tester.element(find.byType(SettingsPage));
        final surface = Theme.of(context).colorScheme.surface;
        // Actually part-way, and M3E widgets see the same colors.
        expect(surface.computeLuminance(), inExclusiveRange(0.02, 0.9));
        expect(M3ETheme.of(context).colorScheme.surface, surface);
        expect(
          Theme.of(context).scaffoldBackgroundColor.computeLuminance(),
          inExclusiveRange(0.02, 0.9),
        );
      },
      verify: () {
        final theme = Theme.of(tester.element(find.byType(SettingsPage)));
        expect(theme.colorScheme.brightness, Brightness.dark);
        expect(theme.scaffoldBackgroundColor.computeLuminance(), lessThan(0.2));
      },
    );
  });
}
