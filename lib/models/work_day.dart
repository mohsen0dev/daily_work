import 'package:hive/hive.dart';

part 'work_day.g.dart';

@HiveType(typeId: 2)
class WorkDay extends HiveObject {
  @HiveField(5)
  int? wage; // مبلغ دستمزد

  // Store Jalali date as yyyy/MM/dd for Persian date persistence
  @HiveField(0)
  String jalaliDate;

  @HiveField(1)
  int? employerId; // Hive key of Employer box

  @HiveField(2)
  bool worked; // true if worked this day

  @HiveField(3)
  double hours; // number of hours worked (or 1 for full day if daily wage)

  @HiveField(4)
  String? description;

  WorkDay({
    required this.jalaliDate,
    this.employerId,
    this.worked = false,
    this.hours = 0,
    this.description,
    this.wage,
  });
}
