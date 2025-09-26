import 'package:daily_work/models/work_day.dart';
import 'package:daily_work/controllers/setting_controller.dart';
import 'package:daily_work/utils/jalali_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart' as sh;

class WorkDaysController extends GetxController {
  // Directly get the already opened box
  Box<WorkDayModel>? _workdayBox;

  final RxMap<String, WorkDayModel> workdays = <String, WorkDayModel>{}.obs;

  Future<void> init() async {
    if (!Hive.isBoxOpen('workdays')) {
      _workdayBox = await Hive.openBox<WorkDayModel>('workdays');
    } else {
      _workdayBox = Hive.box<WorkDayModel>('workdays');
    }
    _refresh();
    _workdayBox?.listenable().addListener(_refresh);
  }

  void _refresh() {
    if (_workdayBox == null) return;
    try {
      final Map<String, WorkDayModel> data = _workdayBox!.toMap().map(
        (key, value) => MapEntry(key.toString(), value),
      );
      workdays.value = data;
    } catch (e) {
      debugPrint('Error refreshing workdays: $e');
    }
  }

  Future<void> upsertDay(WorkDayModel day) async {
    final key = _keyFromJalaliDate(day.jalaliDate);
    // Auto-calc wage if not provided and worked is true
    if (day.worked && day.wage == null) {
      try {
        final SettingController wageController = Get.find<SettingController>();
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
        // If WageController is not available, fallback to provided value (null)
      }
    }
    await _workdayBox!.put(key, day);
  }

  WorkDayModel? getByJalaliDate(String jalaliDate) {
    return workdays[_keyFromJalaliDate(jalaliDate)];
  }

  WorkDayModel? getByJalali(sh.Jalali jalali) {
    final jalaliDate = JalaliUtils.formatFromJalali(jalali);
    return getByJalaliDate(jalaliDate);
  }

  Future<void> deleteByJalaliDate(String jalaliDate) async {
    await _workdayBox!.delete(_keyFromJalaliDate(jalaliDate));
  }

  Future<void> deleteByJalali(sh.Jalali jalali) async {
    final jalaliDate = JalaliUtils.formatFromJalali(jalali);
    await deleteByJalaliDate(jalaliDate);
  }

  String _keyFromJalaliDate(String jalaliDate) {
    return jalaliDate.replaceAll('/', '-');
  }

  @override
  void onClose() {
    _workdayBox?.listenable().removeListener(_refresh);
    // Do not close the box here, as it might be needed by other parts of the app
    super.onClose();
  }
}
