# ARCHITECTURE_AUDIT.md — Neural Workout

**Phase 0 deliverable.** Written from source inspection only (source is authoritative; README is stale — it documents a "Neuroplasticity Model" section duplicated and truncated mid-sentence, and never mentions `CognitionEngine`, `CapabilityEngine`, `ForgettingCurveService` or the session wizard's real step list).

Baseline at time of audit: `flutter test` → **110 passing**; `flutter analyze` → clean. Flutter 3.44.8 / Dart 3.12.2.

---

## 1. What the app actually is

A **general-purpose offline-first cognitive learning notebook**, not an exam app. There is no subject/syllabus/exam/PYQ entity anywhere in the codebase, and none should be introduced.

The real user loop, traced end to end through source:

```
Index/Today ──startSession(anchorTitle, anchorNoteId)──► Session (Hive, autosaved)
                                                            │
                           wizard steps 0..6 (cover→…→back_cover)
                                                            │
                         Blurt (free recall, source hidden) │
                                    │                       │
                      BlurtScorer (deterministic)  ◄────────┤
                      LocalAiScorer (Gemma, optional) ◄──────┘
                                    │
                         BlurtScore → Hive blurt_scores
                                    │
                    scoreToRating() → FsrsEngine.review(card, rating)
                                    │
                         Note.card updated + HiveReview row
                                    │
               PathwayRecord → RankingService / PlasticityService / CognitionEngine
```

There is exactly **one** durable evidence artifact per attempt (`BlurtScore`) and exactly **one** scheduling artifact per attempt (`HiveReview`). Everything else is a projection.

## 2. Dependency graph (verified by import scan)

```
main.dart
 └─ AppState (ChangeNotifier, 1023 lines) ─────────────── the god object
      ├─ AppDatabase (Hive, 10 boxes, schemaVersion 5)
      ├─ FsrsEngine            → package:fsrs
      ├─ BlurtScorer           (pure, deterministic, 0 deps)
      ├─ LocalAiScorer         → flutter_gemma (optional, fallback-safe)
      ├─ PathwayService        (pure)
      ├─ StreakService         (pure)
      ├─ BreakService          (pure)
      ├─ MetricsService        (pure)
      ├─ RankingService        (pure)
      ├─ SuggestionService     (→ AppState)
      ├─ StrategyProfileService(pure)
      ├─ PlasticityService     (pure, 5 proxies + overall0to100)
      ├─ NotificationService   → flutter_local_notifications
      ├─ ExportService         → csv, path_provider
      ├─ ImportService         (JSON restore)
      └─ CognitionEngine       ⚠ NOT referenced by AppState or any page
```

UI: `NotebookShell` (page-turn shell) → `today_page`, `index_page`, `blurt_page`, `compare_page`, `card_page`, `graph_page`, `back_cover_page`, `checkin_page`, `cover_page`.

## 3. Persistence

Single Hive store, 10 boxes, **hand-written mappers** (`_nT`/`_nF` etc.); the `.g.dart` holds only adapters.

| typeId | Hive class | Box | Purpose |
|---|---|---|---|
| 0 | `HiveNote` | `notes` | atomic concept; `cardState` = JSON FSRS `Card`; `deletedAt` soft delete |
| 1 | `HiveSession` | `sessions` | wizard run; `autosaveJson` = lossless resume blob |
| 2 | `HiveBlurtScore` | `blurt_scores` | one free-recall attempt + score |
| 3 | `HivePathwayRecord` | `pathway_records` | daily 5-pathway booleans + grace |
| 4 | `HiveReview` | `reviews` | `note_id`, `rating`, `was_interleaved` |
| 5 | `HiveLink` | `links` | knowledge-graph edge (`from`, `to`, `relationText`) |
| 6 | `HiveSetting` | `settings` | kv, all values strings |
| 7 | `HiveThought` | `thoughts` | quick capture, soft delete |
| 8 | `HiveCheckin` | `checkins` | key = `YYYY-MM-DD` → sleep/energy/activity |

`meta` box holds `schema_version` and `seq_<box>` id counters (`_nextId`).

**Migration mechanism** (`_checkSchemaVersion` → `_runMigrations`): strictly additive, idempotent, versioned `if (from < N) _migrateVN()`. v1→v2 note `deletedAt`; v2→v3 blurt metrics; v3→v4 thoughts box; v4→v5 session `focusPrimed`. **Sound; extend, do not replace.**

### Migration risks found
1. `_migrateV1ToV2` and `_migrateV2ToV3` iterate `box.keys` and cast `box.get(key) as HiveNote?` / `as HiveBlurtScore?` — a malformed legacy row throws a `TypeError` **during app boot**, which `main.dart` swallows into a startup SnackBar. New migrations must type-check, not cast.
2. `_checkSchemaVersion` records the version but not what ran. Additive migrations are re-runnable, so tolerable; log anyway.
3. `HiveSession.stepsCompleted` semantics are overloaded (see §7).
4. `_nextId` is read-modify-write on `meta`; fine single-threaded, unsafe if writes ever interleave. Out of scope; note only.

## 4. Domain model

Thin, mostly-anemic holders with `const` constructors and no behaviour: `Note` (+ FSRS `Card`), `BlurtScore`, `Session`, `PathwayRecord`, `Thought`, `DailyCheckin`, `BreakRecord`, `Capability`, `WorkoutSessionState` (the only model with real logic: sentinel `copyWith`, versioned JSON, total-catch `fromJson`).

**Gap:** no first-class record of *an attempt* that knows **what kind** of learning operation it was. `BlurtScore` conflates target (`noteId`), operation (always free recall), result (`scorePct`) and artefacts (`matched`/`missed`). `wasInterleaved` already exists on `HiveReview` — interleaving infrastructure is **present but never set to true by any call site** (`AppState.reviewNote` defaults `interleaved: false`; no caller passes `true`). Clearest example of a dormant system to activate rather than duplicate.

## 5. Service map — overlapping definitions of "knowledge"

| Service | Output | Data used | Verdict |
|---|---|---|---|
| `BlurtScorer` | `ScoreResult` 0..100 semantic match | note body keywords, aliases, Levenshtein | **keep, extend** (the recall evaluator) |
| `LocalAiScorer` | same shape + depth/clarity | Gemma | keep; parser clamps and throws on garbage |
| `MetricsService` | `BlurtMetrics` | blurts, sessions, links | keep; per-attempt deterministic metrics |
| `RankingService` | `overallScore` 0..100, weakest areas | blurts, notes, pathways, links, reviews | vanity score (see §6) |
| `PlasticityService` | 5 proxies + `overall0to100` | blurts, checkins, reviews, notes, links, sessions | proxy indices; only consumer of checkins |
| `CognitionEngine` | `MetricForecast` indices | same + breaks | **orphaned — zero references** |
| `CapabilityEngine` | `Capability` + 146-line LLM prompt | nothing (never called) | **orphaned**; prompt-in-a-service |
| `ForgettingCurveService` | `R(t)=e^(-t/S)` series | note card | keep; correct and small |
| `FsrsEngine` | `Card` update + interval + retrievability | fsrs package | **keep verbatim** — scheduling is sound |
| `StrategyProfileService` | 6 habits 0..100 | blurts, review rows, autosaveJson | keep as *practice-habit* view |
| `SuggestionService` | <=2 strings | `AppState` directly | keep; priority lives in the service, not the UI |
| `PathwayService`/`StreakService`/`BreakService` | pathway week, streak, break status | records | keep |
| `ExportService`/`ImportService` | CSV/JSON files | models + `export_dto` | keep; `_sanitize` guards CSV injection |

**Three competing "overall" numbers exist simultaneously**: `RankingService.overallScore` (`getOverallScore()`), `PlasticityService.overall0to100` (the "Plasticity Pulse" + "Cognitive Weather"), and ad-hoc **XP/level gamification computed inline in `today_page.dart`** (`_calculateXP`, `_getLevel`) — widget-level metric with no service, no test, no definition. The §35/§36 requirement lands exactly here.


## 6. Existing analytics inventory

- `RankingService.overallScore` = 0.30·blurtAcc + 0.25·reviewRetention + 0.15·AI-depth + 0.10·AI-clarity + 0.10·linked-notes% + 0.10·pathway%. **AI-only terms silently collapse to 0 when AI is off**, dragging the score down for reasons unrelated to learning — the §32 "missing AI information becomes zero scores" problem, confirmed in code.
- `today_page` XP = `blurts*10 + reviews*5 + 5 per blurt scoring 70-85`. Pure effort counter: defensible as *effort*, indefensible as *learning*.
- `CognitionEngine` indices exist but are dead.
- `CapabilityEngine` describes an evidence hierarchy (Level 1 self-rating -> Level 5 repeated objective performance), contradiction detection, calibration gap, bottleneck priority, and states VERIFIED/PROBABLE/DEVELOPING/BOTTLENECK/UNVERIFIED. **Directly reusable** — maps almost 1:1 onto the required evidence->state model. Must NOT be reused: its 0-100 `base_score` weighting, its personality-ish "capability taxonomy", and its research prompt living inside a service.

## 7. Session architecture reality check

`WorkoutSessionState.stepsCompleted` runs 0..7 with 7 = terminal; persisted as 8. Step writers (`setBlurt`, `setCheatSheet`, `setLinkText`, `setTeaching`) each `_autosave()`. `advanceStep()` finalises at step 7 -> `_logPathwayFor` -> `Session.stepsCompleted = 8`.

Documented order is 0 blurt · 1 compare · 2 cheat sheet · 3 link · 4 teach · 5 interleave · 6 schedule — **but `finishBlurt()` calls `advanceStep()` itself** and `scheduleAnchor()` has no step-index coupling, so the wizard is a semi-linear form, not a policy pipeline. No decision anywhere about *what to do next*; the order is fixed in the cover/back-cover widgets.

Preserve: `_PulsePainter` and "Cognitive Weather" are decoration driven by cached `plasticityProfile`; heavy analytics are correctly **not** in `build()` (`_plasticityProfileCache`, invalidated in `_refreshAnalytics()`). Keep that property.

## 8. Dead / orphaned / dormant systems (activation candidates)

| Item | Status | Action |
|---|---|---|
| `HiveReview.wasInterleaved` | written, always `false` | **activate** in the new interleaving engine |
| `CognitionEngine` (613 lines) | zero callers | keep file; do **not** build a second forecast engine |
| `CapabilityEngine` + `Capability` | zero callers | **revive the ideas** as pure domain code; drop the LLM prompt from the execution path |
| `PlasticityService.checkins` | only consumer of `DailyCheckin` | keep; checkins become the Context model |
| `BreakService`/`BreakRecord` | used only in `breakStatus` | keep |
| `break_records` setting | JSON blob in `settings` | leave |
| `today_page` XP/level | inline widget maths | **demote/relabel**; do not delete |
| `SuggestionService` | works, 2-item cap | keep; becomes a thin view over the new policy engine |
| `ForgettingCurveService` | tested, unused by UI | keep; feeds the learning-curve view |

No `lib/` file is unreferenced except through the above. No orphaned boxes. Nothing will be deleted.

## 9. Test surface (110 tests, 24 files)

Strong on: scorer semantics, FSRS scheduling, migration boxes/adapters, end-to-end wizard (incl. cold-start and duplicate-anchor regressions), AI parsing, ranking/plasticity/metrics/strategy/suggestion.

**Untested gaps the upgrade must fill:** delayed outcomes, calibration, error taxonomy, intervention selection, strategy switching, experiment assignment, retention/transfer analytics, AI-malformed-output fallback at the *service* boundary, and migration from *partially populated / malformed* legacy boxes.

## 10. Non-negotiables confirmed from code

1. `FsrsEngine` is a correct thin wrapper over `package:fsrs` — do not reimplement spacing.
2. `LocalAiScorer` throws `StateError` if not ready and `FormatException` on garbage; `AppState.scoreBlurt` catches -> `BlurtScorer`. The fallback chain is real. Extend the same pattern to every new AI call.
3. `WorkoutSessionState.fromJson` catches **everything**, returns `null`, and `load()` drops un-resumable sessions rather than showing a broken step. Preserve this posture in all new deserialisation.
4. Everything is offline; the only network is the one-time Gemma model download.
5. `analysis_options.yaml` enables `flutter_lints` + `avoid_print` etc. New code stays `flutter analyze`-clean.

## 11. Audit conclusion -> change plan

Keep: Hive + additive migrations, FSRS path, Blurt + scorer + AI fallback, graph links, sessions/autosave, pathways/streak/breaks, notifications, CSV/JSON export, the whole UI shell and notebook theming.

Add (additively, in new boxes and new pure services; `AppState` gains delegation only): `LearningAttempt` (discriminated by `TestType`), `ConfidenceJudgment`, `FeedbackRecord`, `ErrorRecord`, `DelayedOutcome`, `Intervention`/`InterventionOutcome`, `Experiment`, `FocusIntegrity`, context fields — plus `FeedbackEngine`, `ErrorDiagnosisService`, `MetacognitionService`, `InterventionEngine`, `RetrievalService`, `LearningAnalyticsService`, `ExperimentService`, `ResearchRegistry`.

Nothing in the existing 110 tests may need to change for any of it.

