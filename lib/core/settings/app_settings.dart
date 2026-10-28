import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../storage/preferences.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.dynamicColor = true,
    this.seedColor,
    this.localeTag,
  });

  final ThemeMode themeMode;

  /// Follow the wallpaper / system accent where the platform supports it.
  final bool dynamicColor;

  /// `null` uses the brand default from `lib/app/theme/seed_colors.dart`.
  final Color? seedColor;

  /// `null` follows the system; otherwise a language code such as `zh`.
  final String? localeTag;

  Locale? get locale => localeTag == null ? null : Locale(localeTag!);
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _themeModeKey = 'settings.themeMode';
  static const _dynamicColorKey = 'settings.dynamicColor';
  static const _seedColorKey = 'settings.seedColor';
  static const _localeKey = 'settings.locale';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final seed = prefs.getInt(_seedColorKey);
    return AppSettings(
      themeMode:
          ThemeMode.values.asNameMap()[prefs.getString(_themeModeKey)] ??
          ThemeMode.system,
      dynamicColor: prefs.getBool(_dynamicColorKey) ?? true,
      seedColor: seed == null ? null : Color(seed),
      localeTag: prefs.getString(_localeKey),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AppSettings(
      themeMode: mode,
      dynamicColor: state.dynamicColor,
      seedColor: state.seedColor,
      localeTag: state.localeTag,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themeModeKey, mode.name);
  }

  Future<void> setDynamicColor(bool enabled) async {
    state = AppSettings(
      themeMode: state.themeMode,
      dynamicColor: enabled,
      seedColor: state.seedColor,
      localeTag: state.localeTag,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_dynamicColorKey, enabled);
  }

  Future<void> setSeedColor(Color color) async {
    state = AppSettings(
      themeMode: state.themeMode,
      dynamicColor: state.dynamicColor,
      seedColor: color,
      localeTag: state.localeTag,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_seedColorKey, color.toARGB32());
  }

  Future<void> setLocaleTag(String? tag) async {
    state = AppSettings(
      themeMode: state.themeMode,
      dynamicColor: state.dynamicColor,
      seedColor: state.seedColor,
      localeTag: tag,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    if (tag == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, tag);
    }
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
