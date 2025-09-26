import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/settings.dart';
import '../models/work_day.dart';
import '../models/payment.dart';

/// کنترلر مرکزی برای مدیریت تنظیمات برنامه از جمله تنظیمات دستمزد و تم.
class SettingController extends GetxController {
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
  static const String _settingsKey = 'app_settings'; // از این کلید برای ذخیره SettingsModel استفاده می‌کنیم

  @override
  void onInit() {
    super.onInit();
    _settingsBox = Hive.box<SettingsModel>('settings'); // نام باکس را بررسی کنید
    _workdayBox = Hive.box<WorkDayModel>('workdays');
    _paymentBox = Hive.box<PaymentModel>('payments');

    // اگر تنظیماتی ذخیره نشده است، مقادیر پیش‌فرض را قرار دهید.
    if (_settingsBox.isEmpty) {
      _settingsBox.put(
        _settingsKey,
        SettingsModel(
          isDaily: true,
          dailyWage: 1000000,
          hourlyWage: 0,
          isDarkMode: false,
          defaultEmployerId: null,
        ),
      );
    }
    // تنظیمات ذخیره شده را بارگذاری کنید.
    settings.value = _settingsBox.get(_settingsKey)!; // استفاده از ! چون مطمئنیم خالی نیست
  }

  /// ذخیره تنظیمات جدید در Hive و به‌روزرسانی Rx.
  /// [newSettings] مدل جدید تنظیمات برای ذخیره.
  Future<void> saveSettings(SettingsModel newSettings) async {
    await _settingsBox.put(_settingsKey, newSettings);
    settings.value = newSettings;
  }

  /// محاسبه کل دستمزد کسب شده بر اساس تنظیمات و کارفرمای مشخص.
  /// [employerId] (اختیاری) شناسه کارفرما برای فیلتر کردن.
  /// برمی‌گرداند مجموع دستمزدها.
  int totalEarned({int? employerId}) {
    final s = settings.value;
    int sum = 0;
    for (final e in _workdayBox.toMap().entries) {
      final d = e.value;
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

  /// محاسبه کل دریافتی‌ها بر اساس کارفرمای مشخص.
  /// [employerId] (اختیاری) شناسه کارفرما برای فیلتر کردن.
  /// برمی‌گرداند مجموع دریافتی‌ها.
  int totalPayments({int? employerId}) {
    int sum = 0;
    for (final e in _paymentBox.toMap().entries) {
      final p = e.value;
      if (employerId != null && p.employerId != employerId) continue;
      sum += p.amount;
    }
    return sum;
  }

  /// محاسبه تراز حساب (دستمزد منهای دریافتی) بر اساس کارفرمای مشخص.
  /// [employerId] (اختیاری) شناسه کارفرما برای فیلتر کردن.
  /// برمی‌گرداند تراز حساب.
  int balance({int? employerId}) {
    final earned = totalEarned(employerId: employerId);
    final paid = totalPayments(employerId: employerId);
    return earned - paid;
  }

  // --- منطق مربوط به تم که از ThemeService منتقل شده است ---

  /// حالت فعلی تم (تیره یا روشن) را بر اساس تنظیمات می‌خواند.
  ThemeMode get themeMode => settings.value.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// بررسی می‌کند که آیا تم فعلی برنامه تیره است یا خیر.
  bool get isDarkMode => settings.value.isDarkMode;

  /// وضعیت تم برنامه را تغییر می‌دهد.
  /// [value] اگر true باشد به تم تیره، وگرنه به تم روشن تغییر می‌کند.
  void switchTheme(bool value) {
    settings.update((val) {
      // از update برای تغییر Rx آبجکت استفاده کنید
      if (val != null) {
        val.isDarkMode = value;
      }
    });
    // ذخیره تغییر در Hive
    saveSettings(settings.value);
    // به GetX اطلاع می‌دهد تا تم را در GetMaterialApp به‌روزرسانی کند.
    Get.changeThemeMode(settings.value.isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }
}
