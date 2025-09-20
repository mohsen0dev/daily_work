// removed unused developer import

import 'package:daily_work/utils/formater.dart';
import 'package:daily_work/utils/price_format.dart';
import 'package:daily_work/utils/jalali_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shamsi_date/shamsi_date.dart' as sh;
import 'package:persian_datetime_picker/persian_datetime_picker.dart' as p;

import '../controllers/payments_controller.dart';
import '../controllers/employers_controller.dart';
import '../models/payment.dart';

class PaymentSummary {
  final String title;
  final int total;
  final List<MapEntry<dynamic, Payment>> payments;

  PaymentSummary({
    required this.title,
    required this.total,
    required this.payments,
  });
}

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  int? selectedEmployerId;
  sh.Jalali? selectedStartDate;
  sh.Jalali? selectedEndDate;

  bool _isInRange(String jalaliDate) {
    if (selectedStartDate == null || selectedEndDate == null) return true;
    final date = JalaliUtils.parseJalali(jalaliDate);
    return !date.isBefore(selectedStartDate!) &&
        !date.isAfter(selectedEndDate!);
  }

  List<PaymentSummary> _getPaymentSummaries(
    List<MapEntry<dynamic, Payment>> payments,
    EmployersController employersController,
  ) {
    final totalSummary = PaymentSummary(
      title: 'کل دریافتی‌ها',
      total: payments.fold(0, (sum, entry) => sum + entry.value.amount),
      payments: payments,
    );

    final Map<int?, List<MapEntry<dynamic, Payment>>> groupedPayments = {};
    for (var entry in payments) {
      final employerId = entry.value.employerId;
      if (!groupedPayments.containsKey(employerId)) {
        groupedPayments[employerId] = [];
      }
      groupedPayments[employerId]!.add(entry);
    }

    final List<PaymentSummary> employerSummaries = groupedPayments.entries.map((
      e,
    ) {
      String title = 'نامشخص';
      if (e.key != null) {
        final employerEntry = employersController.employers.firstWhereOrNull(
          (emp) => emp.key == e.key,
        );
        if (employerEntry != null) {
          title = employerEntry.value.name;
        }
      }
      return PaymentSummary(
        title: title,
        total: e.value.fold(0, (sum, entry) => sum + entry.value.amount),
        payments: e.value,
      );
    }).toList();

    return [totalSummary, ...employerSummaries];
  }

  @override
  Widget build(BuildContext context) {
    final PaymentsController paymentsController =
        Get.find<PaymentsController>();
    final EmployersController employersController =
        Get.find<EmployersController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('دریافتی‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'کپی CSV',
            onPressed: () => _copyCsv(paymentsController, employersController),
          ),
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
        final filtered = paymentsController.payments
            .where(
              (e) =>
                  (selectedEmployerId == null ||
                      e.value.employerId == selectedEmployerId) &&
                  _isInRange(e.value.jalaliDate),
            )
            .toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('هیچ دریافتی ثبت نشده است'));
        }

        final summaries = _getPaymentSummaries(filtered, employersController);

        return ListView.builder(
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final summary = summaries[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 4,
              color: index == 0
                  ? Colors.green[100]
                  : index.isEven
                  ? Colors.amberAccent[100]
                  : Colors.blue[100],
              child: ExpansionTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          summary.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${summary.total.toString().toPriceString()} تومان',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                children: summary.payments.map((entry) {
                  final payment = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.payments, color: Colors.green),
                      title: Text(
                        '${payment.amount.toString().toPriceString()} تومان',
                        style: const TextStyle(color: Colors.green),
                      ),
                      subtitle: Text(
                        (() {
                          String employerName = 'نامشخص';
                          if (payment.employerId != null) {
                            final employer = employersController.employers
                                .firstWhereOrNull(
                                  (e) => e.key == payment.employerId,
                                );
                            if (employer != null) {
                              employerName = employer.value.name;
                            }
                          }
                          final dateStr = payment.jalaliDate;
                          return 'کارفرما: $employerName\n$dateStr';
                        })(),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditPaymentDialog(
                              context,
                              paymentsController,
                              employersController,
                              entry.key,
                              payment,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmDialog(
                              context,
                              paymentsController,
                              entry.key,
                              payment.amount,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showPaymentDetails(
                        context,
                        payment,
                        employersController,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // const Icon(Icons.filter_list),
            // const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int?>(
                borderRadius: BorderRadius.circular(10),
                value: selectedEmployerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'فیلتر کارفرما',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('همه کارفرماها'),
                  ),
                  ...employersController.employers.map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => selectedEmployerId = v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.all(
                        Radius.circular(10),
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.date_range),
                label: Text(
                  selectedStartDate == null || selectedEndDate == null
                      ? 'بازه تاریخ'
                      : '${selectedStartDate!.year}/${selectedStartDate!.month.toString().padLeft(2, '0')}/${selectedStartDate!.day.toString().padLeft(2, '0')} - ${selectedEndDate!.year}/${selectedEndDate!.month.toString().padLeft(2, '0')}/${selectedEndDate!.day.toString().padLeft(2, '0')}',
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () async {
                  final pRange =
                      selectedStartDate == null || selectedEndDate == null
                      ? null
                      : p.JalaliRange(
                          start: p.Jalali(
                            selectedStartDate!.year,
                            selectedStartDate!.month,
                            selectedStartDate!.day,
                          ),
                          end: p.Jalali(
                            selectedEndDate!.year,
                            selectedEndDate!.month,
                            selectedEndDate!.day,
                          ),
                        );
                  final picked = await p.showPersianDateRangePicker(
                    initialEntryMode: p.PersianDatePickerEntryMode.calendarOnly,
                    context: context,
                    firstDate: p.Jalali(1390, 1, 1),
                    lastDate: p.Jalali.now(),
                    initialDateRange: pRange,
                    initialDate: pRange?.start ?? p.Jalali.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedStartDate = sh.Jalali(
                        picked.start.year,
                        picked.start.month,
                        picked.start.day,
                      );
                      selectedEndDate = sh.Jalali(
                        picked.end.year,
                        picked.end.month,
                        picked.end.day,
                      );
                    });
                  }
                },
              ),
            ),
            // const SizedBox(width: 12),
            if (selectedStartDate != null && selectedEndDate != null)
              IconButton(
                tooltip: 'حذف بازه',
                onPressed: () => setState(() {
                  selectedStartDate = null;
                  selectedEndDate = null;
                }),
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
      ),
    );
  }

  void _copyCsv(
    PaymentsController paymentsController,
    EmployersController employersController,
  ) async {
    final rows = <String>[];
    rows.add('amount,employer,date,note');
    final filtered = paymentsController.payments
        .where(
          (e) =>
              (selectedEmployerId == null ||
                  e.value.employerId == selectedEmployerId) &&
              _isInRange(e.value.jalaliDate),
        )
        .toList();
    for (final entry in filtered) {
      final p = entry.value;
      String employerName = 'نامشخص';
      if (p.employerId != null) {
        final emp = employersController.employers.firstWhereOrNull(
          (e) => e.key == p.employerId,
        );
        if (emp != null) employerName = emp.value.name;
      }
      final date = p.jalaliDate;
      final note = (p.note ?? '').replaceAll(',', ' ');
      rows.add('${p.amount},$employerName,$date,$note');
    }
    final csv = rows.join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      Get.snackbar(
        'کپی شد',
        'خروجی CSV در کلیپ‌بورد قرار گرفت',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showEditPaymentDialog(
    BuildContext context,
    PaymentsController paymentsController,
    EmployersController employersController,
    dynamic paymentKey,
    Payment payment,
  ) {
    final amountController = TextEditingController(
      text: payment.amount.toString().toPriceString(),
    );
    final noteController = TextEditingController(text: payment.note ?? '');
    sh.Jalali selectedDate = JalaliUtils.parseJalali(payment.jalaliDate);
    int? selectedEmployerId =
        payment.employerId; // مقدار اولیه از payment گرفته می‌شود

    // اضافه کردن یک متغیر برای نگهداری وضعیت خطا
    String? employerErrorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          // تغییر نام setState
          title: const Text('ویرایش دریافتی'),
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
                  inputFormatters: [ThousandSeparatorInputFormatter()],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedEmployerId,
                  decoration: InputDecoration(
                    // اضافه کردن InputDecoration برای نمایش خطا
                    labelText: 'کارفرما *', // نشانه‌گذاری به عنوان فیلد ضروری
                    border: const OutlineInputBorder(),
                    errorText: employerErrorText, // نمایش متن خطا
                  ),
                  items: [
                    // اگر میخواهید "همه کارفرماها" به عنوان یک placeholder باشد:
                    const DropdownMenuItem(
                      value: null, // مقدار null برای این گزینه
                      child: Text('انتخاب کنید...'), // یا "هیچکدام"
                    ),
                    ...employersController.employers.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      // استفاده از setStateDialog
                      selectedEmployerId = value;
                      if (value != null) {
                        employerErrorText = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'تاریخ: ${JalaliUtils.formatFromJalali(selectedDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await p.showPersianDatePicker(
                      context: context,
                      initialDate: p.Jalali(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                      ),
                      firstDate: p.Jalali(1390, 1, 1),
                      lastDate: p.Jalali.now(),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        selectedDate = sh.Jalali(
                          picked.year,
                          picked.month,
                          picked.day,
                        );
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
                final amount = int.tryParse(
                  amountController.text.replaceAll(',', '').trim(),
                );

                // بررسی اینکه آیا کارفرما انتخاب شده است
                if (selectedEmployerId == null) {
                  setStateDialog(() {
                    // استفاده از setStateDialog برای نمایش خطا
                    employerErrorText = 'لطفا یک کارفرما انتخاب کنید';
                  });
                  return; // از ادامه اجرای تابع جلوگیری کنید
                } else {
                  setStateDialog(() {
                    // اگر انتخاب شده بود، خطا را پاک کنید
                    employerErrorText = null;
                  });
                }

                if (amount != null && amount > 0) {
                  final editedPayment = Payment(
                    jalaliDate: JalaliUtils.formatFromJalali(selectedDate),
                    employerId:
                        selectedEmployerId, // حالا مطمئن هستیم که null نیست
                    amount: amount,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  paymentsController.editPayment(paymentKey, editedPayment);
                  Navigator.pop(context);
                } else {
                  Get.snackbar(
                    'خطا',
                    'مبلغ وارد شده معتبر نیست.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('ذخیره تغییرات'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetails(
    BuildContext context,
    Payment payment,
    EmployersController employersController,
  ) {
    String employerName = 'نامشخص';
    if (payment.employerId != null) {
      final employer = employersController.employers.firstWhereOrNull(
        (e) => e.key == payment.employerId,
      );
      if (employer != null) {
        employerName = employer.value.name;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${payment.amount.toString().toPriceString()} تومان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('کارفرما: $employerName'),
            Text('تاریخ: ${payment.jalaliDate}'),
            if (payment.note != null) Text('یادداشت: ${payment.note}'),
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
  }

  void _showAddPaymentDialog(
    BuildContext context,
    PaymentsController paymentsController,
    EmployersController employersController,
  ) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    sh.Jalali selectedDate = sh.Jalali.now();
    int? selectedEmployerId; // مقدار اولیه null است

    // اضافه کردن یک متغیر برای نگهداری وضعیت خطا
    String? employerErrorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          // تغییر نام setState به setStateDialog برای جلوگیری از تداخل
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
                  inputFormatters: [ThousandSeparatorInputFormatter()],
                  // keyboardType: TextInputType.number, // ThousandSeparatorInputFormatter خودش این را مدیریت می‌کند
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedEmployerId,
                  decoration: InputDecoration(
                    // اضافه کردن InputDecoration برای نمایش خطا
                    labelText: 'کارفرما *', // نشانه‌گذاری به عنوان فیلد ضروری
                    border: const OutlineInputBorder(),
                    errorText: employerErrorText, // نمایش متن خطا
                  ),
                  items: [
                    // آیتم "همه کارفرماها" را به عنوان یک گزینه قابل انتخاب در نظر نگیرید
                    // یا اگر میخواهید باقی بماند، باید در منطق ذخیره سازی آن را مدیریت کنید.
                    // برای سادگی، فعلا آن را حذف می کنیم یا به عنوان placeholder در نظر می گیریم
                    // اگر میخواهید "همه کارفرماها" به عنوان یک placeholder باشد:
                    const DropdownMenuItem(
                      value: null, // مقدار null برای این گزینه
                      child: Text(
                        'انتخاب کنید...',
                      ), // یا "هیچکدام" یا "کارفرما را انتخاب کنید"
                    ),
                    ...employersController.employers.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      // استفاده از setStateDialog
                      selectedEmployerId = value;
                      // وقتی کاربر چیزی انتخاب می‌کند، خطا را پاک کنید
                      if (value != null) {
                        employerErrorText = null;
                      }
                    });
                  },
                  // validator: (value) { // همچنین می توانید از validator استفاده کنید
                  //   if (value == null) {
                  //     return 'لطفا یک کارفرما انتخاب کنید';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'تاریخ: ${JalaliUtils.formatFromJalali(selectedDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await p.showPersianDatePicker(
                      context: context,
                      initialDate: p.Jalali(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                      ),
                      firstDate: p.Jalali(1390, 1, 1),
                      lastDate: p.Jalali.now(),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        selectedDate = sh.Jalali(
                          picked.year,
                          picked.month,
                          picked.day,
                        );
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
                final amount = int.tryParse(
                  amountController.text.replaceAll(',', '').trim(),
                );

                // بررسی اینکه آیا کارفرما انتخاب شده است
                if (selectedEmployerId == null) {
                  setStateDialog(() {
                    // استفاده از setStateDialog برای نمایش خطا
                    employerErrorText = 'لطفا یک کارفرما انتخاب کنید';
                  });
                  return; // از ادامه اجرای تابع جلوگیری کنید
                } else {
                  setStateDialog(() {
                    // اگر انتخاب شده بود، خطا را پاک کنید
                    employerErrorText = null;
                  });
                }

                if (amount != null && amount > 0) {
                  final newPayment = Payment(
                    jalaliDate: JalaliUtils.formatFromJalali(selectedDate),
                    employerId:
                        selectedEmployerId, // حالا مطمئن هستیم که null نیست
                    amount: amount,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  paymentsController.addPayment(newPayment);
                  print(
                    'sabt tarikh= ${JalaliUtils.formatFromJalali(selectedDate)}',
                  );
                  Navigator.pop(context);
                } else {
                  // اینجا می‌توانید برای مبلغ نامعتبر نیز پیغام خطا نمایش دهید
                  // مثلا با استفاده از یک Snackbar یا تغییر border فیلد مبلغ
                  Get.snackbar(
                    'خطا',
                    'مبلغ وارد شده معتبر نیست.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
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

  // Replaced by JalaliUtils.formatJalali
}
