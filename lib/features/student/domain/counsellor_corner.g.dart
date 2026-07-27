// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counsellor_corner.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CounsellorCornerAdapter extends TypeAdapter<CounsellorCorner> {
  @override
  final typeId = 20;

  @override
  CounsellorCorner read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CounsellorCorner(
      qualityTime: fields[0] == null ? '' : fields[0] as String,
      enjoyMost: fields[1] == null ? '' : fields[1] as String,
      enjoyLeast: fields[2] == null ? '' : fields[2] as String,
      routines: fields[3] == null ? '' : fields[3] as String,
      rules: fields[4] == null ? '' : fields[4] as String,
      consequence: fields[5] == null ? '' : fields[5] as String,
      addressedBy: fields[6] == null ? '' : fields[6] as String,
      addressedOther: fields[7] == null ? '' : fields[7] as String,
      flexible: fields[8] == null ? '' : fields[8] as String,
      disagreement: fields[9] == null ? '' : fields[9] as String,
      expressUpset: fields[10] == null ? '' : fields[10] as String,
      talksWith: fields[11] == null ? '' : fields[11] as String,
      talksOther: fields[12] == null ? '' : fields[12] as String,
      calmHow: fields[13] == null ? '' : fields[13] as String,
      eduAdult: fields[14] == null ? '' : fields[14] as String,
      eduAdultOther: fields[15] == null ? '' : fields[15] as String,
      famOther: fields[16] == null ? '' : fields[16] as String,
      prevSchools: fields[17] == null ? '' : fields[17] as String,
      achievements: fields[18] == null ? '' : fields[18] as String,
      neededSupport: fields[19] == null ? '' : fields[19] as String,
      hadTherapy: fields[20] == null ? '' : fields[20] as String,
      currentTherapy: fields[21] == null ? '' : fields[21] as String,
      recentHighlight: fields[22] == null ? '' : fields[22] as String,
      runataNotes: fields[23] == null ? '' : fields[23] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CounsellorCorner obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.qualityTime)
      ..writeByte(1)
      ..write(obj.enjoyMost)
      ..writeByte(2)
      ..write(obj.enjoyLeast)
      ..writeByte(3)
      ..write(obj.routines)
      ..writeByte(4)
      ..write(obj.rules)
      ..writeByte(5)
      ..write(obj.consequence)
      ..writeByte(6)
      ..write(obj.addressedBy)
      ..writeByte(7)
      ..write(obj.addressedOther)
      ..writeByte(8)
      ..write(obj.flexible)
      ..writeByte(9)
      ..write(obj.disagreement)
      ..writeByte(10)
      ..write(obj.expressUpset)
      ..writeByte(11)
      ..write(obj.talksWith)
      ..writeByte(12)
      ..write(obj.talksOther)
      ..writeByte(13)
      ..write(obj.calmHow)
      ..writeByte(14)
      ..write(obj.eduAdult)
      ..writeByte(15)
      ..write(obj.eduAdultOther)
      ..writeByte(16)
      ..write(obj.famOther)
      ..writeByte(17)
      ..write(obj.prevSchools)
      ..writeByte(18)
      ..write(obj.achievements)
      ..writeByte(19)
      ..write(obj.neededSupport)
      ..writeByte(20)
      ..write(obj.hadTherapy)
      ..writeByte(21)
      ..write(obj.currentTherapy)
      ..writeByte(22)
      ..write(obj.recentHighlight)
      ..writeByte(23)
      ..write(obj.runataNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounsellorCornerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
