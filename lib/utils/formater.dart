import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern(
      'en'); // 'en' or your desired locale for formatting

  // Helper to normalize Persian/Arabic digits to ASCII
  String _normalizeToAscii(String input) {
    const arabicIndic = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    const persian = {
      '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
      '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    };
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      buffer.write(persian[ch] ?? arabicIndic[ch] ?? ch);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue,) {
    // If the new value is empty, return it as is
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Normalize Persian/Arabic digits to ASCII then remove non-digit characters
    final String normalizedText = _normalizeToAscii(newValue.text);
    final String digitsOnly = normalizedText.replaceAll(RegExp(r'[^0-9]'), '');

    // If, after removing non-digits, the string is empty, return empty
    if (digitsOnly.isEmpty) {
      // Keep the original newValue if it only contained non-digits that were removed
      // Or return empty if you want to clear it completely.
      // Returning newValue allows the user to see what they typed even if it's invalid.
      // However, for a formatter, it might be better to clear it or return oldValue.
      // For simplicity here, we'll return an empty TextEditingValue.
      return TextEditingValue.empty;
    }

    try {
      // Parse the pure digits to a number
      final num number = int.parse(digitsOnly);

      // Format the number with a thousand separator
      final String formattedText = _formatter.format(number);

      // Calculate the new cursor position
      // This basic approach moves the cursor to the end.
      // More sophisticated cursor handling might be needed for edits in the middle of the text.
      int newCursorOffset = formattedText.length;

      // A slightly more robust way to handle cursor if needed,
      // but this is a complex problem for formatters.
      // For now, end of string is common.

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: newCursorOffset),
      );
    } catch (e) {
      // Log the error for debugging purposes
      // print('Error formatting input: $e');
      // In case of an error (e.g., number too large for int.parse, though less likely with digitsOnly),
      // return the old value to prevent a crash or unexpected behavior.
      return oldValue;
    }
  }
}