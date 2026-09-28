import 'package:flutter/material.dart';
import '../../ui/theme_notebook.dart';

/// Global visual evidence state conventions:
/// SOLID    = observed
/// DASHED   = estimated
/// FADED    = projected
/// OUTLINED = hypothetical
enum EvidenceState {
  observed,
  estimated,
  projected,
  hypothetical,
}

/// Helper styles and paints for consistent visual semantics across all components.
class VisualSemantics {
  static Paint strokePaint({
    Color color = NotebookTheme.graphite,
    double width = 1.5,
    EvidenceState state = EvidenceState.observed,
  }) {
    final paint = Paint()
      ..color = state == EvidenceState.projected
          ? color.withValues(alpha: 0.35)
          : (state == EvidenceState.hypothetical ? color.withValues(alpha: 0.6) : color)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    return paint;
  }

  static Paint fillPaint({
    Color color = NotebookTheme.oxblood,
    EvidenceState state = EvidenceState.observed,
    double opacity = 0.2,
  }) {
    double alpha = opacity;
    if (state == EvidenceState.projected) alpha *= 0.4;
    if (state == EvidenceState.hypothetical) alpha *= 0.6;
    return Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
  }

  /// Alias for stroke Paint with observed state.
  static Paint observedPaint({
    Color color = NotebookTheme.graphite,
    double width = 1.5,
  }) =>
      strokePaint(color: color, width: width, state: EvidenceState.observed);

  /// Alias for stroke Paint with estimated state.
  static Paint estimatedPaint({
    Color color = NotebookTheme.graphite,
    double width = 1.5,
  }) =>
      strokePaint(color: color, width: width, state: EvidenceState.estimated);

  /// Alias for fill Paint with projected state.
  static Paint projectedPaint({
    Color color = NotebookTheme.oxblood,
    double opacity = 0.2,
  }) =>
      fillPaint(color: color, state: EvidenceState.projected, opacity: opacity);

  /// Alias for fill Paint with hypothetical state.
  static Paint hypotheticalPaint({
    Color color = NotebookTheme.oxblood,
    double opacity = 0.2,
  }) =>
      fillPaint(
          color: color, state: EvidenceState.hypothetical, opacity: opacity);

  static void drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashWidth = 4.0,
    double dashSpace = 3.0,
  }) {
    final totalDist = (p2 - p1).distance;
    if (totalDist <= 0) return;
    final dir = (p2 - p1) / totalDist;
    double walked = 0.0;
    while (walked < totalDist) {
      final segLen = (walked + dashWidth > totalDist) ? (totalDist - walked) : dashWidth;
      final start = p1 + dir * walked;
      final end = start + dir * segLen;
      canvas.drawLine(start, end, paint);
      walked += dashWidth + dashSpace;
    }
  }
}

