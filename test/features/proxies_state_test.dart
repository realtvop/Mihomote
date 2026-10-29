import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mihomote/core/backends/backends_providers.dart';
import 'package:mihomote/core/mihomo/mock/mock_mihomo_api.dart';
import 'package:mihomote/features/proxies/proxies_providers.dart';

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [mihomoApiProvider.overrideWithValue(MockMihomoApi())],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('groups follow GLOBAL order, GLOBAL first, nodes excluded', () async {
    final api = MockMihomoApi();
    final state = ProxiesState.from(await api.proxies());

    expect(state.groupNames.first, 'GLOBAL');
    expect(state.groupNames[1], '🚀 节点选择');
    expect(state.groupNames, isNot(contains('DIRECT')));
    expect(state.groupNames, isNot(contains('🇭🇰 香港 01')));
    expect(state.groupNames.toSet().length, state.groupNames.length);
  });

  test('a group resolves its delay through nested selections', () async {
    final api = MockMihomoApi();
    final state = ProxiesState.from(await api.proxies());

    // 🚀 节点选择 → ♻️ 自动选择 → 🇭🇰 香港 03
    expect(state.delayOf('🚀 节点选择'), state.proxies['🇭🇰 香港 03']!.delayFor());
  });

  test('mock selection sticks and rejects unknown members', () async {
    final api = MockMihomoApi();
    await api.selectProxy('🚀 节点选择', 'DIRECT');
    expect((await api.proxies())['🚀 节点选择']!.now, 'DIRECT');
    expect(() => api.selectProxy('🚀 节点选择', 'nope'), throwsA(anything));
  });

  test('providers hide the core\'s inline provider', () async {
    final container = _container();
    final providers = await container.read(proxyProvidersProvider.future);
    expect(providers.map((p) => p.name), ['Subscription', 'Backup']);
  });

  test('a health check records delays and refreshes both tabs', () async {
    final container = _container();
    await container.read(proxiesProvider.future);
    final before = await container.read(proxyProvidersProvider.future);
    final node = before.last.proxies.first.name;
    final nodeBefore = container.read(proxiesProvider).value!.proxies[node]!;

    final check = container
        .read(proxyProvidersProvider.notifier)
        .healthCheck('Backup');
    expect(container.read(checkingProxyProvidersProvider), {'Backup'});
    await check;

    expect(container.read(checkingProxyProvidersProvider), isEmpty);
    final after = container.read(proxyProvidersProvider).value!;
    expect(
      after.last.proxies.first.history.length,
      before.last.proxies.first.history.length + 1,
    );
    expect(
      container.read(proxiesProvider).value!.proxies[node]!.history.length,
      nodeBefore.history.length + 1,
    );
  });

  test('updating a provider moves its update time', () async {
    final container = _container();
    await container.read(proxiesProvider.future);
    final before = await container.read(proxyProvidersProvider.future);
    await container
        .read(proxyProvidersProvider.notifier)
        .updateProvider('Subscription');
    final after = container.read(proxyProvidersProvider).value!;
    expect(after.first.updatedAt!.isAfter(before.first.updatedAt!), isTrue);
    expect(container.read(updatingProxyProvidersProvider), isEmpty);
  });
}
