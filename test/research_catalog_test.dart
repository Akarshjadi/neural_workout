import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/research_catalog.dart';

void main() {
  setUp(() {
    ResearchCatalog.ensureInitialized();
  });

  test('ResearchCatalog initializes and contains entries across all 14 tiers', () {
    final all = ResearchCatalog.getAll();
    expect(all.length, greaterThanOrEqualTo(20));

    final tiersFound = all.map((e) => e.tier).toSet();
    for (int tier = 1; tier <= 14; tier++) {
      expect(tiersFound.contains(tier), isTrue, reason: 'Tier $tier must be represented');
    }
  });

  test('ResearchCatalog resolves canonical IDs from aliases', () {
    final blurtEntry = ResearchCatalog.getById('blurt');
    expect(blurtEntry, isNotNull);
    expect(blurtEntry!.id, equals('free_retrieval'));

    final fsrsEntry = ResearchCatalog.getById('spaced_repetition');
    expect(fsrsEntry, isNotNull);
    expect(fsrsEntry!.id, equals('adaptive_spacing'));
  });

  test('ResearchCatalog respects safety classifications and flags high-risk research items', () {
    final tms = ResearchCatalog.getById('transcranial_stimulation');
    expect(tms, isNotNull);
    expect(tms!.safetyLevel, equals(SafetyClassification.invasiveOrHighRisk));
    expect(tms.implementationStatus, equals(ImplementationStatus.researchOnly));

    final freeRecall = ResearchCatalog.getById('free_retrieval');
    expect(freeRecall, isNotNull);
    expect(freeRecall!.safetyLevel, equals(SafetyClassification.safeSoftware));
    expect(freeRecall.implementationStatus, equals(ImplementationStatus.implemented));
  });

  test('ResearchCatalog search queries find matching mechanisms', () {
    final results = ResearchCatalog.search('feynman');
    expect(results.isNotEmpty, isTrue);
    expect(results.first.id, equals('self_explanation'));
  });
}
