import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'window_size_class.dart';

/// Horizontal padding that keeps content within [maxWidth] and centered,
/// with comfortable gutters on small screens.
EdgeInsets pageGutter(BuildContext context, {double maxWidth = 1200}) {
  final width = MediaQuery.sizeOf(context).width;
  final min = WindowSizeClass.fromWidth(width).isCompact ? 16.0 : 24.0;
  final side = math.max(min, (width - maxWidth) / 2);
  return EdgeInsets.symmetric(horizontal: side);
}
