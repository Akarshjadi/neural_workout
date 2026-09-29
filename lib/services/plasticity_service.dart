import 'dart:math';

import '../models/blurt_score.dart';
import '../models/daily_checkin.dart';
import '../models/note.dart';
import '../models/session.dart';

/// Behavioral recall-speed trend (behavioral proxy, not cholinergic measurement).
class CognitiveSpeedResult {
  final double currentMs;
  final double slopePerDay;
  final String trend; // 'sharpening' | 'stable' | 'slowing'
  final bool isLearning;
  
  const CognitiveSpeedResult({
    required this.currentMs,
    required this.slopePerDay,
    required this.trend,
    required this.isLearning,
  });
  
  Map<String, dynamic> toJson() => {
    'currentMs': currentMs,
    'slopePerDay': slopePerDay,
    'trend': trend,
    'isLearning': isLearning,
  };
}

/// Self-reported recovery index (behavioral proxy, not BDNF measurement).
class RecoveryReserveResult {
  final double index0to100;
  final bool isLearning;
  
  const RecoveryReserveResult({
    required this.index0to100,
    required this.isLearning,
  });

  Map<String, dynamic> toJson() => {
    'index0to100': index0to100,
    'isLearning': isLearning,
  };
}

/// Behavioral challenge calibration proxy (behavioral proxy, not neurochemical measurement).
class DifficultyResult {
  final double index0to100;
  final String detail;
  final bool isLearning;
  
  const DifficultyResult({
    required this.index0to100,
    required this.detail,
    required this.isLearning,
  });

  Map<String, dynamic> toJson() => {
    'index0to100': index0to100,
    'detail': detail,
    'isLearning': isLearning,
  };
}

/// Graph connectivity density proxy (behavioral proxy, not physiological connectome).
class NetworkResult {
  final double index0to100;
  final int linked;
  final int total;
  final int components;
  
  const NetworkResult({
    required this.index0to100,
    required this.linked,
    required this.total,
    required this.components,
  });

  Map<String, dynamic> toJson() => {
    'index0to100': index0to100,
    'linked': linked,
    'total': total,
    'components': components,
  };
}

/// Self-directed focus priming consistency (behavioral proxy, not neural state monitoring).
class MindfulnessResult {
  final double index0to100;
  final bool isLearning;
  
  const MindfulnessResult({
    required this.index0to100,
    required this.isLearning,
  });

  Map<String, dynamic> toJson() => {
    'index0to100': index0to100,
    'isLearning': isLearning,
  };
}


class PlasticityProfile {
  final CognitiveSpeedResult speed;
  final RecoveryReserveResult recovery;
  final DifficultyResult difficulty;
  final NetworkResult network;
  final MindfulnessResult mindfulness;
  /// Note: This is an internal behavioural proxy index, NOT the user-facing composite score. Rankings use RankingService.evidenceScore.
  final double overall0to100;
  final String disclaimer;

  const PlasticityProfile({
    required this.speed,
    required this.recovery,
    required this.difficulty,
    required this.network,
    required this.mindfulness,
    required this.overall0to100,
    this.disclaimer =
        'Behavioral proxies only. Not physiological measurements. Correlations are observational.',
  });

  Map<String, dynamic> toJson() => {
    'speed': speed.toJson(),
    'recovery': recovery.toJson(),
    'difficulty': difficulty.toJson(),
    'network': network.toJson(),
    'mindfulness': mindfulness.toJson(),
    'overall0to100': overall0to100,
    'disclaimer': disclaimer,
  };
}

/// Behavioral adaptivity profile service — five behavioral proxies grounded in 2025–2026 research.
class PlasticityService {
  const PlasticityService();
  /// 1. Behavioral recall-speed trend (behavioral proxy, not cholinergic measurement). 
  CognitiveSpeedResult cognitiveSpeed(List<BlurtScore> blurts, {DateTime? now}) {
    final refDate = now ?? DateTime.now();
    final cutoff = refDate.subtract(const Duration(days: 30));
    final recent = blurts.where((b) => b.recallSpeedMs != null && b.date.isAfter(cutoff)).toList();
    recent.sort((a, b) => a.date.compareTo(b.date));
    if (recent.isEmpty) {
      return const CognitiveSpeedResult(currentMs: 0, slopePerDay: 0, trend: 'stable', isLearning: true);
    }
    final uniqueDays = recent.map((b) => "${b.date.year}-${b.date.month}-${b.date.day}").toSet().length;
    double ewma = recent.first.recallSpeedMs!.toDouble();
    const double alpha = 0.3;
    final smoothed = <double>[];
    final days = <double>[];
    for (final b in recent) {
      ewma = (alpha * b.recallSpeedMs!) + ((1.0 - alpha) * ewma);
      smoothed.add(ewma);
      days.add(b.date.difference(cutoff).inDays.toDouble());
    }
    if (recent.length < 2) {
      return CognitiveSpeedResult(currentMs: smoothed.last, slopePerDay: 0, trend: 'stable', isLearning: uniqueDays < 7);
    }
    final meanDay = days.reduce((a, b) => a + b) / days.length;
    final meanMs = smoothed.reduce((a, b) => a + b) / smoothed.length;
    double num = 0, den = 0;
    for (int i = 0; i < days.length; i++) {
      num += (days[i] - meanDay) * (smoothed[i] - meanMs);
      den += (days[i] - meanDay) * (days[i] - meanDay);
    }
    final double slope = den == 0 ? 0 : num / den;
    String trend = 'stable';
    if (slope < -10) {
      trend = 'sharpening';
    } else if (slope > 10) {
      trend = 'slowing';
    }
    return CognitiveSpeedResult(currentMs: smoothed.last, slopePerDay: slope, trend: trend, isLearning: uniqueDays < 7);
  }

  /// 2. Self-reported recovery index (behavioral proxy, not BDNF measurement).
  RecoveryReserveResult recoveryReserve(List<DailyCheckin> checkins, {DateTime? now}) {
    final refDate = now ?? DateTime.now();
    final cutoff = refDate.subtract(const Duration(days: 7));
    final recent = checkins.where((c) => c.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return const RecoveryReserveResult(index0to100: 0, isLearning: true);
    final uniqueDays = recent.map((c) => "${c.date.year}-${c.date.month}-${c.date.day}").toSet().length;
    double totalWeighted = 0;
    for (final c in recent) {
      totalWeighted += ((c.sleep - 1) * 25.0 * 0.4) + ((c.energy - 1) * 25.0 * 0.3) + ((c.activity - 1) * 25.0 * 0.3);
    }
    return RecoveryReserveResult(index0to100: totalWeighted / recent.length, isLearning: uniqueDays < 7);
  }

  /// 3. Behavioral challenge calibration proxy (behavioral proxy, not neurochemical measurement).
  DifficultyResult desirableDifficulty(List<BlurtScore> blurts, List<Map<String,dynamic>> reviews, {DateTime? now}) {
    final refDate = now ?? DateTime.now();
    final cutoff = refDate.subtract(const Duration(days: 7));
    final recentBlurts = blurts.where((b) => b.date.isAfter(cutoff)).toList();
    final recentReviews = reviews.where((r) {
      if (!r.containsKey('date')) return false;
      final d = DateTime.tryParse(r['date'] as String);
      return d != null && d.isAfter(cutoff);
    }).toList();
    final uniqueBlurtDays = recentBlurts.map((b) => "${b.date.year}-${b.date.month}-${b.date.day}").toSet();
    final uniqueReviewDays = recentReviews.map((r) {
      final d = DateTime.tryParse(r['date'] as String)!;
      return "${d.year}-${d.month}-${d.day}";
    }).toSet();
    final isLearning = (uniqueBlurtDays.length < 7 && uniqueReviewDays.length < 7);
    if (recentBlurts.isEmpty && recentReviews.isEmpty) return const DifficultyResult(index0to100: 0, detail: 'learning...', isLearning: true);
    
    double accScore = 0;
    if (recentBlurts.isNotEmpty) {
      final double avgAcc = recentBlurts.map((b) => b.scorePct).reduce((a, b) => a + b) / recentBlurts.length;
      accScore = (100 - ((avgAcc - 0.775).abs() * (100 / 0.225))).clamp(0.0, 100.0);
    }
    double ratingScore = 0, interleaveScore = 0;
    if (recentReviews.isNotEmpty) {
      final int hardAgain = recentReviews.where((r) => r['rating'] == 'hard' || r['rating'] == 'again').length;
      final double mix = hardAgain / recentReviews.length;
      ratingScore = (100 - ((mix - 0.35).abs() * (100 / 0.65))).clamp(0.0, 100.0);
      final int inter = recentReviews.where((r) => r['wasInterleaved'] == true).length;
      final double interPerDay = inter / max(1, uniqueReviewDays.length);
      interleaveScore = ((interPerDay / 3.0) * 100).clamp(0.0, 100.0);
    }
    double index = 0;
    if (recentBlurts.isNotEmpty && recentReviews.isNotEmpty) {
      index = (accScore * 0.4) + (ratingScore * 0.4) + (interleaveScore * 0.2);
    } else if (recentBlurts.isNotEmpty) {
      index = accScore;
    } else {
      index = (ratingScore * 0.7) + (interleaveScore * 0.3);
    }
    String detail = 'balanced';
    final double avgAcc = recentBlurts.isNotEmpty ? recentBlurts.map((b) => b.scorePct).reduce((a, b) => a + b) / recentBlurts.length : 0;
    if (recentBlurts.isNotEmpty) {
      if (avgAcc > 0.90) {
        detail = 'too easy';
      } else if (avgAcc < 0.60) {
        detail = 'too hard';
      }
    } else if (recentReviews.isNotEmpty) {
      // If we only have reviews to go on
      if (ratingScore < 30) {
        detail = 'too hard';
      }
    }
    return DifficultyResult(index0to100: index, detail: detail, isLearning: isLearning);
  }
  /// 4. Graph connectivity density proxy (behavioral proxy, not physiological connectome).
  NetworkResult networkIntegration(List<Note> notes, Map<int,int> linkCounts) {
    if (notes.isEmpty) return const NetworkResult(index0to100: 0, linked: 0, total: 0, components: 0);
    final int linked = notes.where((n) => (linkCounts[n.id] ?? 0) > 0).length;
    final double ratio = linked / notes.length;
    final double avgLinks = linkCounts.values.fold(0, (a, b) => a + b) / notes.length;
    final int components = (linked > 0) ? (notes.length - linked + 1) : 0; 
    final double sc = (ratio * 50) + (min(avgLinks, 5.0) / 5.0 * 50);
    return NetworkResult(
      index0to100: sc.clamp(0.0, 100.0), linked: linked, total: notes.length, components: components,
    );
  }

  /// 5. Self-directed focus priming consistency (behavioral proxy, not neural state monitoring).
  MindfulnessResult mindfulness(List<Session> sessions, {DateTime? now}) {
    final refDate = now ?? DateTime.now();
    final cutoff = refDate.subtract(const Duration(days: 30));
    final recent = sessions.where((s) => s.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return const MindfulnessResult(index0to100: 0, isLearning: true);
    final uniqueDays = recent.map((s) => "${s.date.year}-${s.date.month}-${s.date.day}").toSet().length;
    final int primed = recent.where((s) => s.focusPrimed).length;
    return MindfulnessResult(
      index0to100: (primed / recent.length) * 100.0,
      isLearning: uniqueDays < 7,
    );
  }

  PlasticityProfile profile({
    required List<BlurtScore> blurts, 
    required List<DailyCheckin> checkins, 
    required List<Map<String,dynamic>> reviews,
    required List<Note> notes,
    required Map<int,int> linkCounts,
    required List<Session> sessions,
    DateTime? now,
  }) {
    final s = cognitiveSpeed(blurts, now: now);
    final r = recoveryReserve(checkins, now: now);
    final d = desirableDifficulty(blurts, reviews, now: now);
    final n = networkIntegration(notes, linkCounts);
    final m = mindfulness(sessions, now: now);
    double speedSc = 100 - ((s.currentMs - 500) / 4500 * 100);
    speedSc = speedSc.clamp(0.0, 100.0);
    final double over = (speedSc * 0.20) + (r.index0to100 * 0.20) + (d.index0to100 * 0.25) + 
                  (n.index0to100 * 0.25) + (m.index0to100 * 0.10);             
    return PlasticityProfile(
      speed: s, recovery: r, difficulty: d, network: n, mindfulness: m, overall0to100: over.clamp(0.0, 100.0),
    );
  }
}

