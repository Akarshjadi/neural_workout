// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveNoteAdapter extends TypeAdapter<HiveNote> {
  @override
  final int typeId = 0;

  @override
  HiveNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveNote()
      ..id = fields[0] as int?
      ..title = fields[1] as String?
      ..body = fields[2] as String?
      ..kind = fields[3] as String?
      ..createdAt = fields[4] as String?
      ..updatedAt = fields[5] as String?
      ..cardState = fields[6] as String?
      ..cardDue = fields[7] as String?
      ..deletedAt = fields[8] as String?;
  }

  @override
  void write(BinaryWriter writer, HiveNote obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.kind)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.cardState)
      ..writeByte(7)
      ..write(obj.cardDue)
      ..writeByte(8)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSessionAdapter extends TypeAdapter<HiveSession> {
  @override
  final int typeId = 1;

  @override
  HiveSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSession()
      ..id = fields[0] as int?
      ..date = fields[1] as String?
      ..durationMs = fields[2] as int?
      ..stepsCompleted = fields[3] as int?
      ..anchorNoteId = fields[4] as int?
      ..anchorTitle = fields[5] as String?
      ..autosaveJson = fields[6] as String?
      ..focusPrimed = fields[7] as bool?;
  }

  @override
  void write(BinaryWriter writer, HiveSession obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.durationMs)
      ..writeByte(3)
      ..write(obj.stepsCompleted)
      ..writeByte(4)
      ..write(obj.anchorNoteId)
      ..writeByte(5)
      ..write(obj.anchorTitle)
      ..writeByte(6)
      ..write(obj.autosaveJson)
      ..writeByte(7)
      ..write(obj.focusPrimed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveBlurtScoreAdapter extends TypeAdapter<HiveBlurtScore> {
  @override
  final int typeId = 2;

  @override
  HiveBlurtScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveBlurtScore()
      ..id = fields[0] as int?
      ..noteId = fields[1] as int?
      ..noteTitle = fields[2] as String?
      ..date = fields[3] as String?
      ..scorePct = fields[4] as double?
      ..matched = (fields[5] as List?)?.cast<String>()
      ..missed = (fields[6] as List?)?.cast<String>()
      ..recallSpeedMs = fields[7] as int?
      ..depthScore = fields[8] as double?
      ..clarityScore = fields[9] as double?;
  }

  @override
  void write(BinaryWriter writer, HiveBlurtScore obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.noteId)
      ..writeByte(2)
      ..write(obj.noteTitle)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.scorePct)
      ..writeByte(5)
      ..write(obj.matched)
      ..writeByte(6)
      ..write(obj.missed)
      ..writeByte(7)
      ..write(obj.recallSpeedMs)
      ..writeByte(8)
      ..write(obj.depthScore)
      ..writeByte(9)
      ..write(obj.clarityScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveBlurtScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePathwayRecordAdapter extends TypeAdapter<HivePathwayRecord> {
  @override
  final int typeId = 3;

  @override
  HivePathwayRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePathwayRecord()
      ..id = fields[0] as int?
      ..date = fields[1] as String?
      ..retrieval = fields[2] as bool?
      ..compression = fields[3] as bool?
      ..association = fields[4] as bool?
      ..explanation = fields[5] as bool?
      ..context = fields[6] as bool?
      ..graceUsed = fields[7] as bool?;
  }

  @override
  void write(BinaryWriter writer, HivePathwayRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.retrieval)
      ..writeByte(3)
      ..write(obj.compression)
      ..writeByte(4)
      ..write(obj.association)
      ..writeByte(5)
      ..write(obj.explanation)
      ..writeByte(6)
      ..write(obj.context)
      ..writeByte(7)
      ..write(obj.graceUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePathwayRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveReviewAdapter extends TypeAdapter<HiveReview> {
  @override
  final int typeId = 4;

  @override
  HiveReview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveReview()
      ..id = fields[0] as int?
      ..noteId = fields[1] as int?
      ..date = fields[2] as String?
      ..rating = fields[3] as String?
      ..wasInterleaved = fields[4] as bool?;
  }

  @override
  void write(BinaryWriter writer, HiveReview obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.noteId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.rating)
      ..writeByte(4)
      ..write(obj.wasInterleaved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveReviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveLinkAdapter extends TypeAdapter<HiveLink> {
  @override
  final int typeId = 5;

  @override
  HiveLink read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveLink()
      ..id = fields[0] as int?
      ..fromNoteId = fields[1] as int?
      ..toNoteId = fields[2] as int?
      ..relationText = fields[3] as String?
      ..createdAt = fields[4] as String?;
  }

  @override
  void write(BinaryWriter writer, HiveLink obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromNoteId)
      ..writeByte(2)
      ..write(obj.toNoteId)
      ..writeByte(3)
      ..write(obj.relationText)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveLinkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSettingAdapter extends TypeAdapter<HiveSetting> {
  @override
  final int typeId = 6;

  @override
  HiveSetting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSetting()
      ..key = fields[0] as String?
      ..value = fields[1] as String?;
  }

  @override
  void write(BinaryWriter writer, HiveSetting obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSettingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveThoughtAdapter extends TypeAdapter<HiveThought> {
  @override
  final int typeId = 7;

  @override
  HiveThought read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveThought()
      ..id = fields[0] as int?
      ..text = fields[1] as String?
      ..createdAt = fields[2] as String?
      ..tags = (fields[3] as List?)?.cast<String>()
      ..linkedNoteId = fields[4] as int?
      ..deletedAt = fields[5] as String?;
  }

  @override
  void write(BinaryWriter writer, HiveThought obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.linkedNoteId)
      ..writeByte(5)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveThoughtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveCheckinAdapter extends TypeAdapter<HiveCheckin> {
  @override
  final int typeId = 8;

  @override
  HiveCheckin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCheckin()
      ..date = fields[0] as String?
      ..sleep = fields[1] as int?
      ..energy = fields[2] as int?
      ..activity = fields[3] as int?;
  }

  @override
  void write(BinaryWriter writer, HiveCheckin obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.sleep)
      ..writeByte(2)
      ..write(obj.energy)
      ..writeByte(3)
      ..write(obj.activity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCheckinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
