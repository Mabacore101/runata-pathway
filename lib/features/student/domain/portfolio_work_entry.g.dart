// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_work_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PortfolioWorkEntryAdapter extends TypeAdapter<PortfolioWorkEntry> {
  @override
  final typeId = 16;

  @override
  PortfolioWorkEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortfolioWorkEntry(
      title: fields[0] as String?,
      type: fields[1] as String?,
      year: fields[2] as String?,
      role: fields[3] as String?,
      brief: fields[4] as String?,
      link: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioWorkEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.brief)
      ..writeByte(5)
      ..write(obj.link);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioWorkEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
