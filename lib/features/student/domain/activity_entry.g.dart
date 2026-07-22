// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityEntryAdapter extends TypeAdapter<ActivityEntry> {
  @override
  final typeId = 13;

  @override
  ActivityEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityEntry(
      activity: fields[0] as String?,
      role: fields[1] as String?,
      dates: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.activity)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.dates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
