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
      ..deletedAt = fields[8] as String?
      ..linkIds = (fields[9] as List?)?.cast<int>();
  }

  @override
  void write(BinaryWriter writer, HiveNote obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.deletedAt)
      ..writeByte(9)
      ..write(obj.linkIds);
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

class HiveAttemptAdapter extends TypeAdapter<HiveAttempt> {
  @override
  final int typeId = 9;

  @override
  HiveAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveAttempt()
      ..id = fields[0] as int?
      ..timestamp = fields[1] as String?
      ..knowledgeTargetId = fields[2] as int?
      ..sessionId = fields[3] as int?
      ..testType = fields[4] as String?
      ..response = fields[5] as String?
      ..correctness = fields[6] as String?
      ..scorePct = fields[7] as double?
      ..responseTimeMs = fields[8] as int?
      ..confidence = fields[9] as int?
      ..difficulty = fields[10] as double?
      ..extras = (fields[11] as Map?)?.cast<String, String>()
      ..feedbackId = fields[12] as int?
      ..errorIds = (fields[13] as List?)?.cast<int>()
      ..interventionId = fields[14] as int?
      ..delayedOutcomeId = fields[15] as int?
      ..wasInterleaved = fields[16] as bool?
      ..interleaveGroupId = fields[17] as String?
      ..interleaveReason = fields[18] as String?
      ..acquiredAt = fields[19] as String?;
  }

  @override
  void write(BinaryWriter writer, HiveAttempt obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.knowledgeTargetId)
      ..writeByte(3)
      ..write(obj.sessionId)
      ..writeByte(4)
      ..write(obj.testType)
      ..writeByte(5)
      ..write(obj.response)
      ..writeByte(6)
      ..write(obj.correctness)
      ..writeByte(7)
      ..write(obj.scorePct)
      ..writeByte(8)
      ..write(obj.responseTimeMs)
      ..writeByte(9)
      ..write(obj.confidence)
      ..writeByte(10)
      ..write(obj.difficulty)
      ..writeByte(11)
      ..write(obj.extras)
      ..writeByte(12)
      ..write(obj.feedbackId)
      ..writeByte(13)
      ..write(obj.errorIds)
      ..writeByte(14)
      ..write(obj.interventionId)
      ..writeByte(15)
      ..write(obj.delayedOutcomeId)
      ..writeByte(16)
      ..write(obj.wasInterleaved)
      ..writeByte(17)
      ..write(obj.interleaveGroupId)
      ..writeByte(18)
      ..write(obj.interleaveReason)
      ..writeByte(19)
      ..write(obj.acquiredAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveAttemptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveFeedbackAdapter extends TypeAdapter<HiveFeedback> {
  @override
  final int typeId = 10;

  @override
  HiveFeedback read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveFeedback()
      ..id = fields[0] as int?
      ..attemptId = fields[1] as int?
      ..createdAt = fields[2] as String?
      ..correctness = fields[3] as String?
      ..scorePct = fields[4] as double?
      ..correctPoints = (fields[5] as List?)?.cast<String>()
      ..missing = (fields[6] as List?)?.cast<String>()
      ..incorrect = (fields[7] as List?)?.cast<String>()
      ..nextAction = fields[8] as String?
      ..fromAi = fields[9] as bool?;
  }

  @override
  void write(BinaryWriter writer, HiveFeedback obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.attemptId)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.correctness)
      ..writeByte(4)
      ..write(obj.scorePct)
      ..writeByte(5)
      ..write(obj.correctPoints)
      ..writeByte(6)
      ..write(obj.missing)
      ..writeByte(7)
      ..write(obj.incorrect)
      ..writeByte(8)
      ..write(obj.nextAction)
      ..writeByte(9)
      ..write(obj.fromAi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveFeedbackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveErrorAdapter extends TypeAdapter<HiveError> {
  @override
  final int typeId = 11;

  @override
  HiveError read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveError()
      ..id = fields[0] as int?
      ..attemptId = fields[1] as int?
      ..type = fields[2] as String?
      ..source = fields[3] as String?
      ..confidence = fields[4] as double?
      ..evidence = fields[5] as String?
      ..createdAt = fields[6] as String?
      ..confusedConceptId = fields[7] as int?;
  }

  @override
  void write(BinaryWriter writer, HiveError obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.attemptId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.confidence)
      ..writeByte(5)
      ..write(obj.evidence)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.confusedConceptId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveErrorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveDelayedOutcomeAdapter extends TypeAdapter<HiveDelayedOutcome> {
  @override
  final int typeId = 12;

  @override
  HiveDelayedOutcome read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveDelayedOutcome()
      ..id = fields[0] as int?
      ..knowledgeTargetId = fields[1] as int?
      ..attemptId = fields[2] as int?
      ..measuredAt = fields[3] as String?
      ..sourceAttemptId = fields[4] as int?
      ..bucket = fields[5] as String?
      ..elapsedMs = fields[6] as int?
      ..correctness = fields[7] as String?
      ..scorePct = fields[8] as double?
      ..experimentId = fields[9] as int?;
  }

  @override
  void write(BinaryWriter writer, HiveDelayedOutcome obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.knowledgeTargetId)
      ..writeByte(2)
      ..write(obj.attemptId)
      ..writeByte(3)
      ..write(obj.measuredAt)
      ..writeByte(4)
      ..write(obj.sourceAttemptId)
      ..writeByte(5)
      ..write(obj.bucket)
      ..writeByte(6)
      ..write(obj.elapsedMs)
      ..writeByte(7)
      ..write(obj.correctness)
      ..writeByte(8)
      ..write(obj.scorePct)
      ..writeByte(9)
      ..write(obj.experimentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveDelayedOutcomeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveInterventionAdapter extends TypeAdapter<HiveIntervention> {
  @override
  final int typeId = 13;

  @override
  HiveIntervention read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveIntervention()
      ..id = fields[0] as int?
      ..createdAt = fields[1] as String?
      ..action = fields[2] as String?
      ..reason = fields[3] as String?
      ..explanation = fields[4] as String?
      ..knowledgeTargetId = fields[5] as int?
      ..contrastTargetId = fields[6] as int?
      ..attemptId = fields[7] as int?
      ..experimentId = fields[8] as int?
      ..thresholds = (fields[9] as Map?)?.cast<String, int>();
  }

  @override
  void write(BinaryWriter writer, HiveIntervention obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.reason)
      ..writeByte(4)
      ..write(obj.explanation)
      ..writeByte(5)
      ..write(obj.knowledgeTargetId)
      ..writeByte(6)
      ..write(obj.contrastTargetId)
      ..writeByte(7)
      ..write(obj.attemptId)
      ..writeByte(8)
      ..write(obj.experimentId)
      ..writeByte(9)
      ..write(obj.thresholds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveInterventionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveExperimentAdapter extends TypeAdapter<HiveExperiment> {
  @override
  final int typeId = 14;

  @override
  HiveExperiment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveExperiment()
      ..id = fields[0] as int?
      ..hypothesis = fields[1] as String?
      ..conditionsJson = fields[2] as String?
      ..outcomeBuckets = (fields[3] as List?)?.cast<String>()
      ..targetConceptTypeFilter = fields[4] as int?
      ..minAttemptsPerCondition = fields[5] as int?
      ..startedAt = fields[6] as String?
      ..endedAt = fields[7] as String?
      ..active = fields[8] as bool?;
  }

  @override
  void write(BinaryWriter writer, HiveExperiment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hypothesis)
      ..writeByte(2)
      ..write(obj.conditionsJson)
      ..writeByte(3)
      ..write(obj.outcomeBuckets)
      ..writeByte(4)
      ..write(obj.targetConceptTypeFilter)
      ..writeByte(5)
      ..write(obj.minAttemptsPerCondition)
      ..writeByte(6)
      ..write(obj.startedAt)
      ..writeByte(7)
      ..write(obj.endedAt)
      ..writeByte(8)
      ..write(obj.active);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveExperimentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveFocusIntegrityAdapter extends TypeAdapter<HiveFocusIntegrity> {
  @override
  final int typeId = 15;

  @override
  HiveFocusIntegrity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveFocusIntegrity()
      ..sessionId = fields[0] as int?
      ..plannedDurationMs = fields[1] as int?
      ..actualDurationMs = fields[2] as int?
      ..interruptions = fields[3] as int?
      ..taskSwitches = fields[4] as int?
      ..abandoned = fields[5] as bool?
      ..completed = fields[6] as bool?
      ..longestFocusMs = fields[7] as int?;
  }

  @override
  void write(BinaryWriter writer, HiveFocusIntegrity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.plannedDurationMs)
      ..writeByte(2)
      ..write(obj.actualDurationMs)
      ..writeByte(3)
      ..write(obj.interruptions)
      ..writeByte(4)
      ..write(obj.taskSwitches)
      ..writeByte(5)
      ..write(obj.abandoned)
      ..writeByte(6)
      ..write(obj.completed)
      ..writeByte(7)
      ..write(obj.longestFocusMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveFocusIntegrityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveConceptProfileAdapter extends TypeAdapter<HiveConceptProfile> {
  @override
  final int typeId = 16;

  @override
  HiveConceptProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveConceptProfile()
      ..noteId = fields[0] as int?
      ..conceptType = fields[1] as String?
      ..updatedAt = fields[2] as String?;
  }

  @override
  void write(BinaryWriter writer, HiveConceptProfile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.noteId)
      ..writeByte(1)
      ..write(obj.conceptType)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveConceptProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
