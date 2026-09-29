import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/learning_enums.dart';

void main() {
  test('user and deterministic diagnoses on the same type both persist', () async {
    final tempDir = await Directory.systemTemp.createTemp('dedup_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    final db = AppDatabase();
    
    await db.insertError(ErrorRecord(
      id: 0, attemptId: 7, type: ErrorType.retrievalFailure,
      source: DiagnosisSource.user, createdAt: DateTime.now(),
    ));

    await db.insertError(ErrorRecord(
      id: 0, attemptId: 7, type: ErrorType.retrievalFailure,
      source: DiagnosisSource.deterministic, createdAt: DateTime.now(),
    ));

    expect(db.allErrors().where((e) => e.attemptId == 7).length, 2);
    
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });
}