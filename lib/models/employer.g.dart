// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployerModelAdapter extends TypeAdapter<EmployerModel> {
  @override
  final int typeId = 1;

  @override
  EmployerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployerModel(
      name: fields[0] as String,
      phone: fields[1] as String?,
      note: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EmployerModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
