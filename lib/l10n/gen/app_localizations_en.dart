// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mihomote';

  @override
  String get navOverview => 'Overview';

  @override
  String get navProxies => 'Proxies';

  @override
  String get navConnections => 'Connections';

  @override
  String get navRules => 'Rules';

  @override
  String get navLogs => 'Logs';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionBack => 'Back';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionClose => 'Close';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionUpdate => 'Update';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionDone => 'Done';

  @override
  String get actionCopied => 'Copied';

  @override
  String get searchNoResults => 'No matches';

  @override
  String get errorNetwork =>
      'Can\'t reach the controller. Check the address and your network.';

  @override
  String get errorUnauthorized => 'The secret is wrong.';

  @override
  String get errorNotFound => 'Not found on the controller.';

  @override
  String get errorTimeout => 'The request timed out.';

  @override
  String errorServer(String message) {
    return 'The controller returned an error: $message';
  }

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get errorNoBackend => 'No backend selected.';

  @override
  String get backendSwitcherTooltip => 'Switch backend';

  @override
  String get backendManage => 'Manage backends';

  @override
  String get backendAddTitle => 'Add backend';

  @override
  String get backendEditTitle => 'Edit backend';

  @override
  String get backendNameLabel => 'Name';

  @override
  String get backendNameHint => 'e.g. Home router';

  @override
  String get backendUrlLabel => 'Controller address';

  @override
  String get backendUrlSupporting =>
      'The external-controller address, e.g. http://192.168.1.1:9090';

  @override
  String get backendUrlInvalid => 'Enter a valid http(s) address';

  @override
  String get backendSecretLabel => 'Secret';

  @override
  String get backendSecretSupporting => 'Leave empty if no secret is set';

  @override
  String get backendTest => 'Test connection';

  @override
  String backendTestSuccess(String version) {
    return 'Connected · $version';
  }

  @override
  String get backendMockName => 'Mock data';

  @override
  String get backendMockDescription => 'Built-in sample data for development';

  @override
  String backendDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get backendActive => 'Current';

  @override
  String get backendsTitle => 'Backends';

  @override
  String get welcomeTitle => 'Welcome to Mihomote';

  @override
  String get welcomeSubtitle =>
      'Connect to a running Mihomo core through its external controller.';

  @override
  String get welcomeConnect => 'Connect';

  @override
  String get welcomeUseMock => 'Use mock data';

  @override
  String get overviewDownload => 'Download';

  @override
  String get overviewUpload => 'Upload';

  @override
  String get overviewDownloadTotal => 'Downloaded';

  @override
  String get overviewUploadTotal => 'Uploaded';

  @override
  String get overviewMemory => 'Memory';

  @override
  String get overviewConnections => 'Connections';

  @override
  String get overviewMode => 'Proxy mode';

  @override
  String get overviewCore => 'Core';

  @override
  String get modeRule => 'Rule';

  @override
  String get modeGlobal => 'Global';

  @override
  String get modeDirect => 'Direct';

  @override
  String get actionFlushDns => 'Flush DNS cache';

  @override
  String get actionFlushFakeIp => 'Flush Fake-IP cache';

  @override
  String get actionReloadConfig => 'Reload config';

  @override
  String get actionUpdateGeo => 'Update GEO databases';

  @override
  String get proxiesTestLatency => 'Test latency';

  @override
  String proxiesNodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nodes',
      one: '1 node',
    );
    return '$_temp0';
  }

  @override
  String get proxiesTimeout => 'Timeout';

  @override
  String get proxiesEmpty => 'No proxy groups';

  @override
  String proxiesGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '1 group',
    );
    return '$_temp0';
  }

  @override
  String get proxiesFixed => 'Fixed';

  @override
  String get proxiesTabGroups => 'Groups';

  @override
  String get proxiesTabProviders => 'Providers';

  @override
  String proxyProvidersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count providers',
      one: '1 provider',
    );
    return '$_temp0';
  }

  @override
  String get proxyProviderHealthCheck => 'Health check';

  @override
  String proxyProviderTraffic(String used, String total) {
    return '$used / $total';
  }

  @override
  String proxyProviderUsed(String used) {
    return '$used used';
  }

  @override
  String proxyProviderExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get proxyProviderExpired => 'Expired';

  @override
  String get actionExpand => 'Expand';

  @override
  String get actionCollapse => 'Collapse';

  @override
  String get connectionsEmpty => 'No active connections';

  @override
  String get connectionsCloseAll => 'Close all';

  @override
  String connectionsCloseAllConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Close all $count connections?',
      one: 'Close 1 connection?',
    );
    return '$_temp0';
  }

  @override
  String get connectionsClose => 'Close connection';

  @override
  String get connectionsSearchHint => 'Search host, IP, rule or chain';

  @override
  String connectionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connections',
      one: '1 connection',
    );
    return '$_temp0';
  }

  @override
  String get statusPaused => 'Paused';

  @override
  String get connectionDetails => 'Connection details';

  @override
  String get connectionHost => 'Host';

  @override
  String get connectionDestination => 'Destination';

  @override
  String get connectionSource => 'Source';

  @override
  String get connectionNetwork => 'Network';

  @override
  String get connectionInbound => 'Inbound';

  @override
  String get connectionRule => 'Rule';

  @override
  String get connectionChains => 'Chain';

  @override
  String get connectionProcess => 'Process';

  @override
  String get connectionDuration => 'Duration';

  @override
  String get rulesTabRules => 'Rules';

  @override
  String get rulesTabProviders => 'Rule providers';

  @override
  String get rulesSearchHint => 'Search rules';

  @override
  String get rulesEmpty => 'No rules';

  @override
  String get ruleProvidersEmpty => 'No rule providers';

  @override
  String ruleProvidersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rule providers',
      one: '1 rule provider',
    );
    return '$_temp0';
  }

  @override
  String ruleProviderRuleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rules',
      one: '1 rule',
    );
    return '$_temp0';
  }

  @override
  String providerUpdatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get logsEmpty => 'Waiting for logs…';

  @override
  String get logsSearchHint => 'Filter logs';

  @override
  String get logsLevelTooltip => 'Log level';

  @override
  String get logLevelDebug => 'Debug';

  @override
  String get logLevelInfo => 'Info';

  @override
  String get logLevelWarning => 'Warning';

  @override
  String get logLevelError => 'Error';

  @override
  String get logLevelSilent => 'Silent';

  @override
  String get settingsBackends => 'Backends';

  @override
  String get settingsAddBackend => 'Add backend';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsDynamicColor => 'Dynamic color';

  @override
  String get settingsDynamicColorSubtitle =>
      'Use the wallpaper or system accent color';

  @override
  String get settingsSeedColor => 'Theme color';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get settingsCore => 'Core';

  @override
  String get settingsAllowLan => 'Allow LAN';

  @override
  String get settingsAllowLanSubtitle =>
      'Let other devices on the network use this proxy';

  @override
  String get settingsIpv6 => 'IPv6';

  @override
  String get settingsLogLevel => 'Log level';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutSubtitle =>
      'A Material 3 Expressive remote panel for Mihomo';

  @override
  String durationSeconds(int s) {
    return '${s}s';
  }

  @override
  String durationMinutes(int m, int s) {
    return '${m}m ${s}s';
  }

  @override
  String durationHours(int h, int m) {
    return '${h}h ${m}m';
  }
}
