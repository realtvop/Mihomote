import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/menu_bar/menu_bar_app.dart';
import 'app/menu_bar/menu_bar_data_host.dart';
import 'core/storage/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MenuBarDataHost(child: MihomoteApp()),
    ),
  );
}

/// Secondary Dart entrypoint for the native macOS status-item popover.
@pragma('vm:entry-point')
Future<void> menuBarMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MenuBarBootstrap(preferences: prefs),
    ),
  );
}
