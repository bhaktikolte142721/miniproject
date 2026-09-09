import 'package:intl/intl.dart';

/// Clinical formatting utilities for timestamps, durations, and vitals.
class Formatters {
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateFormat = DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _logFormat = DateFormat('HH:mm:ss');

  static String timeOnly(DateTime dt) => _timeFormat.format(dt);
  static String fullDate(DateTime dt) => _dateFormat.format(dt);
  static String logTimestamp(DateTime dt) => _logFormat.format(dt);

  static String durationCountdown(int secondsRemaining) {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatBpm(int bpm) => '$bpm BPM';
  static String formatSpo2(int spo2) => '$spo2%';
  static String formatTemp(double temp) => '${temp.toStringAsFixed(1)}°C';
}
