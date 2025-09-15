import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 3)
class Payment extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int? employerId; // optional filter by employer

  @HiveField(2)
  int amount; // in Tomans or Rials as you prefer

  @HiveField(3)
  String? note;

  Payment({
    required this.date,
    this.employerId,
    required this.amount,
    this.note,
  });
}
