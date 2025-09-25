// D:/flutter_project/daily_work/lib/pages/balance_page.dart

import 'package:daily_work/models/employer.dart';
import 'package:daily_work/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shamsi_date/shamsi_date.dart' as sh;
import 'package:daily_work/utils/jalali_utils.dart';

import '../controllers/workdays_controller.dart';
import '../controllers/employers_controller.dart';
import '../controllers/payments_controller.dart';
import '../widgets/shared_filter_bar.dart'; // import ویجت فیلتر مشترک

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

                /// محاسبه کل روزهای کاری فیلتر شده بر اساس تاریخ.
                final overallWorkedDays = workdaysMap.values
                    .where((d) => d.worked && _isInSelectedMonths(d.jalaliDate))
                    .fold<double>(0, (sum, d) => sum + (d.hours / 8));

                /// محاسبه کل دستمزد کسب شده فیلتر شده بر اساس تاریخ.
                final overallTotalEarned = workdaysMap.values
                    .where((d) => _isInSelectedMonths(d.jalaliDate))
                    .fold<int>(0, (sum, d) => sum + (d.wage ?? 0));

                /// محاسبه کل دریافتی‌ها فیلتر شده بر اساس تاریخ.
                final overallTotalPayments = paymentsController.payments
                    .where((p) => _isInSelectedMonths(p.value.jalaliDate))
                    .fold<int>(0, (sum, p) => sum + p.value.amount);

                /// محاسبه تراز کلی حساب.
                final overallBalance = overallTotalEarned - overallTotalPayments;

                /// لیست کارفرمایانی که باید نمایش داده شوند (بر اساس فیلتر کارفرما).
                final employersToDisplay = selectedEmployerId == null
                    ? employersController.employers
                    : employersController.employers
                    .where((entry) => entry.key == selectedEmployerId)
                    .toList();

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
                      if (employersToDisplay.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.groups, color: Colors.blue, size: 22),
                            SizedBox(width: 6),
                            Text(
                              'جزئیات به تفکیک کارفرما',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...employersToDisplay.map((entry) {
                          final employer = entry.value;
                          final employerId = entry.key;

                          /// محاسبه روزهای کاری برای کارفرمای خاص.
                          final employerWorkdays = workdaysMap.values
                              .where(
                                (workday) =>
                            workday.employerId == employerId &&
                                workday.worked &&
                                _isInSelectedMonths(workday.jalaliDate),
                          )
                              .fold<double>(
                            0,
                                (sum, workday) => sum + (workday.hours / 8),
                          );

                          /// محاسبه دستمزد برای کارفرمای خاص.
                          final employerEarn = workdaysMap.values
                              .where(
                                (workday) =>
                            workday.employerId == employerId &&
                                _isInSelectedMonths(workday.jalaliDate),
                          )
                              .fold<int>(
                            0,
                                (sum, workday) => sum + (workday.wage ?? 0),
                          );

                          /// محاسبه دریافتی‌ها برای کارفرمای خاص.
                          final employerPayments = paymentsController.payments
                              .where(
                                (p) =>
                            p.value.employerId == employerId &&
                                _isInSelectedMonths(p.value.jalaliDate),
                          )
                              .fold<int>(0, (sum, p) => sum + p.value.amount);

                          /// محاسبه تراز حساب برای کارفرمای خاص.
                          final employerBalance = employerEarn - employerPayments;

                          return _employersCards(
                            employerId,
                            context,
                            employer,
                            employerWorkdays,
                            employerEarn,
                            employerPayments,
                            employerBalance,
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
  Widget _employersCards(
      int employerId,
      BuildContext context,
      Employer employer,
      double employerWorkdays,
      int employerEarn,
      int employerPayments,
      int employerBalance,
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
            child: Transform.translate(
              offset: Offset((1 - value) * 40, 0),
              child: child,
            ),
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
                  'روزهای کاری: $employerWorkdays\nدستمزد: ${employerEarn.toPriceString()} تومان\nدریافتی: ${employerPayments.toPriceString()} تومان',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('بستن'),
                  ),
                ],
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.all(4),
            elevation: 5,
            shadowColor: context.theme.dividerColor.withAlpha(100),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: context.theme.dividerColor.withAlpha(100),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        employer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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
                    icon: employerBalance >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
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
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 30),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: context.theme.dividerColor.withAlpha(100),
          ),
        ),
        shadowColor: Colors.green.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'خلاصه کلی',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                icon: overallBalance >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
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
                          ? [
                        Colors.green.shade50,
                        Colors.green.shade100,
                      ]
                          : [Colors.red.shade50, Colors.red.shade100],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color:
                        (overallBalance >= 0 ? Colors.green : Colors.red)
                            .withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: overallBalance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        overallBalance >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: overallBalance >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        overallBalance >= 0 ? 'شما طلبکار هستید' : 'شما بدهکار هستید',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: overallBalance >= 0 ? Colors.green : Colors.red,
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
              if (icon != null) ...[
                Icon(icon, color: color, size: fontSize + 2),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: fontSize)),
            ],
          ),
          Text(
            showCurrency ? '$value تومان' : '$value روز',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}