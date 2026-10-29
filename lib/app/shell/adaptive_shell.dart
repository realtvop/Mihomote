import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/l10n.dart';
import '../../shared/layout/window_size_class.dart';
import '../router.dart';
import '../theme/semantic_colors.dart';
import 'backend_switcher.dart';
import 'shell_scope.dart';

typedef _Destination = ({IconData icon, IconData selectedIcon, String label});

/// Navigation chrome that adapts to the window size class (AGENTS.md §6.1):
/// bottom bar when compact, collapsed rail when medium, expanded rail when
/// expanded.
class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({
    super.key,
    required this.navigationShell,
    required this.settingsPage,
  });

  final StatefulNavigationShell navigationShell;

  /// The page pushed over the shell when settings opens on an iOS phone.
  final Widget settingsPage;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int _lastPrimaryBranch = ShellBranch.overview;

  /// Settings while it is pushed over the shell (iOS phones only).
  Route<void>? _settingsRoute;
  bool _settingsSyncScheduled = false;

  StatefulNavigationShell get _shell => widget.navigationShell;

  /// iOS goes back with an edge swipe, which can only pop a pushed page;
  /// switching to the settings branch would leave it nothing to pop. So on
  /// iOS phones settings is pushed over the whole shell and gets the native
  /// slide and swipe. The web keeps the branch so the URL and the browser's
  /// own back stay in charge.
  bool get _pushesSettings =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void _goBranch(int index) {
    // Tapping the current destination again pops it back to its root.
    _shell.goBranch(index, initialLocation: index == _shell.currentIndex);
  }

  void _openSettings() {
    if (_pushesSettings && WindowSizeClass.of(context).isCompact) {
      _pushSettings();
    } else {
      _goBranch(ShellBranch.settings);
    }
  }

  void _leaveSettings() => _goBranch(_lastPrimaryBranch);

  /// [animate] is false when settings is already on screen and only changes
  /// form, so it must not slide in as if just opened.
  void _pushSettings({bool animate = true}) {
    if (_settingsRoute != null) return;
    final route = _SettingsRoute(
      animate: animate,
      builder: (context) => ShellScope(
        sizeClass: WindowSizeClass.of(context),
        openSettings: _openSettings,
        leaveSettings: () => Navigator.of(context).pop(),
        child: widget.settingsPage,
      ),
    );
    _settingsRoute = route;
    Navigator.of(context).push(route).whenComplete(() {
      if (_settingsRoute == route) _settingsRoute = null;
    });
  }

  /// Puts settings in the form the window wants after it crosses the compact
  /// breakpoint (rotation, split view) or a link opens the settings branch on
  /// a phone: pushed on phones, the rail destination otherwise.
  void _scheduleSettingsSync() {
    if (_settingsSyncScheduled) return;
    _settingsSyncScheduled = true;
    // Navigating is not allowed during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsSyncScheduled = false;
      if (!mounted) return;
      final route = _settingsRoute;
      if (WindowSizeClass.of(context).isCompact) {
        if (_shell.currentIndex != ShellBranch.settings) return;
        _goBranch(_lastPrimaryBranch);
        _pushSettings(animate: false);
      } else if (route != null) {
        _settingsRoute = null;
        if (route.isActive) Navigator.of(context).removeRoute(route);
        _goBranch(ShellBranch.settings);
      }
    });
  }

  List<_Destination> _destinations(AppLocalizations l10n) => [
    (
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
      label: l10n.navOverview,
    ),
    (
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub_rounded,
      label: l10n.navProxies,
    ),
    (
      icon: Icons.swap_vert_rounded,
      selectedIcon: Icons.swap_vert_rounded,
      label: l10n.navConnections,
    ),
    (
      icon: Icons.rule_rounded,
      selectedIcon: Icons.rule_rounded,
      label: l10n.navRules,
    ),
    (
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: l10n.navLogs,
    ),
    (
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: l10n.navSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizeClass = WindowSizeClass.of(context);
    final index = _shell.currentIndex;
    if (index != ShellBranch.settings) _lastPrimaryBranch = index;
    if (_pushesSettings &&
        (sizeClass.isCompact
            ? index == ShellBranch.settings
            : _settingsRoute != null)) {
      _scheduleSettingsSync();
    }
    final settingsFullScreen =
        sizeClass.isCompact && index == ShellBranch.settings;
    final destinations = _destinations(l10n);

    final content = ShellScope(
      sizeClass: sizeClass,
      openSettings: _openSettings,
      leaveSettings: settingsFullScreen ? _leaveSettings : null,
      child: _shell,
    );

    final Widget layout;
    if (sizeClass.isCompact) {
      layout = Scaffold(
        body: content,
        bottomNavigationBar: settingsFullScreen
            ? null
            : M3ENavigationBar(
                backgroundColor: Theme.of(context).colorScheme.card,
                selectedIndex: index,
                onDestinationSelected: _goBranch,
                destinations: [
                  for (final d in destinations.take(ShellBranch.primaryCount))
                    M3ENavigationBarDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
      );
    } else {
      M3ENavigationRailDestination railItem(_Destination d) =>
          M3ENavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
      layout = Scaffold(
        body: Row(
          children: [
            M3ENavigationRail(
              type: sizeClass.isExpanded
                  ? M3ENavigationRailType.expanded
                  : M3ENavigationRailType.collapsed,
              modality: sizeClass.isExpanded
                  ? M3ENavigationRailModality.standard
                  : M3ENavigationRailModality.modal,
              selectedIndex: index,
              onDestinationSelected: _goBranch,
              expandTooltip: l10n.actionExpand,
              collapseTooltip: l10n.actionCollapse,
              sections: [
                M3ENavigationRailSection(
                  destinations: [
                    for (final d in destinations.take(ShellBranch.primaryCount))
                      railItem(d),
                  ],
                ),
                M3ENavigationRailSection(
                  destinations: [railItem(destinations.last)],
                ),
              ],
              trailing: const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: BackendSwitcher(),
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    // Android back: settings returns to where the user came from, any other
    // tab returns to the overview, and the overview exits.
    return PopScope(
      canPop: index == ShellBranch.overview,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        index == ShellBranch.settings
            ? _leaveSettings()
            : _goBranch(ShellBranch.overview);
      },
      child: layout,
    );
  }
}

/// Settings as a page of its own over the shell, so iOS can swipe it away.
/// Its transition comes from the theme: the native slide on iOS.
class _SettingsRoute extends MaterialPageRoute<void> {
  _SettingsRoute({required super.builder, required this.animate});

  final bool animate;

  // Keep the standard gesture detector while skipping automatic motion when
  // the system requests reduced animations.
  bool get _reduceMotion => MediaQuery.disableAnimationsOf(navigator!.context);

  @override
  Duration get transitionDuration =>
      _reduceMotion ? Duration.zero : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      _reduceMotion ? Duration.zero : super.reverseTransitionDuration;

  @override
  TickerFuture didPush() {
    if (!animate) controller?.value = 1;
    return super.didPush();
  }
}
