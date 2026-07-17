// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_grades_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentGradesSettingsAdapter extends TypeAdapter<StudentGradesSettings> {
  @override
  final typeId = 8;

  @override
  StudentGradesSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentGradesSettings(
      track: fields[0] == null ? GradeTrack.social : fields[0] as GradeTrack,
      customSubjects: (fields[1] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudentGradesSettings obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.track)
      ..writeByte(1)
      ..write(obj.customSubjects);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentGradesSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GradeTrackAdapter extends TypeAdapter<GradeTrack> {
  @override
  final typeId = 7;

  @override
  GradeTrack read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GradeTrack.science;
      case 1:
        return GradeTrack.social;
      default:
        return GradeTrack.science;
    }
  }

  @override
  void write(BinaryWriter writer, GradeTrack obj) {
    switch (obj) {
      case GradeTrack.science:
        writer.writeByte(0);
      case GradeTrack.social:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeTrackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
