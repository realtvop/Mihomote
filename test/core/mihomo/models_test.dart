import 'package:flutter_test/flutter_test.dart';
import 'package:mihomote/core/mihomo/controller_url.dart';
import 'package:mihomote/core/mihomo/json.dart';
import 'package:mihomote/core/mihomo/mihomo_api.dart';

void main() {
  group('parseControllerUrl', () {
    test('adds http and keeps port', () {
      expect(
        parseControllerUrl(' 192.168.1.1:9090 ').toString(),
        'http://192.168.1.1:9090',
      );
    });

    test('keeps reverse-proxy prefixes, drops query and trailing slash', () {
      expect(
        parseControllerUrl('https://example.com/mihomo/?x=1#y').toString(),
        'https://example.com/mihomo',
      );
    });

    test('accepts IPv6 hosts', () {
      expect(
        parseControllerUrl('http://[::1]:9090').toString(),
        'http://[::1]:9090',
      );
    });

    test('rejects empty and non-http input', () {
      expect(parseControllerUrl(''), isNull);
      expect(parseControllerUrl('ftp://host'), isNull);
      expect(parseControllerUrl('http://'), isNull);
    });
  });

  test('readDateTime handles Go nanoseconds and the zero time', () {
    expect(
      readDateTime('2026-10-29T08:00:00.123456789+08:00'),
      DateTime.parse('2026-10-29T08:00:00.123456+08:00'),
    );
    expect(readDateTime('0001-01-01T00:00:00Z'), isNull);
    expect(readDateTime(null), isNull);
  });

  test('ProxyNode parses groups and per-URL delay history', () {
    final node = ProxyNode.fromJson({
      'name': 'Auto',
      'type': 'URLTest',
      'now': 'HK',
      'all': ['HK', 'JP'],
      'testUrl': 'https://cp.cloudflare.com',
      'history': [
        {'time': '2026-10-29T08:00:00Z', 'delay': 120},
      ],
      'extra': {
        'https://cp.cloudflare.com': {
          'alive': true,
          'history': [
            {'time': '2026-10-29T08:00:00Z', 'delay': 88},
          ],
        },
      },
    });
    expect(node.groupType, ProxyGroupType.urlTest);
    expect(node.isGroup, isTrue);
    expect(node.isSelectable, isTrue);
    expect(node.delayFor(), 120);
    expect(node.delayFor('https://cp.cloudflare.com'), 88);
    expect(node.delayFor('https://unknown.example'), 120);
    expect(node.withDelay(0).delayFor(), 0);
  });

  test('ProxyNode tolerates missing and mistyped fields', () {
    final node = ProxyNode.fromJson({
      'name': 'Odd',
      'type': 42,
      'history': 'nope',
    });
    expect(node.type, '42');
    expect(node.isGroup, isFalse);
    expect(node.delayFor(), isNull);
  });

  test('ConnectionsSnapshot parses connections', () {
    final snapshot = ConnectionsSnapshot.fromJson({
      'downloadTotal': 2048,
      'uploadTotal': 1024,
      'connections': [
        {
          'id': 'abc',
          'metadata': {
            'network': 'tcp',
            'sourceIP': '192.168.1.10',
            'sourcePort': '50000',
            'destinationIP': '1.2.3.4',
            'destinationPort': '443',
            'host': '',
            'sniffHost': 'sniffed.example',
          },
          'upload': 10,
          'download': 20,
          'start': '2026-10-29T08:00:00.123456789Z',
          'chains': ['HK', 'Auto', 'Proxy'],
          'rule': 'DomainSuffix',
          'rulePayload': 'example',
        },
      ],
    });
    final c = snapshot.connections.single;
    expect(snapshot.downloadTotal, 2048);
    expect(c.metadata.displayHost, 'sniffed.example:443');
    expect(c.metadata.source, '192.168.1.10:50000');
    expect(c.chainLabel, 'Proxy → Auto → HK');
    expect(c.ruleLabel, 'DomainSuffix(example)');
    expect(c.start, isNotNull);
  });

  test('CoreConfig and enums parse leniently', () {
    final config = CoreConfig.fromJson({
      'mode': 'Global',
      'log-level': 'warn',
      'allow-lan': true,
      'tun': {'enable': true},
    });
    expect(config.mode, TunnelMode.global);
    expect(config.logLevel, LogLevel.warning);
    expect(config.allowLan, isTrue);
    expect(config.tunEnabled, isTrue);
    expect(CoreConfig.fromJson({}).mode, TunnelMode.unknown);
  });

  test('Rule reads extra fields and falls back to list index', () {
    final rule = Rule.fromJson({
      'type': 'Match',
      'payload': '',
      'proxy': 'Final',
      'extra': {'disabled': true, 'hitCount': 3},
    }, fallbackIndex: 7);
    expect(rule.index, 7);
    expect(rule.disabled, isTrue);
    expect(rule.hitCount, 3);
    expect(rule.size, -1);
  });
}
