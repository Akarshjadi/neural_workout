# Phase 4 Implementation Report

## Test Count Progression
- **Baseline before Phase 4**: 160 passing tests
- **After Phase 4**: 168 passing tests (+8 tests across 3 suites)
- **Analyzer Status**: Clean (0 issues)
- **Unwired Items Count**: Decreased from 3 to 2 (`[UNWIRED]` count strictly reduced)

---

## Wired Items Summary

### 1. Interleaved Review Detection (`HiveReview.wasInterleaved`)
Previously, `reviewNote` defaulted `interleaved = false` and no caller ever passed `true`, leaving `wasInterleaved` permanently at zero across the entire review history. In Phase 4, `AppState.reviewNote` derives `wasInterleaved` dynamically from `activeWorkout`: if a note $B$ is reviewed during a session anchored on note $A$, it is automatically recorded as an interleaved practice trial. This populates durable interleaving flags in both `HiveReview` and `LearningAttempt`, immediately feeding `PlasticityService.desirableDifficulty`, `StrategyProfileService`, and `CognitionEngine`. Verified by `test/interleaved_review_test.dart` (test count increased by 1).

### 2. Personal Capability Engine (`CapabilityEngine`)
Previously, `CapabilityEngine` was orphaned with a 146-line LLM prompt living inside the service. In Phase 4, the prompt was moved out of the runtime path (marked `@Deprecated`), and a pure deterministic domain entry point `CapabilityEngine.assess(KnowledgeEvidence)` was implemented. It derives capability scores, confidence ratings, and contradiction anomalies (`overconfident by Xpts` when calibration error exceeds 20) directly from `EvidenceSummary` without any LLM dependencies or latency. Wired into `AppState.capabilityFor(noteId)` and surfaced as a dedicated "CAPABILITY" block in `CardPage`. Verified and extended in `test/capability_engine_test.dart` (test count increased by 3).

### 3. Empirical Intervention Matching (`AdaptiveInterventionService.matchByEmpiricalData`)
Previously, intervention selection fell back to a hardcoded static switch mapping `ConceptType` to actions regardless of historical learning outcomes. In Phase 4, `AdaptiveInterventionService.matchByEmpiricalData` was introduced to query personal delayed retention outcomes across concept types (`ExperimentService.effectivenessByConceptType`). When empirical evidence has sample size $\ge 3$, the system dynamically selects the intervention action with the highest empirical mean delayed score, falling back to the heuristic switch only under low sample sizes. Wired into `AppState.empiricalMatches` and threaded through `SessionPolicyEngine.planStep`. Verified by `test/empirical_matching_test.dart` (test count increased by 4).

---

## Deferred Items (Phase 5)
- **`CognitionEngine`** (Item 192): Complex 613-line predictive engine; deferred to Phase 5 for full forecasting view integration.
- **`SuggestionService`**: Currently functional with 2-item priority queue; deferred to Phase 5 for direct policy queue binding.
- **`LearningCurveService`** (Item 190): Mathematical curve fitter; deferred to Phase 5 for multi-curve visual widget binding.
