import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/l10n.dart';
import 'backend_switcher.dart';
import 'shell_scope.dart';

/// Common page chrome: a collapsing M3E flexible app bar over [slivers].
///
/// In the compact layout it also hosts the backend switcher and the settings
/// button (the bottom bar has no room for them); in settings it shows a back
/// button instead.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.floatingActionButton,
    this.onRefresh,
    this.controller,
    this.showShellActions = true,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;
  final bool showShellActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shell = ShellScope.maybeOf(context);
    final compact = shell?.sizeClass.isCompact ?? true;
    final leaveSettings = shell?.leaveSettings;

    Widget scrollView = CustomScrollView(
      controller: controller,
      slivers: [
        M3EAppBar.sliver(
          titleText: title,
          variant: M3EAppBarVariant.mediumFlexible,
          leading: leaveSettings == null
              ? null
              : M3EIconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  variant: M3EIconButtonVariant.standard,
                  tooltip: l10n.actionBack,
                  onPressed: leaveSettings,
                ),
          actions: [
            ...actions,
            if (compact && showShellActions) ...[
              const BackendSwitcher(),
              M3EIconButton(
                icon: const Icon(Icons.settings_outlined),
                variant: M3EIconButtonVariant.standard,
                tooltip: l10n.navSettings,
                onPressed: shell?.openSettings,
              ),
            ],
          ],
        ),
        ...slivers,
        const SliverSafeArea(
          top: false,
          sliver: SliverToBoxAdapter(child: SizedBox(height: 24)),
        ),
      ],
    );
    if (onRefresh != null) {
      scrollView = M3ERefreshIndicator(
        onRefresh: onRefresh!,
        child: scrollView,
      );
    }
    return Scaffold(
      body: scrollView,
      floatingActionButton: floatingActionButton,
    );
  }
}
