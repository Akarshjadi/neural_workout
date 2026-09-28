# Phase 4 Triage: Orphaned & Dormant Systems

## Triage Summary
- **Wire**: 3 items (`HiveReview.wasInterleaved`, `CapabilityEngine`, `AdaptiveInterventionService.matchByEmpiricalData`)
- **Delete**: 0 items
- **Defer**: 3 items (`CognitionEngine`, `SuggestionService`, `LearningCurveService`)

---

## 1. Wire (Priority Implementation)

1. **`HiveReview.wasInterleaved` (Audit §8)**:
   - *Rationale*: Field was written but always false. Deriving it dynamically from `activeWorkout` anchor immediately activates interleaving metrics for downstream analytics (`PlasticityService`, `StrategyProfileService`).
2. **`CapabilityEngine` (Item 135 / Audit §8)**:
   - *Rationale*: Pure domain capability assessment revived from `EvidenceSummary` without LLM calls, providing structured capability scores, confidence, and contradiction detection.
3. **`AdaptiveInterventionService.matchByEmpiricalData` (Audit §8)**:
   - *Rationale*: Replaces static hardcoded switch with data-driven selection based on `ExperimentService.effectivenessByConceptType` delayed outcomes when sample size $\ge 3$.

---

## 2. Delete

*(None in this phase; dormant engines are preserved for domain logic reuse or deferred integration.)*

---

## 3. Deferred to Phase 5

1. **`CognitionEngine` (Item 192 / Audit §8)**:
   - *Rationale*: Complex 613-line predictive model requiring full state pipeline integration and multi-horizon forecasting UI components in Phase 5.
2. **`SuggestionService` (Audit §8)**:
   - *Rationale*: Currently functioning with a 2-item cap; full rewrite to consume live `SessionPolicyEngine` queue deferred to Phase 5.
3. **`LearningCurveService` (Item 190 / Audit §8)**:
   - *Rationale*: Pure mathematical curve fitter tested in isolation; deferred to Phase 5 for dynamic chart visual binding.
