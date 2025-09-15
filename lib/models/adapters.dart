// import 'package:hive/hive.dart';

// import 'employer.dart';
// import 'payment.dart';
// import 'wage_settings.dart';
// import 'work_day.dart';

// class EmployerAdapter extends TypeAdapter<Employer> {
//   @override
//   final int typeId = 1;

//   @override
//   Employer read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return Employer(
//       name: fields[0] as String,
//       phone: fields[1] as String?,
//       note: fields[2] as String?,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, Employer obj) {
//     writer
//       ..writeByte(3)
//       ..writeByte(0)
//       ..write(obj.name)
//       ..writeByte(1)
//       ..write(obj.phone)
//       ..writeByte(2)
//       ..write(obj.note);
//   }
// }

// class WorkDayAdapter extends TypeAdapter<WorkDay> {
//   @override
//   final int typeId = 2;

//   @override
//   WorkDay read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return WorkDay(
//       date: fields[0] as DateTime,
//       employerId: fields[1] as int?,
//       worked: fields[2] as bool,
//       hours: (fields[3] as num).toDouble(),
//       description: fields[4] as String?,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, WorkDay obj) {
//     writer
//       ..writeByte(5)
//       ..writeByte(0)
//       ..write(obj.date)
//       ..writeByte(1)
//       ..write(obj.employerId)
//       ..writeByte(2)
//       ..write(obj.worked)
//       ..writeByte(3)
//       ..write(obj.hours)
//       ..writeByte(4)
//       ..write(obj.description);
//   }
// }

// class PaymentAdapter extends TypeAdapter<Payment> {
//   @override
//   final int typeId = 3;

//   @override
//   Payment read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return Payment(
//       date: fields[0] as DateTime,
//       employerId: fields[1] as int?,
//       amount: fields[2] as int,
//       note: fields[3] as String?,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, Payment obj) {
//     writer
//       ..writeByte(4)
//       ..writeByte(0)
//       ..write(obj.date)
//       ..writeByte(1)
//       ..write(obj.employerId)
//       ..writeByte(2)
//       ..write(obj.amount)
//       ..writeByte(3)
//       ..write(obj.note);
//   }
// }

// class WageSettingsAdapter extends TypeAdapter<WageSettings> {
//   @override
//   final int typeId = 4;

//   @override
//   WageSettings read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return WageSettings(
//       isDaily: fields[0] as bool,
//       dailyWage: fields[1] as int,
//       hourlyWage: fields[2] as int,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, WageSettings obj) {
//     writer
//       ..writeByte(3)
//       ..writeByte(0)
//       ..write(obj.isDaily)
//       ..writeByte(1)
//       ..write(obj.dailyWage)
//       ..writeByte(2)
//       ..write(obj.hourlyWage);
//   }
// }
