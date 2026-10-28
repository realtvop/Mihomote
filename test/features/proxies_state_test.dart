import 'package:flutter_test/flutter_test.dart';
import 'package:mihomote/core/mihomo/mock/mock_mihomo_api.dart';
import 'package:mihomote/features/proxies/proxies_providers.dart';

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
}
