// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_club_selection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentClubSelectionAdapter extends TypeAdapter<StudentClubSelection> {
  @override
  final typeId = 12;

  @override
  StudentClubSelection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentClubSelection(
      anchorMajor: fields[0] as String,
      rankedOthers: (fields[1] as List).cast<String>(),
      submittedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StudentClubSelection obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.anchorMajor)
      ..writeByte(1)
      ..write(obj.rankedOthers)
      ..writeByte(2)
      ..write(obj.submittedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentClubSelectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
