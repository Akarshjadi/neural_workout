import 'package:flutter/material.dart';
import '../../ui/theme_notebook.dart';

class ContrastMatrixRow {
  final String dimension;
  final String conceptAValue;
  final String conceptBValue;
  final bool isContrastPoint;

  const ContrastMatrixRow({
    required this.dimension,
    required this.conceptAValue,
    required this.conceptBValue,
    this.isContrastPoint = true,
  });
}

class ContrastMatrixWidget extends StatelessWidget {
  final String conceptAName;
  final String conceptBName;
  final List<ContrastMatrixRow> rows;

  const ContrastMatrixWidget({
    super.key,
    required this.conceptAName,
    required this.conceptBName,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
        color: NotebookTheme.paper,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: NotebookTheme.graphite.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text('FEATURE', style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(conceptAName.toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.bold, color: NotebookTheme.oxblood))),
                Expanded(flex: 3, child: Text(conceptBName.toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.bold, color: NotebookTheme.ink))),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(rows[i].dimension, style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: NotebookTheme.graphite)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(rows[i].conceptAValue, style: const TextStyle(fontFamily: 'Georgia', fontSize: 11, color: NotebookTheme.ink)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(rows[i].conceptBValue, style: const TextStyle(fontFamily: 'Georgia', fontSize: 11, color: NotebookTheme.ink)),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(height: 1, thickness: 0.5, color: NotebookTheme.graphite.withValues(alpha: 0.15)),
          ],
        ],
      ),
    );
  }
}
