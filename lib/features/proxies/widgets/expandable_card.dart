import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../../../app/theme/semantic_colors.dart';
import '../../../shared/widgets/reveal.dart';

/// A card whose top area toggles a [body] that springs open below it.
///
/// The header shows [title], a muted [subtitle], [actions] and a chevron.
/// [details] stays under the header in both states; [summary] only while
/// collapsed. Pass widgets built once per data change: the motion builder
/// only re-clips them, so expanding never rebuilds a large body per frame.
class ExpandableCard extends StatelessWidget {
  const ExpandableCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.body,
    this.actions = const [],
    this.details,
    this.summary,
  });

  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget body;
  final List<Widget> actions;
  final Widget? details;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = this.summary;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: M3ETheme.of(context).typography.emphasized.titleMedium,
                ),
                // Two lines: on phones the update time of a provider would
                // otherwise be cut off next to the header actions.
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ...actions,
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
              // The whole top area toggles the card; the outer card clips
              // this pressable area's corners.
              M3ECard(
                variant: M3ECardVariant.filled,
                color: Colors.transparent,
                borderRadius: BorderRadius.zero,
                padding: EdgeInsets.zero,
                onPressed: onToggle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    ?details,
                    if (summary != null && (open < 0.999 || !expanded))
                      Reveal(factor: 1 - open, child: summary),
                  ],
                ),
              ),
              if (open > 0.001 || expanded) Reveal(factor: open, child: body),
            ],
          );
        },
      ),
    );
  }
}

/// A header action that turns into a loading indicator while [busy].
class ExpandableCardAction extends StatelessWidget {
  const ExpandableCardAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool busy;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: busy
              ? const M3ELoadingIndicator(size: 24)
              : M3EIconButton(
                  icon: Icon(icon),
                  variant: M3EIconButtonVariant.standard,
                  tooltip: tooltip,
                  onPressed: onPressed,
                ),
        ),
      ),
    );
  }
}
