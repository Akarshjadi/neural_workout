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

8. **3M Break Recovery Framework** — Micro (5m/day), Meso (2h/week), Macro (1d/month) recovery rhythms tracked alongside streaks to prevent burnout.

- **Model:** Gemma via `flutter_gemma` package. Model download on first use; cached after.
- **Fallback:** When the model is unavailable or fails, the app falls back to the deterministic `BlurtScorer` — never crashes.
- **Toggle:** Settings → "Use AI scoring". Shows "Model not loaded" when unavailable.
- **Configuration:** Model type (gemmaIt/general/deepSeek), max tokens, temperature.
- **Privacy:** AI inference is 100% local. No API keys, no inference network calls. (Model download requires network on first use.)
- **Honest limitations:** The `flutter_gemma` package exposes only `ModelType` and `maxTokens` — context window and model size selection are not publicly configurable.


## Neuroplasticity Model

This app tracks 5 behavioral proxies grounded in 2025–2026 neuroscience research to evaluate adaptivity instead of just a raw score:

1. **Cognitive Speed Index (Cholinergic proxy)**
   - *Basis*: McGill 2026 (GeroScience) - speed-based training increasing cholinergic binding.
   - *Metric*: `recallSpeedMs` trend slope over trailing 30 days.
   - *Honest Limitation*: Recall speed is a behavioral proxy, not a physiological cholinergic measurement.

2. **Recovery Reserve**
   - *Basis*: BDNF via activity framework (2025 systematic review).
   - *Metric*: Daily Check-in of Sleep, Energy, and Physical Activity.
   - *Honest Limitation*: Self-report sleep/activity is not a physiological BDNF tracker.

3. **Desirable Difficulty Index**
   - *Basis*: 2026 unified theory driving consolidation via effortful retrieval.
   - *Metric*: Blurt accuracy (peak 77.5%), rating mix (peak ~35% hard/again), and review interleaving index.
   
4. **Network Integration**
   - *Basis*: 2025 cognitive-training study tracking functional connectivity improvements.
   - *Metric*: Note co-link clustering density and connected components.
   
5. **Mindfulness Priming**
   - *Basis*: *npj Science of Learning* (2026) brief mindfulness to improve executive control.
   - *Metric*: Pre-session 5-minute breathing execution rate over the trailing 30 days.


## Neuroplasticity Model

This app tracks 5 behavioral proxies grounded in 2025–2026 neuroscience research to evaluate adaptivity instead of just a raw score:

1. **Cognitive Speed Index (Cholinergic proxy)**
   - *Basis*: McGill 2026 (GeroScience) - speed-based training increasing cholinergic binding.
   - *Metric*: `recallSpeedMs` trend slope over trailing 30 days.
   - *Honest Limitation*: Recall speed is a behavioral proxy, not a physiological cholinergic measurement.

2. **Recovery Reserve**
   - *Basis*: BDNF via activity framework (2025 systematic review).
   - *Metric*: Daily Check-in of Sleep, Energy, and Physical Activity.
   - *Honest Limitation*: Self-report sleep/activity is not a physiological BDNF tracker.

3. **Desirable Difficulty Index**
   - *Basis*: 2026 unified theory driving consolidation via effortful retrieval.
   - *Metric*: Blurt accuracy (peak 77.5%), rating mix (peak ~35% hard/again), and review interleaving index.
   
4. **Network Integration**
   - *Basis*: 2025 cognitive-train   - *Basis*: 2025 cogntio   - *Basis*: 2025 cognitive-train   - *Basis*: 2025 cogntio   - *Basis*: 2025 cognitive-train   - *Basis*: 2025 cogntio   - *Basis***
   - *Basis*: *npj Science of Learning* (2026) bri   - *Basis*: *npj Science of Learning* (2026) bri   - *Basis*: *npj Science of Learning* (20ecution rate over the trailing 30 days.
