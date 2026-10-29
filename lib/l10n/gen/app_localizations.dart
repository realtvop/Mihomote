import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mihomote'**
  String get appTitle;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navProxies.
  ///
  /// In en, this message translates to:
  /// **'Proxies'**
  String get navProxies;

  /// No description provided for @navConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get navConnections;

  /// No description provided for @navRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get navRules;

  /// No description provided for @navLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get navLogs;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @actionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get actionUpdate;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Snackbar message after a quick action succeeds.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionCopied;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoResults;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the controller. Check the address and your network.'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'The secret is wrong.'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found on the controller.'**
  String get errorNotFound;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The controller returned an error: {message}'**
  String errorServer(String message);

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnknown;

  /// No description provided for @errorNoBackend.
  ///
  /// In en, this message translates to:
  /// **'No backend selected.'**
  String get errorNoBackend;

  /// No description provided for @backendSwitcherTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch backend'**
  String get backendSwitcherTooltip;

  /// No description provided for @backendManage.
  ///
  /// In en, this message translates to:
  /// **'Manage backends'**
  String get backendManage;

  /// No description provided for @backendAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add backend'**
  String get backendAddTitle;

  /// No description provided for @backendEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit backend'**
  String get backendEditTitle;

  /// No description provided for @backendNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get backendNameLabel;

  /// No description provided for @backendNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home router'**
  String get backendNameHint;

  /// No description provided for @backendUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Controller address'**
  String get backendUrlLabel;

  /// No description provided for @backendUrlSupporting.
  ///
  /// In en, this message translates to:
  /// **'The external-controller address, e.g. http://192.168.1.1:9090'**
  String get backendUrlSupporting;

  /// No description provided for @backendUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http(s) address'**
  String get backendUrlInvalid;

  /// No description provided for @backendSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get backendSecretLabel;

  /// No description provided for @backendSecretSupporting.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if no secret is set'**
  String get backendSecretSupporting;

  /// No description provided for @backendTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get backendTest;

  /// No description provided for @backendTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected · {version}'**
  String backendTestSuccess(String version);

  /// No description provided for @backendMockName.
  ///
  /// In en, this message translates to:
  /// **'Mock data'**
  String get backendMockName;

  /// No description provided for @backendMockDescription.
  ///
  /// In en, this message translates to:
  /// **'Built-in sample data for development'**
  String get backendMockDescription;

  /// No description provided for @backendDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String backendDeleteConfirm(String name);

  /// No description provided for @backendActive.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get backendActive;

  /// No description provided for @backendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Backends'**
  String get backendsTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Mihomote'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a running Mihomo core through its external controller.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get welcomeConnect;

  /// No description provided for @welcomeUseMock.
  ///
  /// In en, this message translates to:
  /// **'Use mock data'**
  String get welcomeUseMock;

  /// No description provided for @overviewDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get overviewDownload;

  /// No description provided for @overviewUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get overviewUpload;

  /// No description provided for @overviewDownloadTotal.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get overviewDownloadTotal;

  /// No description provided for @overviewUploadTotal.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get overviewUploadTotal;

  /// No description provided for @overviewMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get overviewMemory;

  /// No description provided for @overviewConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get overviewConnections;

  /// No description provided for @overviewMode.
  ///
  /// In en, this message translates to:
  /// **'Proxy mode'**
  String get overviewMode;

  /// No description provided for @overviewCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get overviewCore;

  /// No description provided for @modeRule.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get modeRule;

  /// No description provided for @modeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get modeGlobal;

  /// No description provided for @modeDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get modeDirect;

  /// No description provided for @actionFlushDns.
  ///
  /// In en, this message translates to:
  /// **'Flush DNS cache'**
  String get actionFlushDns;

  /// No description provided for @actionFlushFakeIp.
  ///
  /// In en, this message translates to:
  /// **'Flush Fake-IP cache'**
  String get actionFlushFakeIp;

  /// No description provided for @actionReloadConfig.
  ///
  /// In en, this message translates to:
  /// **'Reload config'**
  String get actionReloadConfig;

  /// No description provided for @actionUpdateGeo.
  ///
  /// In en, this message translates to:
  /// **'Update GEO databases'**
  String get actionUpdateGeo;

  /// No description provided for @proxiesTestLatency.
  ///
  /// In en, this message translates to:
  /// **'Test latency'**
  String get proxiesTestLatency;

  /// No description provided for @proxiesNodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 node} other{{count} nodes}}'**
  String proxiesNodeCount(int count);

  /// No description provided for @proxiesTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get proxiesTimeout;

  /// No description provided for @proxiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No proxy groups'**
  String get proxiesEmpty;

  /// No description provided for @proxiesGroupCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 group} other{{count} groups}}'**
  String proxiesGroupCount(int count);

  /// No description provided for @proxiesFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get proxiesFixed;

  /// No description provided for @actionExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get actionExpand;

  /// No description provided for @actionCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get actionCollapse;

  /// No description provided for @connectionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active connections'**
  String get connectionsEmpty;

  /// No description provided for @connectionsCloseAll.
  ///
  /// In en, this message translates to:
  /// **'Close all'**
  String get connectionsCloseAll;

  /// No description provided for @connectionsCloseAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Close 1 connection?} other{Close all {count} connections?}}'**
  String connectionsCloseAllConfirm(int count);

  /// No description provided for @connectionsClose.
  ///
  /// In en, this message translates to:
  /// **'Close connection'**
  String get connectionsClose;

  /// No description provided for @connectionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search host, IP, rule or chain'**
  String get connectionsSearchHint;

  /// No description provided for @connectionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 connection} other{{count} connections}}'**
  String connectionsCount(int count);

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @connectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Connection details'**
  String get connectionDetails;

  /// No description provided for @connectionHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get connectionHost;

  /// No description provided for @connectionDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get connectionDestination;

  /// No description provided for @connectionSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get connectionSource;

  /// No description provided for @connectionNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get connectionNetwork;

  /// No description provided for @connectionInbound.
  ///
  /// In en, this message translates to:
  /// **'Inbound'**
  String get connectionInbound;

  /// No description provided for @connectionRule.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get connectionRule;

  /// No description provided for @connectionChains.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get connectionChains;

  /// No description provided for @connectionProcess.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get connectionProcess;

  /// No description provided for @connectionDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get connectionDuration;

  /// No description provided for @rulesTabRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rulesTabRules;

  /// No description provided for @rulesTabProviders.
  ///
  /// In en, this message translates to:
  /// **'Rule providers'**
  String get rulesTabProviders;

  /// No description provided for @rulesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search rules'**
  String get rulesSearchHint;

  /// No description provided for @rulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rules'**
  String get rulesEmpty;

  /// No description provided for @ruleProvidersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rule providers'**
  String get ruleProvidersEmpty;

  /// No description provided for @ruleProvidersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rule provider} other{{count} rule providers}}'**
  String ruleProvidersCount(int count);

  /// No description provided for @ruleProviderRuleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rule} other{{count} rules}}'**
  String ruleProviderRuleCount(int count);

  /// No description provided for @ruleProviderUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String ruleProviderUpdatedAt(String time);

  /// No description provided for @logsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Waiting for logs…'**
  String get logsEmpty;

  /// No description provided for @logsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter logs'**
  String get logsSearchHint;

  /// No description provided for @logsLevelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get logsLevelTooltip;

  /// No description provided for @logLevelDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get logLevelDebug;

  /// No description provided for @logLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logLevelInfo;

  /// No description provided for @logLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get logLevelWarning;

  /// No description provided for @logLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logLevelError;

  /// No description provided for @logLevelSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get logLevelSilent;

  /// No description provided for @settingsBackends.
  ///
  /// In en, this message translates to:
  /// **'Backends'**
  String get settingsBackends;

  /// No description provided for @settingsAddBackend.
  ///
  /// In en, this message translates to:
  /// **'Add backend'**
  String get settingsAddBackend;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic color'**
  String get settingsDynamicColor;

  /// No description provided for @settingsDynamicColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the wallpaper or system accent color'**
  String get settingsDynamicColorSubtitle;

  /// No description provided for @settingsSeedColor.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get settingsSeedColor;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @settingsCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get settingsCore;

  /// No description provided for @settingsAllowLan.
  ///
  /// In en, this message translates to:
  /// **'Allow LAN'**
  String get settingsAllowLan;

  /// No description provided for @settingsAllowLanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let other devices on the network use this proxy'**
  String get settingsAllowLanSubtitle;

  /// No description provided for @settingsIpv6.
  ///
  /// In en, this message translates to:
  /// **'IPv6'**
  String get settingsIpv6;

  /// No description provided for @settingsLogLevel.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get settingsLogLevel;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A Material 3 Expressive remote panel for Mihomo'**
  String get settingsAboutSubtitle;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{s}s'**
  String durationSeconds(int s);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m}m {s}s'**
  String durationMinutes(int m, int s);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String durationHours(int h, int m);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
