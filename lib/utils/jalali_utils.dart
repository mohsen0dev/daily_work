import 'package:persian_datetime_picker/persian_datetime_picker.dart' as sh;

/// Utilities to work with Jalali dates
class JalaliUtils {
  /// Build a Jalali string from a Jalali instance
  static String formatFromJalali(sh.Jalali j) {
    final mm = j.month.toString().padLeft(2, '0');
    final dd = j.day.toString().padLeft(2, '0');
    return '${j.year}/$mm/$dd';
  }

  /// Parse a Jalali date string to Jalali instance
  static sh.Jalali parseJalali(String jalaliDate) {
    final parts = jalaliDate.split('/');
    if (parts.length != 3) {
      throw FormatException('Invalid Jalali date format: $jalaliDate');
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return sh.Jalali(year, month, day);
  }

  /// Get current Jalali date as string
  static String nowAsString() {
    return formatFromJalali(sh.Jalali.now());
  }
}
