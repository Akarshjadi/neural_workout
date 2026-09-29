import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/learning_enums.dart';

void main() {
  test('ErrorRecord.confusedConceptId survives Hive round-trip', () async {
    final tempDir = await Directory.systemTemp.createTemp('error_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    final db = AppDatabase();
    
    await db.insertError(ErrorRecord(
      id: 0, attemptId: 1, type: ErrorType.confusedConcepts,
      source: DiagnosisSource.user, createdAt: DateTime.now(),
      confusedConceptId: 42,
    ));
    expect(db.allErrors().single.confusedConceptId, 42);
    
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });
}