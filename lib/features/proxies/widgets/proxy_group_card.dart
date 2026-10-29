import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/mihomo/mihomo_api.dart';
import '../../../shared/l10n.dart';
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
          onPressed: () => run(() => notifier.testGroup(group.name)),
        ),
      ],
      summary: _Summary(state: state, group: group),
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
              ? (name) => run(() => notifier.select(group.name, name))
              : null,
          onTest: (name) =>
              run(() => notifier.testNode(name, url: group.testUrl)),
        ),
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
