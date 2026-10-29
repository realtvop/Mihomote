import 'package:material_3_expressive/material_3_expressive.dart';

/// Bundled brand typeface (assets/fonts/GoogleSansFlex.ttf, OFL).
///
/// The asset is a Latin subset with the `wght`, `opsz` and `ROND` axes only
/// (slant and width pinned) to keep the web download small; see AGENTS.md
/// §6.3 for how it was cut. Everything else falls back below.
const appFontFamily = 'Google Sans Flex';

/// CJK and emoji fallbacks applied to every text style.
///
/// Without these, iOS (seen on the iOS 26 simulator) renders Han characters
/// and emoji from proxy names as LastResort boxes. Families that aren't
/// installed are skipped, so one list serves every platform; the web build
/// still downloads Noto fallbacks on its own.
const appFontFamilyFallback = <String>[
  'PingFang SC',
  'Microsoft YaHei',
  'Noto Sans CJK SC',
  'Noto Sans SC',
  'Apple Color Emoji',
  'Segoe UI Emoji',
  'Noto Color Emoji',
];

/// Per-role axes: optical size follows each role's size, and display,
/// headline and title roles get slightly rounded terminals.
///
/// `wght` is left out on purpose: every Flutter renderer (Skia, CanvasKit,
/// skwasm) sets the axis from `fontWeight` unless a style pins it, so any
/// `copyWith(fontWeight: …)`, including inside M3E components, just works.
const appVariableFont = M3EVariableFontConfig(
  syncWghtToWeight: false,
  rond: 40,
);
