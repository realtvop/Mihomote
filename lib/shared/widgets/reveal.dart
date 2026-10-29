import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

/// Shows the top [factor] (0–1) of [child], fading with it. Drive [factor]
/// from a spring; [child] is laid out at full size, so build it once and
/// let only the clip change per frame.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.factor, required this.child});

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

/// Springs [child] open or closed from the top as [visible] changes.
class SpringReveal extends StatelessWidget {
  const SpringReveal({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      value: visible ? 1 : 0,
      motion: const MaterialSpringMotion.standardSpatialDefault(),
      child: child,
      builder: (context, t, child) {
        final factor = t.clamp(0.0, 1.0);
        if (factor <= 0.001 && !visible) {
          return const SizedBox(width: double.infinity);
        }
        return Reveal(factor: factor, child: child!);
      },
    );
  }
}
