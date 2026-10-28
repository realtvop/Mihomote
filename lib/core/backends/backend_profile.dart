import 'package:flutter/foundation.dart';

import '../mihomo/controller_url.dart';
import '../mihomo/json.dart';

/// A saved controller the panel can connect to.
@immutable
class BackendProfile {
  const BackendProfile({
    required this.id,
    required this.name,
    required this.url,
    this.secret = '',
    this.isMock = false,
  });

  /// The built-in sample-data backend (debug builds only).
  const BackendProfile.mock({required this.name})
    : id = mockId,
      url = 'mock://sample',
      secret = '',
      isMock = true;

  factory BackendProfile.fromJson(JsonMap json) => BackendProfile(
    id: readString(json['id']),
    name: readString(json['name']),
    url: readString(json['url']),
    secret: readString(json['secret']),
    isMock: readBool(json['isMock']),
  );

  static const mockId = 'mock';

  final String id;
  final String name;

  /// Normalized controller URL, e.g. `http://192.168.1.1:9090`.
  final String url;

  // TODO: move to secure storage once a WASM-compatible option is settled
  // (see AGENTS.md "已知问题").
  final String secret;
  final bool isMock;

  Uri? get uri => isMock ? null : parseControllerUrl(url);

  /// What to show under the name: host and port without the scheme noise.
  String get displayAddress {
    final parsed = uri;
    if (parsed == null) return url;
    final path = parsed.path.isEmpty ? '' : parsed.path;
    return parsed.hasPort
        ? '${parsed.host}:${parsed.port}$path'
        : '${parsed.host}$path';
  }

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'secret': secret,
    if (isMock) 'isMock': true,
  };

  BackendProfile copyWith({String? name, String? url, String? secret}) =>
      BackendProfile(
        id: id,
        name: name ?? this.name,
        url: url ?? this.url,
        secret: secret ?? this.secret,
        isMock: isMock,
      );

  @override
  bool operator ==(Object other) =>
      other is BackendProfile &&
      other.id == id &&
      other.name == name &&
      other.url == url &&
      other.secret == secret &&
      other.isMock == isMock;

  @override
  int get hashCode => Object.hash(id, name, url, secret, isMock);
}
