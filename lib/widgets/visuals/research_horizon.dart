import '../../services/research_catalog.dart';
import 'package:flutter/material.dart';
import '../../ui/theme_notebook.dart';

class ResearchHorizonWidget extends StatelessWidget {
  final double height;

  const ResearchHorizonWidget({
    super.key,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final tiers = [
      ('BEHAVIORAL (T1-4)', SafetyClassification.safeSoftware, 1.0, 'IMPLEMENTED'),
      ('CONTEXT/CIRCADIAN (T5-7)', SafetyClassification.contextual, 0.75, 'INTEGRATED'),
      ('INSTRUMENTATION (T8-10)', SafetyClassification.sensorRequired, 0.45, 'SENSOR LAYER'),
      ('MEDICAL/NEURAL (T11-13)', SafetyClassification.medicalResearch, 0.2, 'RESEARCH SPEC'),
      ('INVASIVE/HIGH-RISK (T14)', SafetyClassification.invasiveOrHighRisk, 0.05, 'DISCLAIMER ONLY'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RESEARCH EVIDENCE HORIZON', style: Theme.of(context).textTheme.labelSmall),
            Text('14 COGNITIVE TIERS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
            color: NotebookTheme.paper,
          ),
          child: Column(
            children: [
              for (final t in tiers) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(t.$1, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.bold))),
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: NotebookTheme.graphite.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(1),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: t.$3,
                            child: Container(
                              color: t.$3 >= 0.7 ? NotebookTheme.oxblood : NotebookTheme.graphite,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: Text(t.$4, textAlign: TextAlign.right, style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: t.$3 >= 0.7 ? NotebookTheme.oxblood : NotebookTheme.graphite)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

