import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

/// Latency buckets shared by every place that shows a delay.
enum DelayQuality {
  untested,
  good,
  fair,
  poor,
  failed;

  static DelayQuality of(int? delay) => switch (delay) {
    null => untested,
    <= 0 => failed,
    < 200 => good,
    < 500 => fair,
    _ => poor,
  };
}

/// Semantic colors that the Material color roles don't cover. Fixed hues are
/// harmonized toward the current primary so they sit well in any scheme.
extension SemanticColors on ColorScheme {
  bool get _dark => brightness == Brightness.dark;

  /// Page background. Light mode tints it so white [card]s stand out; dark
  /// mode keeps the darkest surface so cards read as raised.
  Color get canvas => _dark ? surface : surfaceContainer;

  /// Cards and list rows on the [canvas].
  Color get card => _dark ? surfaceContainer : surfaceContainerLowest;

  /// Tiles and wells nested inside a [card].
  Color get cardInset => _dark ? surfaceContainerHigh : surfaceContainerLow;

  Color get success =>
      (_dark ? const Color(0xFF7DDB95) : const Color(0xFF2E8B47)).harmonizeWith(
        primary,
      );

  Color get warning =>
      (_dark ? const Color(0xFFF2C46B) : const Color(0xFF9A6700)).harmonizeWith(
        primary,
      );

  Color delayColor(DelayQuality quality) => switch (quality) {
    DelayQuality.good => success,
    DelayQuality.fair => warning,
    DelayQuality.poor => error,
    DelayQuality.failed => outline,
    DelayQuality.untested => onSurfaceVariant,
  };
}
