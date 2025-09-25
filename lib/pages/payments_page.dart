// D:/flutter_project/daily_work/lib/pages/payments_page.dart

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
import '../widgets/shared_filter_bar.dart';

/// کلاس PaymentSummary برای نگهداری خلاصه دریافتی‌ها.
/// شامل عنوان (مثلاً "کل دریافتی‌ها" یا نام کارفرما)، مجموع مبالغ، و لیست دریافتی‌های مرتبط.
class PaymentSummary {
  /// عنوان خلاصه.
  final String title;

  /// مجموع مبالغ دریافتی.
  final int total;

  /// لیست دریافتی‌های مرتبط با این خلاصه.
  final List<MapEntry<dynamic, Payment>> payments;

  /// سازنده PaymentSummary.
  PaymentSummary({
    required this.title,
    required this.total,
    required this.payments,
  });
}

/// صفحه نمایش لیست دریافتی‌ها و خلاصه‌ی آن‌ها.
/// امکان فیلتر کردن بر اساس کارفرما و بازه زمانی (ماهیانه) را فراهم می‌کند.
class PaymentsPage extends StatefulWidget {
  /// سازنده PaymentsPage.
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

/// State مربوط به ویجت PaymentsPage.
class _PaymentsPageState extends State<PaymentsPage> {
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

  /// شناسه کارفرمای انتخاب شده. اگر null باشد، همه کارفرماها را شامل می‌شود.
  int? selectedEmployerId;

  /// لیستی از ماه‌های انتخاب شده برای فیلتر.
  List<sh.Jalali> selectedMonths = [];

  /// بررسی می‌کند که آیا تاریخ جلالی ورودی در بین ماه‌های انتخاب شده قرار دارد یا خیر.
  /// [jalaliDate] تاریخ جلالی به فرمت رشته.
  /// برمی‌گرداند true اگر تاریخ در بازه باشد یا هیچ ماهی انتخاب نشده باشد، در غیر این صورت false.
  bool _isInSelectedMonths(String jalaliDate) {
    if (selectedMonths.isEmpty) return true;
    final date = JalaliUtils.parseJalali(jalaliDate);
    return selectedMonths.any((m) => m.year == date.year && m.month == date.month);
  }

  /// لیست ورودی دریافتی‌ها را بر اساس کارفرما گروه بندی می‌کند و خلاصه‌هایی برای هر کارفرما می‌سازد.
  /// این متد خلاصه‌ی "کل دریافتی‌ها" را نمی‌سازد.
  /// [payments] لیستی از MapEntryهای دریافتی (Payment).
  /// [employersController] کنترلر کارفرماها برای دریافت نام کارفرما.
  /// برمی‌گرداند لیستی از PaymentSummary برای هر کارفرما.
  List<PaymentSummary> _getEmployerPaymentSummaries(
      List<MapEntry<dynamic, Payment>> payments,
      EmployersController employersController,
      ) {
    final Map<int?, List<MapEntry<dynamic, Payment>>> groupedPayments = {};
    for (var entry in payments) {
      final employerId = entry.value.employerId;
      if (!groupedPayments.containsKey(employerId)) {
        groupedPayments[employerId] = [];
      }
      groupedPayments[employerId]!.add(entry);
    }

    final List<PaymentSummary> employerSummaries = groupedPayments.entries.map((e) {
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

    return employerSummaries;
  }

  /// ساختار اصلی UI صفحه دریافتی‌ها.
  @override
  Widget build(BuildContext context) {
    final PaymentsController paymentsController = Get.find<PaymentsController>();
    final EmployersController employersController = Get.find<EmployersController>();

    return Scaffold(
      backgroundColor: Theme.of(context).secondaryHeaderColor.withAlpha(370),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddPaymentDialog(
          context,
          paymentsController,
          employersController,
        ),
      ),
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
                // مرحله ۱: فیلتر فقط بر اساس تاریخ برای کارت "کل دریافتی‌ها"
                final dateFilteredPayments = paymentsController.payments
                    .where((e) => _isInSelectedMonths(e.value.jalaliDate))
                    .toList();

                // اگر حتی برای تاریخ هم هیچ دریافتی وجود ندارد، کلاً پیام "هیچ دریافتی ثبت نشده" را نشان بده
                if (dateFilteredPayments.isEmpty) {
                  return const Center(child: Text('هیچ دریافتی ثبت نشده است'));
                }

                // ساخت خلاصه‌ی کلی به صورت دستی از لیست فیلتر شده با تاریخ
                final totalSummary = PaymentSummary(
                  title: 'کل دریافتی‌ها',
                  total: dateFilteredPayments.fold(
                      0, (sum, entry) => sum + entry.value.amount),
                  payments: dateFilteredPayments,
                );

                // مرحله ۲: اعمال فیلتر کارفرما بر روی لیست بالا برای کارت‌های کارفرمایان
                final fullyFilteredPayments = dateFilteredPayments
                    .where((e) =>
                selectedEmployerId == null ||
                    e.value.employerId == selectedEmployerId)
                    .toList();

                // ساخت خلاصه‌های کارفرمایان از لیست کاملاً فیلتر شده
                final employerSummaries = _getEmployerPaymentSummaries(
                    fullyFilteredPayments, employersController);

                // لیست نهایی خلاصه‌ها برای رندر شدن (شامل کارت کلی و کارت‌های کارفرما)
                final List<PaymentSummary> summariesToRender = [totalSummary];

                // بررسی اینکه آیا نیاز به نمایش پیام "تراکنشی برای این کارفرما ثبت نشده" هست
                final bool showNoEmployerPaymentsMessage =
                    selectedEmployerId != null && fullyFilteredPayments.isEmpty;

                // اگر کارفرمای خاصی انتخاب شده و تراکنشی برای او وجود ندارد، به لیست summariesToRender چیزی اضافه نمی‌کنیم.
                // اگر کارفرمایی انتخاب نشده یا تراکنش برای کارفرمای انتخاب شده وجود دارد، خلاصه‌های کارفرما را اضافه می‌کنیم.
                if (selectedEmployerId == null || fullyFilteredPayments.isNotEmpty) {
                  summariesToRender.addAll(employerSummaries);
                }

                return ListView.builder(
                  itemCount: summariesToRender.length + (showNoEmployerPaymentsMessage ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      // آیتم اول همیشه کارت "کل دریافتی‌ها" است
                      return _buildSummaryCard(
                        context,
                        summariesToRender[0],
                        selectedEmployerId == null, // کارت کلی در حالت "همه کارفرماها" باز باشد
                        index, // Index برای رنگ‌بندی
                        employersController,
                        paymentsController,
                      );
                    } else if (showNoEmployerPaymentsMessage && index == 1) {
                      // اگر پیام "تراکنشی یافت نشد" باید نمایش داده شود و این آیتم دوم است
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 150,
                          child: Center(
                            child: Text(
                              'تراکنشی برای این کارفرما در بازه انتخاب شده ثبت نشده است',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // باقی آیتم‌ها کارت‌های خلاصه‌ی کارفرماها هستند
                      // ایندکس را به خاطر جایگاه احتمالی پیام "تراکنشی یافت نشد" تنظیم می‌کنیم
                      final int actualSummaryIndex = index - (showNoEmployerPaymentsMessage ? 1 : 0);
                      return _buildSummaryCard(
                        context,
                        summariesToRender[actualSummaryIndex],
                        false, // کارت‌های کارفرما به صورت پیش‌فرض بسته باشند
                        index, // Index برای رنگ‌بندی
                        employersController,
                        paymentsController,
                      );
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// متد کمکی برای ساخت کارت خلاصه (کارت کلی یا کارت کارفرما).
  /// [context] کانتکست ویجت.
  /// [summary] شیء PaymentSummary حاوی اطلاعات خلاصه.
  /// [initiallyExpanded] آیا کارت در ابتدا باز باشد یا خیر.
  /// [cardIndex] ایندکس کارت در لیست برای تعیین رنگ‌بندی.
  /// [employersController] کنترلر کارفرماها.
  /// [paymentsController] کنترلر دریافتی‌ها.
  Widget _buildSummaryCard(
      BuildContext context,
      PaymentSummary summary,
      bool initiallyExpanded,
      int cardIndex, // اضافه شدن cardIndex برای رنگ‌بندی
      EmployersController employersController, // اضافه شدن کنترلرها
      PaymentsController paymentsController,
      ) {
    // منطق رنگ‌بندی کارت بر اساس ایندکس در لیست رندر شده
    Color? cardColor;
    if (cardIndex == 0) {
      cardColor = Colors.green[100];
    } else {
      cardColor = cardIndex.isEven ? Colors.amberAccent[100] : Colors.blue[100];
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 4,
      color: cardColor,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Row(
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
                    final employer = employersController
                        .employers
                        .firstWhereOrNull(
                          (e) => e.key == payment.employerId,
                    );
                    if (employer != null) {
                      employerName = employer.value.name;
                    }
                  }
                  final String dateStr = payment.jalaliDate;
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
  }

  /// کپی کردن خروجی CSV دریافتی‌های فیلتر شده به کلیپ‌بورد.
  /// [paymentsController] کنترلر دریافتی‌ها.
  /// [employersController] کنترلر کارفرماها.
  void _copyCsv(
      PaymentsController paymentsController,
      EmployersController employersController,
      ) async {
    final List<String> rows = <String>[];
    rows.add('amount,employer,date,note');
    final List<MapEntry<dynamic, Payment>> filtered = paymentsController.payments
        .where(
          (e) =>
      (selectedEmployerId == null ||
          e.value.employerId == selectedEmployerId) &&
          _isInSelectedMonths(e.value.jalaliDate),
    )
        .toList();
    for (final entry in filtered) {
      final Payment p = entry.value;
      String employerName = 'نامشخص';
      if (p.employerId != null) {
        final emp = employersController.employers.firstWhereOrNull(
              (e) => e.key == p.employerId,
        );
        if (emp != null) employerName = emp.value.name;
      }
      final String date = p.jalaliDate;
      final String note = (p.note ?? '').replaceAll(',', ' ');
      rows.add('${p.amount},$employerName,$date,$note');
    }
    final String csv = rows.join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      Get.snackbar(
        'کپی شد',
        'خروجی CSV در کلیپ‌بورد قرار گرفت',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// نمایش دیالوگ ویرایش یک دریافتی.
  /// [context] کانتکست ویجت.
  /// [paymentsController] کنترلر دریافتی‌ها.
  /// [employersController] کنترلر کارفرماها.
  /// [paymentKey] کلید (Key) دریافتی در Hive/دیتابیس.
  /// [payment] شیء Payment برای ویرایش.
  void _showEditPaymentDialog(
      BuildContext context,
      PaymentsController paymentsController,
      EmployersController employersController,
      dynamic paymentKey,
      Payment payment,
      ) {
    final TextEditingController amountController = TextEditingController(
      text: payment.amount.toString().toPriceString(),
    );
    final TextEditingController noteController = TextEditingController(text: payment.note ?? '');
    sh.Jalali selectedDate = JalaliUtils.parseJalali(payment.jalaliDate);
    int? selectedEmployerId = payment.employerId;
    String? employerErrorText;

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) => AlertDialog(
          title: const Text('ویرایش دریافتی'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
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
                    labelText: 'کارفرما *',
                    border: const OutlineInputBorder(),
                    errorText: employerErrorText,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('انتخاب کنید...'),
                    ),
                    ...employersController.employers.map((entry) {
                      return DropdownMenuItem<int?>(
                        value: entry.key,
                        child: Text(entry.value.name),
                      );
                    }),
                  ],
                  onChanged: (int? value) {
                    setStateDialog(() {
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
                    final p.Jalali? picked = await p.showPersianDatePicker(
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
                final int? amount = int.tryParse(
                  amountController.text.replaceAll(',', '').trim(),
                );

                if (selectedEmployerId == null) {
                  setStateDialog(() {
                    employerErrorText = 'لطفا یک کارفرما انتخاب کنید';
                  });
                  return;
                } else {
                  setStateDialog(() {
                    employerErrorText = null;
                  });
                }

                if (amount != null && amount > 0) {
                  final Payment editedPayment = Payment(
                    jalaliDate: JalaliUtils.formatFromJalali(selectedDate),
                    employerId: selectedEmployerId,
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

  /// نمایش دیالوگ جزئیات یک دریافتی.
  /// [context] کانتکست ویجت.
  /// [payment] شیء Payment برای نمایش جزئیات.
  /// [employersController] کنترلر کارفرماها برای دریافت نام کارفرما.
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
      builder: (BuildContext ctx) => AlertDialog(
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

  /// نمایش دیالوگ افزودن یک دریافتی جدید.
  /// [context] کانتکست ویجت.
  /// [paymentsController] کنترلر دریافتی‌ها.
  /// [employersController] کنترلر کارفرماها.
  void _showAddPaymentDialog(
      BuildContext context,
      PaymentsController paymentsController,
      EmployersController employersController,
      ) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    sh.Jalali selectedDate = sh.Jalali.now();
    int? selectedEmployerId;
    String? employerErrorText;

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) => AlertDialog(
          title: const Text('افزودن دریافتی'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
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
                    labelText: 'کارفرما *',
                    border: const OutlineInputBorder(),
                    errorText: employerErrorText,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('انتخاب کنید...'),
                    ),
                    ...employersController.employers.map((entry) {
                      return DropdownMenuItem<int?>(
                        value: entry.key,
                        child: Text(entry.value.name),
                      );
                    }),
                  ],
                  onChanged: (int? value) {
                    setStateDialog(() {
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
                    final p.Jalali? picked = await p.showPersianDatePicker(
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
                final int? amount = int.tryParse(
                  amountController.text.replaceAll(',', '').trim(),
                );

                if (selectedEmployerId == null) {
                  setStateDialog(() {
                    employerErrorText = 'لطفا یک کارفرما انتخاب کنید';
                  });
                  return;
                } else {
                  setStateDialog(() {
                    employerErrorText = null;
                  });
                }

                if (amount != null && amount > 0) {
                  final Payment newPayment = Payment(
                    jalaliDate: JalaliUtils.formatFromJalali(selectedDate),
                    employerId: selectedEmployerId,
                    amount: amount,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  paymentsController.addPayment(newPayment);
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
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  /// نمایش دیالوگ تأیید حذف یک دریافتی.
  /// [context] کانتکست ویجت.
  /// [controller] کنترلر دریافتی‌ها.
  /// [key] کلید (Key) دریافتی در Hive/دیتابیس.
  /// [amount] مبلغ دریافتی که قرار است حذف شود (برای نمایش در پیام تأیید).
  void _showDeleteConfirmDialog(
      BuildContext context,
      PaymentsController controller,
      dynamic key,
      int amount,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
}