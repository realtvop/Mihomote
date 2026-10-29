import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'fonts.dart';
import 'semantic_colors.dart';

/// Fidelity keeps the primary container at the seed color itself, which gives
/// the bold hero blocks (overview traffic, selected proxies) and makes a
/// picked seed look like what was picked. Tonal spot, the framework default,
/// washed everything out to grey.
const _schemeVariant = DynamicSchemeVariant.fidelity;

/// Light and dark themes generated from one seed color.
///
/// Both brightnesses are generated here from the same seed and variant.
/// `M3ETheme` would instead derive dark from the light primary with the
/// default variant, so Material and M3E widgets would disagree in dark mode.
@immutable
class AppTheme {
  factory AppTheme.fromSeed(Color seed) {
    ColorScheme scheme(Brightness brightness) => ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: _schemeVariant,
    );
    final light = scheme(Brightness.light);
    final dark = scheme(Brightness.dark);
    return AppTheme._(
      _data(light),
      _data(dark),
      AppColors._resolve(light, light: light, dark: dark),
      AppColors._resolve(dark, light: light, dark: dark),
    );
  }

  AppTheme._(this.light, this.dark, AppColors lightColors, AppColors darkColors)
    : lightMaterial = _material(light, lightColors),
      darkMaterial = _material(dark, darkColors);

  final M3EThemeData light;
  final M3EThemeData dark;
  final ThemeData lightMaterial;
  final ThemeData darkMaterial;

  M3EThemeData of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The themes [t] of the way from light (0) to dark (1), both derived from
  /// one lerped color scheme so Material and M3E widgets stay in step.
  (ThemeData, M3EThemeData) lerp(double t) {
    final material = ThemeData.lerp(lightMaterial, darkMaterial, t);
    final expressive = (t < 0.5 ? light : dark).withColorScheme(
      M3EColorScheme.fromColorScheme(material.colorScheme).harmonized(),
    );
    return (material, expressive);
  }

  static M3EThemeData _data(ColorScheme scheme) {
    final data = M3EThemeData(
      colorScheme: M3EColorScheme.fromColorScheme(scheme).harmonized(),
      typography: M3ETypography.material3(mode: M3ETypeScaleMode.variable),
    );
    return data.copyWith(
      fontFamily: appFontFamily,
      fontFamilyFallback: appFontFamilyFallback,
      variableFont: appVariableFont,
      navigationRailTheme: data.navigationRailTheme.copyWith(
        containerColor: scheme.canvas,
      ),
      // Zero tracking like the rest of the variable type scale. With the
      // default 0.5, "Connections" is clipped in a five-item bar on a 400dp
      // phone (Google Sans Flex runs wider than Roboto).
      navigationBarTheme: data.navigationBarTheme.copyWith(
        labelLetterSpacing: 0,
      ),
    );
  }

  static ThemeData _material(M3EThemeData data, AppColors colors) {
    final material = data.toThemeData();
    return material.copyWith(
      scaffoldBackgroundColor: material.colorScheme.canvas,
      dividerColor: material.colorScheme.outlineVariant,
      extensions: [colors],
    );
  }
}

/// Colors that need both brightnesses of the palette to resolve.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.heroAccent});

  /// Picks the tertiary tone that reads on [ColorScheme.primaryContainer]:
  /// fidelity keeps that container at the seed's own tone, so whether it
  /// needs a light or a dark accent depends on the seed, not the brightness.
  factory AppColors._resolve(
    ColorScheme scheme, {
    required ColorScheme light,
    required ColorScheme dark,
  }) {
    final lightContent = scheme.onPrimaryContainer.computeLuminance() > 0.4;
    return AppColors(heroAccent: lightContent ? dark.tertiary : light.tertiary);
  }

  /// Second series and highlights on a primary-container hero.
  final Color heroAccent;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({Color? heroAccent}) =>
      AppColors(heroAccent: heroAccent ?? this.heroAccent);

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(heroAccent: Color.lerp(heroAccent, other.heroAccent, t)!);
}
