import 'package:intl/intl.dart';

/// Small formatting helpers shared by every screen.

DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  if (s.isEmpty || s.startsWith('0000')) return null;
  return DateTime.tryParse(s.length >= 10 ? s : s);
}

String fmtDate(dynamic v, {String pattern = 'MMM d, yyyy'}) {
  final d = parseDate(v);
  return d == null ? '—' : DateFormat(pattern).format(d);
}

String fmtDateTime(dynamic v, {String pattern = 'MMM d, h:mm a'}) {
  final d = parseDate(v);
  return d == null ? '—' : DateFormat(pattern).format(d);
}

/// `09:00:00` -> `9:00 AM`
String fmtTime(dynamic v) {
  if (v == null) return '—';
  final s = v.toString();
  if (s.isEmpty) return '—';
  final p = s.split(':');
  if (p.length < 2) return s;
  final h = int.tryParse(p[0]) ?? 0;
  final m = int.tryParse(p[1]) ?? 0;
  return DateFormat('h:mm a').format(DateTime(2000, 1, 1, h, m));
}

String fmtTimeRange(dynamic start, dynamic end) => '${fmtTime(start)} – ${fmtTime(end)}';

/// `2026-10-21` for API calls.
String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String titleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

int toInt(dynamic v, [int fallback = 0]) => int.tryParse('${v ?? ''}') ?? (double.tryParse('${v ?? ''}')?.toInt() ?? fallback);
double toDouble(dynamic v, [double fallback = 0]) => double.tryParse('${v ?? ''}') ?? fallback;
String str(dynamic v, [String fallback = '']) => (v == null || '$v' == 'null') ? fallback : '$v';
