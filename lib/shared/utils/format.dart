import '../l10n.dart';

const _units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

/// Splits a byte count into a display number and unit, e.g. `('1.24', 'MB')`.
/// Keeps about three significant digits so live values don't jitter in width.
(String, String) splitBytes(num bytes) {
  var value = bytes.toDouble().abs();
  var unit = 0;
  while (value >= 1000 && unit < _units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 ? 0 : (value >= 100 ? 0 : (value >= 10 ? 1 : 2));
  return (value.toStringAsFixed(digits), _units[unit]);
}

String formatBytes(num bytes) {
  final (value, unit) = splitBytes(bytes);
  return '$value $unit';
}

String formatSpeed(num bytesPerSecond) => '${formatBytes(bytesPerSecond)}/s';

String formatDuration(AppLocalizations l10n, Duration duration) {
  if (duration.inHours > 0) {
    return l10n.durationHours(duration.inHours, duration.inMinutes % 60);
  }
  if (duration.inMinutes > 0) {
    return l10n.durationMinutes(duration.inMinutes, duration.inSeconds % 60);
  }
  return l10n.durationSeconds(duration.inSeconds.clamp(0, 59));
}
