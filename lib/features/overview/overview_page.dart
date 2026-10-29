import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/page_scaffold.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/semantic_colors.dart';
import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/mihomo_api.dart';
import '../../core/state/core_providers.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/equal_height_row.dart';
import '../../shared/layout/page_padding.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/status_views.dart';
import 'overview_providers.dart';
import 'widgets/traffic_chart.dart';

const _gap = 12.0;
const _tabular = [FontFeature.tabularFigures()];

/// Live status first (traffic, totals), controls below (mode, core actions).
///
/// Deliberately quiet: the traffic card is the only colored block, every
/// other card is plain text on the card surface.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(activeBackendProvider);
    return PageScaffold(
      title: context.l10n.navOverview,
      subtitle: backend?.name,
      onRefresh: () async {
        ref.invalidate(versionProvider);
        ref.invalidate(coreConfigProvider);
        await ref.read(coreConfigProvider.future);
      },
      slivers: [
        SliverPadding(
          padding: pageGutter(context).copyWith(top: 8),
          sliver: SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                if (width >= 840) {
                  return const Column(
                    children: [
                      EqualHeightRow(
                        spacing: _gap,
                        flex: [3, 2],
                        children: [
                          _TrafficCard(large: true),
                          _StatsCard(columns: 2),
                        ],
                      ),
                      SizedBox(height: _gap),
                      EqualHeightRow(
                        spacing: _gap,
                        flex: [2, 3],
                        children: [_ModeCard(), _CoreCard()],
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    const _TrafficCard(large: false),
                    const SizedBox(height: _gap),
                    _StatsCard(columns: width >= 600 ? 4 : 2),
                    const SizedBox(height: _gap),
                    if (width >= 600)
                      const EqualHeightRow(
                        spacing: _gap,
                        children: [_ModeCard(), _CoreCard()],
                      )
                    else ...const [
                      _ModeCard(),
                      SizedBox(height: _gap),
                      _CoreCard(),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Plain card on the page canvas. Its content is laid out top to bottom and
/// spread out per [alignment] when [EqualHeightRow] stretches the card.
class _Card extends StatelessWidget {
  const _Card({
    required this.children,
    this.alignment = MainAxisAlignment.spaceBetween,
  });

  final List<Widget> children;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Card title with optional muted subtitle and trailing text.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: M3ETheme.of(context).typography.emphasized.titleMedium,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  trailing!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted?.copyWith(fontFeatures: _tabular),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
      ],
    );
  }
}

/// The page's one colored block: live speeds over an edge-to-edge chart.
class _TrafficCard extends ConsumerWidget {
  const _TrafficCard({required this.large});

  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onCard = scheme.onPrimaryContainer;
    final accent = AppColors.of(context).heroAccent;
    final samples = ref.watch(trafficHistoryProvider);
    final traffic = ref.watch(trafficProvider);
    final latest = samples.last;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: scheme.primaryContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: _SpeedReadout(
                      icon: Icons.south_rounded,
                      label: l10n.overviewDownload,
                      bytesPerSecond: latest.down,
                      color: onCard,
                      arrowColor: onCard,
                      size: large ? _ReadoutSize.hero : _ReadoutSize.large,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    flex: 2,
                    child: _SpeedReadout(
                      icon: Icons.north_rounded,
                      label: l10n.overviewUpload,
                      bytesPerSecond: latest.up,
                      color: onCard,
                      arrowColor: accent,
                      size: _ReadoutSize.small,
                      end: true,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: large ? 150 : 112,
              child: traffic.hasError && !traffic.hasValue
                  ? Center(
                      child: Text(
                        describeError(l10n, traffic.error!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onCard,
                        ),
                      ),
                    )
                  : TrafficChart(
                      samples: samples,
                      capacity: TrafficHistoryNotifier.capacity,
                      downColor: onCard,
                      upColor: accent,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReadoutSize { hero, large, small }

class _SpeedReadout extends StatelessWidget {
  const _SpeedReadout({
    required this.icon,
    required this.label,
    required this.bytesPerSecond,
    required this.color,
    required this.arrowColor,
    required this.size,
    this.end = false,
  });

  final IconData icon;
  final String label;
  final int bytesPerSecond;
  final Color color;
  final Color arrowColor;
  final _ReadoutSize size;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = M3ETheme.of(context).typography.emphasized;
    final (value, unit) = splitBytes(bytesPerSecond);
    final muted = color.withValues(alpha: 0.78);
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: arrowColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: muted),
              ),
            ),
          ],
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: switch (size) {
                    _ReadoutSize.hero => type.displayLarge,
                    _ReadoutSize.large => type.displayMedium,
                    _ReadoutSize.small => type.headlineMedium,
                  }.copyWith(color: color, fontFeatures: _tabular),
                ),
                TextSpan(
                  text: ' $unit/s',
                  style: theme.textTheme.titleMedium?.copyWith(color: muted),
                ),
              ],
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// Totals as plain label/value pairs in one card.
class _StatsCard extends ConsumerWidget {
  const _StatsCard({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final latest = ref.watch(trafficProvider).value;
    final snapshot = ref.watch(connectionsStreamProvider).value;
    final memory = ref.watch(memoryProvider).value;

    final downTotal = latest?.downTotal ?? snapshot?.downloadTotal;
    final upTotal = latest?.upTotal ?? snapshot?.uploadTotal;
    final stats = [
      (
        l10n.overviewDownloadTotal,
        downTotal == null ? '—' : formatBytes(downTotal),
      ),
      (l10n.overviewUploadTotal, upTotal == null ? '—' : formatBytes(upTotal)),
      (
        l10n.overviewMemory,
        memory == null || memory.inUse == 0 ? '—' : formatBytes(memory.inUse),
      ),
      (
        l10n.overviewConnections,
        snapshot == null ? '—' : '${snapshot.connections.length}',
      ),
    ];
    final rows = [
      for (var i = 0; i < stats.length; i += columns)
        Row(
          children: [
            for (final (label, value) in stats.sublist(
              i,
              math.min(i + columns, stats.length),
            ))
              Expanded(
                child: _Stat(label: label, value: value),
              ),
          ],
        ),
    ];

    return _Card(
      alignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const SizedBox(height: 20),
          row,
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: M3ETheme.of(context).typography.emphasized.headlineSmall
              .copyWith(
                color: theme.colorScheme.onSurface,
                fontFeatures: _tabular,
              ),
        ),
      ],
    );
  }
}

class _ModeCard extends ConsumerWidget {
  const _ModeCard();

  static const _modes = [TunnelMode.rule, TunnelMode.global, TunnelMode.direct];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final config = ref.watch(coreConfigProvider);
    final mode = config.value?.mode;

    return _Card(
      children: [
        _CardTitle(
          title: l10n.overviewMode,
          subtitle: config.hasError && mode == null
              ? describeError(l10n, config.error!)
              : null,
        ),
        const SizedBox(height: 16),
        M3EButtonGroup(
          type: M3EButtonGroupType.connected,
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.md,
          selectionRequired: true,
          selectedIndex: mode == null ? null : _modes.indexOf(mode),
          // Quiet unselected segments; the selected one keeps the filled
          // primary so it is the only accent in the card.
          decoration: M3EButtonDecoration(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? null
                  : scheme.cardInset,
            ),
          ),
          onSelectedIndexChanged: (index) async {
            if (index == null || index < 0) return;
            try {
              await ref
                  .read(coreConfigProvider.notifier)
                  .setMode(_modes[index]);
            } catch (e) {
              if (context.mounted) showErrorSnackbar(context, e);
            }
          },
          actions: [
            for (final label in [
              l10n.modeRule,
              l10n.modeGlobal,
              l10n.modeDirect,
            ])
              M3EButtonGroupAction(
                label: Text(label, maxLines: 1, softWrap: false),
              ),
          ],
        ),
      ],
    );
  }
}

class _CoreCard extends ConsumerWidget {
  const _CoreCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(versionProvider);
    final backend = ref.watch(activeBackendProvider);
    final api = ref.watch(mihomoApiProvider);

    final actions = [
      _ActionTile(
        icon: Icons.dns_outlined,
        label: l10n.actionFlushDns,
        run: api.flushDnsCache,
      ),
      _ActionTile(
        icon: Icons.blur_on_rounded,
        label: l10n.actionFlushFakeIp,
        run: api.flushFakeIpCache,
      ),
      _ActionTile(
        icon: Icons.restart_alt_rounded,
        label: l10n.actionReloadConfig,
        run: () async {
          await api.reloadConfigs();
          ref.invalidate(coreConfigProvider);
        },
      ),
      _ActionTile(
        icon: Icons.public_rounded,
        label: l10n.actionUpdateGeo,
        run: api.updateGeoDatabases,
      ),
    ];

    return _Card(
      children: [
        _CardTitle(
          title: l10n.overviewCore,
          trailing: switch (version) {
            AsyncData(:final value) => value.version,
            AsyncError(:final error) => describeError(l10n, error),
            _ => null,
          },
          subtitle: backend == null
              ? null
              : backend.isMock
              ? l10n.backendMockDescription
              : backend.displayAddress,
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            EqualHeightRow(spacing: 8, children: actions.sublist(0, 2)),
            const SizedBox(height: 8),
            EqualHeightRow(spacing: 8, children: actions.sublist(2)),
          ],
        ),
      ],
    );
  }
}

/// A quiet tile that runs [run], shows progress, then confirms or reports
/// the error.
class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.run,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() run;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _running = false;

  Future<void> _onTap() async {
    setState(() => _running = true);
    try {
      await widget.run();
      if (mounted) {
        M3ESnackbar.show(
          context,
          message: '${widget.label} · ${context.l10n.actionDone}',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.cardInset,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _running ? null : _onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 20,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _running
                      ? const M3ELoadingIndicator(size: 20)
                      : Icon(
                          widget.icon,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
