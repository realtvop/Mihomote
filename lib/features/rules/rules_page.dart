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
import 'rules_providers.dart';

enum _RulesTab { rules, providers }

class RulesPage extends ConsumerStatefulWidget {
  const RulesPage({super.key});

  @override
  ConsumerState<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends ConsumerState<RulesPage> {
  _RulesTab _tab = _RulesTab.rules;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = switch (_tab) {
      _RulesTab.rules => ref.watch(rulesProvider).value?.length,
      _RulesTab.providers => ref.watch(ruleProvidersProvider).value?.length,
    };
    return PageScaffold(
      title: l10n.navRules,
      subtitle: count == null
          ? null
          : _tab == _RulesTab.rules
          ? l10n.ruleProviderRuleCount(count)
          : l10n.ruleProvidersCount(count),
      onRefresh: () async {
        if (_tab == _RulesTab.rules) {
          ref.invalidate(rulesProvider);
          await ref.read(rulesProvider.future);
        } else {
          ref.invalidate(ruleProvidersProvider);
          await ref.read(ruleProvidersProvider.future);
        }
      },
      slivers: [
        SliverPadding(
          padding: pageGutter(context).copyWith(top: 4, bottom: 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                M3ESegmentedButton<_RulesTab>(
                  segments: [
                    M3ESegment(
                      value: _RulesTab.rules,
                      label: l10n.rulesTabRules,
                    ),
                    M3ESegment(
                      value: _RulesTab.providers,
                      label: l10n.rulesTabProviders,
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (selection) =>
                      setState(() => _tab = selection.first),
                ),
                if (_tab == _RulesTab.rules) ...[
                  const SizedBox(height: 12),
                  SearchField(
                    hint: l10n.rulesSearchHint,
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                ],
              ],
            ),
          ),
        ),
        switch (_tab) {
          _RulesTab.rules => _rulesSliver(),
          _RulesTab.providers => _providersSliver(),
        },
      ],
    );
  }

  Widget _rulesSliver() {
    final l10n = context.l10n;
    return switch (ref.watch(rulesProvider)) {
      AsyncData(:final value) => () {
        final rules = _query.isEmpty
            ? value
            : value
                  .where(
                    (r) => '${r.type} ${r.payload} ${r.proxy}'
                        .toLowerCase()
                        .contains(_query),
                  )
                  .toList();
        if (rules.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              message: value.isEmpty ? l10n.rulesEmpty : l10n.searchNoResults,
            ),
          );
        }
        return SliverPadding(
          padding: pageGutter(context),
          sliver: M3EList.sliver(
            color: Theme.of(context).colorScheme.card,
            itemCount: rules.length,
            itemBuilder: (context, index) => _RuleItem(rule: rules[index]),
          ),
        );
      }(),
      AsyncError(:final error) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(rulesProvider),
        ),
      ),
      _ => const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingView(),
      ),
    };
  }

  Widget _providersSliver() {
    final l10n = context.l10n;
    return switch (ref.watch(ruleProvidersProvider)) {
      AsyncData(:final value) when value.isEmpty => SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          message: l10n.ruleProvidersEmpty,
          icon: Icons.inventory_2_outlined,
        ),
      ),
      AsyncData(:final value) => SliverPadding(
        padding: pageGutter(context),
        sliver: M3EList.sliver(
          color: Theme.of(context).colorScheme.card,
          itemCount: value.length,
          itemBuilder: (context, index) =>
              _RuleProviderItem(provider: value[index]),
        ),
      ),
      AsyncError(:final error) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(ruleProvidersProvider),
        ),
      ),
      _ => const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingView(),
      ),
    };
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.rule});

  final Rule rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return M3EListItem(
      headline: rule.payload.isEmpty ? rule.type : rule.payload,
      supportingText: [
        rule.type,
        if (rule.size >= 0) context.l10n.ruleProviderRuleCount(rule.size),
      ].join(' · '),
      leading: SizedBox(
        width: 40,
        child: Text(
          '${rule.index + 1}',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Text(
          rule.proxy,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RuleProviderItem extends ConsumerWidget {
  const _RuleProviderItem({required this.provider});

  final RuleProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final updating = ref.watch(
      updatingRuleProvidersProvider.select((s) => s.contains(provider.name)),
    );
    final updatedAt = provider.updatedAt;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return M3EListItem(
      headline: provider.name,
      supportingText: [
        '${provider.behavior} · ${provider.vehicleType}',
        l10n.ruleProviderRuleCount(provider.ruleCount),
        if (updatedAt != null)
          l10n.ruleProviderUpdatedAt(
            DateFormat.yMd(locale).add_Hm().format(updatedAt.toLocal()),
          ),
      ].join(' · '),
      trailing: updating
          ? const SizedBox.square(
              dimension: 40,
              child: M3ELoadingIndicator(size: 28),
            )
          : M3EIconButton(
              icon: const Icon(Icons.sync_rounded),
              variant: M3EIconButtonVariant.standard,
              tooltip: l10n.actionUpdate,
              onPressed: provider.vehicleType == 'HTTP'
                  ? () async {
                      try {
                        await ref
                            .read(ruleProvidersProvider.notifier)
                            .updateProvider(provider.name);
                      } catch (e) {
                        if (context.mounted) showErrorSnackbar(context, e);
                      }
                    }
                  : null,
            ),
    );
  }
}
