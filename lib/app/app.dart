import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/settings/app_settings.dart';
import '../shared/l10n.dart';
import 'router.dart';
import 'theme/fonts.dart';
import 'theme/seed_colors.dart';

/// Root widget.
///
/// Mirrors what `M3EMaterialApp` does (Material theme derived from
/// [M3EThemeData], plus an adaptive [M3ETheme] scope that applies brightness
/// and dynamic color) but on top of `MaterialApp.router`, which
/// `M3EMaterialApp` doesn't support. Re-check against `M3EMaterialApp` when
/// upgrading material_3_expressive.
class MihomoteApp extends ConsumerStatefulWidget {
  const MihomoteApp({super.key});

  @override
  ConsumerState<MihomoteApp> createState() => _MihomoteAppState();
}

class _MihomoteAppState extends ConsumerState<MihomoteApp> {
  Color? _seed;
  late M3EThemeData _data;
  late ThemeData _light;
  late ThemeData _dark;

  void _updateTheme(Color seed) {
    if (seed == _seed) return;
    _seed = seed;
    _data = M3EThemeData.light(seedColor: seed)
        .copyWith(fontFamilyFallback: appFontFamilyFallback);
    _light = _data.toThemeData();
    _dark = _data.deriveDarkTemplate().toThemeData();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);
    _updateTheme(settings.seedColor ?? defaultSeedColor);

    return MaterialApp.router(
      routerConfig: router,
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      // M3EResolvedTheme reads the parent Theme without depending on it, so
      // it would freeze on the first frame of an animated switch (dark cards
      // on a light scaffold). Switching instantly keeps them in sync.
      themeAnimationDuration: Duration.zero,
      theme: _light,
      darkTheme: _dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      // material_ui's delegates, not the framework ones that
      // AppLocalizations.localizationsDelegates would pull in (AGENTS.md §3.1).
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => M3ETheme(
        data: _data,
        autoTheming: settings.themeMode == ThemeMode.system,
        initialTheme: settings.themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light,
        dynamicColoring: settings.dynamicColor && supportsDynamicColor,
        child: _SystemBarsStyle(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Transparent system bars with icons that contrast the current theme.
class _SystemBarsStyle extends StatelessWidget {
  const _SystemBarsStyle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        systemNavigationBarIconBrightness: icons,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
