// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 4;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      isDaily: fields[0] as bool,
      dailyWage: fields[1] as int,
      hourlyWage: fields[2] as int,
      isDarkMode: fields[3] as bool,
      defaultEmployerId: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.isDaily)
      ..writeByte(1)
      ..write(obj.dailyWage)
      ..writeByte(2)
      ..write(obj.hourlyWage)
      ..writeByte(3)
      ..write(obj.isDarkMode)
      ..writeByte(4)
      ..write(obj.defaultEmployerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
