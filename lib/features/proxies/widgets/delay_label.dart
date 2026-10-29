import 'package:material_ui/material_ui.dart';

import '../../../app/theme/semantic_colors.dart';
import '../../../shared/l10n.dart';

String _delayText(BuildContext context, int? delay) =>
    switch (DelayQuality.of(delay)) {
      DelayQuality.untested => '—',
      DelayQuality.failed => context.l10n.proxiesTimeout,
      _ => '$delay ms',
    };

/// Colored latency text; color is never the only signal (the number or
/// "Timeout" is always shown).
class DelayLabel extends StatelessWidget {
  const DelayLabel({super.key, required this.delay, this.style});

  final int? delay;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme
        .delayColor(DelayQuality.of(delay));
    return Text(
      _delayText(context, delay),
      maxLines: 1,
      style: (style ?? Theme.of(context).textTheme.labelMedium)?.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// A latency dot followed by the latency, for use on colored containers
/// where colored text wouldn't read: only the dot carries the color.
class DelayBadge extends StatelessWidget {
  const DelayBadge({
    super.key,
    required this.delay,
    required this.color,
    this.style,
  });

  final int? delay;

  /// Text color.
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DelayDot(delay: delay),
        const SizedBox(width: 6),
        Text(
          _delayText(context, delay),
          maxLines: 1,
          style: (style ?? Theme.of(context).textTheme.labelMedium)?.copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A small dot in the latency color.
class DelayDot extends StatelessWidget {
  const DelayDot({super.key, required this.delay, this.size = 8});

  final int? delay;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quality = DelayQuality.of(delay);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Untested stays quiet instead of reading as near-black.
        color: quality == DelayQuality.untested
            ? scheme.outlineVariant
            : scheme.delayColor(quality),
        shape: BoxShape.circle,
      ),
    );
  }
}
