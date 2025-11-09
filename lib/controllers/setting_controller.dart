import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/settings.dart';
import '../models/work_day.dart';
import '../models/payment.dart';
import '../services/backup_restore_service.dart'; // سرویس پشتیبان‌گیری و بازیابی
import '../utils/price_format.dart'; // برای متد toPriceString
import 'employers_controller.dart'; // کنترلر کارفرمایان

/// کنترلر مرکزی برای مدیریت تنظیمات برنامه، تنظیمات دستمزد، تم و عملیات پشتیبان‌گیری/بازیابی.
class SettingsController extends GetxController {
  late final Box<SettingsModel> _settingsBox;
  late final Box<WorkDayModel> _workdayBox;
  late final Box<PaymentModel> _paymentBox;

  /// آبجکت Rx برای نگهداری تمام تنظیمات برنامه.
  final Rx<SettingsModel> settings = SettingsModel(
    isDaily: true,
    dailyWage: 0,
    hourlyWage: 0,
    defaultEmployerId: null,
    isDarkMode: Get.isPlatformDarkMode,
  ).obs;

  /// کلید برای ذخیره تنظیمات در Hive.
  static const String settingsKey = 'app_settings'; // کلید عمومی برای دسترسی در سرویس پشتیبان‌گیری

  /// کنترلر کارفرمایان برای دسترسی به لیست کارفرمایان جهت انتخاب کارفرمای پیش‌فرض.
  late final EmployersController employersController = Get.find<EmployersController>();

  /// سرویس مدیریت پشتیبان‌گیری و بازیابی.
  late final BackupRestoreService backupRestoreService = Get.find<BackupRestoreService>();

  /// وضعیت قابل مشاهده برای نشان دادن اینکه آیا عملیات پشتیبان‌گیری/بازیابی در حال انجام است.
  final isProcessing = false.obs;

  /// متغیر قابل مشاهده برای دستمزد روزانه.
  /// مقدار آن از تنظیمات اولیه بارگذاری شده و هنگام ذخیره استفاده می‌شود.
  final dailyWage = 0.obs;

  /// متغیر قابل مشاهده برای دستمزد ساعتی.
  /// (فعلاً در UI استفاده نمی‌شود اما برای مدل تنظیمات نگهداری می‌شود.)
  final hourlyWage = 0.obs;

  /// شناسه قابل مشاهده کارفرمای پیش‌فرض انتخاب شده.
  /// از نوع null-able است زیرا ممکن است کارفرمایی انتخاب نشده باشد.
  final selectedEmployerId = Rxn<int>(); // Rxn برای متغیرهای nullable

  /// وضعیت قابل مشاهده برای محاسبه روزانه یا ساعتی.
  /// (فعلاً در UI صفحه تنظیمات نمایش داده نمی‌شود.)
  final isDaily = true.obs;

  /// کنترلر متن برای فیلد ورودی دستمزد روزانه.
  /// این کنترلر در onInit مقداردهی می‌شود و در onClose dispose می‌گردد.
  // **تغییر مهم:** استفاده از Rx<TextEditingController> برای واکنش‌پذیری بهتر
  final TextEditingController dailyCtrl = TextEditingController();

  /// کنترلر متن برای فیلد ورودی دستمزد ساعتی.
  /// (فعلاً در UI صفحه تنظیمات نمایش داده نمی‌شود.)
  final Rx<TextEditingController> hourlyCtrl = Rx<TextEditingController>(TextEditingController());

  // متغیری برای نگهداری لیسنر، تا در onClose بتوان آن را dispose کرد
  late final Worker _settingsChangeListener;

  @override
  void onInit() {
    super.onInit();
    _settingsBox = Hive.box<SettingsModel>('settings');
    _workdayBox = Hive.box<WorkDayModel>('workdays');
    _paymentBox = Hive.box<PaymentModel>('payments');

    // اگر تنظیماتی ذخیره نشده است، مقادیر پیش‌فرض را قرار دهید.
    SettingsModel? loadedSettings = _settingsBox.get(settingsKey);
    if (loadedSettings == null) {
      loadedSettings = SettingsModel(
        isDaily: true,
        dailyWage: 1000000,
        hourlyWage: 0,
        isDarkMode: false,
        defaultEmployerId: null,
      );
      _settingsBox.put(settingsKey, loadedSettings);
    }
    settings.value = loadedSettings;
    _settingsBox.listenable().addListener(_refreshSettings);

    _loadInitialSettings(); // بارگذاری تنظیمات اولیه هنگام راه‌اندازی کنترلر

    // گوش دادن به تغییرات settings.value در SettingController
    _settingsChangeListener = ever(settings, (_) {
      updateLocalSettings(); // به‌روزرسانی مقادیر محلی وقتی تنظیمات اصلی تغییر می‌کند
    });
  }

  /// بارگذاری تنظیمات اولیه از [SettingController] و مقداردهی به متغیرها و کنترلرهای متن.
  void _loadInitialSettings() {
    final s = settings.value; // دسترسی به مقادیر تنظیمات جاری
    isDaily.value = s.isDaily;
    dailyWage.value = s.dailyWage;
    hourlyWage.value = s.hourlyWage;
    selectedEmployerId.value = s.defaultEmployerId;

    // به‌روزرسانی متن کنترلرها با مقدار اولیه
    dailyCtrl.text = dailyWage.value.toPriceString();
    hourlyCtrl.value.text = hourlyWage.value.toPriceString();
  }

  void _refreshSettings() {
    final SettingsModel? latestSettings = _settingsBox.get(settingsKey);
    if (latestSettings != null) {
      settings.value = latestSettings;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.changeThemeMode(settings.value.isDarkMode ? ThemeMode.dark : ThemeMode.light);
      });
    }
  }

  @override
  void update([List<Object>? ids, bool condition = true]) {
    _refreshSettings();
    super.update(ids, condition);
  }

  /// ذخیره تنظیمات جدید.
  Future<void> saveSettings2() async {
    // تبدیل متن دستمزد روزانه به عدد صحیح پس از حذف کاماها.
    final int daily = int.tryParse(dailyCtrl.value.text.trim().replaceAll(',', '')) ?? 0;
    // تبدیل متن دستمزد ساعتی به عدد صحیح (فعلاً در UI نمایش داده نمی‌شود).
    final int hourly = int.tryParse(hourlyCtrl.value.text.trim().replaceAll(',', '')) ?? 0;

    final newSettings = SettingsModel(
      isDaily: isDaily.value, // استفاده از مقدار قابل مشاهده isDaily
      dailyWage: daily,
      hourlyWage: hourly,
      defaultEmployerId: selectedEmployerId.value, // استفاده از مقدار قابل مشاهده selectedEmployerId
      isDarkMode: settings.value.isDarkMode, // وضعیت تم را از کنترلر اصلی تم می‌خوانیم
    );

    await saveSettings(newSettings); // ذخیره تنظیمات از طریق کنترلر اصلی

    Get.back<int>(result: 1); // بازگشت به صفحه قبلی با یک نتیجه برای نشان دادن موفقیت
    Get.snackbar(
      'موفق',
      'تنظیمات ذخیره شد',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white, // اضافه کردن رنگ متن برای خوانایی بهتر
    );
  }

  Future<void> saveSettings(SettingsModel newSettings) async {
    await _settingsBox.put(settingsKey, newSettings);
    settings.value = newSettings;
  }

  /// به‌روزرسانی مقادیر محلی و کنترلرهای متن بر اساس آخرین تنظیمات.
  void updateLocalSettings() {
    final s = settings.value;
    isDaily.value = s.isDaily;
    dailyWage.value = s.dailyWage;
    hourlyWage.value = s.hourlyWage;
    selectedEmployerId.value = s.defaultEmployerId;

    // اطمینان از به‌روزرسانی TextEditingController ها بدون تغییر مکان نما
    // اگر متن جدید با متن فعلی فرق دارد، آن را به‌روز کن.
    if (dailyCtrl.value.text != dailyWage.value.toPriceString()) {
      dailyCtrl.text = dailyWage.value.toPriceString();
    }
    if (hourlyCtrl.value.text != hourlyWage.value.toPriceString()) {
      hourlyCtrl.value.text = hourlyWage.value.toPriceString();
    }
  }

  int totalEarned({int? employerId}) {
    final s = settings.value;
    int sum = 0;
    for (final d in _workdayBox.values) {
      if (employerId != null && d.employerId != employerId) continue;
      if (!d.worked) continue;
      if (s.isDaily) {
        sum += s.dailyWage;
      } else {
        sum += (d.hours * s.hourlyWage).round();
      }
    }
    return sum;
  }

  int totalPayments({int? employerId}) {
    int sum = 0;
    for (final p in _paymentBox.values) {
      if (employerId != null && p.employerId != employerId) continue;
      sum += p.amount;
    }
    return sum;
  }

  int balance({int? employerId}) {
    final earned = totalEarned(employerId: employerId);
    final paid = totalPayments(employerId: employerId);
    return earned - paid;
  }

  ThemeMode get themeMode => settings.value.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  bool get isDarkMode => settings.value.isDarkMode;

  /// تغییر وضعیت تم (روشن/تاریک).
  void switchTheme(bool value) {
    settings.update((val) {
      if (val != null) {
        val.isDarkMode = value;
      }
    });
    saveSettings(settings.value);
  }

  /// تغییر کارفرمای پیش‌فرض انتخاب شده.
  /// [value] شناسه کارفرمای جدید انتخاب شده.
  void setSelectedEmployer(int? value) {
    selectedEmployerId.value = value; // به‌روزرسانی مقدار قابل مشاهده
  }

  /// انجام فرایند پشتیبان‌گیری از داده‌ها.
  Future<void> backupData() async {
    if (isProcessing.value) return;
    isProcessing.value = true;
    try {
      await backupRestoreService.backupData();
    } finally {
      isProcessing.value = false;
    }
  }

  /// انجام فرایند بازیابی اطلاعات از فایل پشتیبان.
  Future<void> restoreData() async {
    if (isProcessing.value) return;
    Get.defaultDialog(
      title: 'تایید بازیابی اطلاعات',
      content: const Text(
        'آیا مطمئن هستید که می‌خواهید اطلاعات فعلی را با اطلاعات فایل پشتیبان جایگزین کنید؟',
      ),
      textCancel: 'لغو',
      textConfirm: 'تایید',
      onCancel: () {
        // Get.back();
      },
      onConfirm: () async {
        Get.back(); // بستن دیالوگ
        isProcessing.value = true;
        try {
          await backupRestoreService.restoreData();
        } finally {
          isProcessing.value = false;
        }
      },
    );
  }

  @override
  void onClose() {
    _settingsBox.listenable().removeListener(_refreshSettings);
    _settingsChangeListener.dispose(); // آزاد کردن منابع لیسنر
    // dailyCtrl.dispose(); // آزاد کردن منابع کنترلر متن
    // hourlyCtrl.dispose(); // آزاد کردن منابع کنترلر متن
    super.onClose();
  }
}
