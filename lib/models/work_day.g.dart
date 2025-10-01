// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkDayModelAdapter extends TypeAdapter<WorkDayModel> {
  @override
  final int typeId = 2;

  @override
  WorkDayModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkDayModel(
      jalaliDate: fields[0] as String,
      employerId: fields[1] as int?,
      worked: fields[2] as bool,
      hours: fields[3] as double,
      description: fields[4] as String?,
      wage: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkDayModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(5)
      ..write(obj.wage)
      ..writeByte(0)
      ..write(obj.jalaliDate)
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
      other is WorkDayModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
