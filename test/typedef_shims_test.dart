import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/focus_integrity.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/services/research_catalog.dart';

void main() {
  test('typedef shims resolve to correct runtime types', () {
    const LearningAttemptType attemptType = TestType.freeRecall;
    expect(attemptType, isA<TestType>());

    const AdaptiveInterventionType interventionType = InterventionAction.retrieve;
    expect(interventionType, isA<InterventionAction>());

    const CognitiveErrorCategory errorCategory = ErrorType.factualRecallFailure;
    expect(errorCategory, isA<ErrorType>());

    const FocusIntegrityRecord focusRecord = FocusIntegrity();
    expect(focusRecord, isA<FocusIntegrity>());

    const SafetyClass safety = SafetyClassification.safeSoftware;
    expect(safety, isA<SafetyClassification>());

    const ResearchCatalogItem researchItem = ResearchEntry(
      id: 'test',
      name: 'Test',
      tier: 1,
      category: 'Test',
      description: 'Test',
      evidenceLevel: 1,
      implementationStatus: ImplementationStatus.implemented,
      safetyLevel: SafetyClassification.safeSoftware,
    );
    expect(researchItem, isA<ResearchEntry>());
  });
}
