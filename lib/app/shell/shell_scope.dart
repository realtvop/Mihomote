import 'package:flutter/widgets.dart';

import '../../shared/layout/window_size_class.dart';

/// What pages need to know about the navigation shell around them.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.sizeClass,
    required this.openSettings,
    this.leaveSettings,
    required super.child,
  });

  final WindowSizeClass sizeClass;
  final VoidCallback openSettings;

  /// Non-null when settings is shown full-screen (compact layout) and needs
  /// its own back button.
  final VoidCallback? leaveSettings;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      sizeClass != oldWidget.sizeClass ||
      (leaveSettings == null) != (oldWidget.leaveSettings == null);
}
