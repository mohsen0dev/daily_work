// workdays_controller.dart
import 'package:daily_work/models/work_day.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class WorkDaysController extends GetxController {
  late final Box<WorkDay> _workdayBox;
  // Use RxMap instead of RxList to make searching for a specific date more efficient.
  final RxMap<String, WorkDay> workdays = <String, WorkDay>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _workdayBox = Hive.box<WorkDay>('workdays');
    _refresh();
    // Use .listen() to automatically refresh the RxMap when the Hive Box changes.
    _workdayBox.watch().listen((event) {
      if (event.value is WorkDay) {
        if (event.deleted) {
          workdays.remove(event.key);
        } else {
          workdays[event.key.toString()] = event.value as WorkDay;
        }
      } else {
        _refresh(); // Fallback for other changes
      }
    });
  }

  void _refresh() {
    // Correctly assign the map from the Hive box to the RxMap.
    workdays.assignAll(
      _workdayBox.toMap().map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<int> upsertDay(WorkDay day) async {
    final key = _keyFromDate(day.date);
    await _workdayBox.put(key, day);
    _refresh(); // Make sure the RxMap is updated
    return 0;
  }

  WorkDay? getByDate(DateTime date) {
    // Now getByDate can simply read from the RxMap.
    return workdays[_keyFromDate(date)];
  }

  Future<void> deleteByDate(DateTime date) async {
    await _workdayBox.delete(_keyFromDate(date));
  }

  String _keyFromDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
