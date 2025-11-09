extension PriceFormat on num {
  String toPriceString() {
    final str = toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

extension PriceFormatString on String {
  String toPriceString() {
    final str = replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

extension FixZiro on double {
  String fixZiroString() {
    // بررسی می‌کند آیا باقیمانده تقسیم عدد بر 1 صفر است یا خیر.
    if (this % 1 == 0) {
      return toInt().toString(); // اگر صفر بود، یعنی عدد صحیح است.
    } else {
      return toStringAsFixed(1); // در غیر این صورت، با یک رقم اعشار نمایش بده.
    }
  }
}
