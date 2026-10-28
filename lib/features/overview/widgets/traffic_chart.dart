import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../app/theme/semantic_colors.dart';
import '../../../core/mihomo/mihomo_api.dart';
import '../../../shared/utils/format.dart';

/// Live download/upload area chart. Each new sample slides in from the right
/// over one second, and the vertical scale eases toward the new peak, so the
/// chart flows instead of jumping.
class TrafficChart extends StatefulWidget {
  const TrafficChart({
    super.key,
    required this.samples,
    required this.capacity,
  });

  final List<TrafficSample> samples;
  final int capacity;

  @override
  State<TrafficChart> createState() => _TrafficChartState();
}

class _TrafficChartState extends State<TrafficChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
    value: 1,
  );
  double _peakFrom = _minPeak;
  double _peakTo = _minPeak;

  static const _minPeak = 8.0 * 1024;

  double get _peak =>
      _peakFrom +
      (_peakTo - _peakFrom) * Curves.easeOutCubic.transform(_progress.value);

  @override
  void initState() {
    super.initState();
    _peakTo = _peakFrom = _targetPeak();
  }

  @override
  void didUpdateWidget(TrafficChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.samples, widget.samples) &&
        widget.samples.isNotEmpty) {
      _peakFrom = _peak;
      _peakTo = _targetPeak();
      _progress.forward(from: 0);
    }
  }

  double _targetPeak() {
    var peak = _minPeak;
    for (final s in widget.samples) {
      peak = math.max(peak, math.max(s.down, s.up).toDouble());
    }
    return peak * 1.2;
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _TrafficPainter(
            samples: widget.samples,
            capacity: widget.capacity,
            slide: _progress.value,
            peak: _peak,
            downColor: scheme.downloadColor,
            upColor: scheme.uploadColor,
            gridColor: scheme.outlineVariant.withValues(alpha: 0.6),
            labelStyle: theme.textTheme.labelSmall!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrafficPainter extends CustomPainter {
  _TrafficPainter({
    required this.samples,
    required this.capacity,
    required this.slide,
    required this.peak,
    required this.downColor,
    required this.upColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<TrafficSample> samples;
  final int capacity;
  final double slide;
  final double peak;
  final Color downColor;
  final Color upColor;
  final Color gridColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      _dashedLine(canvas, Offset(0, y), Offset(size.width, y), grid);
    }

    final label = TextPainter(
      text: TextSpan(text: formatSpeed(peak), style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, const Offset(0, 0));

    if (samples.length < 2) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _series(canvas, size, (s) => s.up, upColor);
    _series(canvas, size, (s) => s.down, downColor);
    canvas.restore();
  }

  void _series(
    Canvas canvas,
    Size size,
    int Function(TrafficSample) value,
    Color color,
  ) {
    final step = size.width / (capacity - 2);
    final points = <Offset>[
      for (var i = 0; i < samples.length; i++)
        Offset(
          size.width - (samples.length - 1 - i) * step + (1 - slide) * step,
          size.height -
              (value(samples[i]) / peak).clamp(0.0, 1.0) * size.height * 0.92,
        ),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final midX = (a.dx + b.dx) / 2;
      line.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.32),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 4.0, gap = 6.0;
    var x = from.dx;
    while (x < to.dx) {
      canvas.drawLine(
        Offset(x, from.dy),
        Offset(math.min(x + dash, to.dx), to.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_TrafficPainter old) =>
      !identical(old.samples, samples) ||
      old.slide != slide ||
      old.peak != peak ||
      old.downColor != downColor ||
      old.upColor != upColor;
}
