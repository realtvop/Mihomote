import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/mihomo_api.dart';
import '../../core/state/core_providers.dart';

/// The last [capacity] traffic ticks for the live chart, padded with zeros so
/// the chart spans its full width from the first second. Resets when the
/// backend changes.
class TrafficHistoryNotifier extends Notifier<List<TrafficSample>> {
  static const capacity = 60;

  @override
  List<TrafficSample> build() {
    ref.watch(mihomoApiProvider);
    ref.listen(trafficProvider, (_, next) {
      final sample = next.value;
      if (sample == null) return;
      state = [...state.skip(state.length - capacity + 1), sample];
    });
    return List.filled(capacity, TrafficSample.zero);
  }
}

final trafficHistoryProvider =
    NotifierProvider<TrafficHistoryNotifier, List<TrafficSample>>(
      TrafficHistoryNotifier.new,
    );
