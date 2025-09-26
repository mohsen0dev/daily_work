import 'package:daily_work/models/settings.dart'; // مدل تنظیمات
import 'package:daily_work/utils/price_format.dart'; // برای متد toPriceString
import 'package:flutter/material.dart'; // برای TextEditingController
import 'package:get/get.dart';

import '../employers_controller.dart'; // کنترلر کارفرمایان
import '../setting_controller.dart'; // کنترلر اصلی تنظیمات

/// کنترلر صفحه تنظیمات
/// این کنترلر مسئول مدیریت منطق و وضعیت صفحه تنظیمات است.
/// شامل مقادیر دستمزد روزانه/ساعتی، کارفرمای پیش‌فرض و ذخیره‌سازی تنظیمات.
class SettingsPageController extends GetxController {
  /// کنترلر اصلی تنظیمات برای دسترسی به تنظیمات جاری و ذخیره‌سازی.
  /// با استفاده از Get.find() نمونه‌ای که قبلاً ایجاد شده را دریافت می‌کند.
  late final SettingController settingController = Get.find<SettingController>();

  /// کنترلر کارفرمایان برای دسترسی به لیست کارفرمایان جهت انتخاب کارفرمای پیش‌فرض.
  /// با استفاده از Get.find() نمونه‌ای که قبلاً ایجاد شده را دریافت می‌کند.
  late final EmployersController employersController = Get.find<EmployersController>();

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
  late final TextEditingController dailyCtrl;

  /// کنترلر متن برای فیلد ورودی دستمزد ساعتی.
  /// (فعلاً در UI صفحه تنظیمات نمایش داده نمی‌شود.)
  late final TextEditingController hourlyCtrl;

  @override
  void onInit() {
    super.onInit();
    _loadInitialSettings(); // بارگذاری تنظیمات اولیه هنگام راه‌اندازی کنترلر
  }

  /// بارگذاری تنظیمات اولیه از [SettingController] و مقداردهی به متغیرها و کنترلرهای متن.
  void _loadInitialSettings() {
    final s = settingController.settings.value; // دسترسی به مقادیر تنظیمات جاری
    isDaily.value = s.isDaily;
    dailyWage.value = s.dailyWage;
    hourlyWage.value = s.hourlyWage;
    selectedEmployerId.value = s.defaultEmployerId;

    dailyCtrl = TextEditingController(text: dailyWage.value.toPriceString());
    hourlyCtrl = TextEditingController(text: hourlyWage.value.toPriceString());
  }

  @override
  void onClose() {
    dailyCtrl.dispose(); // آزاد کردن منابع کنترلر متن
    hourlyCtrl.dispose(); // آزاد کردن منابع کنترلر متن
    super.onClose();
  }

  /// ذخیره تنظیمات جدید.
  /// این متد مقادیر وارد شده در فیلدهای متن و انتخاب شده در Dropdown را
  /// جمع‌آوری کرده و یک مدل [SettingsModel] جدید ایجاد می‌کند و آن را ذخیره می‌نماید.
  Future<void> saveSettings() async {
    // تبدیل متن دستمزد روزانه به عدد صحیح پس از حذف کاماها.
    final int daily = int.tryParse(dailyCtrl.text.trim().replaceAll(',', '')) ?? 0;
    // تبدیل متن دستمزد ساعتی به عدد صحیح (فعلاً در UI نمایش داده نمی‌شود).
    final int hourly = int.tryParse(hourlyCtrl.text.trim().replaceAll(',', '')) ?? 0;

    final newSettings = SettingsModel(
      isDaily: isDaily.value, // استفاده از مقدار قابل مشاهده isDaily
      dailyWage: daily,
      hourlyWage: hourly,
      defaultEmployerId: selectedEmployerId.value, // استفاده از مقدار قابل مشاهده selectedEmployerId
      isDarkMode: settingController.isDarkMode, // وضعیت تم را از کنترلر اصلی تم می‌خوانیم
    );

    await settingController.saveSettings(newSettings); // ذخیره تنظیمات از طریق کنترلر اصلی

    Get.back<int>(result: 1); // بازگشت به صفحه قبلی با یک نتیجه برای نشان دادن موفقیت
    Get.snackbar(
      'موفق',
      'تنظیمات ذخیره شد',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white, // اضافه کردن رنگ متن برای خوانایی بهتر
    );
  }

  /// تغییر کارفرمای پیش‌فرض انتخاب شده.
  /// [value] شناسه کارفرمای جدید انتخاب شده.
  void setSelectedEmployer(int? value) {
    selectedEmployerId.value = value; // به‌روزرسانی مقدار قابل مشاهده
  }
}
