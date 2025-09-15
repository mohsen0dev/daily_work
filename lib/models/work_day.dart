import 'package:hive/hive.dart';

part 'work_day.g.dart';

@HiveType(typeId: 2)
class WorkDay extends HiveObject {
  @HiveField(5)
  int? wage; // مبلغ دستمزد
  @HiveField(0)
  DateTime date; // store as UTC date (normalize to midnight UTC)

  @HiveField(1)
  int? employerId; // Hive key of Employer box

  @HiveField(2)
  bool worked; // true if worked this day

  @HiveField(3)
  double hours; // number of hours worked (or 1 for full day if daily wage)

  @HiveField(4)
  String? description;

  WorkDay({
    required this.date,
    this.employerId,
    this.worked = false,
    this.hours = 0,
    this.description,
    this.wage,
  });
}
