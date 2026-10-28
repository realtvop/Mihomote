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
