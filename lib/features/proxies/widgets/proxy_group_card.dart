import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/mihomo/mihomo_api.dart';
import '../../../shared/l10n.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/status_views.dart';
import '../proxies_providers.dart';
import 'delay_label.dart';
import 'expandable_card.dart';
import 'member_grid.dart';

/// One proxy group: its name and current selection while collapsed, a grid
/// of members while expanded.
class ProxyGroupCard extends ConsumerWidget {
  const ProxyGroupCard({super.key, required this.state, required this.group});

  final ProxiesState state;
  final ProxyNode group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final expanded = ref.watch(
      expandedGroupsProvider.select((s) => s.contains(group.name)),
    );
    final testing = ref.watch(
      delayTestingViewProvider.select((s) => s.contains(group.name)),
    );
    final traffic = ref.watch(
      proxyGroupTrafficViewProvider.select(
        (traffic) => traffic[group.name] ?? const ProxyGroupTraffic(),
      ),
    );
    final actions = ref.read(proxyActionsProvider);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) showErrorSnackbar(context, e);
      }
    }

    return ExpandableCard(
      title: group.name,
      subtitle: [
        group.type,
        l10n.proxiesNodeCount(group.all.length),
        if (group.fixed != null) l10n.proxiesFixed,
      ].join(' · '),
      expanded: expanded,
      onToggle: () =>
          ref.read(expandedGroupsProvider.notifier).toggle(group.name),
      actions: [
        ExpandableCardAction(
          icon: Icons.speed_rounded,
          tooltip: l10n.proxiesTestLatency,
          busy: testing,
          onPressed: () => run(() => actions.testGroup(group.name)),
        ),
      ],
      details: _Summary(state: state, group: group, traffic: traffic),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: MemberGrid(
          members: [
            for (final name in group.all)
              (
                name: name,
                type: state.proxies[name]?.type ?? '',
                delay: state.delayOf(name, url: group.testUrl),
              ),
          ],
          selected: group.now,
          onSelect: group.isSelectable
              ? (name) => run(() => actions.select(group.name, name))
              : null,
          onTest: (name) =>
              run(() => actions.testNode(name, url: group.testUrl)),
        ),
      ),
    );
  }
}

/// Current selection, live group traffic and latency.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.state,
    required this.group,
    required this.traffic,
  });

  final ProxiesState state;
  final ProxyNode group;
  final ProxyGroupTraffic traffic;

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
          const SizedBox(width: 8),
          _GroupTraffic(traffic: traffic),
          const SizedBox(width: 10),
          DelayLabel(delay: state.delayOf(now, url: group.testUrl)),
        ],
      ),
    );
  }
}

class _GroupTraffic extends StatelessWidget {
  const _GroupTraffic({required this.traffic});

  final ProxyGroupTraffic traffic;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _TrafficValue(
          icon: Icons.arrow_downward_rounded,
          semanticLabel: l10n.overviewDownload,
          value: formatSpeed(traffic.down),
          style: style,
        ),
        _TrafficValue(
          icon: Icons.arrow_upward_rounded,
          semanticLabel: l10n.overviewUpload,
          value: formatSpeed(traffic.up),
          style: style,
        ),
      ],
    );
  }
}

class _TrafficValue extends StatelessWidget {
  const _TrafficValue({
    required this.icon,
    required this.semanticLabel,
    required this.value,
    required this.style,
  });

  final IconData icon;
  final String semanticLabel;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: style?.color, semanticLabel: semanticLabel),
        const SizedBox(width: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 76),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
