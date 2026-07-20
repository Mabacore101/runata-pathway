// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'major_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MajorEntryAdapter extends TypeAdapter<MajorEntry> {
  @override
  final typeId = 9;

  @override
  MajorEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MajorEntry(
      major: fields[0] as String,
      country: fields[1] == null ? 'United States' : fields[1] as String,
      top: fields[2] == null ? false : fields[2] as bool,
      anchor: fields[3] == null ? false : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MajorEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.major)
      ..writeByte(1)
      ..write(obj.country)
      ..writeByte(2)
      ..write(obj.top)
      ..writeByte(3)
      ..write(obj.anchor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MajorEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
