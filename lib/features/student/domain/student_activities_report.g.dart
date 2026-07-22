// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_activities_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentActivitiesReportAdapter
    extends TypeAdapter<StudentActivitiesReport> {
  @override
  final typeId = 15;

  @override
  StudentActivitiesReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentActivitiesReport(
      sectionA: (fields[0] as List?)?.cast<ActivityEntry>(),
      sectionC: (fields[1] as List?)?.cast<CommunityServiceEntry>(),
      sectionD: (fields[2] as List?)?.cast<ActivityEntry>(),
      sectionE: (fields[3] as List?)?.cast<ActivityEntry>(),
      sectionF: (fields[4] as List?)?.cast<ActivityEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudentActivitiesReport obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.sectionA)
      ..writeByte(1)
      ..write(obj.sectionC)
      ..writeByte(2)
      ..write(obj.sectionD)
      ..writeByte(3)
      ..write(obj.sectionE)
      ..writeByte(4)
      ..write(obj.sectionF);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentActivitiesReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
