import '../json.dart';

class ConnectionMetadata {
  const ConnectionMetadata({
    this.network = '',
    this.type = '',
    this.sourceIp = '',
    this.sourcePort = '',
    this.destinationIp = '',
    this.destinationPort = '',
    this.host = '',
    this.sniffHost = '',
    this.process = '',
    this.processPath = '',
    this.inboundName = '',
    this.dnsMode = '',
  });

  factory ConnectionMetadata.fromJson(JsonMap json) => ConnectionMetadata(
    network: readString(json['network']),
    type: readString(json['type']),
    sourceIp: readString(json['sourceIP']),
    sourcePort: readString(json['sourcePort']),
    destinationIp: readString(json['destinationIP']),
    destinationPort: readString(json['destinationPort']),
    host: readString(json['host']),
    sniffHost: readString(json['sniffHost']),
    process: readString(json['process']),
    processPath: readString(json['processPath']),
    inboundName: readString(json['inboundName']),
    dnsMode: readString(json['dnsMode']),
  );

  final String network;
  final String type;
  final String sourceIp;
  final String sourcePort;
  final String destinationIp;
  final String destinationPort;
  final String host;
  final String sniffHost;
  final String process;
  final String processPath;
  final String inboundName;
  final String dnsMode;

  /// Best human-readable target: host, sniffed host, or bare IP.
  String get displayHost {
    final name = host.isNotEmpty
        ? host
        : (sniffHost.isNotEmpty ? sniffHost : destinationIp);
    return destinationPort.isEmpty ? name : '$name:$destinationPort';
  }

  String get source => sourcePort.isEmpty ? sourceIp : '$sourceIp:$sourcePort';

  String get destination => destinationPort.isEmpty
      ? destinationIp
      : '$destinationIp:$destinationPort';
}

class Connection {
  const Connection({
    required this.id,
    required this.metadata,
    this.upload = 0,
    this.download = 0,
    this.start,
    this.chains = const [],
    this.rule = '',
    this.rulePayload = '',
  });

  factory Connection.fromJson(JsonMap json) => Connection(
    id: readString(json['id']),
    metadata: ConnectionMetadata.fromJson(readMap(json['metadata'])),
    upload: readInt(json['upload']),
    download: readInt(json['download']),
    start: readDateTime(json['start']),
    chains: readStringList(json['chains']),
    rule: readString(json['rule']),
    rulePayload: readString(json['rulePayload']),
  );

  final String id;
  final ConnectionMetadata metadata;

  /// Bytes transferred so far.
  final int upload;
  final int download;
  final DateTime? start;

  /// Proxy chain, outermost first as sent by the core (`[node, ..., group]`).
  final List<String> chains;
  final String rule;
  final String rulePayload;

  String get ruleLabel => rulePayload.isEmpty ? rule : '$rule($rulePayload)';

  /// Chain in the order traffic flows through it: group → … → node.
  String get chainLabel => chains.reversed.join(' → ');
}

class ConnectionsSnapshot {
  const ConnectionsSnapshot({
    this.connections = const [],
    this.uploadTotal = 0,
    this.downloadTotal = 0,
    this.memory,
  });

  factory ConnectionsSnapshot.fromJson(JsonMap json) => ConnectionsSnapshot(
    connections: readList(json['connections'])
        .map((e) => Connection.fromJson(readMap(e)))
        .toList(growable: false),
    uploadTotal: readInt(json['uploadTotal']),
    downloadTotal: readInt(json['downloadTotal']),
    memory: readIntOrNull(json['memory']),
  );

  final List<Connection> connections;
  final int uploadTotal;
  final int downloadTotal;
  final int? memory;
}
