import 'package:flutter/material.dart';
import '../../services/ai_scaffolding_service.dart';
import '../../ui/theme_notebook.dart';

class CueGradientWidget extends StatelessWidget {
  final ScaffoldingLevel currentLevel;
  final ValueChanged<ScaffoldingLevel>? onLevelSelected;

  const CueGradientWidget({
    super.key,
    required this.currentLevel,
    this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final levels = ScaffoldingLevel.values;
    final idx = levels.indexOf(currentLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SCAFFOLD GRADIENT', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5)),
            Text('LEVEL $idx / ${levels.length - 1} (${currentLevel.name.toUpperCase()})',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: NotebookTheme.oxblood, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(levels.length, (i) {
            final active = i <= idx;
            return Expanded(
              child: GestureDetector(
                onTap: onLevelSelected != null ? () => onLevelSelected!(levels[i]) : null,
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < levels.length - 1 ? 3 : 0),
                  decoration: BoxDecoration(
                    color: active ? NotebookTheme.oxblood.withValues(alpha: 0.3 + (i / levels.length * 0.7)) : NotebookTheme.graphite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

