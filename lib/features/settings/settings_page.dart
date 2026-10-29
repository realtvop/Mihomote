import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/page_scaffold.dart';
import '../../app/theme/seed_colors.dart';
import '../../app/theme/semantic_colors.dart';
import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/mihomo_api.dart';
import '../../core/settings/app_settings.dart';
import '../../core/state/core_providers.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/page_padding.dart';
import '../../shared/widgets/status_views.dart';
import '../backends/backend_editor.dart';
import '../logs/logs_page.dart' show logLevelLabel;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      title: l10n.navSettings,
      showShellActions: false,
      slivers: [
        SliverPadding(
          padding: pageGutter(context, maxWidth: 760).copyWith(top: 8),
          sliver: SliverList.list(
            children: [
              _SectionTitle(l10n.settingsBackends),
              const _BackendsSection(),
              _SectionTitle(l10n.settingsAppearance),
              const _AppearanceSection(),
              _SectionTitle(l10n.settingsLanguage),
              const _LanguageSection(),
              _SectionTitle(l10n.settingsCore),
              const _CoreSection(),
              _SectionTitle(l10n.settingsAbout),
              const _AboutSection(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BackendsSection extends ConsumerWidget {
  const _BackendsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(backendsProvider);
    final active = state.active;

    // An M3EListItem inside an M3EList ignores its own onTap; taps are
    // dispatched by index from the list instead.
    final rows = <(Widget, VoidCallback)>[
      for (final profile in state.profiles)
        (
          M3EListItem(
            headline: profile.name,
            supportingText: profile.isMock
                ? l10n.backendMockDescription
                : profile.displayAddress,
            selected: profile.id == active?.id,
            leading: Icon(
              profile.id == active?.id
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: profile.id == active?.id
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!profile.isMock)
                  M3EIconButton(
                    icon: const Icon(Icons.edit_outlined),
                    variant: M3EIconButtonVariant.standard,
                    tooltip: l10n.actionEdit,
                    onPressed: () =>
                        showBackendEditor(context, ref, initial: profile),
                  ),
                M3EIconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  variant: M3EIconButtonVariant.standard,
                  tooltip: l10n.actionDelete,
                  onPressed: () => confirmDeleteBackend(context, ref, profile),
                ),
              ],
            ),
          ),
          () => ref.read(backendsProvider.notifier).activate(profile.id),
        ),
      (
        M3EListItem(
          headline: l10n.settingsAddBackend,
          leading: Icon(Icons.add_rounded, color: scheme.primary),
        ),
        () => showBackendEditor(context, ref),
      ),
    ];
    return M3EList(
      color: Theme.of(context).colorScheme.card,
      itemCount: rows.length,
      itemBuilder: (_, index) => rows[index].$1,
      onTap: (index) => rows[index].$2(),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final dynamicActive = settings.dynamicColor && supportsDynamicColor;

    final items = <Widget>[
      _ControlRow(
        title: l10n.settingsThemeMode,
        child: M3EButtonGroup(
          type: M3EButtonGroupType.connected,
          selectionRequired: true,
          actions: [
            M3EButtonGroupAction(
              label: Text(l10n.themeSystem),
              icon: const Icon(Icons.brightness_auto_rounded),
            ),
            M3EButtonGroupAction(
              label: Text(l10n.themeLight),
              icon: const Icon(Icons.light_mode_rounded),
            ),
            M3EButtonGroupAction(
              label: Text(l10n.themeDark),
              icon: const Icon(Icons.dark_mode_rounded),
            ),
          ],
          selectedIndex: settings.themeMode.index,
          onSelectedIndexChanged: (index) {
            if (index == null) return;
            notifier.setThemeMode(ThemeMode.values[index]);
          },
        ),
      ),
      if (supportsDynamicColor)
        M3EListItem(
          headline: l10n.settingsDynamicColor,
          supportingText: l10n.settingsDynamicColorSubtitle,
          trailing: M3ESwitch(
            value: settings.dynamicColor,
            semanticLabel: l10n.settingsDynamicColor,
            onChanged: notifier.setDynamicColor,
          ),
        ),
      _ControlRow(
        title: l10n.settingsSeedColor,
        child: AnimatedOpacity(
          opacity: dynamicActive ? 0.38 : 1,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: dynamicActive,
            // The buttons' 48dp touch targets already pad the 40dp faces.
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final color in seedColorPresets)
                  _SeedSwatch(
                    color: color,
                    selected: (settings.seedColor ?? defaultSeedColor) == color,
                    onTap: () => notifier.setSeedColor(color),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
    return M3EList(
      color: Theme.of(context).colorScheme.card,
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }
}

/// A list row whose control sits under its title (button groups and
/// swatches need the full width).
class _ControlRow extends StatelessWidget {
  const _ControlRow({this.title, required this.child});

  /// Omitted when the section title already says it.
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The surrounding M3EList paints the row surface.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
          ],
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _SeedSwatch extends StatelessWidget {
  const _SeedSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Fidelity schemes keep the seed as primaryContainer (see AppTheme), so
    // its onPrimaryContainer is the contrast color designed for it.
    final onColor = ColorScheme.fromSeed(
      seedColor: color,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).onPrimaryContainer;
    return M3EIconButton(
      icon: const SizedBox.shrink(),
      selectedIcon: const Icon(Icons.check_rounded),
      isSelected: selected,
      variant: M3EIconButtonVariant.filled,
      semanticLabel:
          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      decoration: M3EIconButtonDecoration(
        backgroundColor: WidgetStatePropertyAll(color),
        foregroundColor: WidgetStatePropertyAll(onColor),
      ),
      onPressed: onTap,
    );
  }
}

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tag =
        ref.watch(appSettingsProvider.select((s) => s.localeTag)) ?? 'system';
    return M3EList(
      color: Theme.of(context).colorScheme.card,
      itemCount: 1,
      itemBuilder: (_, _) => _ControlRow(
        child: M3EButtonGroup(
          type: M3EButtonGroupType.connected,
          selectionRequired: true,
          actions: [
            M3EButtonGroupAction(label: Text(l10n.languageSystem)),
            M3EButtonGroupAction(label: Text(l10n.languageZh)),
            M3EButtonGroupAction(label: Text(l10n.languageEn)),
          ],
          selectedIndex: const ['system', 'zh', 'en'].indexOf(tag),
          onSelectedIndexChanged: (index) {
            if (index == null) return;
            final value = const ['system', 'zh', 'en'][index];
            ref
                .read(appSettingsProvider.notifier)
                .setLocaleTag(value == 'system' ? null : value);
          },
        ),
      ),
    );
  }
}

class _CoreSection extends ConsumerStatefulWidget {
  const _CoreSection();

  @override
  ConsumerState<_CoreSection> createState() => _CoreSectionState();
}

class _CoreSectionState extends ConsumerState<_CoreSection> {
  /// Anchors the log level menu to its row.
  final _logLevelRow = GlobalKey();

  static const _logLevels = [
    LogLevel.debug,
    LogLevel.info,
    LogLevel.warning,
    LogLevel.error,
    LogLevel.silent,
  ];

  Future<void> _pickLogLevel(
    LogLevel current,
    Future<void> Function(Future<void> Function()) run,
  ) async {
    final row = _logLevelRow.currentContext;
    final anchor = row == null ? null : m3eOverlayRectFor(row);
    if (anchor == null) return;
    final l10n = context.l10n;
    final level = await showM3EMenu<LogLevel>(
      context: context,
      anchor: anchor,
      position: M3EMenuAnchorPosition.bottomEnd,
      selectedValue: current,
      children: [
        for (final level in _logLevels)
          M3EMenuSelectable(
            label: logLevelLabel(l10n, level),
            value: level,
            selected: level == current,
          ),
      ],
    );
    if (level == null || level == current) return;
    await run(() => ref.read(coreConfigProvider.notifier).setLogLevel(level));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(coreConfigProvider);
    final notifier = ref.read(coreConfigProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) showErrorSnackbar(context, e);
      }
    }

    return switch (config) {
      AsyncData(:final value) => () {
        // Taps go through the list (see _BackendsSection): a row toggles its
        // switch or opens its menu.
        final rows = <(Widget, VoidCallback)>[
          (
            M3EListItem(
              headline: l10n.settingsAllowLan,
              supportingText: l10n.settingsAllowLanSubtitle,
              trailing: M3ESwitch(
                value: value.allowLan,
                semanticLabel: l10n.settingsAllowLan,
                onChanged: (v) => run(() => notifier.setAllowLan(v)),
              ),
            ),
            () => run(() => notifier.setAllowLan(!value.allowLan)),
          ),
          (
            M3EListItem(
              headline: l10n.settingsIpv6,
              trailing: M3ESwitch(
                value: value.ipv6,
                semanticLabel: l10n.settingsIpv6,
                onChanged: (v) => run(() => notifier.setIpv6(v)),
              ),
            ),
            () => run(() => notifier.setIpv6(!value.ipv6)),
          ),
          // Five levels don't fit a segmented button on a phone, so this is
          // a menu instead.
          (
            M3EListItem(
              key: _logLevelRow,
              headline: l10n.settingsLogLevel,
              trailingText: logLevelLabel(l10n, value.logLevel),
            ),
            () => _pickLogLevel(value.logLevel, run),
          ),
        ];
        return M3EList(
          color: Theme.of(context).colorScheme.card,
          itemCount: rows.length,
          itemBuilder: (_, index) => rows[index].$1,
          onTap: (index) => rows[index].$2(),
        );
      }(),
      AsyncError(:final error) => SizedBox(
        height: 240,
        child: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(coreConfigProvider),
        ),
      ),
      _ => const SizedBox(height: 120, child: LoadingView()),
    };
  }
}

class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(versionProvider).value;
    final items = <Widget>[
      M3EListItem(
        headline: l10n.appTitle,
        supportingText: l10n.settingsAboutSubtitle,
        leading: const Icon(Icons.hub_rounded),
      ),
      if (version != null)
        M3EListItem(
          headline: l10n.overviewCore,
          supportingText: version.version,
          leading: const Icon(Icons.memory_rounded),
        ),
    ];
    return M3EList(
      color: Theme.of(context).colorScheme.card,
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }
}
