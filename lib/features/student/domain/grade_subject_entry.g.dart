// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_subject_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GradeSubjectEntryAdapter extends TypeAdapter<GradeSubjectEntry> {
  @override
  final typeId = 4;

  @override
  GradeSubjectEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GradeSubjectEntry(
      id: fields[0] as String,
      semesterCode: fields[1] as String,
      name: fields[2] as String,
      score: (fields[3] as num?)?.toDouble(),
      group: fields[4] as GradeSubjectGroup,
      isCustom: fields[5] == null ? false : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GradeSubjectEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.semesterCode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.score)
      ..writeByte(4)
      ..write(obj.group)
      ..writeByte(5)
      ..write(obj.isCustom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeSubjectEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GradeSubjectGroupAdapter extends TypeAdapter<GradeSubjectGroup> {
  @override
  final typeId = 5;

  @override
  GradeSubjectGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GradeSubjectGroup.coreEssentials;
      case 1:
        return GradeSubjectGroup.coreSubjects;
      case 2:
        return GradeSubjectGroup.coreGeneral;
      case 3:
        return GradeSubjectGroup.other;
      default:
        return GradeSubjectGroup.coreEssentials;
    }
  }

  @override
  void write(BinaryWriter writer, GradeSubjectGroup obj) {
    switch (obj) {
      case GradeSubjectGroup.coreEssentials:
        writer.writeByte(0);
      case GradeSubjectGroup.coreSubjects:
        writer.writeByte(1);
      case GradeSubjectGroup.coreGeneral:
        writer.writeByte(2);
      case GradeSubjectGroup.other:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeSubjectGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
