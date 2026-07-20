// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'university_target.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UniversityTargetAdapter extends TypeAdapter<UniversityTarget> {
  @override
  final typeId = 11;

  @override
  UniversityTarget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UniversityTarget(
      id: fields[0] as String,
      major: fields[1] as String,
      country: fields[2] as String,
      university: fields[3] as String,
      custom: fields[4] == null ? false : fields[4] as bool,
      note: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UniversityTarget obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.major)
      ..writeByte(2)
      ..write(obj.country)
      ..writeByte(3)
      ..write(obj.university)
      ..writeByte(4)
      ..write(obj.custom)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversityTargetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
