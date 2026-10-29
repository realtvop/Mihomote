import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/page_scaffold.dart';
import '../../core/mihomo/mihomo_api.dart';
import '../../core/state/core_providers.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/page_padding.dart';
import '../../shared/widgets/status_views.dart';
import 'proxies_providers.dart';
import 'widgets/proxy_group_card.dart';

class ProxiesPage extends ConsumerWidget {
  const ProxiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final proxies = ref.watch(proxiesProvider);
    // GLOBAL only matters (and is only shown) in global mode.
    final globalMode = ref.watch(
      coreConfigProvider.select((c) => c.value?.mode == TunnelMode.global),
    );

    final groupCount = proxies.value?.groupNames
        .where((name) => name != 'GLOBAL' || globalMode)
        .length;
    return PageScaffold(
      title: l10n.navProxies,
      subtitle: groupCount == null ? null : l10n.proxiesGroupCount(groupCount),
      onRefresh: () => ref.read(proxiesProvider.notifier).reload(),
      slivers: [
        switch (proxies) {
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
    return SliverPadding(
      padding: pageGutter(context).copyWith(top: 8),
      sliver: SliverList.separated(
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            ProxyGroupCard(state: state, group: groups[index]),
      ),
    );
  }
}
