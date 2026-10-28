import 'package:material_ui/material_ui.dart';

import '../../../app/theme/semantic_colors.dart';
import '../../../shared/l10n.dart';

/// Colored latency text; color is never the only signal (the number or
/// "Timeout" is always shown).
class DelayLabel extends StatelessWidget {
  const DelayLabel({super.key, required this.delay, this.style});

  final int? delay;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final quality = DelayQuality.of(delay);
    final color = Theme.of(context).colorScheme.delayColor(quality);
    final text = switch (quality) {
      DelayQuality.untested => '—',
      DelayQuality.failed => context.l10n.proxiesTimeout,
      _ => '$delay ms',
    };
    return Text(
      text,
      maxLines: 1,
      style: (style ?? Theme.of(context).textTheme.labelMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// A small dot in the latency color, for compact previews.
class DelayDot extends StatelessWidget {
  const DelayDot({super.key, required this.delay, this.selected = false});

  final int? delay;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.delayColor(DelayQuality.of(delay));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: selected ? 18 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
