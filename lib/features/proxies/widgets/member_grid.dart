import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/semantic_colors.dart';
import '../proxies_providers.dart';
import 'delay_label.dart';

/// A node shown in a [MemberGrid].
typedef ProxyMember = ({String name, String type, int? delay});

/// Nodes of a group or provider as tiles with their latency. Tapping picks
/// one when [onSelect] is set; long-press or right-click tests one.
class MemberGrid extends ConsumerWidget {
  const MemberGrid({
    super.key,
    required this.members,
    required this.onTest,
    this.selected,
    this.onSelect,
  });

  final List<ProxyMember> members;
  final ValueChanged<String> onTest;
  final String? selected;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testing = ref.watch(delayTestingProvider);
    final onSelect = this.onSelect;
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
            for (final member in members)
              SizedBox(
                width: width,
                child: _MemberTile(
                  member: member,
                  selected: member.name == selected,
                  testing: testing.contains(member.name),
                  onTap: onSelect == null ? null : () => onSelect(member.name),
                  onTest: () => onTest(member.name),
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
    required this.member,
    required this.selected,
    required this.testing,
    required this.onTap,
    required this.onTest,
  });

  final ProxyMember member;
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
              member.name,
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
                    member.type,
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
                    delay: member.delay,
                    color: muted,
                    style: theme.textTheme.labelSmall,
                  )
                else
                  DelayLabel(
                    delay: member.delay,
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
