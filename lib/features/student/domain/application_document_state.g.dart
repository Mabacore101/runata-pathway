// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_document_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApplicationDocumentStateAdapter
    extends TypeAdapter<ApplicationDocumentState> {
  @override
  final typeId = 19;

  @override
  ApplicationDocumentState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApplicationDocumentState(
      docKey: fields[0] as String,
      content: (fields[1] as Map?)?.cast<String, String>(),
      status: (fields[2] as Map?)?.cast<String, DocumentStatus>(),
      note: fields[3] as String?,
      submitted: fields[4] == null ? false : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ApplicationDocumentState obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.docKey)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.submitted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationDocumentStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DocumentStatusAdapter extends TypeAdapter<DocumentStatus> {
  @override
  final typeId = 18;

  @override
  DocumentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DocumentStatus.notStarted;
      case 1:
        return DocumentStatus.draft;
      case 2:
        return DocumentStatus.inReview;
      case 3:
        return DocumentStatus.finalStatus;
      default:
        return DocumentStatus.notStarted;
    }
  }

  @override
  void write(BinaryWriter writer, DocumentStatus obj) {
    switch (obj) {
      case DocumentStatus.notStarted:
        writer.writeByte(0);
      case DocumentStatus.draft:
        writer.writeByte(1);
      case DocumentStatus.inReview:
        writer.writeByte(2);
      case DocumentStatus.finalStatus:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
