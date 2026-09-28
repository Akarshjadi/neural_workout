# Ponytail cleanup — dead code & audit scaffolding removal

Repo: `neural_workout_app` (Flutter)
Branch: `main`
Start commit: `087fe182fa3e9bca0e95bd65dc625aaae67e50f0`

## Baseline (before any change)

| Check | Result |
| --- | --- |
| `flutter analyze` | `No issues found!` — 0 errors, 0 warnings, 0 infos |
| `flutter test` | **211 tests passed** (`All tests passed!`) |

Ground rule used throughout: after every batch, both commands were re-run. No batch regressed
the analyzer, and the only test-count change is the deliberate removal of 2 tests that pinned a
deleted file (see below). Every remaining test still passes.

## Commits

| Commit | Scope | Result |
| --- | --- | --- |
| `85b1960` | `chore(ponytail):` repo-root audit artifacts + `AppState.getOverallScore()` | analyze clean, 211 pass |
| `57eb25a` | `chore(ponytail):` `lib/` dead code (LearningCurveService, matchByHeuristic, InterventionOutcome) | analyze clean, 209 pass |
| `docs/audit/ponytail_report.md` | Phase D report | analyze clean, 209 pass |

Note: `AppState` had to ride with the repo-root commit. At session start the working tree held an
uncommitted "checkpoint" snapshot (`1598a6f`) in which `lib/state/app_state.dart` was already staged.
Committing only the root deletions would have captured a tree whose `lib/` was mid-refactor and did
not match the baseline. Pairing the deletions with the single-line `getOverallScore` removal — which
touches the already-staged file — keeps every commit's tree buildable and test-green.

## Phase A — repo-root artifacts deleted

| File | One-line reason |
| --- | --- |
| `build_and_validate.py` | One-shot audit runner script, not part of the app. |
| `build_classification_and_doc.py` | One-shot classification/doc generator. |
| `build_full_classification.py` | One-shot classification generator. |
| `classification_data.py` | Data blob consumed only by the deleted generators. |
| `classify_all.py` | One-shot classifier. |
| `classify_engine.py` | One-shot engine classifier. |
| `fix_blurt.py` | One-shot codemod; its output is already in `blurt_page.dart`. |
| `fix_today.py` | One-shot codemod; its output is already in `today_page.dart`. |
| `generate_doc.py` | One-shot doc generator. |
| `generate_revised_and_csv.py` | One-shot doc/CSV generator (was also tracked as staged `A`). |
| `populate_all_items.py` | One-shot audit backlog populator. |
| `test_output.txt` | Generated test log; regenerable with `flutter test`. |
| `test_results.txt` | Stale test log that contradicted `test_output.txt`. |
| `feature0_baseline.txt` | Audit snapshot. |
| `phase6_prereq.txt` | Audit scratch note. |
| `verification_phase1.txt` | Audit verification transcript. |
| `item_classification.csv` | Generated audit output. |
| `Neural Workout Complete Architecture & Feature.txt` | Audit input document, not app source. |
| `Neural Workout Complete Architecture & Feature.REVISED.txt` | Generated audit output (was staged `??`). |
| `__pycache__/` (untracked dir) | Bytecode cache for the deleted Python scripts. |

Also removed: `lib/ui/pages/blurt_page.dart.bak` — a stray backup of an app file (never referenced).


## Phase B — `lib/` decisions

Grep evidence is recorded per item (`grep -rn "<symbol>" lib/ test/`).

### 1. `LearningCurveService` — REMOVED

References found:

```
lib/state/app_state.dart:73                   final LearningCurveService learningCurveSvc = const LearningCurveService();
lib/services/learning_curve_service.dart:46   class LearningCurveService {
test/learning_curve_service_test.dart:9       const service = LearningCurveService();
```

Only the `AppState` field and the dedicated test — the exact condition in the brief. Removed:
- the `learningCurveSvc` field from `AppState` (last non-test "caller": the declaration itself; the
  field was never read anywhere),
- the now-unused `import '../services/learning_curve_service.dart'` from `app_state.dart`,
- `lib/services/learning_curve_service.dart` (class + `LearningCurvePoint` + `InterventionEffectivenessRow`),
- `test/learning_curve_service_test.dart` (2 tests).

Neither `LearningCurvePoint` nor `InterventionEffectivenessRow` was referenced outside that file.

### 2. `CapabilityEngine.capabilityArchitectureEnginePrompt` / `systemPrompt` / `researchPrompt` — KEPT

Pinned by `test/capability_engine_test.dart:65-67`. Added above the constant:

```dart
// Not on the execution path — research reference only. Pinned by test/capability_engine_test.dart.
```

The `const researchPrompt` alias and both `@Deprecated` getters stay as-is.

### 3. `CognitionEngine.neuroForecast` / `.focusForecast` / `.memoryForecast` — KEPT

Pinned by `test/cognition_engine_test.dart` (lines 26, 60, 86, 93, 112). Added a comment above
`neuroForecast`:

```dart
// The three forecasts below are deprecated as a *surface* (no fourth composite
// score is shown). The math is unchanged and remains the basis for
// [neuroFactorsFor], which is what the UI actually renders.
```

### 4. `LocalAiScorer.semanticVectorSearch` — KEPT as-is

Throws `UnimplementedError` by design; pinned by `test/phase1_services_parity_test.dart` as an
intentional honesty stub. No change.

### 5. `RankingService.overallScore` — KEPT

`@Deprecated` alias for `evidenceScore`; pinned by `test/ranking_service_test.dart` (6 call sites)
and `test/single_score_test.dart:33` as an explicit parity check ("evidenceScore and overallScore
return identical results"). No change.

### 6. `AppState.getOverallScore()` + `AppState.overallScore` — PARTIALLY REMOVED

Grep results:

```
lib/state/app_state.dart:93    double get overallScore => _overallScore;      <- deprecated property
lib/state/app_state.dart:413   _overallScore = rankingSvc.overallScore(...)   <- RankingService method (kept)
lib/state/app_state.dart:1433  double getOverallScore() => _overallScore;     <- deprecated method
test/workout_e2e_test.dart:72  expect(state.getOverallScore(), >= 0);         <- the only consumer
```

`getOverallScore()` was a pure delegate to `_overallScore` with no production callers and exactly
one test consumer. Removed it; the E2E test now asserts `state.evidenceScore`, which is byte-for-byte
the same value (`evidenceScore => _overallScore`). The deprecated `overallScore` **property** was
kept as the safety net for that same value (see the `@Deprecated` sweep below).

### 7. `AdaptiveInterventionService.matchByHeuristic` — COLLAPSED

Grep showed exactly two hits: its own definition and the call from `matchByEmpiricalData`. It was a
one-line delegation to `matchByConceptType`, so `matchByEmpiricalData` now calls
`matchByConceptType` directly and the shim is gone. Behavior is identical (same named arguments,
same target).

### 8. `InterventionOutcome` — REMOVED

Grep showed zero non-test callers:

```
lib/models/intervention.dart:137   class InterventionOutcome {
test/phase1_parity_test.dart:64    const outcome = InterventionOutcome(...
```

The test only constructed it and asserted `outcome.delayedDelta`. Removed the class and the test's
3 lines of construction/assertion (same commit). The `delayedDelta` math this DTO was meant to carry
lives in `DelayedOutcomeService` / `DelayedOutcome`; the model was never wired.

### 9. `today_page.dart` dangling painters — confirmed clean

`grep -n "_PulsePainter\|_CognitiveWeatherWidget" lib/ui/pages/today_page.dart` returns nothing
(no match, exit status 1), and the same grep across all of `lib/` and `test/` returns nothing.
Nothing to remove.

Kept at repo root, untouched per the brief: `ARCHITECTURE_AUDIT.md`, `phase1_report.md`,
`phase4_report.md`, `phase4_triage.md`, `phase5_report.md`, `phase5_verdicts.md`, `features.md`,
`README.md`, `devtools_options.yaml`. No reviewer asked to relocate them, so they stay in the root
(no links needed updating). `repomix-output.xml` and `test_output.log` were left alone: regenerable
export/log artifacts that the brief did not list for removal.

**Dangling-reference sweep after deletion.** `grep -rn` across tracked text files for every deleted
filename/script name returned hits in exactly two places — both of which were themselves deleted:
- `phase6_prereq.txt:4` → references `Neural Workout Complete Architecture & Feature.REVISED.txt`
- `Neural Workout Complete Architecture & Feature.REVISED.txt:943` → references `verification_phase1.txt`

No reference remains in `README.md`, `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, CI,

### 10. Full `@Deprecated` sweep

| Location | Symbol | Verdict | Reason |
| --- | --- | --- | --- |
| `capability_engine.dart:7` | `researchPrompt` const | KEEP | Pinned transitively by `capability_engine_test.dart` via `systemPrompt`. |
| `capability_engine.dart:160` | `CapabilityEngine.systemPrompt` | KEEP | Asserted by `test/capability_engine_test.dart:65-67`. |
| `capability_engine.dart:163` | `CapabilityEngine.researchPrompt` | KEEP | Same research-reference surface as above. |
| `cognition_engine.dart:99` | `neuroForecast` | KEEP | Pinned by `test/cognition_engine_test.dart`. |
| `cognition_engine.dart:129` | `focusForecast` | KEEP | Pinned by `test/cognition_engine_test.dart:93`. |
| `cognition_engine.dart:150` | `memoryForecast` | KEEP | Pinned by `test/cognition_engine_test.dart:86`. |
| `ranking_service.dart:93` | `RankingService.overallScore` | KEEP | Pinned by `ranking_service_test.dart` + `single_score_test.dart` parity check. |
| `app_state.dart:90` | `AppState.overallScore` | KEEP | Alias of `evidenceScore`; no non-test consumer, but left as the documented rename alias for the same cached value. Removing it was not required by any item. |
| `app_state.dart:89` | `/// @Deprecated(...)` doc comment above the property | KEEP | Doc comment for the kept property. |

`lib/services/learning_curve_service.dart:45` was the ninth hit in the baseline sweep — that whole
file is deleted, so the hit is gone. Nothing in `lib/` is deprecated *and* unreferenced at this point.

## Phase C — analyzer noise

`dart fix --dry-run` → **"Nothing to fix!"** (nothing to apply, so no diff to review).

`flutter analyze` (also run with `--fatal-infos --fatal-warnings`) → **"No issues found!"**. There
were no `unused_import`, `unused_element`, `unused_field`, or `dead_code` diagnostics to fix: the
only unused import created by Phase B (the `learning_curve_service.dart` import in `app_state.dart`)
was removed by hand in the same edit, and no `// ignore:` suppression exists anywhere in `lib/` or
`test/` for those codes (verified by grep). No warning was silenced.

## Phase D — final verification

| Check | Baseline | Final |
| --- | --- | --- |
| `flutter analyze` | No issues found (0 errors / 0 warnings / 0 infos) | **No issues found (0/0/0)** |
| `flutter test` | **211 passed** | **209 passed** |

The −2 delta is fully accounted for: `test/learning_curve_service_test.dart` contained exactly two
tests, both of which only exercised the deleted `LearningCurveService`. No other test was weakened.

The one test that had to change (`test/workout_e2e_test.dart`) asserts against the identical value
through the current API name; its diff is:

```diff
-    expect(state.getOverallScore(), greaterThanOrEqualTo(0));
+    expect(state.evidenceScore, greaterThanOrEqualTo(0));
```

And the `phase1_parity_test.dart` line removed alongside `InterventionOutcome`:

```diff
-      const outcome = InterventionOutcome(
-        interventionId: 1,
-        sampleSize: 5,
-        delayedDelta: 10.5,
-      );
-      expect(outcome.delayedDelta, 10.5);
-
```

Net effect: **19 root-level files removed, 2 `lib/` files removed, 1 stray `.bak` removed, 5 symbols
deleted (`AppState.getOverallScore`, `AdaptiveInterventionService.matchByHeuristic`,
`InterventionOutcome`, `LearningCurveService` + the 2 model classes that lived only inside it),
0 behavior changes, 0 analyzer regressions, all remaining tests green.**

`android/`, `web/`, or any other tracked file. No link cleanup was required.
