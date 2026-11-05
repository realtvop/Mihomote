import 'package:flutter/gestures.dart'
    show MultitouchDragStrategy, PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

/// Keeps mouse input wheel-driven while retaining drag scrolling for touch-like
/// devices.
///
/// Some descendant components add mouse to their local scroll configuration
/// through [copyWith]. Filtering it here also covers those local overrides.
class MihomoteScrollBehavior extends MaterialScrollBehavior {
  const MihomoteScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices =>
      super.dragDevices.difference(const {PointerDeviceKind.mouse});

  @override
  ScrollBehavior copyWith({
    bool? scrollbars,
    bool? overscroll,
    Set<PointerDeviceKind>? dragDevices,
    MultitouchDragStrategy? multitouchDragStrategy,
    Set<LogicalKeyboardKey>? pointerAxisModifiers,
    ScrollPhysics? physics,
    TargetPlatform? platform,
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior,
  }) {
    return super.copyWith(
      scrollbars: scrollbars,
      overscroll: overscroll,
      dragDevices: (dragDevices ?? this.dragDevices).difference(const {
        PointerDeviceKind.mouse,
      }),
      multitouchDragStrategy: multitouchDragStrategy,
      pointerAxisModifiers: pointerAxisModifiers,
      physics: physics,
      platform: platform,
      keyboardDismissBehavior: keyboardDismissBehavior,
    );
  }
}
