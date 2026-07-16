// GENERATED CODE (hand-authored stand-in — see chat notes)
//
// Mirrors what
//   dart run build_runner build --delete-conflicting-outputs
// produces from the @HiveType/@HiveField annotations in test_entry.dart.
// Regenerate locally once to get the authoritative version.

part of 'test_entry.dart';

class TestTypeAdapter extends TypeAdapter<TestType> {
  @override
  final int typeId = 2;

  @override
  TestType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TestType.ielts;
      case 1:
        return TestType.toefl;
      case 2:
        return TestType.duolingo;
      case 3:
        return TestType.sat;
      case 4:
        return TestType.csca;
      case 5:
        return TestType.hsk;
      case 6:
        return TestType.ap;
      case 7:
        return TestType.other;
      default:
        return TestType.ielts;
    }
  }

  @override
  void write(BinaryWriter writer, TestType obj) {
    switch (obj) {
      case TestType.ielts:
        writer.writeByte(0);
        break;
      case TestType.toefl:
        writer.writeByte(1);
        break;
      case TestType.duolingo:
        writer.writeByte(2);
        break;
      case TestType.sat:
        writer.writeByte(3);
        break;
      case TestType.csca:
        writer.writeByte(4);
        break;
      case TestType.hsk:
        writer.writeByte(5);
        break;
      case TestType.ap:
        writer.writeByte(6);
        break;
      case TestType.other:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TestStatusAdapter extends TypeAdapter<TestStatus> {
  @override
  final int typeId = 3;

  @override
  TestStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TestStatus.planned;
      case 1:
        return TestStatus.registered;
      case 2:
        return TestStatus.taken;
      default:
        return TestStatus.planned;
    }
  }

  @override
  void write(BinaryWriter writer, TestStatus obj) {
    switch (obj) {
      case TestStatus.planned:
        writer.writeByte(0);
        break;
      case TestStatus.registered:
        writer.writeByte(1);
        break;
      case TestStatus.taken:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TestEntryAdapter extends TypeAdapter<TestEntry> {
  @override
  final int typeId = 1;

  @override
  TestEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestEntry(
      id: fields[0] as String,
      type: fields[1] as TestType,
      target: fields[2] as String?,
      latest: fields[3] as String?,
      status: fields[4] as TestStatus,
      date: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TestEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.target)
      ..writeByte(3)
      ..write(obj.latest)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
