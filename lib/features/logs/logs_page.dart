import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/page_scaffold.dart';
import '../../app/theme/semantic_colors.dart';
import '../../core/mihomo/mihomo_api.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/page_padding.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/status_views.dart';
import 'logs_providers.dart';

String logLevelLabel(AppLocalizations l10n, LogLevel level) => switch (level) {
  LogLevel.debug => l10n.logLevelDebug,
  LogLevel.info => l10n.logLevelInfo,
  LogLevel.warning => l10n.logLevelWarning,
  LogLevel.error => l10n.logLevelError,
  LogLevel.silent => l10n.logLevelSilent,
  _ => level.name,
};

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  String _query = '';

  static const _levels = [
    LogLevel.debug,
    LogLevel.info,
    LogLevel.warning,
    LogLevel.error,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(logsProvider);
    final level = ref.watch(logLevelFilterProvider);
    final notifier = ref.read(logsProvider.notifier);
    final entries = _query.isEmpty
        ? state.entries
        : state.entries
              .where((e) => e.payload.toLowerCase().contains(_query))
              .toList();

    return PageScaffold(
      title: l10n.navLogs,
      actions: [
        MenuAnchor(
          menuChildren: [
            for (final option in _levels)
              MenuItemButton(
                leadingIcon: Icon(
                  option == level ? Icons.check_rounded : null,
                  size: 20,
                ),
                onPressed: () =>
                    ref.read(logLevelFilterProvider.notifier).set(option),
                child: Text(logLevelLabel(l10n, option)),
              ),
          ],
          builder: (context, controller, _) => M3EIconButton(
            icon: const Icon(Icons.filter_list_rounded),
            variant: M3EIconButtonVariant.standard,
            tooltip: '${l10n.logsLevelTooltip} · ${logLevelLabel(l10n, level)}',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
        M3EIconButton(
          icon: Icon(
            state.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          ),
          variant: M3EIconButtonVariant.standard,
          tooltip: state.paused ? l10n.actionResume : l10n.actionPause,
          onPressed: notifier.togglePaused,
        ),
        M3EIconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          variant: M3EIconButtonVariant.standard,
          tooltip: l10n.actionClear,
          onPressed: state.entries.isEmpty ? null : notifier.clear,
        ),
      ],
      slivers: [
        SliverPadding(
          padding: pageGutter(context).copyWith(top: 4, bottom: 12),
          sliver: SliverToBoxAdapter(
            child: SearchField(
              hint: l10n.logsSearchHint,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
        ),
        if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: state.error != null && state.entries.isEmpty
                ? ErrorView(
                    error: state.error!,
                    onRetry: () => ref.invalidate(logsProvider),
                  )
                : EmptyView(
                    message: state.entries.isEmpty
                        ? l10n.logsEmpty
                        : l10n.searchNoResults,
                    icon: Icons.receipt_long_rounded,
                  ),
          )
        else
          SliverPadding(
            padding: pageGutter(context),
            sliver: SliverList.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) => _LogTile(
                entry: entries[index],
                first: index == 0,
                last: index == entries.length - 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.entry,
    required this.first,
    required this.last,
  });

  final LogEntry entry;
  final bool first;
  final bool last;

  static final _time = DateFormat.Hms();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (entry.level) {
      LogLevel.error => (scheme.errorContainer, scheme.onErrorContainer),
      LogLevel.warning => (
        scheme.warning.withValues(alpha: 0.18),
        scheme.onSurface,
      ),
      LogLevel.debug => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    // Segmented-list corners: large at the ends of the group, small between.
    final radius = BorderRadius.vertical(
      top: Radius.circular(first ? 20 : 6),
      bottom: Radius.circular(last ? 20 : 6),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              logLevelLabel(context.l10n, entry.level),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _time.format(entry.time),
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              entry.payload,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
