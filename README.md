# neural_workout

A personal spaced-repetition and cognitive-training app built with Flutter. Write quick "blurts" (free-recall dumps) about topics you're learning, get them scored semantically (local AI via Gemma or deterministic fallback), link related notes, and schedule reviews through FSRS. Tracks streaks with a grace-token system, computes overall cognitive profile scores, and surfaces weakest areas.

## Phases

1. **Local AI scorer** — Hybrid: deterministic + AI scoring with fallback.
2. **Deterministic metrics** — recall accuracy, speed, retention, cross-link density (% of notes linked), loss rate.
3. **Thoughts stream** — Quick capture with tags, keyword search, CSV export.
4. **Data lifecycle** — Soft-delete with recovery; manual archive of stale data (no auto-prune).
5. **Ranking & dashboard** — Overall cognitive profile score, weakest areas.
6. **Notifications & suggestions** — Time-based daily reminders and prioritized session suggestions.
7. **Memory configuration** — Model type, max tokens, temperature in settings.

- **Model:** Gemma via `flutter_gemma` package. Model download on first use; cached after.
- **Fallback:** When the model is unavailable or fails, the app falls back to the deterministic `BlurtScorer` — never crashes.
- **Toggle:** Settings → "Use AI scoring". Shows "Model not loaded" when unavailable.
- **Configuration:** Model type (gemmaIt/general/deepSeek), max tokens, temperature.
- **Privacy:** AI inference is 100% local. No API keys, no inference network calls. (Model download requires network on first use.)
- **Honest limitations:** The `flutter_gemma` package exposes only `ModelType` and `maxTokens` — context window and model size selection are not publicly configurable.
