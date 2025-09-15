// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployerAdapter extends TypeAdapter<Employer> {
  @override
  final int typeId = 1;

  @override
  Employer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Employer(
      name: fields[0] as String,
      phone: fields[1] as String?,
      note: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Employer obj) {
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
      other is EmployerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
