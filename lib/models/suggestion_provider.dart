import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/models/workout_session.dart';
import 'package:neural_workout/data/app_database.dart';

abstract class SuggestionStateProvider {
  List<ErrorRecord> get errorRecords;
  List<dynamic> get delayedOutcomes;
  List<Note> get dueNotesList;
  List<dynamic> get blurtScores;
  List<dynamic> get learningAttempts;
  List<Note> get notes;
  List<dynamic> get pathwayRecords;
  List<WorkoutSessionState> get sessions;
  AppDatabase get db;
}
