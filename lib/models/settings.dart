import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 4)
class SettingsModel extends HiveObject {
  @HiveField(0)
  bool isDaily; // true = daily wage, false = hourly

  @HiveField(1)
  int dailyWage; // if isDaily

  @HiveField(2)
  int hourlyWage; // if hourly

  @HiveField(3)
  bool isDarkMode ;

  SettingsModel({this.isDaily = true, this.dailyWage = 0, this.hourlyWage = 0,this.isDarkMode=false});
}
