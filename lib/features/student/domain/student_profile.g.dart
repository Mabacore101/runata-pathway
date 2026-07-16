// GENERATED CODE (hand-authored stand-in — see chat notes)
//
// This file mirrors exactly what
//   dart run build_runner build --delete-conflicting-outputs
// produces from the @HiveType/@HiveField annotations in student_profile.dart.
// It was written by hand because the environment used to draft this change
// couldn't reach pub.dev to run build_runner. Regenerate it locally once —
// the output should be byte-for-byte equivalent to this file. If it isn't,
// trust the regenerated version, not this one.

part of 'student_profile.dart';

class StudentProfileAdapter extends TypeAdapter<StudentProfile> {
  @override
  final int typeId = 0;

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
      parentName: fields[3] as String?,
      parentPhone: fields[4] as String?,
      parentEmail: fields[5] as String?,
      parentAvailableTime: fields[6] as String?,
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
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.dateOfBirth)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.parentName)
      ..writeByte(4)
      ..write(obj.parentPhone)
      ..writeByte(5)
      ..write(obj.parentEmail)
      ..writeByte(6)
      ..write(obj.parentAvailableTime)
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
      ..write(obj.emergencyContact);
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
