// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentProfileAdapter extends TypeAdapter<StudentProfile> {
  @override
  final typeId = 0;

  @override
  StudentProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentProfile(
      dateOfBirth: fields[0] as DateTime?,
      phoneNumber: fields[1] as String?,
      address: fields[2] as String?,
      parents: (fields[13] as List?)?.cast<ParentGuardianEntry>(),
      siblings: fields[7] as String?,
      allergies: fields[8] as String?,
      regularMedicine: fields[9] as String?,
      hospital: fields[10] as String?,
      transportation: fields[11] as String?,
      emergencyContact: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.dateOfBirth)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.siblings)
      ..writeByte(8)
      ..write(obj.allergies)
      ..writeByte(9)
      ..write(obj.regularMedicine)
      ..writeByte(10)
      ..write(obj.hospital)
      ..writeByte(11)
      ..write(obj.transportation)
      ..writeByte(12)
      ..write(obj.emergencyContact)
      ..writeByte(13)
      ..write(obj.parents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
