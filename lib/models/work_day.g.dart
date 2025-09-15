// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkDayAdapter extends TypeAdapter<WorkDay> {
  @override
  final int typeId = 2;

  @override
  WorkDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkDay(
      date: fields[0] as DateTime,
      employerId: fields[1] as int?,
      worked: fields[2] as bool,
      hours: fields[3] as double,
      description: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkDay obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.employerId)
      ..writeByte(2)
      ..write(obj.worked)
      ..writeByte(3)
      ..write(obj.hours)
      ..writeByte(4)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
