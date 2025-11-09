import 'package:daily_work/models/work_day.dart';
import 'package:daily_work/controllers/setting_controller.dart';
import 'package:daily_work/utils/jalali_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart' as sh;

/// کنترلر مدیریت روزهای کاری و ارتباط با Hive.
class WorkDaysController extends GetxController {
  /// باکس Hive برای ذخیره مدل‌های WorkDayModel.
  Box<WorkDayModel>? _workdayBox;

  /// نقشه واکنشی برای نگهداری روزهای کاری (کلید: تاریخ جلالی، مقدار: WorkDayModel).
  final RxMap<String, WorkDayModel> workdays = <String, WorkDayModel>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initWorkdayBox(); // فراخوانی متد راه‌اندازی باکس Hive
  }

  /// متد خصوصی برای باز کردن باکس Hive و تنظیم شنونده.
  Future<void> _initWorkdayBox() async {
    if (!Hive.isBoxOpen('workdays')) {
      _workdayBox = await Hive.openBox<WorkDayModel>('workdays');
    } else {
      _workdayBox = Hive.box<WorkDayModel>('workdays');
    }
    _refreshWorkdays(); // بارگذاری اولیه داده‌ها
    _workdayBox?.listenable().addListener(_refreshWorkdays); // گوش دادن به تغییرات Hive
  }

  /// به‌روزرسانی نقشه workdays از باکس Hive.
  void _refreshWorkdays() {
    if (_workdayBox == null) {
      return;
    }
    try {
      final Map<String, WorkDayModel> data = {}; // ساخت یک Map جدید
      for (var entry in _workdayBox!.toMap().entries) {
        final String key = entry.key.toString(); // اطمینان از تبدیل کلید به رشته
        final WorkDayModel value = entry.value;
        data[key] = value;
      }
      workdays.assignAll(data); // به‌روزرسانی RxMap که Obx را فعال می‌کند
    } catch (e) {
      debugPrint('Error refreshing workdays from box: $e'); // لاگ خطا را برای اشکال‌زدایی حفظ می‌کنیم
    }
  }

  /// override کردن متد update از GetxController برای اطمینان از به‌روزرسانی داده‌ها.
  @override
  void update([List<Object>? ids, bool condition = true]) {
    _refreshWorkdays(); // اطمینان از به‌روزرسانی RxMap workdays با آخرین داده‌ها
    super.update(ids, condition); // فراخوانی متد اصلی برای اطلاع‌رسانی به GetBuilderها
  }

  /// ذخیره یا به‌روزرسانی یک روز کاری.
  /// [day] مدل روز کاری برای ذخیره.
  Future<void> upsertDay(WorkDayModel day) async {
    final key = _keyFromJalali(JalaliUtils.parseJalali(day.jalaliDate));
    // محاسبه خودکار دستمزد در صورت عدم ارائه و اگر روز کاری فعال باشد
    if (day.worked && day.wage == null) {
      try {
        final SettingsController wageController = Get.find<SettingsController>();
        final s = wageController.settings.value;
        final computed = s.isDaily ? s.dailyWage : (day.hours * s.hourlyWage).round();
        day = WorkDayModel(
          jalaliDate: day.jalaliDate,
          employerId: day.employerId,
          worked: day.worked,
          hours: day.hours,
          description: day.description,
          wage: computed,
        );
      } catch (e) {
        debugPrint('Error in upsertDay calculating wage: $e'); // لاگ خطا را حفظ می‌کنیم
      }
    }
    await _workdayBox!.put(key, day);
    // نیازی به فراخوانی _refreshWorkdays اینجا نیست چون شنونده Hive آن را انجام می‌دهد.
  }

  /// دریافت مدل روز کاری بر اساس تاریخ جلالی (فرمت رشته‌ای).
  /// [jalaliDate] تاریخ جلالی به صورت رشته.
  /// برمی‌گرداند WorkDayModel یا null.
  WorkDayModel? getByJalaliDate(String jalaliDate) {
    final key = _keyFromJalali(JalaliUtils.parseJalali(jalaliDate));
    final workday = workdays[key];
    return workday;
  }

  /// دریافت مدل روز کاری بر اساس شیء Jalali.
  /// [jalali] شیء Jalali.
  /// برمی‌گرداند WorkDayModel یا null.
  WorkDayModel? getByJalali(sh.Jalali jalali) {
    final key = _keyFromJalali(jalali);
    final workday = workdays[key];
    return workday;
  }

  /// حذف یک روز کاری بر اساس تاریخ جلالی (فرمت رشته‌ای).
  /// [jalaliDate] تاریخ جلالی به صورت رشته.
  Future<void> deleteByJalaliDate(String jalaliDate) async {
    await _workdayBox!.delete(_keyFromJalali(JalaliUtils.parseJalali(jalaliDate)));
  }

  /// حذف یک روز کاری بر اساس شیء Jalali.
  /// [jalali] شیء Jalali.
  Future<void> deleteByJalali(sh.Jalali jalali) async {
    await _workdayBox!.delete(_keyFromJalali(jalali));
  }

  /// ایجاد کلید Hive از تاریخ جلالی.
  /// [jalali] شیء Jalali.
  /// برمی‌گرداند کلید Hive با فرمت YYYY/MM/DD.
  String _keyFromJalali(sh.Jalali jalali) {
    // همیشه از فرمت YYYY/MM/DD استفاده کنید که با فرمت ذخیره‌شده در مدل مطابقت داشته باشد.
    return JalaliUtils.formatFromJalali(jalali);
  }

  @override
  void onClose() {
    _workdayBox?.listenable().removeListener(_refreshWorkdays);
    super.onClose();
  }
}
