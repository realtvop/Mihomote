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
import 'package:mihomote/features/overview/overview_page.dart';
import 'package:mihomote/features/settings/settings_page.dart';
import 'package:mihomote/core/backends/backend_profile.dart';
import 'package:mihomote/core/backends/backends_providers.dart';
import 'package:mihomote/core/mihomo/mihomo_api.dart';
import 'package:mihomote/core/settings/app_settings.dart';
import 'package:mihomote/core/state/core_providers.dart';
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
  group('iOS settings navigation', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await _pumpFrames(tester);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byType(M3ENavigationBar), findsNothing);
    }

    Future<void> swipeBack(WidgetTester tester) async {
      await tester.dragFrom(const Offset(1, 350), const Offset(320, 0));
      await _pumpFrames(tester);
    }

    testWidgets('edge swipe follows the finger, cancels, then returns', (
      tester,
    ) async {
      await _render(
        tester,
        size: _sizes['compact']!,
        withMockBackend: true,
        route: AppRoutes.proxies,
        act: (container) async {
          await openSettings(tester);
          final page = find.byType(SettingsPage);
          final gesture = await tester.startGesture(const Offset(1, 350));
          await gesture.moveBy(const Offset(100, 0));
          await tester.pump();
          await gesture.moveBy(const Offset(30, 0));
          await tester.pump();
          expect(tester.getTopLeft(page).dx, greaterThan(0));
          await tester.pump(const Duration(milliseconds: 500));
          await gesture.up();
          await _pumpFrames(tester);
          expect(page, findsOneWidget);
          expect(tester.getTopLeft(page).dx, 0);

          await swipeBack(tester);
          expect(page, findsNothing);
          expect(
            container.read(routerProvider).state.uri.path,
            AppRoutes.proxies,
          );
          expect(
            tester
                .widget<M3ENavigationBar>(find.byType(M3ENavigationBar))
                .selectedIndex,
            ShellBranch.proxies,
          );
          // The completed route must not prevent opening settings again.
          await openSettings(tester);
          await tester.tap(find.byIcon(Icons.arrow_back_rounded));
          await _pumpFrames(tester);
          expect(page, findsNothing);
        },
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('backend menu opens swipeable settings', (tester) async {
      await _render(
        tester,
        size: _sizes['compact']!,
        withMockBackend: true,
        act: (_) async {
          await tester.tap(find.byType(BackendSwitcher).first);
          await _pumpFrames(tester);
          await tester.tap(find.text('Manage backends'));
          await _pumpFrames(tester);
          expect(find.byType(SettingsPage), findsOneWidget);
          await swipeBack(tester);
          expect(find.byType(SettingsPage), findsNothing);
        },
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('reduced motion keeps settings swipeable', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _render(
        tester,
        size: _sizes['compact']!,
        withMockBackend: true,
        act: (_) async {
          await openSettings(tester);
          final route = ModalRoute.of(
            tester.element(find.byType(SettingsPage)),
          )!;
          expect(route.transitionDuration, Duration.zero);
          expect(route.reverseTransitionDuration, Duration.zero);
          await swipeBack(tester);
          expect(find.byType(SettingsPage), findsNothing);
        },
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('direct settings route can swipe back to overview', (
      tester,
    ) async {
      await _render(
        tester,
        size: _sizes['compact']!,
        withMockBackend: true,
        route: AppRoutes.settings,
        act: (container) async {
          await _pumpFrames(tester);
          expect(find.byType(SettingsPage), findsOneWidget);
          await swipeBack(tester);
          expect(find.byType(SettingsPage), findsNothing);
          expect(
            container.read(routerProvider).state.uri.path,
            AppRoutes.overview,
          );
        },
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('settings adapts across widths and preserves return tab', (
      tester,
    ) async {
      await _render(
        tester,
        size: _sizes['compact']!,
        withMockBackend: true,
        route: AppRoutes.rules,
        act: (container) async {
          await openSettings(tester);
          for (final width in [700.0, 1280.0]) {
            tester.view.physicalSize = Size(width, 820) * 2;
            await _pumpFrames(tester);
            expect(find.byType(SettingsPage), findsOneWidget);
            expect(find.byType(M3ENavigationRail), findsOneWidget);
            expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
            expect(
              container.read(routerProvider).state.uri.path,
              AppRoutes.settings,
            );
          }
          tester.view.physicalSize = _sizes['compact']! * 2;
          await _pumpFrames(tester);
          expect(find.byType(SettingsPage), findsOneWidget);
          expect(find.byType(M3ENavigationBar), findsNothing);
          await swipeBack(tester);
          expect(find.byType(SettingsPage), findsNothing);
          expect(
            container.read(routerProvider).state.uri.path,
            AppRoutes.rules,
          );
        },
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('removing last backend dismisses pushed settings', (
      tester,
    ) async {
      await _render(
        tester,
        size: _sizes['compact']!,
        withMockBackend: true,
        act: (container) async {
          await openSettings(tester);
          final backend = container.read(activeBackendProvider)!;
          await container.read(backendsProvider.notifier).remove(backend.id);
          await _pumpFrames(tester);
          expect(find.byType(SettingsPage), findsNothing);
          expect(
            container.read(routerProvider).state.uri.path,
            AppRoutes.welcome,
          );
        },
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

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

    testWidgets('leaving rule mode asks first ($label)', (tester) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.overview,
        act: (container) async {
          TunnelMode? mode() => container.read(coreConfigProvider).value?.mode;
          // The group also lays its labels out offstage to measure them.
          Finder segment(String label) => find.text(label).hitTestable();

          final group = find.descendant(
            of: find.byType(OverviewPage),
            matching: find.byType(M3EButtonGroup),
          );
          await tester.scrollUntilVisible(
            group,
            200,
            scrollable: find
                .descendant(
                  of: find.byType(OverviewPage),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(tester.element(group), alignment: 0.5);
          await tester.pump();

          await tester.tap(segment('Global'));
          await _pumpFrames(tester);
          expect(find.text('Switch to Global mode?'), findsOneWidget);
          expect(find.textContaining('ignoring rules'), findsOneWidget);
          await tester.tap(find.widgetWithText(M3EButton, 'Cancel'));
          await _pumpFrames(tester);
          expect(find.byType(M3EDialog), findsNothing);
          expect(mode(), TunnelMode.rule);

          await tester.tap(segment('Direct'));
          await _pumpFrames(tester);
          await tester.tap(find.widgetWithText(M3EButton, 'Switch'));
          await _pumpFrames(tester);
          expect(mode(), TunnelMode.direct);

          // Back to rule needs no confirmation.
          await tester.tap(segment('Rule'));
          await _pumpFrames(tester);
          expect(find.byType(M3EDialog), findsNothing);
          expect(mode(), TunnelMode.rule);
        },
      );
    });

    testWidgets('proxy providers open and health-check ($label)', (
      tester,
    ) async {
      await _render(
        tester,
        size: size,
        withMockBackend: true,
        route: AppRoutes.proxies,
        act: (_) async {
          // The switch springs in once the providers load.
          await _pumpFrames(tester);
          await tester.tap(find.text('Providers').hitTestable());
          await _pumpFrames(tester);
          await tester.tap(find.text('Subscription'));
          await _pumpFrames(tester);
          await tester.tap(find.byIcon(Icons.speed_rounded).first);
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byType(M3ELoadingIndicator), findsOneWidget);
          await tester.pump(const Duration(seconds: 3));
          await _pumpFrames(tester);
        },
        verify: () {
          expect(find.text('Backup'), findsOneWidget);
          // The core's implicit provider for inline proxies stays hidden.
          expect(find.text('default'), findsNothing);
          expect(find.text('🇭🇰 香港 01'), findsOneWidget);
          expect(find.byType(M3ELoadingIndicator), findsNothing);
        },
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
