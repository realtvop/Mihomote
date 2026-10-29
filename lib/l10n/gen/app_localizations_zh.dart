// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Mihomote';

  @override
  String get navOverview => '概览';

  @override
  String get navProxies => '代理';

  @override
  String get navConnections => '连接';

  @override
  String get navRules => '规则';

  @override
  String get navLogs => '日志';

  @override
  String get navSettings => '设置';

  @override
  String get actionRetry => '重试';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '保存';

  @override
  String get actionDelete => '删除';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionAdd => '添加';

  @override
  String get actionBack => '返回';

  @override
  String get actionRefresh => '刷新';

  @override
  String get actionClose => '关闭';

  @override
  String get actionClear => '清空';

  @override
  String get actionPause => '暂停';

  @override
  String get actionResume => '继续';

  @override
  String get actionUpdate => '更新';

  @override
  String get actionCopy => '复制';

  @override
  String get actionDone => '已完成';

  @override
  String get actionCopied => '已复制';

  @override
  String get searchNoResults => '没有匹配的结果';

  @override
  String get errorNetwork => '连不上控制器，检查一下地址和网络';

  @override
  String get errorUnauthorized => '密钥不对';

  @override
  String get errorNotFound => '控制器上找不到这个资源';

  @override
  String get errorTimeout => '请求超时';

  @override
  String errorServer(String message) {
    return '控制器返回错误：$message';
  }

  @override
  String get errorUnknown => '出错了';

  @override
  String get errorNoBackend => '还没有选择后端';

  @override
  String get backendSwitcherTooltip => '切换后端';

  @override
  String get backendManage => '管理后端';

  @override
  String get backendAddTitle => '添加后端';

  @override
  String get backendEditTitle => '编辑后端';

  @override
  String get backendNameLabel => '名称';

  @override
  String get backendNameHint => '例如：家里路由器';

  @override
  String get backendUrlLabel => '控制器地址';

  @override
  String get backendUrlSupporting =>
      '即 external-controller 地址，例如 http://192.168.1.1:9090';

  @override
  String get backendUrlInvalid => '请输入有效的 http(s) 地址';

  @override
  String get backendSecretLabel => '密钥';

  @override
  String get backendSecretSupporting => '没有设置 secret 可以留空';

  @override
  String get backendTest => '测试连接';

  @override
  String backendTestSuccess(String version) {
    return '连接成功 · $version';
  }

  @override
  String get backendMockName => 'Mock 数据';

  @override
  String get backendMockDescription => '内置示例数据，仅用于开发调试';

  @override
  String backendDeleteConfirm(String name) {
    return '删除「$name」？';
  }

  @override
  String get backendActive => '当前';

  @override
  String get backendsTitle => '后端';

  @override
  String get welcomeTitle => '欢迎使用 Mihomote';

  @override
  String get welcomeSubtitle => '通过 external-controller 连接一个正在运行的 Mihomo 内核';

  @override
  String get welcomeConnect => '连接';

  @override
  String get welcomeUseMock => '使用 Mock 数据';

  @override
  String get overviewDownload => '下载';

  @override
  String get overviewUpload => '上传';

  @override
  String get overviewDownloadTotal => '累计下载';

  @override
  String get overviewUploadTotal => '累计上传';

  @override
  String get overviewMemory => '内存';

  @override
  String get overviewConnections => '连接数';

  @override
  String get overviewMode => '代理模式';

  @override
  String get overviewCore => '内核';

  @override
  String get modeRule => '规则';

  @override
  String get modeGlobal => '全局';

  @override
  String get modeDirect => '直连';

  @override
  String get actionFlushDns => '清空 DNS 缓存';

  @override
  String get actionFlushFakeIp => '清空 Fake-IP 缓存';

  @override
  String get actionReloadConfig => '重载配置';

  @override
  String get actionUpdateGeo => '更新 GEO 数据库';

  @override
  String get proxiesTestLatency => '测试延迟';

  @override
  String proxiesNodeCount(int count) {
    return '$count 个节点';
  }

  @override
  String get proxiesTimeout => '超时';

  @override
  String get proxiesEmpty => '没有策略组';

  @override
  String proxiesGroupCount(int count) {
    return '$count 个代理组';
  }

  @override
  String get proxiesFixed => '已固定';

  @override
  String get proxiesTabGroups => '策略组';

  @override
  String get proxiesTabProviders => '代理集';

  @override
  String proxyProvidersCount(int count) {
    return '$count 个代理集';
  }

  @override
  String get proxyProviderHealthCheck => '健康检查';

  @override
  String proxyProviderTraffic(String used, String total) {
    return '$used / $total';
  }

  @override
  String proxyProviderUsed(String used) {
    return '已用 $used';
  }

  @override
  String proxyProviderExpires(String date) {
    return '$date 到期';
  }

  @override
  String get proxyProviderExpired => '已过期';

  @override
  String get actionExpand => '展开';

  @override
  String get actionCollapse => '收起';

  @override
  String get connectionsEmpty => '当前没有连接';

  @override
  String get connectionsCloseAll => '全部断开';

  @override
  String connectionsCloseAllConfirm(int count) {
    return '断开全部 $count 个连接？';
  }

  @override
  String get connectionsClose => '断开连接';

  @override
  String get connectionsSearchHint => '搜索主机、IP、规则或代理链';

  @override
  String connectionsCount(int count) {
    return '$count 个连接';
  }

  @override
  String get statusPaused => '已暂停';

  @override
  String get connectionDetails => '连接详情';

  @override
  String get connectionHost => '主机';

  @override
  String get connectionDestination => '目标地址';

  @override
  String get connectionSource => '来源';

  @override
  String get connectionNetwork => '网络';

  @override
  String get connectionInbound => '入站';

  @override
  String get connectionRule => '规则';

  @override
  String get connectionChains => '代理链';

  @override
  String get connectionProcess => '进程';

  @override
  String get connectionDuration => '时长';

  @override
  String get rulesTabRules => '规则';

  @override
  String get rulesTabProviders => '规则集';

  @override
  String get rulesSearchHint => '搜索规则';

  @override
  String get rulesEmpty => '没有规则';

  @override
  String get ruleProvidersEmpty => '没有规则集';

  @override
  String ruleProvidersCount(int count) {
    return '$count 个规则集';
  }

  @override
  String ruleProviderRuleCount(int count) {
    return '$count 条规则';
  }

  @override
  String providerUpdatedAt(String time) {
    return '更新于 $time';
  }

  @override
  String get logsEmpty => '等待日志中…';

  @override
  String get logsSearchHint => '筛选日志';

  @override
  String get logsLevelTooltip => '日志等级';

  @override
  String get logLevelDebug => '调试';

  @override
  String get logLevelInfo => '信息';

  @override
  String get logLevelWarning => '警告';

  @override
  String get logLevelError => '错误';

  @override
  String get logLevelSilent => '静默';

  @override
  String get settingsBackends => '后端';

  @override
  String get settingsAddBackend => '添加后端';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeMode => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsDynamicColor => '动态取色';

  @override
  String get settingsDynamicColorSubtitle => '使用壁纸或系统强调色';

  @override
  String get settingsSeedColor => '主题色';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get settingsCore => '内核';

  @override
  String get settingsAllowLan => '允许局域网连接';

  @override
  String get settingsAllowLanSubtitle => '让局域网内的其他设备也能使用这个代理';

  @override
  String get settingsIpv6 => 'IPv6';

  @override
  String get settingsLogLevel => '日志等级';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsAboutSubtitle => 'Material 3 Expressive 风格的 Mihomo 远程面板';

  @override
  String durationSeconds(int s) {
    return '$s 秒';
  }

  @override
  String durationMinutes(int m, int s) {
    return '$m 分 $s 秒';
  }

  @override
  String durationHours(int h, int m) {
    return '$h 小时 $m 分';
  }
}
