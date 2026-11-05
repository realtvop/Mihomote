import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/mihomo/mihomo_api.dart';
import '../../core/settings/app_settings.dart';
import '../../core/state/core_providers.dart';
import '../../core/storage/preferences.dart';
import '../../features/proxies/proxies_page.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/page_padding.dart';
import '../../shared/utils/format.dart';
import '../scroll_behavior.dart';
import '../theme/app_theme.dart';
import '../theme/seed_colors.dart';
import '../theme/semantic_colors.dart';
import 'menu_bar_bridge.dart';

/// Owns the menu-bar engine's provider container and rebuilds it after the
/// main window changes shared settings or the active backend.
class MenuBarBootstrap extends StatefulWidget {
  const MenuBarBootstrap({super.key, required this.preferences});

  final SharedPreferencesWithCache preferences;

  @override
  State<MenuBarBootstrap> createState() => _MenuBarBootstrapState();
}

class _MenuBarBootstrapState extends State<MenuBarBootstrap> {
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    MenuBarBridge.channel.setMethodCallHandler((call) async {
      if (call.method != 'preferencesChanged') return;
      await widget.preferences.reloadCache();
      if (mounted) setState(() => _generation++);
    });
  }

  @override
  void dispose() {
    MenuBarBridge.channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(_generation),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(widget.preferences),
      ],
      child: const MenuBarApp(),
    );
  }
}

/// Compact proxies surface hosted by the macOS status-item popover.
class MenuBarApp extends ConsumerStatefulWidget {
  const MenuBarApp({super.key});

  @override
  ConsumerState<MenuBarApp> createState() => _MenuBarAppState();
}

class _MenuBarAppState extends ConsumerState<MenuBarApp> {
  Color? _seed;
  late AppTheme _theme;

  AppTheme _themeFor(Color seed) {
    if (seed != _seed) {
      _seed = seed;
      _theme = AppTheme.fromSeed(seed);
    }
    return _theme;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final fallback = settings.seedColor ?? defaultSeedColor;
    if (supportsDynamicColor) {
      return M3EDynamicColorHost(
        builder: (light, _) => _app(
          settings,
          _themeFor(
            settings.dynamicColor ? light?.primary ?? fallback : fallback,
          ),
        ),
      );
    }
    return _app(settings, _themeFor(fallback));
  }

  Widget _app(AppSettings settings, AppTheme theme) {
    return MaterialApp(
      scrollBehavior: const MihomoteScrollBehavior(),
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: theme.lightMaterial,
      darkTheme: theme.darkMaterial,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => M3EResolvedTheme(
        data: theme.of(Theme.of(context).brightness),
        child: child!,
      ),
      home: const _MenuBarProxiesSurface(),
    );
  }
}

class _MenuBarProxiesSurface extends ConsumerStatefulWidget {
  const _MenuBarProxiesSurface();

  @override
  ConsumerState<_MenuBarProxiesSurface> createState() =>
      _MenuBarProxiesSurfaceState();
}

class _MenuBarProxiesSurfaceState
    extends ConsumerState<_MenuBarProxiesSurface> {
  String? _configuredLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_configuredLocale == locale) return;
    _configuredLocale = locale;
    final l10n = context.l10n;
    unawaited(
      MenuBarBridge.configure(
        showTraffic: l10n.menuBarShowTraffic,
        openMainWindow: l10n.menuBarOpenMainWindow,
        quit: l10n.menuBarQuit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<TrafficSample>>(trafficProvider, (_, next) {
      final sample = next.value;
      if (sample != null) {
        unawaited(MenuBarBridge.publishTraffic(sample));
      }
    });
    return ProxiesPage(
      showShellActions: false,
      showPageHeader: false,
      header: const _LiveSummary(),
    );
  }
}

class _LiveSummary extends ConsumerWidget {
  const _LiveSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final traffic = ref.watch(trafficProvider).value;
    final connections = ref.watch(connectionsStreamProvider).value;
    return Padding(
      padding: pageGutter(context).copyWith(top: 12, bottom: 8),
      child: M3ECard(
        variant: M3ECardVariant.filled,
        color: Theme.of(context).colorScheme.card,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _SummaryValue(
                label: l10n.overviewUpload,
                value: traffic == null ? '—' : formatSpeed(traffic.up),
              ),
            ),
            Expanded(
              child: _SummaryValue(
                label: l10n.overviewDownload,
                value: traffic == null ? '—' : formatSpeed(traffic.down),
              ),
            ),
            Expanded(
              child: _SummaryValue(
                label: l10n.overviewConnections,
                value: connections?.connections.length.toString() ?? '—',
              ),
            ),
            M3EIconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              variant: M3EIconButtonVariant.standard,
              tooltip: l10n.menuBarOpenMainWindow,
              onPressed: () => unawaited(MenuBarBridge.openMainWindow()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
