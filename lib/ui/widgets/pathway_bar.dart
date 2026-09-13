import 'package:flutter/material.dart';

import '../../services/pathway_service.dart';
import '../theme.dart';

/// A single pathway activation bar for the Today dashboard.
///
/// Accessibility-critical: the bar is labeled with the pathway name + a
/// text percentage and trend arrow (⬆/⬇/→). Color is decorative, never the
/// only signal (UIUX §1).
class PathwayBar extends StatelessWidget {
  final PathwayInfo info;
  final String trend; // '⬆' '⬇' '→'

  const PathwayBar({super.key, required this.info, required this.trend});

  @override
  Widget build(BuildContext context) {
    final pct = info.percent;
    final color = _colorFor(pct);
    final done = info.completed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(info.label,
              style: const TextStyle(color: AppTheme.textPrimary))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 10,
                    backgroundColor: AppTheme.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$done/${info.target} done · ${pct.round()}% $trend',
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorFor(double pct) {
    if (pct >= 75) return AppTheme.accent;
    if (pct >= 40) return AppTheme.warm;
    return AppTheme.danger;
  }
}