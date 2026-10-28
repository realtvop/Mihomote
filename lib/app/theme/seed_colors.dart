import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Whether `dynamic_color` has a native implementation here (Android
/// wallpaper colors, or the desktop accent color). Not on iOS or the web.
bool get supportsDynamicColor =>
    !kIsWeb &&
    const {
      TargetPlatform.android,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    }.contains(defaultTargetPlatform);

/// Brand default used when dynamic color is off or unavailable.
const defaultSeedColor = Color(0xFF4F5BD5);

/// Presets offered in Settings → Appearance.
const seedColorPresets = <Color>[
  defaultSeedColor, // Indigo
  Color(0xFF00897B), // Teal
  Color(0xFF3F8F3A), // Green
  Color(0xFFC77700), // Amber
  Color(0xFFE0583A), // Coral
  Color(0xFFD13B7A), // Rose
  Color(0xFF8E4BC9), // Violet
  Color(0xFF5E7183), // Slate
];
