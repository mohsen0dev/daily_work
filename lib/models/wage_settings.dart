import 'package:hive/hive.dart';

part 'wage_settings.g.dart';

@HiveType(typeId: 4)
class WageSettings extends HiveObject {
  @HiveField(0)
  bool isDaily; // true = daily wage, false = hourly

  @HiveField(1)
  int dailyWage; // if isDaily

  @HiveField(2)
  int hourlyWage; // if hourly

  WageSettings({this.isDaily = true, this.dailyWage = 0, this.hourlyWage = 0});
}
