# Phase 5 Decisions and Verdicts

## Verdict Summary
- **wire-as-diagnostic**: 1 (`CognitionEngine` - Item 192)
- **wire-as-policy**: 1 (`SuggestionService` - Evidence suggestions)
- **keep-frozen**: 1 (`LearningCurveService` - Item 190)
- **delete**: 0

---

## Verdict Details

| Symbol / Item | Verdict | Rationale & Responsibility Mapping |
|---|---|---|
| **`CognitionEngine`** (Item 192) | `wire-as-diagnostic` | Surfaced as read-only diagnostic factor breakdown (`todayNeuroFactors` in `today_page.dart`). Composite forecast total is deprecated and not surfaced to avoid a competing overall brain score. |
| **`SuggestionService`** (Audit §8) | `wire-as-policy` | Wired directly to the evidence layer (`generateEvidenceSuggestions`) using error recurrence, delayed retention gaps, and experiment power thresholds to steer learner practice priorities. |
| **`LearningCurveService`** (Item 190) | `keep-frozen` | Preserved and marked `@Deprecated`. Pure mathematical exponential curve fitting preserved for research reference; visual retention decay curves are handled directly by `RetentionDecay` and `HorizonCurve` widgets. |

---

## Absorbing Responsibilities
- No files were deleted outright. Responsibilities for visual retention curves are absorbed by `RetentionDecay` (`lib/widgets/visuals/retention_decay.dart`) and `VisualSemantics`.
- Overall scoring responsibility is absorbed strictly by `RankingService.evidenceScore`.
