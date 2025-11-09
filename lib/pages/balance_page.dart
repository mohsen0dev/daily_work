import 'package:daily_work/models/employer.dart';
import 'package:daily_work/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // برای Clipboard و ByteData
import 'package:get/get.dart';
import 'package:daily_work/utils/jalali_utils.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart' as sh;

import '../controllers/workdays_controller.dart';
import '../controllers/employers_controller.dart';
import '../controllers/payments_controller.dart';
import '../models/payment.dart';
import '../models/report_record.dart'; // <<< ADD THIS IMPORT
import '../widgets/shared_filter_bar.dart'; // import ویجت فیلتر مشترک
import 'package:pdf/pdf.dart'; // برای PdfPageFormat و سایر انواع
import 'package:pdf/widgets.dart' as pw; // برای ویجت‌های PDF
import 'package:path_provider/path_provider.dart'; // برای مسیرهای فایل
import 'package:share_plus/share_plus.dart'; // برای اشتراک‌گذاری
import 'dart:io'; // برای File
// برای Uint8List

/// صفحه نمایش تراز حسابداری، شامل خلاصه‌ی کلی و جزئیات به تفکیک کارفرما.
/// امکان فیلتر کردن بر اساس کارفرما و بازه زمانی (ماهیانه) را فراهم می‌کند.
class BalancePage extends StatefulWidget {
  /// سازنده BalancePage.
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

/// State مربوط به ویجت BalancePage.
class _BalancePageState extends State<BalancePage> {
  /// شناسه کارفرمای انتخاب شده. اگر null باشد، همه کارفرماها را شامل می‌شود.
  int? selectedEmployerId;

  /// لیستی از ماه‌های انتخاب شده برای فیلتر.
  List<sh.Jalali> selectedMonths = [];

  /// مقداردهی اولیه State.
  /// فیلتر تاریخ را به صورت پیش‌فرض روی ماه جاری تنظیم می‌کند.
  @override
  void initState() {
    super.initState();
    _setDefaultMonthFilter();
  }

  /// تنظیم فیلتر ماه به صورت پیش‌فرض روی ماه جاری.
  void _setDefaultMonthFilter() {
    final now = sh.Jalali.now();
    setState(() {
      selectedMonths = [sh.Jalali(now.year, now.month, 1)];
    });
  }

  /// بررسی می‌کند که آیا تاریخ جلالی ورودی در بین ماه‌های انتخاب شده قرار دارد یا خیر.
  /// [jalaliDate] تاریخ جلالی به فرمت رشته.
  /// برمی‌گرداند true اگر تاریخ در بازه باشد یا هیچ ماهی انتخاب نشده باشد، در غیر این صورت false.
  bool _isInSelectedMonths(String jalaliDate) {
    if (selectedMonths.isEmpty) return true;
    final date = JalaliUtils.parseJalali(jalaliDate);
    return selectedMonths.any((m) => m.year == date.year && m.month == date.month);
  }

  /// ساختار اصلی UI صفحه تراز حسابداری.
  @override
  Widget build(BuildContext context) {
    final WorkDaysController workDaysController = Get.find<WorkDaysController>();
    final EmployersController employersController = Get.find<EmployersController>();
    final PaymentsController paymentsController = Get.find<PaymentsController>();

    return Scaffold(
      backgroundColor: Theme.of(context).secondaryHeaderColor.withAlpha(370),
      body: SafeArea(
        child: Column(
          children: [
            /// ویجت نوار فیلتر مشترک برای انتخاب کارفرما و ماه.
            SharedFilterBar(
              employersController: employersController,
              initialSelectedEmployerId: selectedEmployerId,
              initialSelectedMonths: selectedMonths,
              onEmployerChanged: (newId) {
                setState(() => selectedEmployerId = newId);
              },
              onDateFilterChanged: (newMonths) {
                setState(() => selectedMonths = newMonths);
              },
            ),
            Expanded(
              child: Obx(() {
                final workdaysMap = workDaysController.workdays;
                final allPayments = paymentsController.payments;
                final allEmployers = employersController.employers;

                /// محاسبه کل روزهای کاری فیلتر شده بر اساس تاریخ.
                final overallWorkedDays = workdaysMap.values
                    .where((d) => d.worked && _isInSelectedMonths(d.jalaliDate))
                    .fold<double>(0, (sum, d) => sum + (d.hours / 8));

                /// محاسبه کل دستمزد کسب شده فیلتر شده بر اساس تاریخ.
                final overallTotalEarned = workdaysMap.values
                    .where((d) => _isInSelectedMonths(d.jalaliDate))
                    .fold<int>(0, (sum, d) => sum + (d.wage ?? 0));

                /// محاسبه کل دریافتی‌ها فیلتر شده بر اساس تاریخ.
                final overallTotalPayments = allPayments
                    .where((p) => _isInSelectedMonths(p.value.jalaliDate))
                    .fold<int>(0, (sum, p) => sum + p.value.amount);

                /// محاسبه تراز کلی حساب.
                final overallBalance = overallTotalEarned - overallTotalPayments;

                /// لیست کارفرمایانی که باید بررسی شوند (بر اساس فیلتر کارفرما).
                final employersToConsider = selectedEmployerId == null
                    ? allEmployers
                    : allEmployers.where((entry) => entry.key == selectedEmployerId).toList();

                /// لیست کارفرماهای فعال با داده‌های محاسبه شده.
                final List<Map<String, dynamic>> activeEmployersData = [];
                for (final entry in employersToConsider) {
                  final employerId = entry.key;

                  final employerWorkdays = workdaysMap.values
                      .where(
                        (workday) =>
                            workday.employerId == employerId &&
                            workday.worked &&
                            _isInSelectedMonths(workday.jalaliDate),
                      )
                      .fold<double>(0, (sum, workday) => sum + (workday.hours / 8));

                  final employerPayments = allPayments
                      .where(
                        (p) => p.value.employerId == employerId && _isInSelectedMonths(p.value.jalaliDate),
                      )
                      .fold<int>(0, (sum, p) => sum + p.value.amount);

                  // فقط کارفرماهایی را اضافه کن که کارکرد یا پرداختی داشته‌اند.
                  if (employerWorkdays > 0 || employerPayments > 0) {
                    final employerEarn = workdaysMap.values
                        .where(
                          (workday) =>
                              workday.employerId == employerId && _isInSelectedMonths(workday.jalaliDate),
                        )
                        .fold<int>(0, (sum, workday) => sum + (workday.wage ?? 0));
                    final employerBalance = employerEarn - employerPayments;

                    activeEmployersData.add({
                      'entry': entry,
                      'workdays': employerWorkdays,
                      'earn': employerEarn,
                      'payments': employerPayments,
                      'balance': employerBalance,
                    });
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.all(8),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      /// کارت نمایش خلاصه‌ی کلی.
                      _sumDataCard(
                        context,
                        overallWorkedDays,
                        overallTotalEarned,
                        overallTotalPayments,
                        overallBalance,
                      ),
                      const SizedBox(height: 18),

                      // کارت‌های جزئیات به تفکیک کارفرما
                      if (activeEmployersData.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.groups, color: Colors.blue, size: 22),
                            SizedBox(width: 6),
                            Text(
                              'جزئیات به تفکیک کارفرما',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...activeEmployersData.map((data) {
                          final entry = data['entry'] as MapEntry<dynamic, EmployerModel>;
                          final employer = entry.value;
                          final employerId = entry.key;

                          return _employersCards(
                            employerId,
                            context,
                            employer,
                            data['workdays'],
                            data['earn'],
                            data['payments'],
                            data['balance'],
                            workDaysController,
                            paymentsController,
                            employersController,
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// ویجت کارت نمایش جزئیات هر کارفرما.
  /// [employerId] شناسه کارفرما برای `ValueKey`.
  /// [context] کانتکست ویجت.
  /// [employer] شیء کارفرما.
  /// [employerWorkdays] تعداد روزهای کاری برای این کارفرما.
  /// [employerEarn] دستمزد کل برای این کارفرما.
  /// [employerPayments] دریافتی کل از این کارفرما.
  /// [employerBalance] تراز حساب برای این کارفرما.
  /// [workDaysController] کنترلر روزهای کاری برای دسترسی به داده‌ها.
  /// [paymentsController] کنترلر پرداخت‌ها برای دسترسی به داده‌ها.
  /// [employersController] کنترلر کارفرماها برای دسترسی به نام کارفرماها.
  Widget _employersCards(
    int employerId,
    BuildContext context,
    EmployerModel employer,
    double employerWorkdays,
    int employerEarn,
    int employerPayments,
    int employerBalance,
    WorkDaysController workDaysController,
    PaymentsController paymentsController,
    EmployersController employersController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(employerId),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (BuildContext context, double value, Widget? child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset((1 - value) * 40, 0), child: child),
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.blue.shade100,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext ctx) => AlertDialog(
                title: Text(employer.name),
                content: Text(
                  'روزهای کاری: ${employerWorkdays.fixZiroString()} روز\nدستمزد: ${employerEarn.toPriceString()} تومان\nدریافتی: ${employerPayments.toPriceString()} تومان \n',
                ),
                actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('بستن'))],
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.all(4),
            elevation: 5,
            shadowColor: context.theme.dividerColor.withAlpha(100),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.theme.dividerColor.withAlpha(100)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue, size: 20),
                      const SizedBox(width: 6),
                      Text(employer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      OutlinedButton(
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        onPressed: () {
                          _showReportOptionsDialog(
                            // <<< CALL NEW DIALOG
                            context,
                            workDaysController,
                            paymentsController,
                            employersController,
                            employerId,
                          );
                        },
                        child: const Text('دریافت گزارش'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'روزهای کاری:',
                    employerWorkdays % 1 == 0
                        ? employerWorkdays.toInt().toString()
                        : employerWorkdays.toStringAsFixed(1),
                    Colors.orange,
                    fontSize: 14,
                    icon: Icons.calendar_today,
                    showCurrency: false,
                  ),
                  _buildSummaryRow(
                    'دستمزد:',
                    employerEarn.toPriceString(),
                    Colors.green,
                    fontSize: 14,
                    icon: Icons.attach_money,
                  ),
                  _buildSummaryRow(
                    'دریافتی:',
                    employerPayments.toPriceString(),
                    Colors.blue,
                    fontSize: 14,
                    icon: Icons.payments,
                  ),
                  _buildSummaryRow(
                    'تراز حساب:',
                    employerBalance.toPriceString(),
                    employerBalance >= 0 ? Colors.green : Colors.red,
                    fontSize: 14,
                    icon: employerBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ویجت کارت نمایش خلاصه‌ی کلی اطلاعات.
  /// [context] کانتکست ویجت.
  /// [overallWorkedDays] کل روزهای کاری محاسبه شده.
  /// [overallTotalEarned] کل دستمزد کسب شده.
  /// [overallTotalPayments] کل دریافتی‌ها.
  /// [overallBalance] تراز کلی حساب.
  Widget _sumDataCard(
    BuildContext context,
    double overallWorkedDays,
    int overallTotalEarned,
    int overallTotalPayments,
    int overallBalance,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 30), child: child),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.theme.dividerColor.withAlpha(100)),
        ),
        shadowColor: Colors.green.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text('خلاصه کلی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                'تعداد روز کاری:',
                overallWorkedDays % 1 == 0
                    ? overallWorkedDays.toInt().toString()
                    : overallWorkedDays.toStringAsFixed(1),
                Colors.orange,
                icon: Icons.calendar_today,
                showCurrency: false,
              ),
              _buildSummaryRow(
                'کل دستمزد:',
                overallTotalEarned.toPriceString(),
                Colors.green,
                icon: Icons.attach_money,
              ),
              _buildSummaryRow(
                'کل دریافتی:',
                overallTotalPayments.toPriceString(),
                Colors.blue,
                icon: Icons.payments,
              ),
              const Divider(),
              _buildSummaryRow(
                'تراز حساب:',
                overallBalance.toPriceString(),
                overallBalance >= 0 ? Colors.green : Colors.red,
                icon: overallBalance >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Container(
                  key: ValueKey(overallBalance >= 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: overallBalance >= 0
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.red.shade50, Colors.red.shade100],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (overallBalance >= 0 ? Colors.green : Colors.red).withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: overallBalance >= 0 ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        overallBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: overallBalance >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        overallBalance == 0
                            ? 'حساب شما تسویه است'
                            : overallBalance > 0
                            ? 'شما طلبکار هستید'
                            : overallBalance < 0
                            ? 'شما بدهکار هستید'
                            : '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: overallBalance == 0
                              ? Colors.blue
                              : overallBalance > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ویجت سطر خلاصه اطلاعات.
  /// [label] عنوان سطر (مثلاً "کل دستمزد").
  /// [value] مقدار مربوطه.
  /// [color] رنگ متن و آیکون.
  /// [fontSize] سایز فونت (پیش‌فرض 16).
  /// [icon] آیکون نمایش داده شده در کنار label.
  /// [showCurrency] آیا "تومان" نمایش داده شود یا "روز" (پیش‌فرض true).
  Widget _buildSummaryRow(
    String label,
    String value,
    Color color, {
    double fontSize = 16,
    IconData? icon,
    bool showCurrency = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: color, size: fontSize + 2), const SizedBox(width: 4)],
              Text(label, style: TextStyle(fontSize: fontSize)),
            ],
          ),
          Text(
            showCurrency ? '$value تومان' : '$value روز',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  /// نمایش دیالوگ انتخاب فرمت گزارش.
  Future<void> _showReportOptionsDialog(
    BuildContext context,
    WorkDaysController workDaysController,
    PaymentsController paymentsController,
    EmployersController employersController,
    int? filterEmployerId,
  ) async {
    return await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('انتخاب فرمت گزارش'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('گزارش متنی ساده'),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndCopyReport(
                    workDaysController,
                    paymentsController,
                    employersController,
                    filterEmployerId,
                    ReportFormat.plainText, // Pass format
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('گزارش Markdown'),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndCopyReport(
                    workDaysController,
                    paymentsController,
                    employersController,
                    filterEmployerId,
                    ReportFormat.markdown, // Pass format
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.picture_as_pdf), // Icon for PDF
                title: const Text('گزارش PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndCopyReport(
                    workDaysController,
                    paymentsController,
                    employersController,
                    filterEmployerId,
                    ReportFormat.pdf, // Pass format
                  );
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('انصراف'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// تولید یک گزارش متنی قالب‌بندی شده (Markdown/HTML/Plain Text/PDF) شامل روزهای کاری و دریافتی‌ها
  /// و کپی کردن آن به کلیپ‌بورد یا اشتراک‌گذاری فایل.
  /// [workDaysController] کنترلر روزهای کاری.
  /// [paymentsController] کنترلر دریافتی‌ها.
  /// [employersController] کنترلر کارفرماها.
  /// [filterEmployerId] (اختیاری) شناسه کارفرمای خاصی که گزارش برای او تهیه شود.
  /// [format] فرمت مورد نظر برای گزارش (PlainText, Markdown, HTML, PDF).
  void _generateAndCopyReport(
    WorkDaysController workDaysController,
    PaymentsController paymentsController,
    EmployersController employersController,
    int? filterEmployerId,
    ReportFormat format, // <<< ADD ReportFormat parameter
  ) async {
    // --- اطلاعات سربرگ گزارش ---
    String employerFilterName = 'همه کارفرماها';
    if (filterEmployerId != null) {
      final emp = employersController.employers.firstWhereOrNull((e) => e.key == filterEmployerId);
      if (emp != null) employerFilterName = emp.value.name;
    }

    String monthFilterText = 'کل دوره‌ها';
    if (selectedMonths.isNotEmpty) {
      if (selectedMonths.length == 1) {
        monthFilterText = '${selectedMonths.first.formatter.mN} ${selectedMonths.first.year}';
      } else {
        final sortedMonths = List<sh.Jalali>.from(selectedMonths)..sort((a, b) => a.compareTo(b));
        if (sortedMonths.length > 1) {
          monthFilterText =
              '${sortedMonths.first.formatter.mN} ${sortedMonths.first.year} - ${sortedMonths.last.formatter.mN} ${sortedMonths.last.year}';
        } else {
          monthFilterText = '${selectedMonths.length} ماه';
        }
      }
    }

    // --- جمع‌آوری و فیلتر کردن داده‌ها ---
    final List<ReportRecord> allRecords = []; // <<< Use ReportRecord

    // Filter and add workdays
    final filteredWorkdays = workDaysController.workdays.values
        .where(
          (d) =>
              (filterEmployerId == null || d.employerId == filterEmployerId) &&
              _isInSelectedMonths(d.jalaliDate),
        )
        .toList();

    for (final workday in filteredWorkdays) {
      String employerName = 'نامشخص';
      if (workday.employerId != null) {
        final emp = employersController.employers.firstWhereOrNull((e) => e.key == workday.employerId);
        if (emp != null) employerName = emp.value.name;
      }
      allRecords.add(
        ReportRecord(
          type: 'کارکرد',
          employerName: employerName,
          jalaliDate: workday.jalaliDate,
          amount: workday.wage ?? 0,
          hours: workday.hours,
          description: workday.description ?? '',
        ),
      );
    }

    // Filter and add payments
    final filteredPayments = paymentsController.payments
        .where(
          (e) =>
              (filterEmployerId == null || e.value.employerId == filterEmployerId) &&
              _isInSelectedMonths(e.value.jalaliDate),
        )
        .toList();

    for (final entry in filteredPayments) {
      final PaymentModel p = entry.value;
      String employerName = 'نامشخص';
      if (p.employerId != null) {
        final emp = employersController.employers.firstWhereOrNull((e) => e.key == p.employerId);
        if (emp != null) employerName = emp.value.name;
      }
      allRecords.add(
        ReportRecord(
          type: 'دریافتی',
          employerName: employerName,
          jalaliDate: p.jalaliDate,
          amount: p.amount,
          hours: null, // Payments don't have hours
          description: p.note ?? '',
        ),
      );
    }

    // Sort all records by date
    allRecords.sort((a, b) => a.jalaliDate.compareTo(b.jalaliDate));

    // --- محاسبه خلاصه‌ها ---
    final double currentWorkedDays = allRecords
        .where((r) => r.type == 'کارکرد' && r.hours != null)
        .fold<double>(0, (sum, r) => sum + (r.hours! / 8.0));
    final int currentTotalEarned = allRecords
        .where((r) => r.type == 'کارکرد')
        .fold<int>(0, (sum, r) => sum + r.amount);
    final int currentTotalPayments = allRecords
        .where((r) => r.type == 'دریافتی')
        .fold<int>(0, (sum, r) => sum + r.amount);
    final int currentBalance = currentTotalEarned - currentTotalPayments;
    final String currentBalanceStatus = currentBalance == 0
        ? 'حساب شما تسویه است'
        : currentBalance >= 0
        ? 'شما طلبکار هستید'
        : 'شما بدهکار هستید';

    // --- تولید گزارش بر اساس فرمت انتخاب شده ---
    String? finalReportContent; // Make nullable for PDF case

    switch (format) {
      case ReportFormat.plainText:
        finalReportContent = _generatePlainTextReport(
          monthFilterText,
          employerFilterName,
          allRecords,
          currentWorkedDays,
          currentTotalEarned,
          currentTotalPayments,
          currentBalance,
          currentBalanceStatus,
        );
        break;
      case ReportFormat.markdown:
        finalReportContent = _generateMarkdownReport(
          monthFilterText,
          employerFilterName,
          allRecords,
          currentWorkedDays,
          currentTotalEarned,
          currentTotalPayments,
          currentBalance,
          currentBalanceStatus,
        );
        break;

      case ReportFormat.pdf: // <<< NEW CASE FOR PDF
        await _generatePdfReport(
          // PDF needs to be awaited directly and handles sharing itself
          monthFilterText,
          employerFilterName,
          allRecords,
          currentWorkedDays,
          currentTotalEarned,
          currentTotalPayments,
          currentBalance,
          currentBalanceStatus,
        );
        return; // PDF handles its own sharing, no need for Clipboard
    }

    // --- کپی کردن گزارش متنی/Markdown/HTML به کلیپ‌بورد ---
    // This part only executes for non-PDF formats
    await Clipboard.setData(ClipboardData(text: finalReportContent));
    if (mounted) {
      Get.snackbar(
        'کپی شد',
        'گزارش ${format.toPersianString()} در کلیپ‌بورد قرار گرفت',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // --- متدهای تولید گزارش برای هر فرمت ---

  /// تولید گزارش متنی ساده.
  String _generatePlainTextReport(
    String monthFilterText,
    String employerFilterName,
    List<ReportRecord> allRecords,
    double currentWorkedDays,
    int currentTotalEarned,
    int currentTotalPayments,
    int currentBalance,
    String currentBalanceStatus,
  ) {
    final StringBuffer report = StringBuffer();

    report.writeln('--- گزارش مالی [$monthFilterText - کارفرما: $employerFilterName] ---');
    report.writeln('');

    if (allRecords.isEmpty) {
      report.writeln('هیچ کارکرد یا دریافتی در بازه انتخاب شده یافت نشد.');
    } else {
      for (final record in allRecords) {
        report.writeln('[${record.type}]');
        report.writeln('تاریخ: ${record.jalaliDate}');
        report.writeln('کارفرما: ${record.employerName}');
        if (record.type == 'کارکرد') {
          report.writeln('ساعات کار: ${record.hours} ساعت');
        }
        report.writeln('مبلغ: ${record.amount.toString().toPriceString()} تومان');
        if (record.description.isNotEmpty) {
          report.writeln('توضیحات: ${record.description}');
        }
        report.writeln('---'); // جداکننده بین رکوردها
      }
    }
    report.writeln('');

    report.writeln('--- خلاصه کلی ---');
    report.writeln(
      'تعداد روزهای کاری: ${currentWorkedDays % 1 == 0 ? currentWorkedDays.toInt() : currentWorkedDays.toStringAsFixed(1)} روز',
    );
    report.writeln('مجموع دستمزد: ${currentTotalEarned.toPriceString()} تومان');
    report.writeln('مجموع دریافتی: ${currentTotalPayments.toPriceString()} تومان');
    report.writeln('تراز حساب: ${currentBalance.toPriceString()} تومان ($currentBalanceStatus)');
    report.writeln('');

    return report.toString();
  }

  /// تولید گزارش Markdown.
  String _generateMarkdownReport(
    String monthFilterText,
    String employerFilterName,
    List<ReportRecord> allRecords,
    double currentWorkedDays,
    int currentTotalEarned,
    int currentTotalPayments,
    int currentBalance,
    String currentBalanceStatus,
  ) {
    final StringBuffer report = StringBuffer();

    report.writeln('# 📊 گزارش مالی');
    report.writeln('---');
    report.writeln('### تاریخ: $monthFilterText');
    report.writeln('### کارفرما: $employerFilterName');
    report.writeln('');

    report.writeln('## جزئیات تراکنش‌ها:');
    report.writeln('');

    if (allRecords.isEmpty) {
      report.writeln('هیچ کارکرد یا دریافتی در بازه انتخاب شده یافت نشد.');
    } else {
      for (final record in allRecords) {
        report.writeln('*   **${record.type} - ${record.jalaliDate}**');
        report.writeln('    *   **کارفرما:** ${record.employerName}');
        if (record.type == 'کارکرد') {
          report.writeln('    *   **ساعات کار:** ${record.hours} ساعت');
        }
        report.writeln('    *   **مبلغ:** ${record.amount.toString().toPriceString()} تومان');
        if (record.description.isNotEmpty) {
          report.writeln('    *   **توضیحات:** ${record.description}');
        }
        report.writeln('    ---');
      }
    }
    report.writeln('');

    report.writeln('## 📈 خلاصه کلی:');
    report.writeln('');
    report.writeln('| عنوان            | مقدار              |');
    report.writeln('| :--------------- | :------------------ |');
    report.writeln(
      '| تعداد روزهای کاری | ${currentWorkedDays % 1 == 0 ? currentWorkedDays.toInt() : currentWorkedDays.toStringAsFixed(1)} روز |',
    );
    report.writeln('| مجموع دستمزد     | ${currentTotalEarned.toPriceString()} تومان     |');
    report.writeln('| مجموع دریافتی    | ${currentTotalPayments.toPriceString()} تومان     |');
    report.writeln('| **تراز حساب**    | **${currentBalance.toPriceString()} تومان** |');
    report.writeln('| وضعیت           | $currentBalanceStatus   |');
    report.writeln('');

    return report.toString();
  }

  /// تولید گزارش PDF شامل روزهای کاری و دریافتی‌ها و اشتراک‌گذاری آن.
  Future<void> _generatePdfReport(
    String monthFilterText,
    String employerFilterName,
    List<ReportRecord> allRecords,
    double currentWorkedDays,
    int currentTotalEarned,
    int currentTotalPayments,
    int currentBalance,
    String currentBalanceStatus,
  ) async {
    final pdf = pw.Document();

    // فونت فارسی (مهم برای نمایش صحیح فارسی در PDF)
    // نیاز به یک فایل فونت .ttf فارسی دارید، مثلاً Vazirmatn.
    // آن را در پوشه assets/fonts/ در پروژه خود قرار دهید و در pubspec.yaml تعریف کنید.
    final ByteData fontData = await rootBundle.load('assets/fonts/sans.ttf'); // مسیر فونت را اصلاح کنید
    final pw.Font ttf = pw.Font.ttf(fontData);
    // ویجت‌های PDF (pw.*) با کدهای Flutter/Dart متفاوت هستند.
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData(
          // Use .with() for applying fonts
          defaultTextStyle: pw.TextStyle(font: ttf, fontSize: 12),
          // می‌توانید تم PDF را اینجا سفارشی کنید
        ),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl, // برای جهت متن فارسی
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'گزارش مالی',
                      style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 10),

                  // اطلاعات سربرگ
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [pw.Text('تاریخ: $monthFilterText'), pw.Text('کارفرما: $employerFilterName')],
                  ),
                  pw.SizedBox(height: 20),

                  // خلاصه کلی (با جدول)
                  pw.Text(
                    'خلاصه کلی:',
                    style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.TableHelper.fromTextArray(
                    headers: [
                      pw.Text(
                        'مقدار',
                        style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'عنوان',
                        style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                    ], // Changed order
                    data: <List<dynamic>>[
                      // CHANGE: Reorder data for each row
                      [
                        '${currentWorkedDays % 1 == 0 ? currentWorkedDays.toInt() : currentWorkedDays.toStringAsFixed(1)} روز',
                        'تعداد روزهای کاری',
                      ],
                      ['${currentTotalEarned.toPriceString()} تومان', 'مجموع دستمزد'],
                      ['${currentTotalPayments.toPriceString()} تومان', 'مجموع دریافتی'],
                      ['${currentBalance.toPriceString()} تومان', 'تراز حساب'],
                      [
                        pw.Text(
                          currentBalanceStatus,
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: currentBalanceStatus.contains('بدهکار') ? PdfColors.red : PdfColors.green,
                          ),
                        ),
                        'وضعیت',
                      ],
                    ],
                    cellAlignment: pw.Alignment.centerRight, // Ensure text is right-aligned
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    border: pw.TableBorder.all(width: 0.5),
                  ),
                  pw.SizedBox(height: 20),

                  // جزئیات تراکنش‌ها
                  pw.Text(
                    'جزئیات تراکنش‌ها:',
                    style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  if (allRecords.isEmpty)
                    pw.Text('هیچ کارکرد یا دریافتی در بازه انتخاب شده یافت نشد.')
                  else
                    ...allRecords.map((record) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,

                          children: [
                            pw.Text(
                              '${record.type} - ${record.jalaliDate}',
                              style: pw.TextStyle(
                                font: ttf,
                                fontWeight: pw.FontWeight.bold,
                                color: record.type == 'کارکرد' ? PdfColors.green : PdfColors.blue,
                              ),
                            ),
                            // pw.Text('کارفرما: ${record.employerName}'),
                            if (record.type == 'کارکرد')
                              pw.Text('ساعات کار: ${record.hours == 4 ? 'نصف روز' : 'یک روز'} '),
                            pw.Text('مبلغ: ${record.amount.toString().toPriceString()} تومان'),
                            if (record.description.isNotEmpty) pw.Text('توضیحات: ${record.description}'),
                            pw.Divider(),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // ذخیره و اشتراک‌گذاری PDF
    final Uint8List bytes = await pdf.save();

    // Get the temporary directory
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/report.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    // Share the PDF file
    // await Share.shareXFiles([XFile(filePath)], text: 'گزارش مالی'); // Use Share.shareXFiles for files
    final params = ShareParams(text: 'گزارش مالی', files: [XFile(filePath)]);

    final result = await SharePlus.instance.share(params);

    if (result.status == ShareResultStatus.success) {
      Get.snackbar('کپی شد', 'گزارش به اشتراک گذاشته شد', snackPosition: SnackPosition.BOTTOM);
      Get.snackbar('کپی شد', 'گزارش به اشتراک گذاشته شد', snackPosition: SnackPosition.BOTTOM);
    }
  }
}

enum ReportFormat {
  plainText,
  markdown,
  pdf, // <<< ADD PDF OPTION
}

extension ReportFormatExtension on ReportFormat {
  String toPersianString() {
    switch (this) {
      case ReportFormat.plainText:
        return 'متنی ساده';
      case ReportFormat.markdown:
        return 'Markdown';
      case ReportFormat.pdf: // <<< ADD PDF OPTION
        return 'PDF';
    }
  }
}
