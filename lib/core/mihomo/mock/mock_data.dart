// Sample data for MockMihomoApi. Shapes mirror real Mihomo responses so the
// same fromJson code paths are exercised (and reused as test fixtures).
import '../json.dart';

class MockNode {
  const MockNode(this.name, this.type, this.baseDelay);

  final String name;
  final String type;

  /// Typical latency in ms; `0` means this node always fails.
  final int baseDelay;
}

const mockNodes = <MockNode>[
  MockNode('🇭🇰 香港 01', 'Vless', 48),
  MockNode('🇭🇰 香港 02', 'Trojan', 63),
  MockNode('🇭🇰 香港 03', 'Hysteria2', 41),
  MockNode('🇯🇵 日本 01', 'Vmess', 86),
  MockNode('🇯🇵 日本 02', 'Shadowsocks', 102),
  MockNode('🇸🇬 新加坡 01', 'Vless', 118),
  MockNode('🇸🇬 新加坡 02', 'Tuic', 131),
  MockNode('🇺🇸 美国 01', 'Hysteria2', 192),
  MockNode('🇺🇸 美国 02', 'Trojan', 236),
  MockNode('🇹🇼 台湾 01', 'AnyTLS', 0),
  MockNode('🇰🇷 韩国 01', 'WireGuard', 74),
];

const mockAuto = '♻️ 自动选择';
const mockFallback = '🔯 故障转移';
const mockSelect = '🚀 节点选择';

/// Groups in config order. `now: null` lets the mock pick the first member.
final mockGroups = <JsonMap>[
  {
    'name': mockSelect,
    'type': 'Selector',
    'now': mockAuto,
    'all': [mockAuto, mockFallback, ...mockNodes.map((n) => n.name), 'DIRECT'],
  },
  {
    'name': mockAuto,
    'type': 'URLTest',
    'now': '🇭🇰 香港 03',
    'all': mockNodes.map((n) => n.name).toList(),
  },
  {
    'name': mockFallback,
    'type': 'Fallback',
    'now': '🇭🇰 香港 01',
    'all': ['🇭🇰 香港 01', '🇯🇵 日本 01', '🇸🇬 新加坡 01'],
  },
  {
    'name': '🤖 AI 服务',
    'type': 'Selector',
    'now': '🇺🇸 美国 01',
    'all': [
      '🇺🇸 美国 01',
      '🇺🇸 美国 02',
      '🇯🇵 日本 01',
      '🇸🇬 新加坡 01',
      mockSelect,
    ],
  },
  {
    'name': '📺 流媒体',
    'type': 'Selector',
    'now': '🇸🇬 新加坡 01',
    'all': [
      mockSelect,
      '🇭🇰 香港 01',
      '🇯🇵 日本 02',
      '🇸🇬 新加坡 01',
      '🇺🇸 美国 02',
    ],
  },
  {
    'name': '⚖️ 负载均衡',
    'type': 'LoadBalance',
    'now': null,
    'all': ['🇭🇰 香港 01', '🇭🇰 香港 02', '🇸🇬 新加坡 02'],
  },
  {
    'name': '🍎 Apple',
    'type': 'Selector',
    'now': 'DIRECT',
    'all': ['DIRECT', mockSelect],
  },
  {
    'name': '🛑 广告拦截',
    'type': 'Selector',
    'now': 'REJECT',
    'all': ['REJECT', 'DIRECT'],
  },
  {
    'name': '🐟 漏网之鱼',
    'type': 'Selector',
    'now': mockSelect,
    'all': [mockSelect, 'DIRECT'],
  },
];

const mockBuiltins = <String, String>{
  'DIRECT': 'Direct',
  'REJECT': 'Reject',
  'REJECT-DROP': 'RejectDrop',
  'PASS': 'Pass',
  'COMPATIBLE': 'Compatible',
};

final mockConfig = <String, Object?>{
  'port': 0,
  'socks-port': 0,
  'mixed-port': 7890,
  'redir-port': 0,
  'tproxy-port': 0,
  'allow-lan': true,
  'bind-address': '*',
  'mode': 'rule',
  'log-level': 'info',
  'ipv6': false,
  'tun': {'enable': true, 'stack': 'mixed', 'device': 'Meta'},
};

/// `(type, payload, proxy, size)`
const mockRules = <(String, String, String, int)>[
  ('RuleSet', 'reject_domain', '🛑 广告拦截', 12873),
  ('DomainSuffix', 'openai.com', '🤖 AI 服务', -1),
  ('DomainSuffix', 'anthropic.com', '🤖 AI 服务', -1),
  ('DomainSuffix', 'claude.ai', '🤖 AI 服务', -1),
  ('DomainSuffix', 'gemini.google.com', '🤖 AI 服务', -1),
  ('DomainKeyword', 'netflix', '📺 流媒体', -1),
  ('DomainSuffix', 'youtube.com', '📺 流媒体', -1),
  ('DomainSuffix', 'googlevideo.com', '📺 流媒体', -1),
  ('DomainSuffix', 'spotify.com', '📺 流媒体', -1),
  ('RuleSet', 'apple', '🍎 Apple', 832),
  ('DomainSuffix', 'github.com', mockSelect, -1),
  ('DomainSuffix', 'githubusercontent.com', mockSelect, -1),
  ('DomainSuffix', 'pub.dev', mockSelect, -1),
  ('DomainSuffix', 'telegram.org', mockSelect, -1),
  ('ProcessName', 'Telegram', mockSelect, -1),
  ('GeoSite', 'google', mockSelect, -1),
  ('GeoSite', 'cn', 'DIRECT', -1),
  ('RuleSet', 'private', 'DIRECT', 34),
  ('IPCIDR', '192.168.0.0/16', 'DIRECT', -1),
  ('IPCIDR', '10.0.0.0/8', 'DIRECT', -1),
  ('RuleSet', 'cn_ip', 'DIRECT', 8762),
  ('GeoIP', 'CN', 'DIRECT', -1),
  ('Match', '', '🐟 漏网之鱼', -1),
];

/// `(name, behavior, format, vehicleType, ruleCount)`
const mockRuleProviders = <(String, String, String, String, int)>[
  ('reject_domain', 'Domain', 'MrsRule', 'HTTP', 12873),
  ('apple', 'Domain', 'YamlRule', 'HTTP', 832),
  ('cn_ip', 'IPCIDR', 'MrsRule', 'HTTP', 8762),
  ('private', 'Classical', 'TextRule', 'File', 34),
];

/// `(host, port, process, rule, rulePayload, chain)`; chain is listed
/// group-first and reversed into Mihomo's node-first order when emitted.
const mockTargets = <(String, String, String, String, String, List<String>)>[
  (
    'www.google.com',
    '443',
    'Google Chrome',
    'GeoSite',
    'google',
    [mockSelect, mockAuto, '🇭🇰 香港 03'],
  ),
  (
    'api.openai.com',
    '443',
    'ChatGPT',
    'DomainSuffix',
    'openai.com',
    ['🤖 AI 服务', '🇺🇸 美国 01'],
  ),
  (
    'claude.ai',
    '443',
    'Claude',
    'DomainSuffix',
    'claude.ai',
    ['🤖 AI 服务', '🇺🇸 美国 01'],
  ),
  (
    'api.anthropic.com',
    '443',
    'node',
    'DomainSuffix',
    'anthropic.com',
    ['🤖 AI 服务', '🇺🇸 美国 01'],
  ),
  (
    'github.com',
    '443',
    'git',
    'DomainSuffix',
    'github.com',
    [mockSelect, mockAuto, '🇭🇰 香港 03'],
  ),
  (
    'avatars.githubusercontent.com',
    '443',
    'Safari',
    'DomainSuffix',
    'githubusercontent.com',
    [mockSelect, mockAuto, '🇭🇰 香港 03'],
  ),
  (
    'rr4---sn-i3b7knzl.googlevideo.com',
    '443',
    'Google Chrome',
    'DomainSuffix',
    'googlevideo.com',
    ['📺 流媒体', '🇸🇬 新加坡 01'],
  ),
  (
    'www.youtube.com',
    '443',
    'Google Chrome',
    'DomainSuffix',
    'youtube.com',
    ['📺 流媒体', '🇸🇬 新加坡 01'],
  ),
  (
    'pub.dev',
    '443',
    'dart',
    'DomainSuffix',
    'pub.dev',
    [mockSelect, mockAuto, '🇭🇰 香港 03'],
  ),
  (
    'storage.googleapis.com',
    '443',
    'flutter',
    'GeoSite',
    'google',
    [mockSelect, mockAuto, '🇭🇰 香港 03'],
  ),
  (
    'www.apple.com',
    '443',
    'Safari',
    'RuleSet',
    'apple',
    ['🍎 Apple', 'DIRECT'],
  ),
  (
    'gateway.icloud.com',
    '443',
    'cloudd',
    'RuleSet',
    'apple',
    ['🍎 Apple', 'DIRECT'],
  ),
  ('www.bilibili.com', '443', 'Safari', 'GeoSite', 'cn', ['DIRECT']),
  (
    'api.spotify.com',
    '443',
    'Spotify',
    'DomainSuffix',
    'spotify.com',
    ['📺 流媒体', '🇸🇬 新加坡 01'],
  ),
  (
    '149.154.167.51',
    '443',
    'Telegram',
    'ProcessName',
    'Telegram',
    [mockSelect, mockAuto, '🇭🇰 香港 03'],
  ),
  (
    'ads.example-tracker.com',
    '443',
    'Safari',
    'RuleSet',
    'reject_domain',
    ['🛑 广告拦截', 'REJECT'],
  ),
  (
    'x.com',
    '443',
    'Safari',
    'Match',
    '',
    ['🐟 漏网之鱼', mockSelect, mockAuto, '🇭🇰 香港 03'],
  ),
];

const mockSources = [
  '192.168.1.10',
  '192.168.1.23',
  '192.168.1.35',
  '127.0.0.1',
];
