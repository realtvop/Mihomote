import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/page_scaffold.dart';
import '../../app/theme/semantic_colors.dart';
import '../../core/state/core_providers.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/page_padding.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/status_views.dart';
import 'connections_providers.dart';

class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({super.key});

  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  String _query = '';

  bool _matches(ConnectionRow row) {
    if (_query.isEmpty) return true;
    final c = row.connection;
    final m = c.metadata;
    return [
      m.host,
      m.sniffHost,
      m.destinationIp,
      m.sourceIp,
      m.process,
      c.rule,
      c.rulePayload,
      ...c.chains,
    ].any((field) => field.toLowerCase().contains(_query));
  }

  Future<void> _closeAll(int count) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.connectionsCloseAllConfirm(count)),
        actions: [
          M3EButton.text(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          M3EButton.filled(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.connectionsCloseAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(connectionsProvider.notifier).closeAll();
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(connectionsProvider);
    final stream = ref.watch(connectionsStreamProvider);
    final rows = state.rows.where(_matches).toList();

    final Widget content;
    if (!state.loaded) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: stream.hasError
            ? ErrorView(
                error: stream.error!,
                onRetry: () => ref.invalidate(connectionsStreamProvider),
              )
            : const LoadingView(),
      );
    } else if (rows.isEmpty) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          message: state.rows.isEmpty
              ? l10n.connectionsEmpty
              : l10n.searchNoResults,
          icon: Icons.swap_vert_rounded,
        ),
      );
    } else {
      content = SliverPadding(
        padding: pageGutter(context),
        sliver: M3EList.sliver(
          itemCount: rows.length,
          itemBuilder: (context, index) => _ConnectionItem(row: rows[index]),
        ),
      );
    }

    return PageScaffold(
      title: l10n.navConnections,
      actions: [
        M3EIconButton(
          icon: Icon(
            state.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          ),
          variant: M3EIconButtonVariant.standard,
          tooltip: state.paused ? l10n.actionResume : l10n.actionPause,
          onPressed: ref.read(connectionsProvider.notifier).togglePaused,
        ),
        M3EIconButton(
          icon: const Icon(Icons.clear_all_rounded),
          variant: M3EIconButtonVariant.standard,
          tooltip: l10n.connectionsCloseAll,
          onPressed: state.rows.isEmpty
              ? null
              : () => _closeAll(state.rows.length),
        ),
      ],
      slivers: [
        SliverPadding(
          padding: pageGutter(context).copyWith(top: 4, bottom: 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchField(
                  hint: l10n.connectionsSearchHint,
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    l10n.connectionsCount(state.rows.length),
                    if (state.paused) l10n.connectionsPaused,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        content,
      ],
    );
  }
}

class _ConnectionItem extends StatelessWidget {
  const _ConnectionItem({required this.row});

  final ConnectionRow row;

  @override
  Widget build(BuildContext context) {
    final c = row.connection;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const tabular = [FontFeature.tabularFigures()];
    final udp = c.metadata.network.toLowerCase() == 'udp';

    return M3EListItem(
      headline: c.metadata.displayHost,
      supportingText: [
        c.chainLabel,
        c.ruleLabel,
        if (c.metadata.process.isNotEmpty) c.metadata.process,
      ].join(' · '),
      leading: M3EShapeContainer(
        kind: udp ? M3EShapeKind.pill : M3EShapeKind.cookie4Sided,
        width: 40,
        height: 40,
        color: udp ? scheme.tertiaryContainer : scheme.secondaryContainer,
        child: Center(
          child: Text(
            c.metadata.network.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: udp
                  ? scheme.onTertiaryContainer
                  : scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '↓ ${formatSpeed(row.downSpeed)}',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.downloadColor,
              fontFeatures: tabular,
            ),
          ),
          Text(
            '↑ ${formatSpeed(row.upSpeed)}',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.uploadColor,
              fontFeatures: tabular,
            ),
          ),
        ],
      ),
      onTap: () => _showDetails(context, row),
    );
  }
}

void _showDetails(BuildContext context, ConnectionRow row) {
  final l10n = context.l10n;
  M3EBottomSheet.showAdaptive<void>(
    context,
    title: l10n.connectionDetails,
    builder: (sheetContext) => _ConnectionDetails(row: row),
  );
}

class _ConnectionDetails extends ConsumerWidget {
  const _ConnectionDetails({required this.row});

  final ConnectionRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = row.connection;
    final m = c.metadata;
    final start = c.start;
    final entries = <(String, String)>[
      (l10n.connectionHost, m.displayHost),
      (l10n.connectionDestination, m.destination),
      (l10n.connectionSource, m.source),
      (l10n.connectionNetwork, '${m.network.toUpperCase()} · ${m.type}'),
      if (m.inboundName.isNotEmpty) (l10n.connectionInbound, m.inboundName),
      (l10n.connectionRule, c.ruleLabel),
      (l10n.connectionChains, c.chainLabel),
      if (m.process.isNotEmpty)
        (
          l10n.connectionProcess,
          m.processPath.isEmpty ? m.process : m.processPath,
        ),
      if (start != null)
        (
          l10n.connectionDuration,
          formatDuration(l10n, DateTime.now().difference(start)),
        ),
      (
        l10n.connectionTraffic,
        '↓ ${formatBytes(c.download)}  ↑ ${formatBytes(c.upload)}',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value) in entries)
            _DetailRow(label: label, value: value),
          const SizedBox(height: 16),
          M3EButton.tonal(
            onPressed: () async {
              try {
                await ref.read(connectionsProvider.notifier).close(c.id);
                if (context.mounted) Navigator.of(context).maybePop();
              } catch (e) {
                if (context.mounted) showErrorSnackbar(context, e);
              }
            },
            icon: const Icon(Icons.link_off_rounded),
            label: Text(l10n.connectionsClose),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) {
          M3ESnackbar.show(context, message: context.l10n.actionCopied);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            SelectableText(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
