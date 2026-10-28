import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mihomo/json.dart';
import '../mihomo/mihomo_api.dart';
import '../mihomo/mihomo_client.dart';
import '../mihomo/mock/mock_mihomo_api.dart';
import '../storage/preferences.dart';
import 'backend_profile.dart';

@immutable
class BackendsState {
  const BackendsState({this.profiles = const [], this.activeId});

  final List<BackendProfile> profiles;
  final String? activeId;

  /// The selected profile, falling back to the first one.
  BackendProfile? get active =>
      profiles.where((p) => p.id == activeId).firstOrNull ??
      profiles.firstOrNull;
}

class BackendsNotifier extends Notifier<BackendsState> {
  static const _profilesKey = 'backends.profiles';
  static const _activeKey = 'backends.active';

  @override
  BackendsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    var profiles = <BackendProfile>[];
    final raw = prefs.getString(_profilesKey);
    if (raw != null) {
      try {
        profiles = readList(jsonDecode(raw))
            .map((e) => BackendProfile.fromJson(readMap(e)))
            .where((p) => p.id.isNotEmpty)
            .toList();
      } on FormatException catch (e) {
        debugPrint('Discarding corrupt backend list: $e');
      }
    }
    // The sample-data backend never survives into release builds.
    if (!kDebugMode) profiles.removeWhere((p) => p.isMock);
    return BackendsState(
      profiles: profiles,
      activeId: prefs.getString(_activeKey),
    );
  }

  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// Inserts or replaces [profile] (matched by id).
  Future<void> save(BackendProfile profile, {bool activate = false}) {
    final profiles = [...state.profiles];
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    return _commit(
      BackendsState(
        profiles: profiles,
        activeId: activate ? profile.id : state.activeId,
      ),
    );
  }

  Future<void> remove(String id) {
    final profiles = state.profiles.where((p) => p.id != id).toList();
    final activeId = state.activeId == id
        ? profiles.firstOrNull?.id
        : state.activeId;
    return _commit(BackendsState(profiles: profiles, activeId: activeId));
  }

  Future<void> activate(String id) =>
      _commit(BackendsState(profiles: state.profiles, activeId: id));

  Future<void> _commit(BackendsState next) async {
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _profilesKey,
      jsonEncode(next.profiles.map((p) => p.toJson()).toList()),
    );
    final activeId = next.active?.id;
    if (activeId == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, activeId);
    }
  }
}

final backendsProvider = NotifierProvider<BackendsNotifier, BackendsState>(
  BackendsNotifier.new,
);

final activeBackendProvider = Provider<BackendProfile?>(
  (ref) => ref.watch(backendsProvider.select((s) => s.active)),
);

/// The API for the active backend. Everything that talks to the core watches
/// this, so switching backends rebuilds dependents and closes old sockets.
final mihomoApiProvider = Provider<MihomoApi>((ref) {
  final backend = ref.watch(activeBackendProvider);
  if (backend == null) {
    throw const MihomoException(MihomoErrorKind.unknown, 'No backend selected');
  }
  final MihomoApi api;
  if (kDebugMode && backend.isMock) {
    api = MockMihomoApi();
  } else {
    final uri = backend.uri;
    if (uri == null) {
      throw const MihomoException(
        MihomoErrorKind.network,
        'Invalid controller URL',
      );
    }
    api = MihomoClient(baseUri: uri, secret: backend.secret);
  }
  ref.onDispose(api.close);
  return api;
});
