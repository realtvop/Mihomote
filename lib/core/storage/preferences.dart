import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Created once in `main()` and injected via a `ProviderScope` override, so
/// reads stay synchronous everywhere else.
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) =>
      throw UnimplementedError('Override sharedPreferencesProvider in main()'),
);
