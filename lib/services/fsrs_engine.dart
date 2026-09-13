import 'package:fsrs/fsrs.dart';

/// Thin, pure-Dart wrapper around the FSRS scheduler.
///
/// Keeps the `fsrs` package's low-level `Card` API behind app-friendly calls,
/// and gives the review history the app logs (turns a rating choice into the
/// updated card + interval one-liner). One of the three "real risks" in the
/// plan (silent scheduling math), so it gets direct unit tests.
///
/// The package returns a new Card on every review; we hand back the exact
/// object to persist so `due`/`stability`/`difficulty` stay correct.
class FsrsEngine {
  final Scheduler _scheduler;

  FsrsEngine({Scheduler? scheduler}) : _scheduler = scheduler ?? Scheduler();

  /// Creates a brand-new card in the learning state for a fresh note.
  Card newCard() => Card(cardId: DateTime.now().millisecondsSinceEpoch);

  /// Reviews [card] with [rating], returning the updated card + the interval
  /// until the next due date (for display like "review in 3d").
  ({Card card, Duration interval, Rating rating}) review(
    Card card,
    Rating rating,
  ) {
    final result = _scheduler.reviewCard(card, rating);
    final interval = result.card.due.difference(result.reviewLog.reviewDateTime);
    return (
      card: result.card,
      interval: interval,
      rating: rating,
    );
  }

  /// Current predicted recall probability (retrievability) for [card].
  double retrievability(Card card, {DateTime? at}) =>
      _scheduler.getCardRetrievability(card, currentDateTime: at);

  /// Human-friendly "in Xd / Xh / now" for display.
  static String intervalLabel(Duration interval) {
    if (interval.isNegative || interval.inSeconds < 60) return 'now';
    if (interval.inMinutes < 60) return 'in ${interval.inMinutes}m';
    if (interval.inHours < 24) return 'in ${interval.inHours}h';
    return 'in ${interval.inDays}d';
  }
}