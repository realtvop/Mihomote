import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/mihomo_api.dart';

/// Minimum level requested from the core; survives backend switches.
class LogLevelFilterNotifier extends Notifier<LogLevel> {
  @override
  LogLevel build() => LogLevel.info;

  void set(LogLevel level) => state = level;
}

final logLevelFilterProvider =
    NotifierProvider<LogLevelFilterNotifier, LogLevel>(
      LogLevelFilterNotifier.new,
    );

@immutable
class LogsState {
  const LogsState({this.entries = const [], this.paused = false, this.error});

  /// Newest first, capped at [LogsNotifier.capacity].
  final List<LogEntry> entries;
  final bool paused;
  final Object? error;
}

class LogsNotifier extends Notifier<LogsState> {
  static const capacity = 500;

  @override
  LogsState build() {
    final api = ref.watch(mihomoApiProvider);
    final level = ref.watch(logLevelFilterProvider);
    final subscription = api.logs(level: level).listen(
      (entry) {
        if (state.paused) return;
        final kept = state.entries.length >= capacity
            ? state.entries.sublist(0, capacity - 1)
            : state.entries;
        state = LogsState(entries: [entry, ...kept], paused: state.paused);
      },
      onError: (Object error) => state = LogsState(
        entries: state.entries,
        paused: state.paused,
        error: error,
      ),
    );
    ref.onDispose(subscription.cancel);
    return const LogsState();
  }

  void togglePaused() => state = LogsState(
    entries: state.entries,
    paused: !state.paused,
    error: state.error,
  );

  void clear() => state = LogsState(paused: state.paused);
}

final logsProvider = NotifierProvider<LogsNotifier, LogsState>(
  LogsNotifier.new,
);
