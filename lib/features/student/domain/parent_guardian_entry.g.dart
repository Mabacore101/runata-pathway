// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parent_guardian_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParentGuardianEntryAdapter extends TypeAdapter<ParentGuardianEntry> {
  @override
  final typeId = 6;

  @override
  ParentGuardianEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ParentGuardianEntry(
      name: fields[0] as String?,
      phone: fields[1] as String?,
      email: fields[2] as String?,
      availableTime: fields[3] as String?,
      address: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ParentGuardianEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.availableTime)
      ..writeByte(4)
      ..write(obj.address);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentGuardianEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
