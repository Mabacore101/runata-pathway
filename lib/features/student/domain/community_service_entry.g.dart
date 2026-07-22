// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_service_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommunityServiceEntryAdapter extends TypeAdapter<CommunityServiceEntry> {
  @override
  final typeId = 14;

  @override
  CommunityServiceEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommunityServiceEntry(
      activity: fields[0] as String?,
      role: fields[1] as String?,
      months: fields[2] == null ? 0 : (fields[2] as num).toInt(),
      proof: fields[3] == null ? false : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CommunityServiceEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.activity)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.months)
      ..writeByte(3)
      ..write(obj.proof);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityServiceEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
