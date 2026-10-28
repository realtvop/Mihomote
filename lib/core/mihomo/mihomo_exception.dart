enum MihomoErrorKind {
  network,
  unauthorized,
  notFound,
  timeout,
  server,
  unknown,
}

/// The single error type surfaced by the API layer. UI maps [kind] to a
/// localized message; [message] carries the controller's own text, if any.
class MihomoException implements Exception {
  const MihomoException(this.kind, [this.message]);

  final MihomoErrorKind kind;
  final String? message;

  @override
  String toString() =>
      'MihomoException(${kind.name}${message == null ? '' : ': $message'})';
}
