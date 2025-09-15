import 'package:hive/hive.dart';

part 'employer.g.dart';

@HiveType(typeId: 1)
class Employer extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? phone;

  @HiveField(2)
  String? note;

  Employer({required this.name, this.phone, this.note});
}
