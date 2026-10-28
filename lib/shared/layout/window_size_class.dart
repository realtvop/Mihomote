import 'package:flutter/widgets.dart';

/// Material 3 window size classes. The only place breakpoints are defined;
/// layouts depend on available width, never on the platform.
enum WindowSizeClass {
  /// < 600: phones in portrait, narrow desktop windows.
  compact,

  /// 600–839: tablets in portrait, foldables, half-screen windows.
  medium,

  /// ≥ 840: tablets in landscape, desktops, browsers.
  expanded;

  static WindowSizeClass fromWidth(double width) => switch (width) {
    < 600 => compact,
    < 840 => medium,
    _ => expanded,
  };

  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == compact;

  bool get isExpanded => this == expanded;
}
