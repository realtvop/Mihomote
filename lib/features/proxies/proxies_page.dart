import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/page_scaffold.dart';
import '../../core/mihomo/mihomo_api.dart';
import '../../core/state/core_providers.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/page_padding.dart';
import '../../shared/widgets/reveal.dart';
import '../../shared/widgets/status_views.dart';
import 'proxies_providers.dart';
import 'widgets/proxy_group_card.dart';
import 'widgets/proxy_provider_card.dart';

enum _ProxiesTab { groups, providers }

class ProxiesPage extends ConsumerStatefulWidget {
  const ProxiesPage({super.key});

  @override
  ConsumerState<ProxiesPage> createState() => _ProxiesPageState();
}

class _ProxiesPageState extends ConsumerState<ProxiesPage> {
  _ProxiesTab _tab = _ProxiesTab.groups;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final proxies = ref.watch(proxiesProvider);
    // Many configs have no providers; then there is nothing to switch to.
    final providers = ref.watch(proxyProvidersProvider).value ?? const [];
    final tab = providers.isEmpty ? _ProxiesTab.groups : _tab;
    // GLOBAL only matters (and is only shown) in global mode.
    final globalMode = ref.watch(
      coreConfigProvider.select((c) => c.value?.mode == TunnelMode.global),
    );

    final groupCount = proxies.value?.groupNames
        .where((name) => name != 'GLOBAL' || globalMode)
        .length;
    return PageScaffold(
      title: l10n.navProxies,
      subtitle: switch (tab) {
        _ProxiesTab.groups =>
          groupCount == null ? null : l10n.proxiesGroupCount(groupCount),
        _ProxiesTab.providers => l10n.proxyProvidersCount(providers.length),
      },
      onRefresh: () => switch (tab) {
        _ProxiesTab.groups => ref.read(proxiesProvider.notifier).reload(),
        _ProxiesTab.providers =>
          ref.read(proxyProvidersProvider.notifier).reload(),
      },
      slivers: [
        SliverToBoxAdapter(
          // Springs in when providers arrive instead of shoving the list.
          child: SpringReveal(
            visible: providers.isNotEmpty,
            child: Padding(
              padding: pageGutter(context).copyWith(top: 4, bottom: 4),
              child: M3EButtonGroup(
                type: M3EButtonGroupType.connected,
                selectionRequired: true,
                actions: [
                  M3EButtonGroupAction(label: Text(l10n.proxiesTabGroups)),
                  M3EButtonGroupAction(label: Text(l10n.proxiesTabProviders)),
                ],
                selectedIndex: tab.index,
                onSelectedIndexChanged: (index) {
                  if (index == null) return;
                  setState(() => _tab = _ProxiesTab.values[index]);
                },
              ),
            ),
          ),
        ),
        switch (tab) {
          _ProxiesTab.groups => switch (proxies) {
            AsyncData(:final value) => _groups(context, value, globalMode),
            AsyncError(:final error) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                error: error,
                onRetry: () => ref.invalidate(proxiesProvider),
              ),
            ),
            _ => const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingView(),
            ),
          },
          _ProxiesTab.providers => _cards(
            context,
            itemCount: providers.length,
            itemBuilder: (context, index) => ProxyProviderCard(
              provider: providers[index],
              proxies: proxies.value,
            ),
          ),
        },
      ],
    );
  }

  Widget _groups(BuildContext context, ProxiesState state, bool globalMode) {
    final groups = [
      for (final name in state.groupNames)
        if (name != 'GLOBAL' || globalMode) state.proxies[name]!,
    ];
    if (groups.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          message: context.l10n.proxiesEmpty,
          icon: Icons.hub_outlined,
        ),
      );
    }
    return _cards(
      context,
      itemCount: groups.length,
      itemBuilder: (context, index) =>
          ProxyGroupCard(state: state, group: groups[index]),
    );
  }

  Widget _cards(
    BuildContext context, {
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
  }) {
    return SliverPadding(
      padding: pageGutter(context).copyWith(top: 8),
      sliver: SliverList.separated(
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
