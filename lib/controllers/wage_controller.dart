import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/wage_settings.dart';
import '../models/work_day.dart';
import '../models/payment.dart';

class WageController extends GetxController {
  late final Box<WageSettings> _settingsBox;
  late final Box<WorkDay> _workdayBox;
  late final Box<Payment> _paymentBox;

  final Rx<WageSettings> settings = WageSettings().obs;

  @override
  void onInit() {
    super.onInit();
    _settingsBox = Hive.box<WageSettings>('settings');
    _workdayBox = Hive.box<WorkDay>('workdays');
    _paymentBox = Hive.box<Payment>('payments');

    if (_settingsBox.isEmpty) {
      _settingsBox.put(
        'wage',
        WageSettings(isDaily: true, dailyWage: 0, hourlyWage: 0),
      );
    }
    settings.value =
        _settingsBox.get('wage') ??
        WageSettings(isDaily: true, dailyWage: 0, hourlyWage: 0);
  }

  Future<void> saveSettings(WageSettings newSettings) async {
    await _settingsBox.put('wage', newSettings);
    settings.value = newSettings;
  }

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

  int totalPayments({int? employerId}) {
    int sum = 0;
    for (final e in _paymentBox.toMap().entries) {
      final p = e.value;
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
}
