// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_portfolio.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentPortfolioAdapter extends TypeAdapter<StudentPortfolio> {
  @override
  final typeId = 17;

  @override
  StudentPortfolio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentPortfolio(
      works: (fields[0] as List?)?.cast<PortfolioWorkEntry>(),
      statement: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentPortfolio obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.works)
      ..writeByte(1)
      ..write(obj.statement);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentPortfolioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
