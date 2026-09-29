import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:neural_workout/models/delayed_outcome.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/experiment.dart';
import 'package:neural_workout/models/focus_integrity.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/ai_scaffolding_service.dart';

import 'package:neural_workout/ui/theme_notebook.dart';
import 'package:neural_workout/widgets/visuals/calibration_field.dart';
import 'package:neural_workout/widgets/visuals/circadian_performance_card.dart';
import 'package:neural_workout/widgets/visuals/contrast_matrix.dart';
import 'package:neural_workout/widgets/visuals/cue_gradient.dart';
import 'package:neural_workout/widgets/visuals/error_topology.dart';
import 'package:neural_workout/widgets/visuals/intervention_trial_board.dart';
import 'package:neural_workout/widgets/visuals/memory_horizon.dart';
import 'package:neural_workout/widgets/visuals/multidimensional_evidence_profile.dart';
import 'package:neural_workout/models/evidence_profile_dimension.dart';
import 'package:neural_workout/widgets/visuals/research_horizon.dart';
import 'package:neural_workout/widgets/visuals/retention_trajectory.dart';
import 'package:neural_workout/widgets/visuals/session_integrity_timeline.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: NotebookTheme.theme,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('Visual components render cleanly', (tester) async {
    // 1. Evidence Profile
    await tester.pumpWidget(wrap(
      const MultidimensionalEvidenceProfile(
        dimensions: [
          EvidenceProfileDimension(label: 'Retrieval', value: 0.85, detail: '85% accuracy'),
          EvidenceProfileDimension(label: 'Retention', value: 0.70, detail: '70% delayed'),
        ],
      ),
    ));
    expect(find.byType(MultidimensionalEvidenceProfile), findsOneWidget);

    // 2. Memory Horizon
    await tester.pumpWidget(wrap(
      MemoryHorizon(notes: [
        Note(id: 1, title: 'Concept A', body: 'Body A', kind: NoteKind.blurtSummary, card: fsrs.Card(cardId: 1), createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ]),
    ));
    expect(find.text('MEMORY HORIZON'), findsOneWidget);

    // 3. Calibration Field
    await tester.pumpWidget(wrap(
      CalibrationField(attempts: [
        LearningAttempt(id: 1, timestamp: DateTime.now(), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 80.0, confidence: 85),
      ]),
    ));
    expect(find.text('CALIBRATION FIELD'), findsOneWidget);

    // 4. Error Topology
    await tester.pumpWidget(wrap(
      ErrorTopology(errorRecords: [
        ErrorRecord(id: 1, attemptId: 1, type: ErrorType.conceptualMisunderstanding, source: DiagnosisSource.user, createdAt: DateTime.now()),
      ]),
    ));
    expect(find.text('ERROR TOPOLOGY'), findsOneWidget);

    // 5. Retention Trajectory
    await tester.pumpWidget(wrap(
      RetentionTrajectoryWidget(outcomes: [
        DelayedOutcome(id: 1, knowledgeTargetId: 1, attemptId: 1, measuredAt: DateTime.now(), bucket: DelayBucket.shortDelay, elapsed: const Duration(days: 1), correctness: Correctness.correct, scorePct: 85.0),
      ]),
    ));
    expect(find.text('RETENTION TRAJECTORY'), findsOneWidget);

    // 6. Cue Gradient
    await tester.pumpWidget(wrap(
      const CueGradientWidget(currentLevel: ScaffoldingLevel.hint),
    ));
    expect(find.text('SCAFFOLD GRADIENT'), findsOneWidget);

    // 7. Contrast Matrix
    await tester.pumpWidget(wrap(
      const ContrastMatrixWidget(
        conceptAName: 'TCP',
        conceptBName: 'UDP',
        rows: [ContrastMatrixRow(dimension: 'Connection', conceptAValue: 'Connection-oriented', conceptBValue: 'Connectionless')],
      ),
    ));
    expect(find.text('TCP'), findsOneWidget);

    // 8. Session Integrity
    await tester.pumpWidget(wrap(
      const SessionIntegrityTimelineWidget(integrity: FocusIntegrity(plannedDuration: Duration(minutes: 25), actualDuration: Duration(minutes: 25), longestFocusMs: 1200000, interruptions: 1)),
    ));
    expect(find.text('FOCUS INTEGRITY'), findsOneWidget);

    // 9. Research Horizon
    await tester.pumpWidget(wrap(
      ResearchHorizonWidget()));
    expect(find.text('RESEARCH EVIDENCE HORIZON'), findsOneWidget);

    // 10. Trial Board
    await tester.pumpWidget(wrap(
      InterventionTrialBoardWidget(activeExperiment: Experiment(
        id: 1,
        hypothesis: 'Interleaving increases delayed retention vs massing',
        conditions: const [
          ExperimentCondition(key: 'ctrl', label: 'Massed', action: InterventionAction.retrieve),
          ExperimentCondition(key: 'exp', label: 'Interleaved', action: InterventionAction.interleave),
        ],
        startedAt: DateTime.now(),
      )),
    ));
    expect(find.text('ACTIVE INVESTIGATION'), findsOneWidget);

    // 11. Circadian Performance Card (empty)
    await tester.pumpWidget(wrap(
      const CircadianPerformanceCard(attempts: []),
    ));
    expect(find.text('CIRCADIAN PERFORMANCE'), findsOneWidget);
    expect(find.text('0 measured hours · observational, not causal'), findsOneWidget);

    // 12. Circadian Performance Card (3 attempts at hour 9)
    await tester.pumpWidget(wrap(
      CircadianPerformanceCard(attempts: [
        LearningAttempt(id: 1, timestamp: DateTime(2026, 1, 1, 9, 15), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 80.0),
        LearningAttempt(id: 2, timestamp: DateTime(2026, 1, 2, 9, 30), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 85.0),
        LearningAttempt(id: 3, timestamp: DateTime(2026, 1, 3, 9, 45), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90.0),
      ]),
    ));
    expect(find.text('1 measured hours · observational, not causal'), findsOneWidget);
  });
}



