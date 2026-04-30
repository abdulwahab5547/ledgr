import 'money.dart';

/// PKR formatting with Pakistani number grouping (lakh / crore).
/// 12345678 → "Rs 1,23,45,678".  Negative values use "−" (Unicode minus).
class PkrFormat {
  const PkrFormat._();

  /// Format an integer minor-units amount as "Rs 1,23,45,678".
  /// Set [sign] to true to prefix '+'/'−' explicitly (otherwise negative
  /// gets a '−' and positive has no prefix).
  static String fromMinor(
    int minorUnits, {
    bool sign = false,
    bool includeSymbol = true,
  }) {
    final neg = minorUnits < 0;
    final whole = (minorUnits.abs() / 100).round();
    final grouped = _pakGroup(whole.toString());
    final prefix = sign ? (neg ? '−' : '+') : (neg ? '−' : '');
    return '$prefix${includeSymbol ? 'Rs ' : ''}$grouped';
  }

  /// Format a [Money] as PKR — useful at UI boundaries.
  static String money(
    Money m, {
    bool sign = false,
    bool includeSymbol = true,
  }) =>
      fromMinor(m.minorUnits, sign: sign, includeSymbol: includeSymbol);

  /// Convert a numeric string to Pak grouping. "12345678" → "1,23,45,678".
  static String _pakGroup(String s) {
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = rest.length; i > 0; i -= 2) {
      final start = (i - 2).clamp(0, rest.length);
      final chunk = rest.substring(start, i);
      if (buf.isEmpty) {
        buf.write(chunk);
      } else {
        buf.write(',$chunk');
      }
    }
    final restGrouped = buf.toString().split(',').reversed.join(',');
    return '$restGrouped,$last3';
  }
}
