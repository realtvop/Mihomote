import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/mihomo_api.dart';
import '../../core/state/core_providers.dart';

/// A connection plus its speed since the previous snapshot.
@immutable
class ConnectionRow {
  const ConnectionRow({
    required this.connection,
    this.downSpeed = 0,
    this.upSpeed = 0,
  });

  final Connection connection;
  final int downSpeed;
  final int upSpeed;
}

@immutable
class ConnectionsState {
  const ConnectionsState({
    this.rows = const [],
    this.paused = false,
    this.loaded = false,
  });

  /// Newest first.
  final List<ConnectionRow> rows;
  final bool paused;

  /// False until the first snapshot arrives.
  final bool loaded;

  ConnectionsState copyWith({
    List<ConnectionRow>? rows,
    bool? paused,
    bool? loaded,
  }) => ConnectionsState(
    rows: rows ?? this.rows,
    paused: paused ?? this.paused,
    loaded: loaded ?? this.loaded,
  );
}

class ConnectionsNotifier extends Notifier<ConnectionsState> {
  Map<String, Connection> _previous = const {};
  DateTime? _previousAt;

  @override
  ConnectionsState build() {
    ref.watch(mihomoApiProvider);
    _previous = const {};
    _previousAt = null;
    ref.listen(connectionsStreamProvider, (_, next) {
      final snapshot = next.value;
      if (snapshot != null && !state.paused) {
        state = _apply(snapshot, paused: false);
      }
    });
    // Start from the latest snapshot if another page already subscribed.
    // (Reading `state` before build returns is an error, hence no
    // fireImmediately above.)
    final initial = ref.read(connectionsStreamProvider).value;
    return initial == null
        ? const ConnectionsState()
        : _apply(initial, paused: false);
  }

  ConnectionsState _apply(
    ConnectionsSnapshot snapshot, {
    required bool paused,
  }) {
    final now = DateTime.now();
    final seconds = _previousAt == null
        ? 1.0
        : math.max(0.25, now.difference(_previousAt!).inMilliseconds / 1000);
    int rate(int current, int? before) =>
        before == null ? 0 : (math.max(0, current - before) / seconds).round();

    final rows =
        [
          for (final c in snapshot.connections)
            ConnectionRow(
              connection: c,
              downSpeed: rate(c.download, _previous[c.id]?.download),
              upSpeed: rate(c.upload, _previous[c.id]?.upload),
            ),
        ]..sort(
          (a, b) =>
              (b.connection.start ?? now).compareTo(a.connection.start ?? now),
        );

    _previous = {for (final c in snapshot.connections) c.id: c};
    _previousAt = now;
    return ConnectionsState(rows: rows, paused: paused, loaded: true);
  }

  void togglePaused() => state = state.copyWith(paused: !state.paused);

  Future<void> close(String id) async {
    await ref.read(mihomoApiProvider).closeConnection(id);
    state = state.copyWith(
      rows: state.rows.where((r) => r.connection.id != id).toList(),
    );
  }

  Future<void> closeAll() async {
    await ref.read(mihomoApiProvider).closeAllConnections();
    state = state.copyWith(rows: const []);
  }
}

final connectionsProvider =
    NotifierProvider<ConnectionsNotifier, ConnectionsState>(
      ConnectionsNotifier.new,
    );
