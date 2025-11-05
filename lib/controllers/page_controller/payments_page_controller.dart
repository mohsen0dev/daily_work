// lib/controllers/payments_page_controller.dart

import 'package:daily_work/utils/formater.dart';
import 'package:daily_work/utils/jalali_utils.dart';
import 'package:daily_work/utils/price_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart' as p;

import '../../models/payment.dart';
import '../employers_controller.dart';
import '../payments_controller.dart';
import '../setting_controller.dart';

/// کلاس PaymentSummary برای نگهداری خلاصه دریافتی‌ها.
/// شامل عنوان (مثلاً "کل دریافتی‌ها" یا نام کارفرما)، مجموع مبالغ، و لیست دریافتی‌های مرتبط.
class PaymentSummary {
  /// عنوان خلاصه.
  final String title;

  /// مجموع مبالغ دریافتی.
  final int total;

  /// لیست دریافتی‌های مرتبط با این خلاصه.
  final List<MapEntry<dynamic, PaymentModel>> payments;

  /// سازنده PaymentSummary.
  const PaymentSummary({required this.title, required this.total, required this.payments});
}

/// کنترلر صفحه دریافتی‌ها
/// این کنترلر مسئول مدیریت منطق و وضعیت صفحه دریافتی‌ها است.
/// شامل فیلتر کردن، گروه‌بندی، نمایش دیالوگ‌ها و مدیریت داده‌ها.
class PaymentsPageController extends GetxController {
  final PaymentsController _paymentsController = Get.find<PaymentsController>();
  final EmployersController _employersController = Get.find<EmployersController>();
  final SettingController _settingController = Get.find<SettingController>();

  final Rxn<int> selectedEmployerId = Rxn<int>();
  final RxList<p.Jalali> selectedMonths = <p.Jalali>[].obs;

  late final TextEditingController amountController;
  late final TextEditingController noteController;

  // متغیرهای وضعیت برای دیالوگ‌ها - اینها باید Rx باشند تا UI واکنش‌گرا باشد
  final Rxn<int> dialogSelectedEmployerId = Rxn<int>();
  final Rx<p.Jalali> dialogSelectedDate = p.Jalali.now().obs;
  final RxString employerErrorText = ''.obs; // برای نمایش خطای اعتبارسنجی کارفرما
  final RxList<PaymentSummary> _currentProcessedSummaries = <PaymentSummary>[].obs;
  List<PaymentSummary> get processedSummaries => _currentProcessedSummaries; // یک گتر ساده

  @override
  void onInit() {
    super.onInit();
    _setDefaultMonthFilter();
    amountController = TextEditingController();
    noteController = TextEditingController();
    ever(_paymentsController.payments, (_) => _updateProcessedSummaries());
    ever(selectedEmployerId, (_) => _updateProcessedSummaries());
    ever(selectedMonths, (_) => _updateProcessedSummaries());

    _updateProcessedSummaries(); //
  }

  // متدی برای به روز رسانی لیست خلاصه ها
  void _updateProcessedSummaries() {
    // مرحله ۱: فیلتر فقط بر اساس تاریخ برای کارت "کل دریافتی‌ها"
    final dateFilteredPayments = _paymentsController.payments
        .where((e) => _isInSelectedMonths(e.value.jalaliDate))
        .toList();

    // اگر هیچ پرداختی پس از فیلتر تاریخ وجود ندارد، لیست خالی برمی‌گردانیم
    if (dateFilteredPayments.isEmpty) {
      _currentProcessedSummaries.assignAll([]);
      return;
    }

    // ساخت خلاصه‌ی کلی به صورت دستی از لیست فیلتر شده با تاریخ
    final totalSummary = PaymentSummary(
      title: 'کل دریافتی‌ها',
      total: dateFilteredPayments.fold(0, (sum, entry) => sum + entry.value.amount),
      payments: dateFilteredPayments,
    );
    // مرحله ۲: اعمال فیلتر کارفرما بر روی لیست بالا برای کارت‌های کارفرمایان
    final fullyFilteredPayments = dateFilteredPayments
        .where((e) => selectedEmployerId.value == null || e.value.employerId == selectedEmployerId.value)
        .toList();

    // ساخت خلاصه‌های کارفرمایان از لیست کاملاً فیلتر شده
    final employerSummaries = _getEmployerPaymentSummaries(fullyFilteredPayments);

    final List<PaymentSummary> tempSummariesToRender = [totalSummary];

    // اگر کارفرمای خاصی انتخاب شده و تراکنشی برای او وجود ندارد، به لیست summariesToRender چیزی اضافه نمی‌کنیم.
    // اگر کارفرمایی انتخاب نشده یا تراکنش برای کارفرمای انتخاب شده وجود دارد، خلاصه‌های کارفرما را اضافه می‌کنیم.
    if (selectedEmployerId.value == null || fullyFilteredPayments.isNotEmpty) {
      tempSummariesToRender.addAll(employerSummaries);
    }

    _currentProcessedSummaries.assignAll(tempSummariesToRender);
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  void _setDefaultMonthFilter() {
    final now = p.Jalali.now();
    selectedMonths.assignAll([p.Jalali(now.year, now.month, 1)]);
  }

  void onEmployerChanged(int? newId) {
    selectedEmployerId.value = newId;
  }

  void onDateFilterChanged(List<p.Jalali> newMonths) {
    selectedMonths.assignAll(newMonths);
  }

  bool _isInSelectedMonths(String jalaliDate) {
    if (selectedMonths.isEmpty) return true;
    final date = JalaliUtils.parseJalali(jalaliDate);
    return selectedMonths.any((m) => m.year == date.year && m.month == date.month);
  }

  List<PaymentSummary> _getEmployerPaymentSummaries(List<MapEntry<dynamic, PaymentModel>> payments) {
    final Map<int?, List<MapEntry<dynamic, PaymentModel>>> groupedPayments = {};
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
        final employerEntry = _employersController.employers.firstWhereOrNull((emp) => emp.key == e.key);
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

  RxList<PaymentSummary> get processedSummariess {
    RxList<PaymentSummary>().bindStream(
      _paymentsController.payments.stream.map((_) {
        final dateFilteredPayments = _paymentsController.payments
            .where((e) => _isInSelectedMonths(e.value.jalaliDate))
            .toList();

        final totalSummary = PaymentSummary(
          title: 'کل دریافتی‌ها',
          total: dateFilteredPayments.fold(0, (sum, entry) => sum + entry.value.amount),
          payments: dateFilteredPayments,
        );

        final fullyFilteredPayments = dateFilteredPayments
            .where((e) => selectedEmployerId.value == null || e.value.employerId == selectedEmployerId.value)
            .toList();

        final employerSummaries = _getEmployerPaymentSummaries(fullyFilteredPayments);

        final List<PaymentSummary> summariesToRender = [totalSummary];

        if (selectedEmployerId.value == null || fullyFilteredPayments.isNotEmpty) {
          summariesToRender.addAll(employerSummaries);
        }
        return summariesToRender;
      }),
    );
    return _currentProcessedSummaries;
  }

  bool get showNoEmployerPaymentsMessage {
    if (selectedEmployerId.value == null) return false;

    final dateFilteredPayments = _paymentsController.payments
        .where((e) => _isInSelectedMonths(e.value.jalaliDate))
        .toList();

    final fullyFilteredPayments = dateFilteredPayments
        .where((e) => e.value.employerId == selectedEmployerId.value)
        .toList();

    return fullyFilteredPayments.isEmpty;
  }

  bool get hasNoPayments {
    final dateFilteredPayments = _paymentsController.payments
        .where((e) => _isInSelectedMonths(e.value.jalaliDate))
        .toList();
    return dateFilteredPayments.isEmpty;
  }

  String getEmployerNameById(int? employerId) {
    if (employerId == null) return 'نامشخص';
    final employer = _employersController.employers.firstWhereOrNull((e) => e.key == employerId);
    return employer?.value.name ?? 'نامشخص';
  }

  /// نمایش دیالوگ ویرایش یک دریافتی.
  Future<void> showEditPaymentDialog(BuildContext context, dynamic paymentKey, PaymentModel payment) async {
    amountController.text = payment.amount.toString().toPriceString();
    noteController.text = payment.note ?? '';
    dialogSelectedDate.value = JalaliUtils.parseJalali(payment.jalaliDate); // مقداردهی به Rx متغیر
    dialogSelectedEmployerId.value = payment.employerId; // مقداردهی به Rx متغیر
    employerErrorText.value = ''; // پاک کردن خطای قبلی

    await Get.dialog(
      AlertDialog(
        title: const Text('ویرایش دریافتی'),
        // اینجا دیگر نیازی به StatefulBuilder نیست، از Obx برای قسمت‌هایی که نیاز به ری‌بیلد دارند استفاده می‌کنیم
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مبلغ (تومان) *', border: OutlineInputBorder()),
                inputFormatters: <ThousandSeparatorInputFormatter>[ThousandSeparatorInputFormatter()],
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<int?>(
                  value: dialogSelectedEmployerId.value, // استفاده از .value
                  decoration: InputDecoration(
                    labelText: 'کارفرما *',
                    border: const OutlineInputBorder(),
                    errorText: employerErrorText.value.isEmpty
                        ? null
                        : employerErrorText.value, // استفاده از .value
                  ),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(value: null, child: Text('انتخاب کنید...')),
                    ..._employersController.employers.map((entry) {
                      return DropdownMenuItem<int?>(value: entry.key, child: Text(entry.value.name));
                    }),
                  ],
                  onChanged: (int? value) {
                    dialogSelectedEmployerId.value = value; // به‌روزرسانی Rx متغیر
                    if (value != null) {
                      employerErrorText.value = ''; // پاک کردن خطا
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => ListTile(
                  title: Text(
                    'تاریخ: ${JalaliUtils.formatFromJalali(dialogSelectedDate.value)}',
                  ), // استفاده از .value
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final p.Jalali? picked = await p.showPersianDatePicker(
                      context: context,
                      initialDate: dialogSelectedDate.value, // استفاده از .value
                      firstDate: p.Jalali(1390, 1, 1),
                      lastDate: p.Jalali.now(),
                    );
                    if (picked != null) {
                      dialogSelectedDate.value = picked; // به‌روزرسانی Rx متغیر
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'یادداشت', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Get.back(), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              final int? amount = int.tryParse(amountController.text.replaceAll(',', '').trim());

              if (dialogSelectedEmployerId.value == null) {
                employerErrorText.value = 'لطفا یک کارفرما انتخاب کنید'; // به‌روزرسانی Rx متغیر خطا
                return;
              } else {
                employerErrorText.value = '';
              }

              if (amount != null && amount > 0) {
                final PaymentModel editedPayment = PaymentModel(
                  jalaliDate: JalaliUtils.formatFromJalali(dialogSelectedDate.value),
                  employerId: dialogSelectedEmployerId.value,
                  amount: amount,
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                );
                _paymentsController.editPayment(paymentKey, editedPayment);
                Get.back();
                // نیازی به پاک کردن کنترلرها اینجا نیست، چون مقداردهی اولیه در ابتدای متد show...Dialog انجام می‌شود.
                // اما اگر می‌خواهید کاملاً پاک شوند، می‌توانید این خطوط را اضافه کنید:
                // amountController.clear();
                // noteController.clear();
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
    );
  }

  /// نمایش دیالوگ جزئیات یک دریافتی.
  Future<void> showPaymentDetails(BuildContext context, PaymentModel payment) async {
    final String employerName = getEmployerNameById(payment.employerId);

    await Get.dialog(
      AlertDialog(
        title: Text('${payment.amount.toString().toPriceString()} تومان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('کارفرما: $employerName'),
            Text('تاریخ: ${payment.jalaliDate}'),
            if (payment.note != null) Text('یادداشت: ${payment.note}'),
          ],
        ),
        actions: <Widget>[TextButton(onPressed: () => Get.back(), child: const Text('بستن'))],
      ),
    );
  }

  /// نمایش دیالوگ افزودن یک دریافتی جدید.
  Future<void> showAddPaymentDialog(BuildContext context) async {
    amountController.clear();
    noteController.clear();
    dialogSelectedDate.value = p.Jalali.now(); // مقداردهی به Rx متغیر
    dialogSelectedEmployerId.value =
        _settingController.settings.value.defaultEmployerId; // مقداردهی به Rx متغیر
    employerErrorText.value = ''; // پاک کردن خطای قبلی

    await Get.dialog(
      AlertDialog(
        title: const Text('افزودن دریافتی'),
        // اینجا دیگر نیازی به StatefulBuilder نیست، از Obx برای قسمت‌هایی که نیاز به ری‌بیلد دارند استفاده می‌کنیم
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مبلغ (تومان) *', border: OutlineInputBorder()),
                inputFormatters: <ThousandSeparatorInputFormatter>[ThousandSeparatorInputFormatter()],
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<int?>(
                  value: dialogSelectedEmployerId.value, // استفاده از .value
                  decoration: InputDecoration(
                    labelText: 'کارفرما *',
                    border: const OutlineInputBorder(),
                    errorText: employerErrorText.value.isEmpty
                        ? null
                        : employerErrorText.value, // استفاده از .value
                  ),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(value: null, child: Text('انتخاب کنید...')),
                    ..._employersController.employers.map((entry) {
                      return DropdownMenuItem<int?>(value: entry.key, child: Text(entry.value.name));
                    }),
                  ],
                  onChanged: (int? value) {
                    dialogSelectedEmployerId.value = value; // به‌روزرسانی Rx متغیر
                    if (value != null) {
                      employerErrorText.value = ''; // پاک کردن خطا
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => ListTile(
                  title: Text(
                    'تاریخ: ${JalaliUtils.formatFromJalali(dialogSelectedDate.value)}',
                  ), // استفاده از .value
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final p.Jalali? picked = await p.showPersianDatePicker(
                      context: context,
                      initialDate: dialogSelectedDate.value, // استفاده از .value
                      firstDate: p.Jalali(1390, 1, 1),
                      lastDate: p.Jalali.now(),
                    );
                    if (picked != null) {
                      dialogSelectedDate.value = picked; // به‌روزرسانی Rx متغیر
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'یادداشت', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Get.back(), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              final int? amount = int.tryParse(amountController.text.replaceAll(',', '').trim());

              if (dialogSelectedEmployerId.value == null) {
                employerErrorText.value = 'لطفا یک کارفرما انتخاب کنید'; // به‌روزرسانی Rx متغیر خطا
                return;
              } else {
                employerErrorText.value = '';
              }

              if (amount != null && amount > 0) {
                final PaymentModel newPayment = PaymentModel(
                  jalaliDate: JalaliUtils.formatFromJalali(dialogSelectedDate.value),
                  employerId: dialogSelectedEmployerId.value,
                  amount: amount,
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                );
                _paymentsController.addPayment(newPayment);
                Get.back();
                // amountController.clear(); // پاک کردن کنترلرها
                // noteController.clear();
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
    );
  }

  /// نمایش دیالوگ تأیید حذف یک دریافتی.
  Future<void> showDeleteConfirmDialog(BuildContext context, dynamic key, int amount) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text('آیا مطمئن هستید که می‌خواهید دریافتی ${amount.toString()} تومان را حذف کنید؟'),
        actions: <Widget>[
          TextButton(onPressed: () => Get.back(), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              _paymentsController.deletePayment(key);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
