/// Normalizes what a user typed as a controller address.
///
/// Accepts `host:port`, full URLs and reverse-proxy path prefixes. Adds
/// `http://` when no scheme is given, and drops credentials, query, fragment
/// and trailing slashes. Returns `null` for anything that isn't http(s).
Uri? parseControllerUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'http://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    pathSegments: segments.isEmpty ? null : segments,
  );
}
