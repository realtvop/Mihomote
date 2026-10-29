import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/backends/backends_providers.dart';
import '../features/backends/welcome_page.dart';
import '../features/connections/connections_page.dart';
import '../features/logs/logs_page.dart';
import '../features/overview/overview_page.dart';
import '../features/proxies/proxies_page.dart';
import '../features/rules/rules_page.dart';
import '../features/settings/settings_page.dart';
import 'shell/adaptive_shell.dart';
import 'shell/branch_transition.dart';

abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const overview = '/overview';
  static const proxies = '/proxies';
  static const connections = '/connections';
  static const rules = '/rules';
  static const logs = '/logs';
  static const settings = '/settings';
}

/// Shell branch indexes, in navigation order.
abstract final class ShellBranch {
  static const overview = 0;
  static const proxies = 1;
  static const connections = 2;
  static const rules = 3;
  static const logs = 4;
  static const settings = 5;

  /// Branches shown in the compact bottom bar (settings lives in the top bar).
  static const primaryCount = 5;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Read + listen instead of watch: rebuilding the router would reset
  // navigation state.
  final hasBackend = ValueNotifier<bool>(
    ref.read(activeBackendProvider) != null,
  );
  ref.listen(
    activeBackendProvider,
    (_, next) => hasBackend.value = next != null,
  );

  StatefulShellBranch branch(String path, Widget page) => StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, _) => page)],
  );

  final router = GoRouter(
    initialLocation: AppRoutes.overview,
    refreshListenable: hasBackend,
    redirect: (context, state) {
      final atWelcome = state.matchedLocation == AppRoutes.welcome;
      if (!hasBackend.value) return atWelcome ? null : AppRoutes.welcome;
      return atWelcome ? AppRoutes.overview : null;
    },
    routes: [
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
      StatefulShellRoute(
        builder: (context, state, shell) =>
            AdaptiveShell(navigationShell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            BranchFadeThrough(
              currentIndex: shell.currentIndex,
              children: children,
            ),
        branches: [
          branch(AppRoutes.overview, const OverviewPage()),
          branch(AppRoutes.proxies, const ProxiesPage()),
          branch(AppRoutes.connections, const ConnectionsPage()),
          branch(AppRoutes.rules, const RulesPage()),
          branch(AppRoutes.logs, const LogsPage()),
          branch(AppRoutes.settings, const SettingsPage()),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    hasBackend.dispose();
  });
  return router;
});
