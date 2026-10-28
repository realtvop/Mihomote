import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/shell/page_scaffold.dart';
import '../../app/theme/seed_colors.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
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

    final items = <Widget>[
      for (final profile in state.profiles)
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
          onTap: () => ref.read(backendsProvider.notifier).activate(profile.id),
        ),
      M3EListItem(
        headline: l10n.settingsAddBackend,
        leading: Icon(Icons.add_rounded, color: scheme.primary),
        onTap: () => showBackendEditor(context, ref),
      ),
    ];
    return M3EList(
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
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
        child: M3ESegmentedButton<ThemeMode>(
          segments: [
            M3ESegment(
              value: ThemeMode.system,
              label: l10n.themeSystem,
              icon: const Icon(Icons.brightness_auto_rounded),
            ),
            M3ESegment(
              value: ThemeMode.light,
              label: l10n.themeLight,
              icon: const Icon(Icons.light_mode_rounded),
            ),
            M3ESegment(
              value: ThemeMode.dark,
              label: l10n.themeDark,
              icon: const Icon(Icons.dark_mode_rounded),
            ),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (selection) =>
              notifier.setThemeMode(selection.first),
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
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
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
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }
}

/// A list row whose control sits under its title (segmented buttons and
/// swatches need the full width).
class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
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
    return Semantics(
      button: true,
      selected: selected,
      label:
          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: M3EShapeContainer(
              key: ValueKey(selected),
              kind: selected ? M3EShapeKind.cookie9Sided : M3EShapeKind.circle,
              width: 44,
              height: 44,
              color: color,
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
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
      itemCount: 1,
      itemBuilder: (_, _) => _ControlRow(
        title: l10n.settingsLanguage,
        child: M3ESegmentedButton<String>(
          segments: [
            M3ESegment(value: 'system', label: l10n.languageSystem),
            M3ESegment(value: 'zh', label: l10n.languageZh),
            M3ESegment(value: 'en', label: l10n.languageEn),
          ],
          selected: {tag},
          onSelectionChanged: (selection) {
            final value = selection.first;
            ref
                .read(appSettingsProvider.notifier)
                .setLocaleTag(value == 'system' ? null : value);
          },
        ),
      ),
    );
  }
}

class _CoreSection extends ConsumerWidget {
  const _CoreSection();

  static const _logLevels = [
    LogLevel.debug,
    LogLevel.info,
    LogLevel.warning,
    LogLevel.error,
    LogLevel.silent,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final items = <Widget>[
          M3EListItem(
            headline: l10n.settingsAllowLan,
            supportingText: l10n.settingsAllowLanSubtitle,
            trailing: M3ESwitch(
              value: value.allowLan,
              semanticLabel: l10n.settingsAllowLan,
              onChanged: (v) => run(() => notifier.setAllowLan(v)),
            ),
          ),
          M3EListItem(
            headline: l10n.settingsIpv6,
            trailing: M3ESwitch(
              value: value.ipv6,
              semanticLabel: l10n.settingsIpv6,
              onChanged: (v) => run(() => notifier.setIpv6(v)),
            ),
          ),
          // Five levels don't fit a segmented button on a phone, so this is
          // a menu instead.
          MenuAnchor(
            alignmentOffset: const Offset(16, 0),
            menuChildren: [
              for (final level in _logLevels)
                MenuItemButton(
                  leadingIcon: Icon(
                    level == value.logLevel ? Icons.check_rounded : null,
                    size: 20,
                  ),
                  onPressed: () => run(() => notifier.setLogLevel(level)),
                  child: Text(logLevelLabel(l10n, level)),
                ),
            ],
            builder: (context, controller, _) => M3EListItem(
              headline: l10n.settingsLogLevel,
              trailingText: logLevelLabel(l10n, value.logLevel),
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        ];
        return M3EList(
          itemCount: items.length,
          itemBuilder: (_, index) => items[index],
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
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }
}
