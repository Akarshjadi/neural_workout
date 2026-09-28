/// Session-level attention measurements (§26).
///
/// Only records what the app can actually observe on the platform. There is no
/// "focus score" here and there never should be: interruptions are counted from
/// real app lifecycle events, task switches from real wizard navigations.
class FocusIntegrity {
  final int? sessionId;

  /// What the learner (or the policy) intended the session to run for.
  /// Null when no plan was set — not a fabricated default.
  final Duration? plannedDuration;

  /// Wall clock from session start to completion/abandonment.
  final Duration actualDuration;

  /// App went to background during the session.
  final int interruptions;

  /// Wizard steps visited more than once, or target changes mid-session.
  final int taskSwitches;

  final bool abandoned;
  final bool completed;

  /// Longest unbroken foreground stretch, in ms. Null when never tracked.
  final int? longestFocusMs;

  const FocusIntegrity({
    this.sessionId,
    this.plannedDuration,
    this.actualDuration = Duration.zero,
    this.interruptions = 0,
    this.taskSwitches = 0,
    this.abandoned = false,
    this.completed = false,
    this.longestFocusMs,
  });

  /// Fraction of the plan actually delivered, clamped to 0..1. Null when no
  /// plan existed — an unplanned session is not a 0% session.
  double? get completionRatio {
    final plan = plannedDuration;
    if (plan == null || plan.inMilliseconds <= 0) return null;
    return (actualDuration.inMilliseconds / plan.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Interruptions per 10 minutes of actual work. Null for zero-length sessions
  /// (division would be meaningless, not zero).
  double? get interruptionRate {
    if (actualDuration.inSeconds < 60) return null;
    return interruptions / (actualDuration.inMilliseconds / 600000);
  }

  FocusIntegrity copyWith({
    int? sessionId,
    Duration? plannedDuration,
    Duration? actualDuration,
    int? interruptions,
    int? taskSwitches,
    bool? abandoned,
    bool? completed,
    int? longestFocusMs,
  }) =>
      FocusIntegrity(
        sessionId: sessionId ?? this.sessionId,
        plannedDuration: plannedDuration ?? this.plannedDuration,
        actualDuration: actualDuration ?? this.actualDuration,
        interruptions: interruptions ?? this.interruptions,
        taskSwitches: taskSwitches ?? this.taskSwitches,
        abandoned: abandoned ?? this.abandoned,
        completed: completed ?? this.completed,
        longestFocusMs: longestFocusMs ?? this.longestFocusMs,
      );
}

/// Typedef alias for FocusIntegrity.
typedef FocusIntegrityRecord = FocusIntegrity;
