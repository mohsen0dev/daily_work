import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:daily_work/services/permission_service.dart';
// **فقط مدل‌های فعلی نگهداری شدند.**
import 'package:daily_work/models/employer.dart'; // مدل کارفرما
import 'package:daily_work/models/payment.dart'; // مدل پرداخت
import 'package:daily_work/models/work_day.dart'; // مدل روز کاری
import 'package:daily_work/models/settings.dart'; // مدل تنظیمات
import 'package:daily_work/utils/jalali_utils.dart'; // برای استفاده از JalaliUtils.parseJalali

import '../controllers/setting_controller.dart';
import '../controllers/workdays_controller.dart'; // مدل تنظیمات

// فرض بر این است که این متدها برای نمایش اعلان‌ها در دسترس هستند.
// در صورت عدم وجود، باید پیاده‌سازی شوند.
void notficationSuccess(String message) {
  Get.snackbar(
    'موفق',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.green,
    colorText: Colors.white,
  );
}

void notficationError({String message = 'عملیات با خطا مواجه شد'}) {
  Get.snackbar(
    'خطا',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.red,
    colorText: Colors.white,
  );
}

/// سرویس مدیریت پشتیبان‌گیری و بازیابی اطلاعات برنامه با استفاده از Hive.
class BackupRestoreService extends GetxService {
  /// سرویس دسترسی برای مدیریت مجوزهای فایل.
  late final PermissionService _permissionService;

  /// نام فایل پشتیبان.
  static const String _backupFileName = 'daily_work_backup.json';

  @override
  void onInit() {
    super.onInit();
    _permissionService = Get.find<PermissionService>();
  }

  /// بازگرداندن مسیر کامل فایل پشتیبان در دایرکتوری اسناد برنامه.
  Future<File> get _localFile async {
    // مسیر ذخیره‌سازی فایل پشتیبان در دایرکتوری Downloads.
    try {
      final directory = await getDownloadsDirectory().then((value) => value!);
      return File('${directory.path}/$_backupFileName');
    } catch (e) {
      Get.log('خطا در بازیابی مسیر پشتیبان: $e');
      return File('');
    }
  }

  /// انجام فرایند پشتیبان‌گیری کامل از اطلاعات Hive.
  /// فقط شامل باکس‌های اصلی (تنظیمات، کارفرمایان، پرداخت‌ها، روزهای کاری).
  Future<File?> backupData() async {
    // 1. بررسی و درخواست دسترسی‌های ذخیره‌سازی.
    if (!await _permissionService.requestStoragePermissions()) {
      Get.log('مجوز ذخیره‌سازی اعطا نشد.');
      return null;
    }

    try {
      // باکس‌های اصلی
      List<SettingsModel> settingsList =
          []; // از آنجایی که settings سینگلتون است، معمولاً یک آیتم دارد.
      List<EmployerModel> employers = [];
      List<PaymentModel> payments = [];
      List<WorkDayModel> workdays = [];

      // جمع‌آوری داده‌ها
      try {
        if (!Hive.isBoxOpen('settings')) {
          await Hive.openBox<SettingsModel>('settings');
        }
        settingsList = Hive.box<SettingsModel>('settings').values.toList();
      } catch (e) {
        Get.log('خطا در خواندن باکس settings: $e');
      }
      try {
        if (!Hive.isBoxOpen('employers')) {
          await Hive.openBox<EmployerModel>('employers');
        }
        employers = Hive.box<EmployerModel>('employers').values.toList();
      } catch (e) {
        Get.log('خطا در خواندن باکس employers: $e');
      }
      try {
        if (!Hive.isBoxOpen('payments')) {
          await Hive.openBox<PaymentModel>('payments');
        }
        payments = Hive.box<PaymentModel>('payments').values.toList();
      } catch (e) {
        Get.log('خطا در خواندن باکس payments: $e');
      }
      try {
        if (!Hive.isBoxOpen('workdays')) {
          await Hive.openBox<WorkDayModel>('workdays');
        }
        workdays = Hive.box<WorkDayModel>('workdays').values.toList();
      } catch (e) {
        Get.log('خطا در خواندن باکس workdays: $e');
      }

      // ساختار نهایی داده برای پشتیبان‌گیری (نسخه 3)
      final Map<String, dynamic> payload = {
        'version': 3, // نسخه پشتیبان
        'settings': settingsList.isNotEmpty
            ? settingsList.first.toJson()
            : null, // فرض بر سینگلتون بودن
        'employers': List.generate(
          employers.length,
          (i) => employers[i].toJson(),
        ),
        'payments': List.generate(payments.length, (i) => payments[i].toJson()),
        'workdays': List.generate(workdays.length, (i) => workdays[i].toJson()),
      };

      return _writeBackUp(payload: payload);
    } catch (e) {
      Get.log('خطای کلی در فرایند پشتیبان‌گیری: $e');
      notficationError(message: 'خطا در ساخت فایل پشتیبان');
      return null;
    }
  }

  /// نوشتن محتوای JSON به فایل.
  Future<File> _writeBackUp({required Map<String, dynamic> payload}) async {
    final file = await _localFile;
    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    final String encodedString = jsonEncode(payload);

    final File writtenFile = await file.writeAsString(encodedString);

    // به دلیل احتمال اینکه مسیر فایل در دایرکتوری Downloads باشد، بهتر است
    // نام و مسیر فایل را به کاربر اعلام کنیم.
    final String path = writtenFile.path;
    notficationSuccess('فایل پشتیبان با موفقیت ایجاد شد در مسیر: $path');

    return writtenFile;
  }

  /// انجام فرایند بازیابی اطلاعات از فایل پشتیبان.
  Future<void> restoreData() async {
    // 1. بررسی و درخواست دسترسی‌های ذخیره‌سازی.
    if (!await _permissionService.requestStoragePermissions()) {
      Get.log('مجوز ذخیره‌سازی اعطا نشد.');
      return;
    }

    final file = await _localFile;
    if (!await file.exists()) {
      notficationError(message: 'فایل پشتیبان در مسیر ${file.path} یافت نشد');
      return;
    }

    try {
      final String jsonContents = await file.readAsString();
      final dynamic jsonResponse = json.decode(jsonContents);
      final int version =
          (jsonResponse is Map && jsonResponse['version'] is int)
          ? jsonResponse['version'] as int
          : 1;

      // تنها نسخه 3 (ساختار جدید) پشتیبانی می‌شود.
      if (jsonResponse is Map && version >= 3) {
        await _restoreV3(jsonResponse as Map<String, dynamic>);
        // برای اطمینان از به‌روزرسانی تقویم
        Get.find<WorkDaysController>().update();
        // برای اطمینان از به‌روزرسانی نمایش تم و مقادیر صفحه تنظیمات
        Get.find<SettingsController>().update();
      } else {
        // برای نسخه‌های قدیمی‌تر، یک پیام خطا یا لاگ می‌دهیم چون قرار است فقط ساختار جدید پشتیبانی شود.
        Get.log(
          'نسخه پشتیبان قدیمی ($version) یا ساختار ناقص. فقط از نسخه 3 پشتیبانی می‌شود.',
        );
        notficationError(
          message: 'فایل پشتیبان با ساختار جدید سازگار نیست. (نسخه $version)',
        );
        return;
      }

      // فراخوانی متد برای به‌روزرسانی UI (مانند Home Controller)
      // فرض بر این است که `HomeController` و متد `getAllData` وجود دارند.
      try {
        // Get.find<HomeController>().getAllData();
        Get.log('اطلاعات با موفقیت بازیابی شد. نیاز به به‌روزرسانی UI.');
      } catch (e) {
        Get.log('خطا: HomeController برای به‌روزرسانی UI پیدا نشد.');
      }

      notficationSuccess('بازیابی اطلاعات با موفقیت انجام شد');
    } catch (e) {
      Get.log('خطا در فرایند بازیابی اطلاعات: $e');
      notficationError(message: 'خطا در خواندن یا پردازش فایل پشتیبان: $e');
    }
  }

  /// منطق بازیابی برای فایل‌های پشتیبان نسخه 3.
  Future<void> _restoreV3(Map<String, dynamic> payload) async {
    // 1. بازیابی تنظیمات
    try {
      if (payload['settings'] is Map<String, dynamic>) {
        if (!Hive.isBoxOpen('settings')) {
          await Hive.openBox<SettingsModel>('settings');
        }
        final box = Hive.box<SettingsModel>('settings');
        await box.clear();

        final Map<String, dynamic> s =
            payload['settings'] as Map<String, dynamic>;
        // تنها یک آیتم تنظیمات سینگلتون را بازسازی می‌کنیم
        final settingsModel = SettingsModel(
          isDaily: s['isDaily'] == true,
          dailyWage: s['dailyWage'] as int? ?? 0,
          hourlyWage: s['hourlyWage'] as int? ?? 0,
          isDarkMode: s['isDarkMode'] == true,
          defaultEmployerId: s['defaultEmployerId'] as int?,
        );
        await box.put(SettingsController.settingsKey, settingsModel);
      }
    } catch (e) {
      Get.log('خطا در بازیابی مدل تنظیمات: $e');
    }

    // 2. بازیابی مدل‌های اصلی: کارفرمایان
    try {
      if (payload['employers'] is List) {
        if (!Hive.isBoxOpen('employers')) {
          await Hive.openBox<EmployerModel>('employers');
        }
        final box = Hive.box<EmployerModel>('employers');
        await box.clear();
        for (final e in (payload['employers'] as List)) {
          if (e is Map<String, dynamic>) {
            box.add(
              EmployerModel(
                name: (e['name'] ?? '').toString(),
                phone: e['phone'],
                note: e['note'],
              ),
            );
          }
        }
      }
    } catch (e) {
      Get.log('خطا در بازیابی مدل کارفرمایان: $e');
    }

    // 3. بازیابی مدل‌های اصلی: پرداخت‌ها
    try {
      if (payload['payments'] is List) {
        if (!Hive.isBoxOpen('payments')) {
          await Hive.openBox<PaymentModel>('payments');
        }
        final box = Hive.box<PaymentModel>('payments');
        await box.clear();
        for (final p in (payload['payments'] as List)) {
          if (p is Map<String, dynamic>) {
            box.add(
              PaymentModel(
                jalaliDate: (p['jalaliDate'] ?? '').toString(),
                employerId: p['employerId'] as int?,
                amount: p['amount'] as int? ?? 0,
                note: p['note'],
              ),
            );
          }
        }
      }
    } catch (e) {
      Get.log('خطا در بازیابی مدل پرداخت‌ها: $e');
    }

    // 4. بازیابی مدل‌های اصلی: روزهای کاری
    try {
      if (payload['workdays'] is List) {
        if (!Hive.isBoxOpen('workdays')) {
          await Hive.openBox<WorkDayModel>('workdays');
        }
        final box = Hive.box<WorkDayModel>('workdays');
        await box.clear();
        for (final w in (payload['workdays'] as List)) {
          if (w is Map<String, dynamic>) {
            final WorkDayModel workday = WorkDayModel(
              jalaliDate: (w['jalaliDate'] ?? '').toString(),
              employerId: w['employerId'] as int?,
              worked: w['worked'] == true,
              hours: (w['hours'] as num?)?.toDouble() ?? 0.0,
              description: w['description'],
              wage: w['wage'] as int?,
            );
            // **تغییر اعمال شده:** استفاده از put با کلید رشته‌ای تاریخ جلالی
            final String key = JalaliUtils.formatFromJalali(
              JalaliUtils.parseJalali(workday.jalaliDate),
            );
            await box.put(key, workday);
          }
        }
      }
    } catch (e) {
      Get.log('خطا در بازیابی مدل روزهای کاری: $e');
    }
  }
}
