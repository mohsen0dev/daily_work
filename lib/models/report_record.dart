// D:/flutter_project/daily_work/lib/models/report_record.dart

/// یک کلاس برای یکپارچه‌سازی رکورد کارهای انجام شده و دریافتی‌ها برای گزارش‌گیری.
class ReportRecord {
  /// نوع رکورد: 'کارکرد' یا 'دریافتی'.
  final String type;

  /// نام کارفرما.
  final String employerName;

  /// تاریخ جلالی رکورد.
  final String jalaliDate;

  /// مبلغ مرتبط با رکورد (دستمزد برای کارکرد، مبلغ دریافتی برای دریافتی).
  final int amount;

  /// ساعات کار (فقط برای 'کارکرد'، در غیر این صورت null).
  final double? hours;

  /// توضیحات/یادداشت مربوط به رکورد.
  final String description;

  /// سازنده ReportRecord.
  ReportRecord({
    required this.type,
    required this.employerName,
    required this.jalaliDate,
    required this.amount,
    this.hours,
    this.description = '',
  });
}
