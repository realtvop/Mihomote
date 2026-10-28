import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../../../core/mihomo/mihomo_api.dart';
import '../../../shared/l10n.dart';
import '../../../shared/widgets/status_views.dart';
import '../proxies_providers.dart';
import 'delay_label.dart';

/// One proxy group: header with current selection and a latency test, and an
/// expandable grid of members.
class ProxyGroupCard extends ConsumerWidget {
  const ProxyGroupCard({super.key, required this.state, required this.group});

  final ProxiesState state;
  final ProxyNode group;

  static (M3EShapeKind, IconData) _look(ProxyGroupType? type) => switch (type) {
    ProxyGroupType.selector => (
      M3EShapeKind.cookie4Sided,
      Icons.touch_app_rounded,
    ),
    ProxyGroupType.urlTest => (M3EShapeKind.sunny, Icons.bolt_rounded),
    ProxyGroupType.fallback => (M3EShapeKind.clover4Leaf, Icons.shield_rounded),
    ProxyGroupType.loadBalance => (M3EShapeKind.flower, Icons.balance_rounded),
    ProxyGroupType.relay => (M3EShapeKind.arrow, Icons.route_rounded),
    null => (M3EShapeKind.circle, Icons.hub_rounded),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final expanded = ref.watch(
      expandedGroupsProvider.select((s) => s.contains(group.name)),
    );
    final testing = ref.watch(
      delayTestingProvider.select((s) => s.contains(group.name)),
    );
    final notifier = ref.read(proxiesProvider.notifier);
    final (shape, icon) = _look(group.groupType);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) showErrorSnackbar(context, e);
      }
    }

    final header = InkWell(
      onTap: () => ref.read(expandedGroupsProvider.notifier).toggle(group.name),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            M3EShapeContainer(
              kind: shape,
              width: 44,
              height: 44,
              color: scheme.primaryContainer,
              child: Icon(icon, size: 22, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      group.type,
                      l10n.proxiesNodeCount(group.all.length),
                      if (group.now != null) group.now!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (group.fixed != null) ...[
              Tooltip(
                message: l10n.proxiesFixed,
                child: Icon(
                  Icons.push_pin_rounded,
                  size: 18,
                  color: scheme.tertiary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            DelayLabel(delay: state.delayOf(group.name, url: group.testUrl)),
            const SizedBox(width: 4),
            SizedBox.square(
              dimension: 48,
              child: Center(
                child: testing
                    ? const M3ELoadingIndicator(size: 28)
                    : M3EIconButton(
                        icon: const Icon(Icons.speed_rounded),
                        variant: M3EIconButtonVariant.standard,
                        tooltip: l10n.proxiesTestLatency,
                        onPressed: () =>
                            run(() => notifier.testGroup(group.name)),
                      ),
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Icon(
                Icons.expand_more_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    return Material(
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SingleMotionBuilder(
            value: expanded ? 1 : 0,
            motion: const MaterialSpringMotion.standardSpatialDefault(),
            builder: (context, t, _) {
              if (t <= 0.001 && !expanded) {
                return _DotPreview(state: state, group: group);
              }
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: t.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _MemberGrid(
                      state: state,
                      group: group,
                      onSelect: (name) =>
                          run(() => notifier.select(group.name, name)),
                      onTest: (name) => run(
                        () => notifier.testNode(name, url: group.testUrl),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Collapsed summary: one latency dot per member.
class _DotPreview extends StatelessWidget {
  const _DotPreview({required this.state, required this.group});

  final ProxiesState state;
  final ProxyNode group;

  @override
  Widget build(BuildContext context) {
    final members = group.all.take(64);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final name in members)
            DelayDot(
              delay: state.delayOf(name, url: group.testUrl),
              selected: name == group.now,
            ),
        ],
      ),
    );
  }
}

class _MemberGrid extends ConsumerWidget {
  const _MemberGrid({
    required this.state,
    required this.group,
    required this.onSelect,
    required this.onTest,
  });

  final ProxiesState state;
  final ProxyNode group;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testing = ref.watch(delayTestingProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = (constraints.maxWidth / 176).floor().clamp(2, 8);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final name in group.all)
              SizedBox(
                width: width,
                child: _MemberTile(
                  name: name,
                  type: state.proxies[name]?.type ?? '',
                  delay: state.delayOf(name, url: group.testUrl),
                  selected: name == group.now,
                  testing: testing.contains(name),
                  onTap: group.isSelectable ? () => onSelect(name) : null,
                  onTest: () => onTest(name),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.name,
    required this.type,
    required this.delay,
    required this.selected,
    required this.testing,
    required this.onTap,
    required this.onTest,
  });

  final String name;
  final String type;
  final int? delay;
  final bool selected;
  final bool testing;
  final VoidCallback? onTap;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;

    // Long-press (touch) and right-click (mouse) both test this member.
    return GestureDetector(
      onSecondaryTapUp: (TapUpDetails _) => onTest(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(selected ? 24 : 14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: onTest,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: foreground,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: scheme.secondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (testing)
                        const SizedBox.square(
                          dimension: 16,
                          child: M3ELoadingIndicator(size: 16),
                        )
                      else
                        DelayLabel(
                          delay: delay,
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
