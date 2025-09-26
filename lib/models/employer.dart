import 'package:hive/hive.dart';

part 'employer.g.dart';

@HiveType(typeId: 1)
class EmployerModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? phone;

  @HiveField(2)
  String? note;

  EmployerModel({required this.name, this.phone, this.note});
}
