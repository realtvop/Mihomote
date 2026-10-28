import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/l10n.dart';
import '../../shared/layout/window_size_class.dart';
import '../router.dart';
import 'backend_switcher.dart';
import 'shell_scope.dart';

typedef _Destination = ({IconData icon, IconData selectedIcon, String label});

/// Navigation chrome that adapts to the window size class (AGENTS.md §6.1):
/// bottom bar when compact, collapsed rail when medium, expanded rail when
/// expanded.
class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int _lastPrimaryBranch = ShellBranch.overview;

  StatefulNavigationShell get _shell => widget.navigationShell;

  void _goBranch(int index) {
    // Tapping the current destination again pops it back to its root.
    _shell.goBranch(index, initialLocation: index == _shell.currentIndex);
  }

  void _openSettings() => _goBranch(ShellBranch.settings);

  void _leaveSettings() => _goBranch(_lastPrimaryBranch);

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
