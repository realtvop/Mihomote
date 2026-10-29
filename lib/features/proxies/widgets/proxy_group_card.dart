import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../../../app/theme/semantic_colors.dart';
import '../../../core/mihomo/mihomo_api.dart';
import '../../../shared/l10n.dart';
import '../../../shared/widgets/status_views.dart';
import '../proxies_providers.dart';
import 'delay_label.dart';

/// One proxy group: its name and current selection while collapsed, a grid
/// of members while expanded.
class ProxyGroupCard extends ConsumerWidget {
  const ProxyGroupCard({super.key, required this.state, required this.group});

  final ProxiesState state;
  final ProxyNode group;

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

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) showErrorSnackbar(context, e);
      }
    }

    void toggle() =>
        ref.read(expandedGroupsProvider.notifier).toggle(group.name);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: M3ETheme.of(context).typography.emphasized.titleMedium,
                ),
                Text(
                  [
                    group.type,
                    l10n.proxiesNodeCount(group.all.length),
                    if (group.fixed != null) l10n.proxiesFixed,
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
          SizedBox.square(
            dimension: 48,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: testing
                    ? const M3ELoadingIndicator(size: 24)
                    : M3EIconButton(
                        icon: const Icon(Icons.speed_rounded),
                        variant: M3EIconButtonVariant.standard,
                        tooltip: l10n.proxiesTestLatency,
                        onPressed: () =>
                            run(() => notifier.testGroup(group.name)),
                      ),
              ),
            ),
          ),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.expand_more_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );

    // Built once per data change, not per animation frame: the motion
    // builder below only re-clips them.
    final summary = _Summary(state: state, group: group);
    final grid = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: _MemberGrid(
        state: state,
        group: group,
        onSelect: (name) => run(() => notifier.select(group.name, name)),
        onTest: (name) =>
            run(() => notifier.testNode(name, url: group.testUrl)),
      ),
    );

    return M3ECard(
      variant: M3ECardVariant.filled,
      color: scheme.card,
      borderRadius: BorderRadius.circular(28),
      padding: EdgeInsets.zero,
      child: SingleMotionBuilder(
        value: expanded ? 1 : 0,
        motion: const MaterialSpringMotion.standardSpatialDefault(),
        builder: (context, t, _) {
          final open = t.clamp(0.0, 1.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The header and the collapsed summary toggle the group
              // together; the outer card clips this pressable area's corners.
              M3ECard(
                variant: M3ECardVariant.filled,
                color: Colors.transparent,
                borderRadius: BorderRadius.zero,
                padding: EdgeInsets.zero,
                onPressed: toggle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    if (open < 0.999 || !expanded)
                      _Reveal(factor: 1 - open, child: summary),
                  ],
                ),
              ),
              if (open > 0.001 || expanded) _Reveal(factor: open, child: grid),
            ],
          );
        },
      ),
    );
  }
}

/// Shows the top [factor] of [child], fading with it.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.factor, required this.child});

  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: factor,
        child: Opacity(opacity: factor, child: child),
      ),
    );
  }
}

/// Collapsed body: just the current selection and its latency.
class _Summary extends StatelessWidget {
  const _Summary({required this.state, required this.group});

  final ProxiesState state;
  final ProxyNode group;

  @override
  Widget build(BuildContext context) {
    final now = group.now;
    if (now == null) return const SizedBox(width: double.infinity);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              now,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(width: 12),
          DelayLabel(delay: state.delayOf(now, url: group.testUrl)),
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
        final columns = (constraints.maxWidth / 180).floor().clamp(2, 8);
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
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final muted = selected
        ? scheme.onPrimaryContainer.withValues(alpha: 0.78)
        : scheme.onSurfaceVariant;

    // Long-press (touch) and right-click (mouse) both test this member.
    return GestureDetector(
      onSecondaryTapUp: (TapUpDetails _) => onTest(),
      child: M3ECard(
        variant: M3ECardVariant.filled,
        color: selected ? scheme.primaryContainer : scheme.cardInset,
        borderRadius: BorderRadius.circular(selected ? 22 : 14),
        animationDuration: const Duration(milliseconds: 250),
        animationCurve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        onPressed: onTap,
        onLongPress: onTest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ),
                if (testing)
                  const SizedBox.square(
                    dimension: 16,
                    child: M3ELoadingIndicator(size: 16),
                  )
                else if (selected)
                  // Colored text wouldn't read on the primary fill.
                  DelayBadge(
                    delay: delay,
                    color: muted,
                    style: theme.textTheme.labelSmall,
                  )
                else
                  DelayLabel(delay: delay, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
