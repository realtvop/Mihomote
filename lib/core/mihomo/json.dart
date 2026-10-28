/// Lenient JSON readers.
///
/// Mihomo responses differ between core versions, so models must never throw
/// on a missing or oddly-typed field. These helpers fall back to sane defaults.
library;

typedef JsonMap = Map<String, Object?>;

int readInt(Object? value, [int fallback = 0]) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v) ?? fallback,
  _ => fallback,
};

int? readIntOrNull(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};

String readString(Object? value, [String fallback = '']) => switch (value) {
  final String v => v,
  null => fallback,
  _ => value.toString(),
};

String? readStringOrNull(Object? value) => switch (value) {
  final String v when v.isNotEmpty => v,
  _ => null,
};

bool readBool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

JsonMap readMap(Object? value) =>
    value is Map ? value.cast<String, Object?>() : const <String, Object?>{};

List<Object?> readList(Object? value) =>
    value is List ? value : const <Object?>[];

List<String> readStringList(Object? value) =>
    readList(value).whereType<String>().toList(growable: false);

/// Parses Go's RFC 3339 timestamps. Go may emit nanoseconds, which
/// [DateTime.tryParse] doesn't accept, so the fraction is trimmed to
/// microseconds first. The zero time (`0001-01-01…`) is treated as absent.
DateTime? readDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final normalized = value.replaceFirstMapped(
    RegExp(r'\.(\d{6})\d+'),
    (m) => '.${m[1]}',
  );
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null || parsed.year <= 1) return null;
  return parsed;
}
