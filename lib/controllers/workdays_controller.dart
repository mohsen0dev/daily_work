import 'package:daily_work/models/work_day.dart';
import 'package:daily_work/controllers/wage_controller.dart';
import 'package:daily_work/utils/jalali_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shamsi_date/shamsi_date.dart' as sh;

class WorkDaysController extends GetxController {
  // Directly get the already opened box
  Box<WorkDay>? _workdayBox;

  final RxMap<String, WorkDay> workdays = <String, WorkDay>{}.obs;

  Future<void> init() async {
    if (!Hive.isBoxOpen('workdays')) {
      _workdayBox = await Hive.openBox<WorkDay>('workdays');
    } else {
      _workdayBox = Hive.box<WorkDay>('workdays');
    }
    _refresh();
    _workdayBox?.listenable().addListener(_refresh);
  }

  void _refresh() {
    if (_workdayBox == null) return;
    try {
      final Map<String, WorkDay> data = _workdayBox!.toMap().map(
        (key, value) => MapEntry(key.toString(), value),
      );
      workdays.value = data;
    } catch (e) {
      debugPrint('Error refreshing workdays: $e');
    }
  }

  Future<void> upsertDay(WorkDay day) async {
    final key = _keyFromJalaliDate(day.jalaliDate);
    // Auto-calc wage if not provided and worked is true
    if (day.worked && day.wage == null) {
      try {
        final WageController wageController = Get.find<WageController>();
        final s = wageController.settings.value;
        final computed = s.isDaily
            ? s.dailyWage
            : (day.hours * s.hourlyWage).round();
        day = WorkDay(
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

  WorkDay? getByJalaliDate(String jalaliDate) {
    return workdays[_keyFromJalaliDate(jalaliDate)];
  }

  WorkDay? getByJalali(sh.Jalali jalali) {
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
