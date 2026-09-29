import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/models/session.dart';
import 'package:neural_workout/models/pathway_record.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/models/delayed_outcome.dart';
import 'package:neural_workout/data/app_database.dart';

abstract class SuggestionContext {
  List<ErrorRecord> get errorRecords;
  List<DelayedOutcome> get delayedOutcomes;
  List<LearningAttempt> get learningAttempts;
  List<Session> get sessions;
  List<Note> get dueNotesList;
  List<BlurtScore> get blurtScores;
  List<Note> get notes;
  List<PathwayRecord> get pathwayRecords;
  AppDatabase get db;
}
