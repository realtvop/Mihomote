import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/page_scaffold.dart';
import '../../app/theme/semantic_colors.dart';
import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/mihomo_api.dart';
import '../../core/state/core_providers.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/page_padding.dart';
import '../../shared/utils/format.dart';
import '../../shared/widgets/status_views.dart';
import 'overview_providers.dart';
import 'widgets/traffic_chart.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: context.l10n.navOverview,
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
                const gap = SizedBox.square(dimension: 12);
                if (constraints.maxWidth >= 840) {
                  return const Column(
                    children: [
                      // No IntrinsicHeight here: M3EButtonGroup lays out
                      // with a LayoutBuilder, which can't report intrinsics.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _SpeedCard()),
                          gap,
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [_ModeCard(), gap, _CoreCard()],
                            ),
                          ),
                        ],
                      ),
                      gap,
                      _StatGrid(columns: 4),
                    ],
                  );
                }
                return Column(
                  children: [
                    const _SpeedCard(),
                    gap,
                    _StatGrid(columns: constraints.maxWidth >= 600 ? 4 : 2),
                    gap,
                    const _ModeCard(),
                    gap,
                    const _CoreCard(),
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

/// Rounded container used by every overview card.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class _SpeedCard extends ConsumerWidget {
  const _SpeedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final samples = ref.watch(trafficHistoryProvider);
    final traffic = ref.watch(trafficProvider);
    final latest = samples.isEmpty ? TrafficSample.zero : samples.last;

    return _Panel(
      color: scheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SpeedReadout(
                  label: l10n.overviewDownload,
                  icon: Icons.south_rounded,
                  color: scheme.downloadColor,
                  bytesPerSecond: latest.down,
                ),
              ),
              Expanded(
                child: _SpeedReadout(
                  label: l10n.overviewUpload,
                  icon: Icons.north_rounded,
                  color: scheme.uploadColor,
                  bytesPerSecond: latest.up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: traffic.hasError && samples.isEmpty
                ? Center(child: Text(describeError(l10n, traffic.error!)))
                : TrafficChart(
                    samples: samples,
                    capacity: TrafficHistoryNotifier.capacity,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SpeedReadout extends StatelessWidget {
  const _SpeedReadout({
    required this.label,
    required this.icon,
    required this.color,
    required this.bytesPerSecond,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int bytesPerSecond;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emphasized = M3ETheme.of(context).typography.emphasized;
    final (value, unit) = splitBytes(bytesPerSecond);
    const tabular = [FontFeature.tabularFigures()];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            M3EShapeContainer(
              kind: M3EShapeKind.cookie4Sided,
              width: 24,
              height: 24,
              color: color.withValues(alpha: 0.16),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: emphasized.displaySmall.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontFeatures: tabular,
                ),
              ),
              TextSpan(
                text: ' $unit/s',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}

class _StatGrid extends ConsumerWidget {
  const _StatGrid({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final latest = ref.watch(trafficProvider).value;
    final snapshot = ref.watch(connectionsStreamProvider).value;
    final memory = ref.watch(memoryProvider).value;

    final downTotal = latest?.downTotal ?? snapshot?.downloadTotal;
    final upTotal = latest?.upTotal ?? snapshot?.uploadTotal;
    final tiles = [
      _StatTile(
        icon: Icons.download_rounded,
        kind: M3EShapeKind.cookie9Sided,
        label: l10n.overviewDownloadTotal,
        value: downTotal == null ? '—' : formatBytes(downTotal),
      ),
      _StatTile(
        icon: Icons.upload_rounded,
        kind: M3EShapeKind.clover4Leaf,
        label: l10n.overviewUploadTotal,
        value: upTotal == null ? '—' : formatBytes(upTotal),
      ),
      _StatTile(
        icon: Icons.memory_rounded,
        kind: M3EShapeKind.sunny,
        label: l10n.overviewMemory,
        value: memory == null || memory.inUse == 0
            ? '—'
            : formatBytes(memory.inUse),
      ),
      _StatTile(
        icon: Icons.swap_vert_rounded,
        kind: M3EShapeKind.pentagon,
        label: l10n.overviewConnections,
        value: snapshot == null ? '—' : '${snapshot.connections.length}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.kind,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final M3EShapeKind kind;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          M3EShapeContainer(
            kind: kind,
            width: 40,
            height: 40,
            color: scheme.secondaryContainer,
            child: Icon(icon, size: 20, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: M3ETheme.of(context).typography.emphasized.titleLarge
                .copyWith(
                  color: scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends ConsumerWidget {
  const _ModeCard();

  static const _modes = [TunnelMode.rule, TunnelMode.global, TunnelMode.direct];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(coreConfigProvider);
    final mode = config.value?.mode;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.overviewMode,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (config.hasError && mode == null)
            Text(describeError(l10n, config.error!))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final withIcons = constraints.maxWidth >= 360;
                return M3EButtonGroup(
                  type: M3EButtonGroupType.connected,
                  style: M3EButtonStyle.tonal,
                  size: M3EButtonSize.md,
                  selectionRequired: true,
                  selectedIndex: mode == null ? null : _modes.indexOf(mode),
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
                    for (final (icon, label) in [
                      (Icons.rule_rounded, l10n.modeRule),
                      (Icons.public_rounded, l10n.modeGlobal),
                      (Icons.arrow_forward_rounded, l10n.modeDirect),
                    ])
                      M3EButtonGroupAction(
                        // Icons only when there's room; labels must never clip.
                        icon: withIcons ? Icon(icon) : null,
                        label: Text(label, maxLines: 1, softWrap: false),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CoreCard extends ConsumerWidget {
  const _CoreCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final version = ref.watch(versionProvider);
    final backend = ref.watch(activeBackendProvider);
    final api = ref.watch(mihomoApiProvider);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.overviewCore,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              switch (version) {
                AsyncData(:final value) => _Pill(text: value.version),
                AsyncError(:final error) => _Pill(
                  text: describeError(l10n, error),
                  error: true,
                ),
                _ => const SizedBox.square(
                  dimension: 24,
                  child: M3ELoadingIndicator(size: 24),
                ),
              },
            ],
          ),
          if (backend != null) ...[
            const SizedBox(height: 4),
            Text(
              backend.isMock
                  ? l10n.backendMockDescription
                  : backend.displayAddress,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.overviewQuickActions, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickAction(
                icon: Icons.dns_rounded,
                label: l10n.actionFlushDns,
                run: api.flushDnsCache,
              ),
              _QuickAction(
                icon: Icons.blur_on_rounded,
                label: l10n.actionFlushFakeIp,
                run: api.flushFakeIpCache,
              ),
              _QuickAction(
                icon: Icons.restart_alt_rounded,
                label: l10n.actionReloadConfig,
                run: () async {
                  await api.reloadConfigs();
                  ref.invalidate(coreConfigProvider);
                },
              ),
              _QuickAction(
                icon: Icons.public_rounded,
                label: l10n.actionUpdateGeo,
                run: api.updateGeoDatabases,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: error ? scheme.errorContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: error ? scheme.onErrorContainer : scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

/// A tonal button that runs [run], shows progress, then confirms or reports.
class _QuickAction extends StatefulWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.run,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() run;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _running = false;

  Future<void> _onPressed() async {
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
    return M3EButton.tonal(
      onPressed: _running ? null : _onPressed,
      icon: _running
          ? const SizedBox.square(
              dimension: 18,
              child: M3ELoadingIndicator(size: 18),
            )
          : Icon(widget.icon),
      label: Text(widget.label),
    );
  }
}
