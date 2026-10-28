import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/mihomo_api.dart';

final rulesProvider = FutureProvider<List<Rule>>(
  (ref) => ref.watch(mihomoApiProvider).rules(),
);

class RuleProvidersNotifier extends AsyncNotifier<List<RuleProvider>> {
  @override
  Future<List<RuleProvider>> build() =>
      ref.watch(mihomoApiProvider).ruleProviders();

  Future<void> updateProvider(String name) async {
    final updating = ref.read(updatingRuleProvidersProvider.notifier);
    updating.add(name);
    try {
      final api = ref.read(mihomoApiProvider);
      await api.updateRuleProvider(name);
      state = AsyncData(await api.ruleProviders());
    } finally {
      updating.remove(name);
    }
  }
}

final ruleProvidersProvider =
    AsyncNotifierProvider<RuleProvidersNotifier, List<RuleProvider>>(
      RuleProvidersNotifier.new,
    );

class UpdatingSetNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String name) => state = {...state, name};

  void remove(String name) => state = {...state}..remove(name);
}

final updatingRuleProvidersProvider =
    NotifierProvider<UpdatingSetNotifier, Set<String>>(UpdatingSetNotifier.new);
