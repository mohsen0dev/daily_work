// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wage_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WageSettingsAdapter extends TypeAdapter<WageSettings> {
  @override
  final int typeId = 4;

  @override
  WageSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WageSettings(
      isDaily: fields[0] as bool,
      dailyWage: fields[1] as int,
      hourlyWage: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WageSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.isDaily)
      ..writeByte(1)
      ..write(obj.dailyWage)
      ..writeByte(2)
      ..write(obj.hourlyWage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WageSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
