import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/mihomo/mihomo_api.dart';
import '../../../shared/l10n.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/status_views.dart';
import '../proxies_providers.dart';
import 'expandable_card.dart';
import 'member_grid.dart';

/// One proxy provider: where it comes from and its subscription usage, with
/// its nodes and their latency when expanded.
class ProxyProviderCard extends ConsumerWidget {
  const ProxyProviderCard({
    super.key,
    required this.provider,
    required this.proxies,
  });

  final ProxyProvider provider;

  /// Delays come from here first, so single-node tests show up on both tabs;
  /// the provider's own node histories are the fallback.
  final ProxiesState? proxies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = provider.name;
    final expanded = ref.watch(
      expandedProxyProvidersProvider.select((s) => s.contains(name)),
    );
    final updating = ref.watch(
      updatingProxyProvidersProvider.select((s) => s.contains(name)),
    );
    final checking = ref.watch(
      checkingProxyProvidersProvider.select((s) => s.contains(name)),
    );
    final notifier = ref.read(proxyProvidersProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) showErrorSnackbar(context, e);
      }
    }

    final updatedAt = provider.updatedAt;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final subscription = provider.subscription;
    return ExpandableCard(
      title: name,
      subtitle: [
        provider.vehicleType,
        l10n.proxiesNodeCount(provider.proxies.length),
        if (updatedAt != null)
          l10n.providerUpdatedAt(
            DateFormat.yMd(locale).add_Hm().format(updatedAt.toLocal()),
          ),
      ].join(' · '),
      expanded: expanded,
      onToggle: () =>
          ref.read(expandedProxyProvidersProvider.notifier).toggle(name),
      actions: [
        ExpandableCardAction(
          icon: Icons.speed_rounded,
          tooltip: l10n.proxyProviderHealthCheck,
          busy: checking,
          onPressed: provider.proxies.isEmpty
              ? null
              : () => run(() => notifier.healthCheck(name)),
        ),
        // Only remote providers have anything to download.
        ExpandableCardAction(
          icon: Icons.sync_rounded,
          tooltip: l10n.actionUpdate,
          busy: updating,
          onPressed: provider.vehicleType == 'HTTP'
              ? () => run(() => notifier.updateProvider(name))
              : null,
        ),
      ],
      details: subscription == null || !_Usage.shows(subscription)
          ? null
          : _Usage(subscription: subscription),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: MemberGrid(
          members: [
            for (final node in provider.proxies)
              (
                name: node.name,
                type: node.type,
                delay:
                    proxies?.delayOf(node.name, url: provider.testUrl) ??
                    node.delayFor(provider.testUrl),
              ),
          ],
          onTest: (node) => run(
            () => ref
                .read(proxiesProvider.notifier)
                .testNode(node, url: provider.testUrl),
          ),
        ),
      ),
    );
  }
}

/// Traffic used out of the plan and when it expires.
class _Usage extends StatelessWidget {
  const _Usage({required this.subscription});

  final SubscriptionInfo subscription;

  /// Cores report all zeros when a provider sends no usage header.
  static bool shows(SubscriptionInfo info) =>
      info.total > 0 || info.upload + info.download > 0 || info.expire != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final used = subscription.upload + subscription.download;
    final total = subscription.total;
    final ratio = total > 0 ? (used / total).clamp(0.0, 1.0) : null;
    final expire = subscription.expire;
    final expired = expire != null && expire.isBefore(DateTime.now());
    final locale = Localizations.localeOf(context).toLanguageTag();
    final style = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ratio != null) ...[
            M3EProgressIndicator.linear(
              value: ratio,
              linearSize: M3EProgressIndicatorSize.s,
              // Nearly used up is worth flagging; otherwise stay quiet.
              color: ratio >= 0.9 ? scheme.error : null,
              semanticsLabel: l10n.proxyProviderTraffic(
                formatBytes(used),
                formatBytes(total),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  total > 0
                      ? l10n.proxyProviderTraffic(
                          formatBytes(used),
                          formatBytes(total),
                        )
                      : l10n.proxyProviderUsed(formatBytes(used)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              if (expire != null)
                Text(
                  expired
                      ? l10n.proxyProviderExpired
                      : l10n.proxyProviderExpires(
                          DateFormat.yMd(locale).format(expire.toLocal()),
                        ),
                  style: expired ? style?.copyWith(color: scheme.error) : style,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
