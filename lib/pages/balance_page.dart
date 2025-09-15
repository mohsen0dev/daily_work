import 'package:daily_work/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/workdays_controller.dart';
import '../controllers/employers_controller.dart';
import '../controllers/payments_controller.dart';

class BalancePage extends StatelessWidget {
  const BalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkDaysController workDaysController =
        Get.find<WorkDaysController>();
    final EmployersController employersController =
        Get.find<EmployersController>();
    final PaymentsController paymentsController =
        Get.find<PaymentsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('تسویه حساب'), centerTitle: true),
      body: Obx(() {
        final workdaysMap = workDaysController.workdays;
        final workedDays = workdaysMap.values
            .where((d) => d.worked)
            .fold<double>(0, (sum, d) => sum + (d.hours / 8));
        final totalEarned = workdaysMap.values.fold<int>(
          0,
          (sum, d) => sum + (d.wage ?? 0),
        );

        final totalPayments = paymentsController.payments.fold<int>(
          0,
          (sum, p) => sum + p.value.amount,
        );
        final balance = totalEarned - totalPayments;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card with Fade Animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                builder: (context, value, child) {
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
                  ),
                  shadowColor: Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.green,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            const Text(
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
                          workedDays % 1 == 0
                              ? workedDays.toInt().toString()
                              : workedDays.toStringAsFixed(1),
                          Colors.orange,
                          icon: Icons.calendar_today,
                          showCurrency: false,
                        ),
                        _buildSummaryRow(
                          'کل دستمزد:',
                          totalEarned.toPriceString(),
                          Colors.green,
                          icon: Icons.attach_money,
                        ),
                        _buildSummaryRow(
                          'کل دریافتی:',
                          totalPayments.toPriceString(),
                          Colors.blue,
                          icon: Icons.payments,
                        ),
                        const Divider(),
                        _buildSummaryRow(
                          'تراز حساب:',
                          balance.toPriceString(),
                          balance >= 0 ? Colors.green : Colors.red,
                          icon: balance >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Container(
                            key: ValueKey(balance >= 0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: balance >= 0
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
                                      (balance >= 0 ? Colors.green : Colors.red)
                                          .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  balance >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: balance >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  balance >= 0
                                      ? 'شما طلبکار هستید'
                                      : 'شما بدهکار هستید',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0
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
              ),
              const SizedBox(height: 16),

              // Per Employer Breakdown with Slide Animation & InkWell
              if (employersController.employers.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.groups, color: Colors.blue, size: 22),
                    const SizedBox(width: 6),
                    const Text(
                      'جزئیات به تفکیک کارفرما',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...employersController.employers.map((entry) {
                  final employer = entry.value;
                  final employerId = entry.key;
                  final employerWorkdays = workdaysMap.values
                      .where(
                        (workday) =>
                            workday.employerId == employerId && workday.worked,
                      )
                      .fold<double>(
                        0,
                        (sum, workday) => sum + (workday.hours / 8),
                      );
                  final employerEarn = workdaysMap.values
                      .where((workday) => workday.employerId == employerId)
                      .fold<int>(
                        0,
                        (sum, workday) => sum + (workday.wage ?? 0),
                      );
                  final employerPayments = paymentsController.payments
                      .where((p) => p.value.employerId == employerId)
                      .fold<int>(0, (sum, p) => sum + p.value.amount);
                  final employerBalance = employerEarn - employerPayments;
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
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
                        // امکان افزودن دیالوگ یا جزئیات بیشتر
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
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
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                employerBalance >= 0
                                    ? Colors.green
                                    : Colors.red,
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
                  );
                }),
              ],
            ],
          ),
        );
      }),
    );
  }

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
