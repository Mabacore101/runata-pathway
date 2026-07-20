// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_majors_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentMajorsSettingsAdapter extends TypeAdapter<StudentMajorsSettings> {
  @override
  final typeId = 10;

  @override
  StudentMajorsSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentMajorsSettings(
      majors: (fields[0] as List?)?.cast<MajorEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudentMajorsSettings obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.majors);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentMajorsSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
