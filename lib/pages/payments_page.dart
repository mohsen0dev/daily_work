import 'package:daily_work/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/payments_controller.dart';
import '../controllers/employers_controller.dart';
import '../models/payment.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentsController paymentsController = Get.put(PaymentsController());
    final EmployersController employersController = Get.put(
      EmployersController(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('دریافتی‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPaymentDialog(
              context,
              paymentsController,
              employersController,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (paymentsController.payments.isEmpty) {
          return const Center(child: Text('هیچ دریافتی ثبت نشده است'));
        }

        return ListView.builder(
          itemCount: paymentsController.payments.length,
          itemBuilder: (context, index) {
            final entry = paymentsController.payments[index];
            final payment = entry.value;
            final key = entry.key;

            // Find employer name
            String employerName = 'نامشخص';
            if (payment.employerId != null) {
              final employerEntry = employersController.employers
                  .firstWhereOrNull((e) => e.key == payment.employerId);
              if (employerEntry != null) {
                employerName = employerEntry.value.name;
              }
            }

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 30),
                    child: child,
                  ),
                );
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.green.shade100,
                onTap: () {
                  // امکان نمایش جزئیات بیشتر یا دیالوگ
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        '${payment.amount.toString().toPriceString()} تومان',
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('کارفرما: $employerName'),
                          Text('تاریخ: ${_formatDate(payment.date)}'),
                          if (payment.note != null)
                            Text('یادداشت: ${payment.note}'),
                        ],
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.payments,
                      color: Colors.green,
                      size: 28,
                    ),
                    title: Text(
                      '${payment.amount.toString().toPriceString()} تومان',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('کارفرما: $employerName'),
                        Text('تاریخ: ${_formatDate(payment.date)}'),
                        if (payment.note != null)
                          Text('یادداشت: ${payment.note}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmDialog(
                        context,
                        paymentsController,
                        key,
                        payment.amount,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddPaymentDialog(
    BuildContext context,
    PaymentsController paymentsController,
    EmployersController employersController,
  ) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    int? selectedEmployerId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('افزودن دریافتی'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'مبلغ (تومان) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedEmployerId,
                  decoration: const InputDecoration(
                    labelText: 'کارفرما (اختیاری)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('همه کارفرماها'),
                    ),
                    ...employersController.employers.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedEmployerId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('تاریخ: ${_formatDate(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'یادداشت',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(amountController.text.trim());
                if (amount != null && amount > 0) {
                  final payment = Payment(
                    date: selectedDate,
                    employerId: selectedEmployerId,
                    amount: amount,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  paymentsController.addPayment(payment);
                  Navigator.pop(context);
                }
              },
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    PaymentsController controller,
    dynamic key,
    int amount,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید دریافتی ${amount.toString()} تومان را حذف کنید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deletePayment(key);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
